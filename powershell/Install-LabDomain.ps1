#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
$config = Get-LabConfig
Assert-LabComputer -Role DC -Standalone

if (-not $Apply -or -not $PSCmdlet.ShouldProcess($config.Domain, 'Create a new AD DS forest and restart the new server')) {
    Write-Output "Preflight passed for $($config.DcName). Run with -Apply to install AD DS, DNS and management tools."
    return
}

Import-Module ServerManager
$result = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
if (-not $result.Success) { throw 'Installation of the AD DS role failed.' }
if ($result.RestartNeeded -eq 'Yes') { throw 'Restart the server, confirm its lab network, and rerun this script.' }

Import-Module ADDSDeployment
$promotion = @{
    DomainName = $config.Domain
    DomainNetbiosName = $config.NetBIOS
    ForestMode = 'WinThreshold'
    DomainMode = 'WinThreshold'
    InstallDns = $true
    SafeModeAdministratorPassword = Read-Host 'Enter the unique lab Directory Services Restore Mode password' -AsSecureString
}
Install-ADDSForest @promotion -Force
