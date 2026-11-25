#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('Before', 'After')][string]$Phase,
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
Import-Module ActiveDirectory
$config = Get-LabConfig
$layout = Get-LabLayout
$domain = Get-LabDomain

if (-not $Apply -or -not $PSCmdlet.ShouldProcess('Two disabled lab test accounts', 'Run delegated password reset authorization checks')) {
    Write-Output 'Preflight passed. The test will attempt resets against the two disabled fictional fixtures.'
    return
}

$name = "$($config.NetBIOS)\$($config.HelpdeskOperator)"
$credential = Get-Credential -UserName $name -Message 'Authenticate as the separate lab helpdesk operator'
if ($credential.UserName -ne $name -and $credential.UserName -ne "$($config.HelpdeskOperator)@$($config.Domain)") {
    throw 'Use the designated fictional helpdesk credentials.'
}

foreach ($target in @{
    'reset.inside' = $layout.People
    'reset.outside' = $layout.Operators
}.GetEnumerator()) {
    $dn = "CN=$($target.Key),$($target.Value)"
    $user = Get-ADUser -Identity $dn -Server $domain.PDCEmulator -Credential $credential -Properties Description
    if ($user.Enabled -or $user.Description -ne $config.PolicyOwner) { throw 'The target is outside the disabled test fixtures.' }
    $password = Read-Host "Enter a unique policy-compliant disposable password for $($target.Key)" -AsSecureString
    $success = $false
    try {
        Set-ADAccountPassword -Identity $dn -Reset -NewPassword $password -Credential $credential -Server $domain.PDCEmulator
        $success = $true
    } catch {
        if ($_.CategoryInfo.Category -ne 'PermissionDenied' -and
            $_.Exception.GetBaseException() -isnot [System.UnauthorizedAccessException]) { throw }
    }
    $shouldSucceed = $Phase -eq 'After' -and $target.Key -eq 'reset.inside'
    if ($success -ne $shouldSucceed) { throw "Unexpected authorization outcome on the disabled $($target.Key) test fixture." }
    Write-Output "PASS   $($target.Key) reset allowed=$success in $Phase"
}
