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
$system = Get-CimInstance -ClassName Win32_ComputerSystem
$computer = if ($Role -eq 'DC') { $config.DcName } else { $config.WorkstationName }
$address = if ($Role -eq 'DC') { $config.DcAddress } else { $config.WorkstationAddress }
$expectedRole = if ($Role -eq 'DC') { 2 } else { 0 }
$adapters = @(Get-NetAdapter | Where-Object Status -eq 'Up')
if ($system.Name -ne $computer -or $system.DomainRole -ne $expectedRole -or $system.PartOfDomain -or $adapters.Count -ne 1) {
    throw 'Use this command on the renamed, standalone lab guest with exactly one connected NIC.'
}
if (-not $Apply -or -not $PSCmdlet.ShouldProcess($computer, "Set $address/24 with lab DNS and no default gateway")) {
    Write-Output "Preflight passed. Check the hypervisor attachment before setting $address."
    return
}

$index = $adapters[0].ifIndex
Set-NetIPInterface -InterfaceIndex $index -AddressFamily IPv4 -Dhcp Disabled
$null = Remove-NetRoute -InterfaceIndex $index -DestinationPrefix '0.0.0.0/0' -Confirm:$false -ErrorAction SilentlyContinue
$old = @(Get-NetIPAddress -InterfaceIndex $index -AddressFamily IPv4)
foreach ($item in $old) {
    if ($item.IPAddress -ne $address -or $item.PrefixLength -ne 24) {
        Remove-NetIPAddress -InputObject $item -Confirm:$false
    }
}
if (-not ($old | Where-Object { $_.IPAddress -eq $address -and $_.PrefixLength -eq 24 })) {
    New-NetIPAddress -InterfaceIndex $index -IPAddress $address -PrefixLength 24 | Out-Null
}
Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $config.DcAddress
Assert-LabNetwork -Role $Role
Write-Output 'Guest network matches the lab plan.'
