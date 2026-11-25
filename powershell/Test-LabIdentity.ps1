#Requires -Version 5.1
[CmdletBinding()]
param([switch]$IncludeLdaps)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
$config = Get-LabConfig
$layout = Get-LabLayout
Assert-LabComputer -Role Workstation

$current = [Security.Principal.WindowsIdentity]::GetCurrent()
$employee = $config.Departments | Where-Object { $current.Name -eq "$($config.NetBIOS)\$($_.User)" }
if (-not $employee) { throw 'Use the normal Windows sign-in of a fictional department user on the lab workstation.' }
$other = $config.Departments | Where-Object Name -ne $employee.Name
$fqdn = "$($config.DcName).$($config.Domain)"
$share = "\\$fqdn\$($employee.Name)"
$otherFile = "\\$fqdn\$($other.Name)\welcome.txt"

$null = Invoke-LabNative klist.exe @('get', "cifs/$fqdn")
Write-Output 'PASS   Kerberos service ticket acquired for the DC CIFS SPN'

Add-Type -AssemblyName System.DirectoryServices.Protocols
function Test-DirectoryBind {
    param([switch]$Tls)
    $port = if ($Tls) { 636 } else { 389 }
    $identifier = [System.DirectoryServices.Protocols.LdapDirectoryIdentifier]::new($fqdn, $port)
    $connection = [System.DirectoryServices.Protocols.LdapConnection]::new($identifier)
    try {
        $connection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Kerberos
        $connection.Timeout = [timespan]::FromSeconds(10)
        $connection.SessionOptions.ProtocolVersion = 3
        if ($Tls) {
            $connection.SessionOptions.SecureSocketLayer = $true
        } else {
            $connection.SessionOptions.Signing = $true
            $connection.SessionOptions.Sealing = $true
        }
        $connection.Bind()
        $request = [System.DirectoryServices.Protocols.SearchRequest]::new(
            '', '(objectClass=*)', [System.DirectoryServices.Protocols.SearchScope]::Base,
            [string[]]@('defaultNamingContext')
        )
        $answer = $connection.SendRequest($request)
        if ($answer.Entries.Count -ne 1 -or [string]$answer.Entries[0].Attributes['defaultNamingContext'][0] -ne $layout.Domain) {
            throw 'The directory returned an unexpected RootDSE.'
        }
    } finally {
        $connection.Dispose()
    }
}
Test-DirectoryBind
Write-Output 'PASS   Signed and sealed Kerberos LDAP bind and RootDSE on TCP 389'

if ($IncludeLdaps) {
    Test-DirectoryBind -Tls
    Write-Output 'PASS   Kerberos LDAPS bind and RootDSE using normal certificate validation on TCP 636'
}

$null = [IO.File]::ReadAllText((Join-Path $share 'welcome.txt'))
$probe = Join-Path $share ("check-{0}.txt" -f [guid]::NewGuid())
$content = [Text.Encoding]::UTF8.GetBytes('Fictional lab access check')
$stream = [IO.File]::Open($probe, 'CreateNew', 'Write', 'None')
try {
    try {
        $stream.Write($content, 0, $content.Length)
    } finally {
        $stream.Dispose()
    }
    if ([IO.File]::ReadAllText($probe) -ne 'Fictional lab access check') { throw 'Share write verification failed.' }
} finally {
    [IO.File]::Delete($probe)
}
Write-Output 'PASS   Own department can read, create, and delete a fictional file'

try {
    $null = [IO.File]::ReadAllText($otherFile)
} catch {
    if (($_.Exception.GetBaseException().HResult -band 0xffff) -ne 5) { throw }
    Write-Output 'PASS   Other department share returned Windows Access Denied'
    return
}
throw 'The other department file was readable by the current employee.'
