#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('PrepareClients', 'Enforce')][string]$Stage,
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
Import-Module ActiveDirectory
Import-Module GroupPolicy
$config = Get-LabConfig
$layout = Get-LabLayout
$domain = Get-LabDomain

if (-not $Apply -or -not $PSCmdlet.ShouldProcess($config.Domain, "Apply $Stage policy in the dedicated forest")) {
    Write-Output "Preflight passed for $Stage. Capture both Before files before applying hardening."
    return
}

function Get-OrCreateLabPolicy {
    param([string]$Name, [string]$Target)

    $gpo = Get-GPO -All -Domain $config.Domain | Where-Object DisplayName -eq $Name
    if (-not $gpo) { $gpo = New-GPO -Name $Name -Comment $config.PolicyOwner -Domain $config.Domain }
    if (@($gpo).Count -ne 1 -or $gpo.Description -ne $config.PolicyOwner) {
        throw "Group Policy object $Name was not created by this lab. Review it before applying changes."
    }
    $link = (Get-GPInheritance -Target $Target -Domain $config.Domain).GpoLinks | Where-Object GpoId -eq $gpo.Id
    if (-not $link) {
        New-GPLink -Guid $gpo.Id -Target $Target -Domain $config.Domain -LinkEnabled Yes | Out-Null
    } elseif (-not $link.Enabled) {
        Set-GPLink -Guid $gpo.Id -Target $Target -Domain $config.Domain -LinkEnabled Yes | Out-Null
    }
    $gpo
}

function Write-LabRegistryDword {
    param([guid]$Id, [string]$Key, [string]$Name, [int]$Value)
    Set-GPRegistryValue -Guid $Id -Domain $config.Domain -Key $Key -ValueName $Name -Type DWord -Value $Value | Out-Null
}

$dcPolicy = Get-OrCreateLabPolicy -Name $config.DcGpo -Target $layout.DomainControllers
$wsPolicy = Get-OrCreateLabPolicy -Name $config.WorkstationGpo -Target $layout.Workstations
$lsa = 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa'
$services = 'HKLM\SYSTEM\CurrentControlSet\Services'

if ($Stage -eq 'PrepareClients') {
    foreach ($policy in $dcPolicy, $wsPolicy) {
        Write-LabRegistryDword $policy.Id "$services\LDAP" LDAPClientIntegrity 2
        Write-LabRegistryDword $policy.Id "$services\LanmanWorkstation\Parameters" RequireSecuritySignature 1
        Write-LabRegistryDword $policy.Id "$lsa\MSV1_0" AuditReceivingNTLMTraffic 2
    }
    Write-LabRegistryDword $dcPolicy.Id "$services\Netlogon\Parameters" AuditNTLMInDomain 7
    Write-Output 'Refresh Group Policy locally on both guests. Check signed LDAP, SYSVOL, and the NTLM Operational log before enforcement.'
    return
}

$duration = New-TimeSpan -Minutes $config.LockoutMinutes
$passwordPolicy = @{
    Identity = $domain.DistinguishedName
    ComplexityEnabled = $true
    MinPasswordLength = $config.PasswordLength
    PasswordHistoryCount = $config.PasswordHistory
    ReversibleEncryptionEnabled = $false
    MinPasswordAge = New-TimeSpan -Days 1
    LockoutThreshold = $config.LockoutThreshold
    LockoutDuration = $duration
    LockoutObservationWindow = $duration
}
Set-ADDefaultDomainPasswordPolicy @passwordPolicy
Set-ADObject -Identity $domain.DistinguishedName -Replace @{ 'ms-DS-MachineAccountQuota' = 0 }

foreach ($policy in $dcPolicy, $wsPolicy) {
    Write-LabRegistryDword $policy.Id $lsa LmCompatibilityLevel 5
    Write-LabRegistryDword $policy.Id $lsa SCENoApplyLegacyAuditPolicy 1
    $firewallPolicy = @{
        PolicyStore = "$($config.Domain)\$($policy.DisplayName)"
        Profile = @('Domain', 'Private', 'Public')
        Enabled = 'True'
        DefaultInboundAction = 'Block'
    }
    Set-NetFirewallProfile @firewallPolicy
}
Write-LabRegistryDword $dcPolicy.Id "$services\NTDS\Parameters" LDAPServerIntegrity 2
Write-LabRegistryDword $dcPolicy.Id "$services\LanmanServer\Parameters" RequireSecuritySignature 1
Write-LabRegistryDword $wsPolicy.Id 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' fDenyTSConnections 1
Write-LabRegistryDword $wsPolicy.Id 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' DisableRealtimeMonitoring 0

$helpdesk = Get-ADGroup -Identity $config.HelpdeskGroup
if ($helpdesk.DistinguishedName -ne "CN=$($config.HelpdeskGroup),$($layout.Groups)") {
    throw 'The delegated group is outside the managed groups OU.'
}
$path = "AD:\$($layout.People)"
$acl = Get-Acl -Path $path
$rule = [System.DirectoryServices.ActiveDirectoryAccessRule]::new(
    $helpdesk.SID,
    [System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight,
    [System.Security.AccessControl.AccessControlType]::Allow,
    [guid]$config.ResetRight,
    [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Descendents,
    [guid]$config.UserClass
)
$matching = @($acl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]) | Where-Object IdentityReference -eq $helpdesk.SID)
if ($matching.Count -eq 0) {
    $acl.AddAccessRule($rule)
    Set-Acl -Path $path -AclObject $acl
} elseif ($matching.Count -ne 1 -or $matching[0].ActiveDirectoryRights -ne $rule.ActiveDirectoryRights -or
    $matching[0].AccessControlType -ne $rule.AccessControlType -or $matching[0].ObjectType -ne $rule.ObjectType -or
    $matching[0].InheritanceType -ne $rule.InheritanceType -or $matching[0].InheritedObjectType -ne $rule.InheritedObjectType) {
    throw 'Unexpected delegations for the lab helpdesk exist. Review the People OU ACL.'
}
Write-Output 'Apply Group Policy on both guests, refresh the directory password baseline, and run the checks.'
