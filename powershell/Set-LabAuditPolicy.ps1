#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('DC', 'Workstation')][string]$Role,
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
$config = Get-LabConfig
Assert-LabComputer -Role $Role

if (-not $Apply -or -not $PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Enable scoped advanced audit policy')) {
    Write-Output 'Preflight passed. Apply changes only the selected lab audit subcategories on this guest.'
    return
}

$lsa = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
if ((Get-LabRegistryNumber $lsa SCENoApplyLegacyAuditPolicy) -ne 1) {
    throw 'Refresh the hardened GPO first so legacy category auditing cannot override the subcategories.'
}

$subcategories = @($config.AuditLogon)
if ($Role -eq 'DC') {
    $subcategories += @($config.AuditUserManagement, $config.AuditGroupManagement, $config.AuditKerberosTicket)
}
foreach ($subcategory in $subcategories) {
    Invoke-LabNative auditpol.exe @('/set', "/subcategory:$subcategory", '/success:enable', '/failure:enable')
}
