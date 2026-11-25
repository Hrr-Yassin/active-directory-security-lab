#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply, [switch]$InitializeKds, [switch]$SingleDcLab)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
Import-Module ActiveDirectory
Import-Module Kds
$config = Get-LabConfig
$layout = Get-LabLayout
$domain = Get-LabDomain
$hosts = Get-ADGroup -Identity $config.ServiceHosts -Properties member
if ($hosts.DistinguishedName -ne "CN=$($config.ServiceHosts),$($layout.Groups)" -or @($hosts.member).Count -ne 0) {
    throw 'The staged gMSA requires the empty, managed service host group.'
}

if (-not $Apply -or -not $PSCmdlet.ShouldProcess($config.Domain, 'Initialize the lab managed service account')) {
    Write-Output 'Preflight passed. The gMSA is staged for outbound authentication with no eligible retrieval hosts.'
    return
}

$keys = @(Get-KdsRootKey | Where-Object { $null -ne $_ })
if ($keys.Count -eq 0) {
    if (-not $InitializeKds) { throw 'No KDS root key exists. Use -Apply -InitializeKds to create one for the lab forest.' }
    if ($SingleDcLab) {
        if (@(Get-ADDomainController -Filter *).Count -ne 1) {
            throw 'The Microsoft single-DC test setup requires exactly one domain controller.'
        }
        Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10)) | Out-Null
        Write-Output 'KDS root key created with the Microsoft single-DC test timing. Rerun with -Apply.'
    } else {
        Add-KdsRootKey -EffectiveImmediately | Out-Null
        Write-Output 'KDS root key created. Allow the Microsoft KDS propagation window, then rerun with -Apply.'
    }
    return
}
$configuration = (Get-ADRootDSE -Server $domain.PDCEmulator).ConfigurationNamingContext
$keyContainer = "CN=Master Root Keys,CN=Group Key Distribution Service,CN=Services,$configuration"
$effectiveBy = [datetime]::UtcNow.AddHours(-10).ToFileTimeUtc()
$readyKey = Get-ADObject -Server $domain.PDCEmulator -SearchBase $keyContainer -SearchScope OneLevel `
    -LDAPFilter "(&(objectClass=msKds-ProvRootKey)(msKds-UseStartTime<=$effectiveBy))" -ResultSetSize 1
if (-not $readyKey) {
    throw 'Wait at least ten hours from KDS key activation before provisioning the managed service account.'
}

$pendingDescription = "$($config.PolicyOwner) (provisioning)"
$service = Get-ADServiceAccount -Filter "Name -eq '$($config.ServiceName)'" -Properties Description -Server $domain.PDCEmulator
if ($service) {
    if ($service.ObjectClass -ne 'msDS-GroupManagedServiceAccount' -or
        $service.Description -notin @($config.PolicyOwner, $pendingDescription) -or
        $service.DistinguishedName -ne "CN=$($config.ServiceName),$($layout.Services)") {
        throw 'An incompatible service account already uses the managed name.'
    }
    if ($service.Description -eq $config.PolicyOwner) {
        Write-Output 'The managed fixture already exists. Use the assessment to detect drift.'
        return
    }
    if ($service.Enabled) { throw 'The incomplete managed fixture is enabled. Review it before retrying.' }
} else {
    $managedAccount = @{
        Name = $config.ServiceName
        Description = $pendingDescription
        Path = $layout.Services
        RestrictToOutboundAuthenticationOnly = $true
        KerberosEncryptionType = @('AES128', 'AES256')
        Enabled = $false
        Server = $domain.PDCEmulator
        PassThru = $true
    }
    $service = New-ADServiceAccount @managedAccount
}

# Outbound-only creation and password retrieval permissions use different cmdlets.
$retrievalPolicy = @{
    Identity = $service
    Description = $config.PolicyOwner
    PrincipalsAllowedToRetrieveManagedPassword = $hosts.DistinguishedName
    Enabled = $true
    Server = $domain.PDCEmulator
}
Set-ADServiceAccount @retrievalPolicy
Write-Output 'Staged the outbound-only gMSA with an empty retrieval group.'
