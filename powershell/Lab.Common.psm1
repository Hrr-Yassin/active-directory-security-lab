#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$config = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Lab.Config.psd1')

function Get-LabConfig {
    $config.Clone()
}

function Get-LabLayout {
    $domainDn = ($config.Domain.Split('.') | ForEach-Object { "DC=$_" }) -join ','
    $root = "OU=$($config.ParentOU),$domainDn"
    @{
        Domain = $domainDn
        Root = $root
        People = "OU=People,$root"
        Operators = "OU=Operators,$root"
        Groups = "OU=Groups,$root"
        Services = "OU=Service Accounts,$root"
        Workstations = "OU=Workstations,$root"
        DomainControllers = "OU=Domain Controllers,$domainDn"
    }
}

function Assert-LabNetwork {
    param([Parameter(Mandatory)][ValidateSet('DC', 'Workstation')][string]$Role)

    $expected = if ($Role -eq 'DC') { $config.DcAddress } else { $config.WorkstationAddress }
    $adapters = @(Get-NetAdapter | Where-Object Status -eq 'Up')
    if ($adapters.Count -ne 1) { throw 'Connect exactly one lab NIC before continuing.' }

    $adapterIndex = $adapters[0].ifIndex
    $addresses = @(Get-NetIPAddress -InterfaceIndex $adapterIndex -AddressFamily IPv4)
    $dns = @((Get-DnsClientServerAddress -InterfaceIndex $adapterIndex -AddressFamily IPv4).ServerAddresses)
    $ipv6Dns = (Get-DnsClientServerAddress -InterfaceIndex $adapterIndex -AddressFamily IPv6).ServerAddresses
    $defaultRoute = Get-NetRoute | Where-Object DestinationPrefix -in '0.0.0.0/0', '::/0'
    $allowedDns = @($config.DcAddress)
    $allowedV6Dns = @()
    if ($Role -eq 'DC') {
        $allowedDns += '127.0.0.1'
        $allowedV6Dns += '::1'
    }
    if ($addresses.Count -ne 1 -or $addresses[0].IPAddress -ne $expected -or
        $addresses[0].PrefixLength -ne 24 -or $dns.Count -eq 0 -or
        ($dns | Where-Object { $_ -notin $allowedDns }) -or
        ($ipv6Dns | Where-Object { $_ -notin $allowedV6Dns }) -or $defaultRoute) {
        throw "The guest needs $expected/24, only the lab DC for DNS, and no IPv4 or IPv6 default route."
    }
}

function Assert-LabComputer {
    param(
        [Parameter(Mandatory)][ValidateSet('DC', 'Workstation')][string]$Role,
        [switch]$Standalone
    )

    $system = Get-CimInstance -ClassName Win32_ComputerSystem
    $name = if ($Role -eq 'DC') { $config.DcName } else { $config.WorkstationName }
    $expectedRole = if ($Role -eq 'DC') { 5 } else { 1 }
    if ($Standalone) { $expectedRole = if ($Role -eq 'DC') { 2 } else { 0 } }
    if ($system.Name -ne $name -or $system.DomainRole -ne $expectedRole -or
        ($Standalone -and $system.PartOfDomain) -or
        (-not $Standalone -and (-not $system.PartOfDomain -or $system.Domain -ne $config.Domain))) {
        throw "This command requires the dedicated $name guest in the expected membership state."
    }
    Assert-LabNetwork -Role $Role
}

function Get-LabDomain {
    Assert-LabComputer -Role DC
    Import-Module ActiveDirectory
    $domain = Get-ADDomain -Current LocalComputer
    if ($domain.DNSRoot -ne $config.Domain -or $domain.NetBIOSName -ne $config.NetBIOS -or
        $domain.Forest -ne $config.Domain -or $domain.PDCEmulator -ne "$($config.DcName).$($config.Domain)") {
        throw 'The local directory is outside the dedicated forest scope.'
    }
    $domain
}

function Invoke-LabNative {
    param(
        [Parameter(Mandatory)][string]$File,
        [Parameter(Mandatory)][string[]]$ArgumentList
    )
    $output = & $File @ArgumentList
    if ($LASTEXITCODE -ne 0) { throw "$File exited with code $LASTEXITCODE." }
    $output
}

function Get-LabRegistryNumber {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name)
    if (-not (Test-Path -LiteralPath $Path)) { return -1 }
    $item = Get-ItemProperty -LiteralPath $Path
    $property = $item.PSObject.Properties[$Name]
    if ($null -eq $property) { return -1 }
    [int]$property.Value
}

function Get-LabSid {
    param([Parameter(Mandatory)][string]$Account)
    ([System.Security.Principal.NTAccount]::new($Account)).Translate(
        [System.Security.Principal.SecurityIdentifier]
    ).Value
}

Export-ModuleMember -Function Get-LabConfig, Get-LabLayout, Assert-LabNetwork, Assert-LabComputer,
    Get-LabDomain, Invoke-LabNative, Get-LabRegistryNumber, Get-LabSid
