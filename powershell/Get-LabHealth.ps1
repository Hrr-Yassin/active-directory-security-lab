#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('DC', 'Workstation')][string]$Role)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
$config = Get-LabConfig
Assert-LabComputer -Role $Role
$fqdn = "$($config.DcName).$($config.Domain)"

$srv = @(Resolve-DnsName "_ldap._tcp.dc._msdcs.$($config.Domain)" -Type SRV -DnsOnly -Server $config.DcAddress |
    Where-Object Type -eq 'SRV')
$address = @(Resolve-DnsName $fqdn -Type A -DnsOnly -Server $config.DcAddress | Where-Object Type -eq 'A')
$answersMatch = $srv.Count -eq 1 -and $srv[0].NameTarget.TrimEnd('.') -eq $fqdn -and
    $address.Count -eq 1 -and $address[0].IPAddress -eq $config.DcAddress
if (-not $answersMatch) { throw 'AD DNS discovery and the DC host address do not match the lab topology.' }
Write-Output 'PASS   AD DNS service and host records'

Invoke-LabNative w32tm.exe @('/query', '/status')
if ($Role -eq 'DC') {
    $domain = Get-LabDomain
    $services = @(Get-Service NTDS, DNS, KDC, Netlogon, W32Time)
    if (@($services | Where-Object Status -ne 'Running').Count -gt 0) { throw 'A required DC service is stopped.' }
    $shares = @(Get-SmbShare | Where-Object Name -in 'SYSVOL', 'NETLOGON')
    if ($shares.Count -ne 2) { throw 'SYSVOL or NETLOGON is unavailable.' }
    $lines = Invoke-LabNative dcdiag.exe @('/test:Advertising', '/test:Services', '/test:SysVolCheck', '/test:NetLogons')
    if ($lines -match '\bfailed test\b') { throw 'One or more dcdiag tests failed. Inspect the console output with dcdiag.' }
    $lines
    Write-Output "PASS   AD DS, DNS, KDC, SYSVOL and NETLOGON for $($domain.DNSRoot)"
    return
}

if (-not (Test-ComputerSecureChannel -Server $fqdn)) { throw 'The workstation trust channel failed.' }
if (-not (Test-Path -LiteralPath "\\$fqdn\SYSVOL\$($config.Domain)")) { throw 'The workstation cannot access SYSVOL.' }
Invoke-LabNative w32tm.exe @('/stripchart', "/computer:$fqdn", '/dataonly', '/samples:3')
Write-Output 'PASS   Workstation domain trust and SYSVOL access. Review the printed clock offsets.'
