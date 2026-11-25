#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply, [switch]$ExtendSchema)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
Import-Module ActiveDirectory
Import-Module GroupPolicy
Import-Module LAPS
$config = Get-LabConfig
$layout = Get-LabLayout
$domain = Get-LabDomain
if ($domain.DomainMode -ne 'Windows2016Domain') { throw 'This lab requires 2016 domain mode for encrypted LAPS backups.' }
$gpo = Get-GPO -Name $config.WorkstationGpo -Domain $config.Domain
if ($gpo.Description -ne $config.PolicyOwner) { throw 'The designated GPO is outside the lab policy scope.' }

$schema = (Get-ADRootDSE).schemaNamingContext
$lapsAttribute = Get-ADObject -LDAPFilter '(lDAPDisplayName=msLAPS-EncryptedPassword)' -SearchBase $schema
if (-not $Apply -or -not $PSCmdlet.ShouldProcess($layout.Workstations, 'Configure Windows LAPS for the lab workstation OU')) {
    Write-Output "Preflight passed. LAPS schema present: $([bool]$lapsAttribute)."
    return
}
if (-not $lapsAttribute) {
    if (-not $ExtendSchema) { throw 'Explicitly select -ExtendSchema to extend the disposable forest schema.' }
    Update-LapsADSchema -Confirm:$false
}
Set-LapsADComputerSelfPermission -Identity $layout.Workstations
$key = 'HKLM\SOFTWARE\Microsoft\Policies\LAPS'
$settings = @{
    BackupDirectory = 2
    ADPasswordEncryptionEnabled = 1
    PasswordLength = 20
    PasswordAgeDays = 30
}
foreach ($item in $settings.GetEnumerator()) {
    Set-GPRegistryValue -Guid $gpo.Id -Domain $config.Domain -Key $key -ValueName $item.Key -Type DWord -Value $item.Value | Out-Null
}
Write-Output 'Refresh policy and run Invoke-LapsPolicyProcessing on the workstation. Leave the encrypted backup access at its default domain administrator scope.'
