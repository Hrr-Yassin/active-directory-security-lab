#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
$config = Get-LabConfig
$layout = Get-LabLayout
Assert-LabComputer -Role Workstation -Standalone
$edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
if ($edition -notmatch '^(Professional|Enterprise|Education|IoTEnterprise)') {
    throw "Windows edition $edition is outside the supported domain-join editions for this lab."
}

$dc = "$($config.DcName).$($config.Domain)"
$answers = Resolve-DnsName "_ldap._tcp.dc._msdcs.$($config.Domain)" -Type SRV -Server $config.DcAddress -DnsOnly
if (-not ($answers | Where-Object { $_.Type -eq 'SRV' -and $_.NameTarget.TrimEnd('.') -eq $dc })) {
    throw 'Domain controller discovery did not identify the lab DC.'
}
if (-not $Apply -or -not $PSCmdlet.ShouldProcess($config.WorkstationName, "Join $($config.Domain)")) {
    Write-Output 'Preflight passed. Apply only on the approved lab workstation.'
    return
}

$credential = Get-Credential -UserName "$($config.NetBIOS)\$($config.Administrator)" -Message 'Enter the lab join administrator credential'
if ($credential.UserName -ne "$($config.NetBIOS)\$($config.Administrator)" -and
    $credential.UserName -ne "$($config.Administrator)@$($config.Domain)") {
    throw 'Use the designated fictional lab administrator account for this join.'
}
Add-Computer -DomainName $config.Domain -Server $dc -OUPath $layout.Workstations -Credential $credential -PassThru
Write-Output 'Restart the workstation from the console to complete the join.'
