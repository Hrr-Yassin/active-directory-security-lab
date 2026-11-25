#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('DC', 'Workstation')][string]$Role,
    [Parameter(Mandatory)][ValidateSet('Before', 'After')][string]$Phase,
    [Parameter(Mandatory)][guid]$RunId,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{7,40}$')][string]$Revision,
    [Parameter(Mandatory)][string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
Import-Module (Join-Path $PSScriptRoot 'Lab.Evidence.psm1')
$config = Get-LabConfig
$layout = Get-LabLayout
$catalog = Get-LabControlCatalog
Assert-LabComputer -Role $Role
if ($Role -eq 'DC') {
    Import-Module ActiveDirectory
    Import-Module GroupPolicy
    $domain = Get-LabDomain
}

$lsa = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
$services = 'HKLM:\SYSTEM\CurrentControlSet\Services'
$records = [ordered]@{}

function Add-Probe {
    param([string]$Id, [scriptblock]$Collect)
    $rule = $catalog.Controls | Where-Object Id -eq $Id
    if (-not $rule.Rules.ContainsKey($Role)) { throw "Measurement $Id is outside the $Role scope." }
    try {
        $facts = & $Collect
    } catch {
        Write-Verbose "$Id could not be collected ($($_.Exception.GetType().Name))."
        $records[$Id] = $null
        return
    }
    Assert-LabFactMap $facts @($rule.Rules[$Role].Keys)
    $records[$Id] = $facts
}

function Get-LabAuditRows {
    $path = Join-Path ([IO.Path]::GetTempPath()) ('idlab-audit-{0}.csv' -f [guid]::NewGuid())
    try {
        # The backup includes numeric masks. The native /get CSV can omit them.
        $null = Invoke-LabNative auditpol.exe @('/backup', "/file:$path")
        Import-Csv -LiteralPath $path -Header Machine, Target, Subcategory, Id, Inclusion, Exclusion, Mask |
            Select-Object -Skip 1 | Where-Object Target -eq 'System'
    } finally {
        [IO.File]::Delete($path)
    }
}

function Get-AuditMask {
    param([object[]]$Rows, [string]$Id)
    $row = @($Rows | Where-Object Id -eq $Id)
    if ($row.Count -ne 1 -or $row[0].Mask -notmatch '^[0-3]$') {
        throw 'No numeric system audit policy setting was identified in the auditpol backup.'
    }
    [int]$row[0].Mask
}

function Get-PrivilegeMeasurement {
    $prefix = $domain.DomainSID.Value
    $admin = Get-ADUser -Identity $config.Administrator -Properties AccountNotDelegated
    $helpdesk = Get-ADGroup -Identity $config.HelpdeskGroup -Properties member
    $operator = Get-ADUser -Identity $config.HelpdeskOperator -Properties AccountNotDelegated
    $builtIn = "$prefix-500"
    $approved = @($builtIn, $admin.SID.Value)
    $groups = [ordered]@{
        "$prefix-512" = $approved
        "$prefix-518" = @($builtIn)
        "$prefix-519" = @($builtIn)
        'S-1-5-32-544' = @($builtIn, "$prefix-512", "$prefix-519")
        'S-1-5-32-548' = @()
        'S-1-5-32-549' = @()
        'S-1-5-32-550' = @()
        'S-1-5-32-551' = @()
    }
    $unexpectedDirect = 0
    $unexpectedEffective = 0
    foreach ($entry in $groups.GetEnumerator()) {
        $direct = @(Get-ADGroupMember -Identity $entry.Key)
        $effective = @(Get-ADGroupMember -Identity $entry.Key -Recursive)
        $unexpectedDirect += @($direct | Where-Object { $_.SID.Value -notin $entry.Value }).Count
        $unexpectedEffective += @($effective | Where-Object { $_.SID.Value -notin $approved }).Count
    }
    $domainAdmins = (Get-ADGroup -Identity "$prefix-512" -Properties member).member
    @{
        GroupsChecked = $groups.Count
        UnexpectedDirectMembers = $unexpectedDirect
        UnexpectedEffectiveMembers = $unexpectedEffective
        SeparateProtectedAdmin = [int]($admin.Enabled -and $admin.AccountNotDelegated -and
            $admin.DistinguishedName -eq "CN=$($config.Administrator),$($layout.Operators)" -and
            $admin.DistinguishedName -in @($domainAdmins))
        HelpdeskUsesSeparateAccount = [int]($operator.Enabled -and $operator.AccountNotDelegated -and
            $operator.DistinguishedName -eq "CN=$($config.HelpdeskOperator),$($layout.Operators)" -and
            @($helpdesk.member).Count -eq 1 -and $helpdesk.member[0] -eq $operator.DistinguishedName)
    }
}

function Get-ShareMeasurement {
    $result = @{ SharePathsVerified = 0; ShareAclsVerified = 0; NtfsAclsVerified = 0; GroupChainsVerified = 0 }
    $shares = @(Get-SmbShare -Special $false)
    foreach ($department in $config.Departments) {
        $name = $department.Name
        $path = "C:\IdentityLabShares\$name"
        $share = $shares | Where-Object Name -eq $name
        $global = Get-ADGroup -Identity $department.RoleGroup -Properties member
        $local = Get-ADGroup -Identity $department.ShareGroup -Properties member
        $user = Get-ADUser -Identity $department.User
        if ($global.GroupScope -eq 'Global' -and $local.GroupScope -eq 'DomainLocal' -and
            $global.GroupCategory -eq 'Security' -and $local.GroupCategory -eq 'Security' -and
            @($global.member).Count -eq 1 -and $global.member[0] -eq $user.DistinguishedName -and
            @($local.member).Count -eq 1 -and $local.member[0] -eq $global.DistinguishedName) {
            $result.GroupChainsVerified++
        }
        if (-not $share -or $share.Path -ne $path -or $share.Description -ne $config.PolicyOwner) { continue }
        $result.SharePathsVerified++
        $shareRules = @(Get-SmbShareAccess -Name $name)
        $expectedShare = @{ 'S-1-5-32-544' = 'Full'; ($local.SID.Value) = 'Change' }
        foreach ($ace in $shareRules) {
            $sid = Get-LabSid $ace.AccountName
            if ($ace.AccessControlType -eq 'Allow' -and $expectedShare[$sid] -eq [string]$ace.AccessRight) {
                $expectedShare.Remove($sid)
            }
        }
        if ($shareRules.Count -eq 2 -and $expectedShare.Count -eq 0) { $result.ShareAclsVerified++ }

        $acl = Get-Acl -LiteralPath $path
        $rules = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
        $all = [Security.AccessControl.FileSystemRights]::FullControl
        $modify = [Security.AccessControl.FileSystemRights]'Modify, Synchronize'
        $inherit = [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
        $expectedNtfs = @{ 'S-1-5-32-544' = $all; 'S-1-5-18' = $all; ($local.SID.Value) = $modify }
        foreach ($ace in $rules) {
            $sid = $ace.IdentityReference.Value
            if ($ace.AccessControlType -eq 'Allow' -and $ace.InheritanceFlags -eq $inherit -and
                $ace.PropagationFlags -eq 'None' -and $expectedNtfs[$sid] -eq $ace.FileSystemRights) {
                $expectedNtfs.Remove($sid)
            }
        }
        if ($acl.AreAccessRulesProtected -and $rules.Count -eq 3 -and $expectedNtfs.Count -eq 0) {
            $result.NtfsAclsVerified++
        }
    }
    $result
}

function Get-DelegationMeasurement {
    $group = Get-ADGroup -Identity $config.HelpdeskGroup
    $identity = $group.SID
    $resetRight = [guid]$config.ResetRight
    $userClass = [guid]$config.UserClass
    $peopleAcl = Get-Acl -Path "AD:\$($layout.People)"
    $explicit = @($peopleAcl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]) |
        Where-Object IdentityReference -eq $identity)
    $exact = @($explicit | Where-Object {
        $_.ActiveDirectoryRights -eq 'ExtendedRight' -and $_.AccessControlType -eq 'Allow' -and
        $_.ObjectType -eq $resetRight -and $_.InheritanceType -eq 'Descendents' -and $_.InheritedObjectType -eq $userClass
    })
    $otherExplicit = $explicit.Count - $exact.Count
    $scopes = @($layout.Domain, $layout.Root, $layout.Operators, $layout.Groups, $layout.Services, $layout.Workstations,
        $layout.DomainControllers, "CN=AdminSDHolder,CN=System,$($layout.Domain)")
    $scopes += @($config.Departments | ForEach-Object { "OU=$($_.Name),$($layout.People)" })
    foreach ($scope in $scopes) {
        $acl = Get-Acl -Path "AD:\$scope"
        $otherExplicit += @($acl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]) |
            Where-Object IdentityReference -eq $identity).Count
    }
    $tests = @{}
    foreach ($sample in @{ 'reset.inside' = $layout.People; 'reset.outside' = $layout.Operators }.GetEnumerator()) {
        $acl = Get-Acl -Path "AD:\CN=$($sample.Key),$($sample.Value)"
        $matching = @($acl.GetAccessRules($false, $true, [Security.Principal.SecurityIdentifier]) | Where-Object {
            $_.IdentityReference -eq $identity -and $_.ObjectType -eq $resetRight -and
            $_.AccessControlType -eq 'Allow' -and $_.ActiveDirectoryRights -eq 'ExtendedRight'
        })
        $tests[$sample.Key] = [int]($matching.Count -eq 1)
    }
    @{
        ExactScopedResetAces = $exact.Count
        OtherExplicitAces = $otherExplicit
        InScopeInheritedReset = $tests['reset.inside']
        OutOfScopeInheritedReset = $tests['reset.outside']
    }
}

function Get-ServiceMeasurement {
    $properties = @('msDS-SupportedEncryptionTypes', 'PrincipalsAllowedToRetrieveManagedPassword', 'memberOf', 'servicePrincipalName')
    $service = Get-ADServiceAccount -Filter "Name -eq '$($config.ServiceName)'" -Properties $properties
    $hostGroup = Get-ADGroup -Identity $config.ServiceHosts -Properties member
    $result = @{ ManagedAccountPresent = 0; AesWithoutLegacy = 0; ExpectedRetrieverGroup = 0
        EligibleHosts = @($hostGroup.member).Count; DirectRoleMemberships = 0; ServicePrincipalNames = 0 }
    if ($service) {
        $supported = [int]$service.'msDS-SupportedEncryptionTypes'
        $retrievers = @($service.PrincipalsAllowedToRetrieveManagedPassword)
        $result.ManagedAccountPresent = [int]($service.Enabled -and $service.ObjectClass -eq 'msDS-GroupManagedServiceAccount' -and
            $service.DistinguishedName -eq "CN=$($config.ServiceName),$($layout.Services)")
        $result.AesWithoutLegacy = [int](($supported -band 0x1f) -eq 0x18)
        $result.ExpectedRetrieverGroup = [int]($retrievers.Count -eq 1 -and [string]$retrievers[0] -eq $hostGroup.DistinguishedName)
        $result.DirectRoleMemberships = @($service.memberOf).Count
        $result.ServicePrincipalNames = @($service.servicePrincipalName).Count
    }
    $result
}

$inventory = @{}
function Add-Inventory {
    param([string]$Name, [scriptblock]$Collect)
    try {
        $inventory[$Name] = & $Collect
    } catch {
        Write-Verbose "$Name could not be collected ($($_.Exception.GetType().Name))."
        $inventory[$Name] = -1
    }
}

if ($Role -eq 'DC') {
    $password = Get-ADDefaultDomainPasswordPolicy -Identity $domain.DistinguishedName
    Add-Probe C01 { @{
        MinimumLength = [int]$password.MinPasswordLength
        History = [int]$password.PasswordHistoryCount
        Complexity = [int]$password.ComplexityEnabled
        ReversibleEncryption = [int]$password.ReversibleEncryptionEnabled
        MinimumAgeHours = [int]$password.MinPasswordAge.TotalHours
    } }
    Add-Probe C02 { @{
        Threshold = [int]$password.LockoutThreshold
        DurationMinutes = [int]$password.LockoutDuration.TotalMinutes
        ObservationMinutes = [int]$password.LockoutObservationWindow.TotalMinutes
    } }
    Add-Probe C03 { Get-PrivilegeMeasurement }
    Add-Probe C04 { @{
        MachineAccountQuota = [int](Get-ADObject -Identity $layout.Domain -Properties 'ms-DS-MachineAccountQuota').'ms-DS-MachineAccountQuota'
    } }
    Add-Probe C06 { @{ SigningRequired = [int](Get-SmbServerConfiguration).RequireSecuritySignature } }
    Add-Probe C13 { Get-ShareMeasurement }
    Add-Probe C14 { Get-DelegationMeasurement }
    Add-Probe C15 { Get-ServiceMeasurement }
    Add-Probe C16 {
        $schema = (Get-ADRootDSE).schemaNamingContext
        $attribute = Get-ADObject -LDAPFilter '(lDAPDisplayName=msLAPS-EncryptedPassword)' -SearchBase $schema
        $backup = $false
        if ($attribute) {
            $filter = "(&(name=$($config.WorkstationName))(msLAPS-EncryptedPassword=*))"
            $backup = [bool](Get-ADComputer -LDAPFilter $filter -SearchBase $layout.Workstations)
        }
        @{ LapsSchemaPresent = [int][bool]$attribute; EncryptedBackupPresent = [int]$backup }
    }
    $users = @(Get-ADUser -Filter * -Properties LastLogonDate, PasswordNeverExpires, whenCreated)
    $cutoff = (Get-Date).AddDays(-90)
    Add-Inventory EnabledUsers { @($users | Where-Object Enabled).Count }
    Add-Inventory DisabledUsers { @($users | Where-Object { -not $_.Enabled }).Count }
    Add-Inventory EnabledDormant90Days {
        @($users | Where-Object { $_.Enabled -and
            (($_.LastLogonDate -and $_.LastLogonDate -lt $cutoff) -or (-not $_.LastLogonDate -and $_.whenCreated -lt $cutoff)) }).Count
    }
    Add-Inventory EnabledNeverSeen { @($users | Where-Object { $_.Enabled -and -not $_.LastLogonDate }).Count }
    Add-Inventory EnabledPasswordNeverExpires { @($users | Where-Object { $_.Enabled -and $_.PasswordNeverExpires }).Count }
    Add-Inventory FineGrainedPasswordPolicies { @(Get-ADFineGrainedPasswordPolicy -Filter *).Count }
    Add-Inventory MaximumPasswordAgeDays { [int]$password.MaxPasswordAge.TotalDays }
    Add-Inventory GpoCount { @(Get-GPO -All -Domain $config.Domain).Count }
    Add-Inventory ExpectedDcLinks {
        @((Get-GPInheritance -Target $layout.DomainControllers -Domain $config.Domain).GpoLinks |
            Where-Object { $_.DisplayName -eq $config.DcGpo -and $_.Enabled }).Count
    }
    Add-Inventory ExpectedWorkstationLinks {
        @((Get-GPInheritance -Target $layout.Workstations -Domain $config.Domain).GpoLinks |
            Where-Object { $_.DisplayName -eq $config.WorkstationGpo -and $_.Enabled }).Count
    }
    Add-Inventory DefenderAntivirus { [int](Get-MpComputerStatus).AntivirusEnabled }
    Add-Inventory DefenderRealTime { [int](Get-MpComputerStatus).RealTimeProtectionEnabled }
    Add-Inventory LdapChannelBinding { Get-LabRegistryNumber "$services\NTDS\Parameters" LdapEnforceChannelBinding }
    Add-Inventory TraditionalServiceOuUsers { @(Get-ADUser -Filter * -SearchBase $layout.Services).Count }
} else {
    Add-Probe C07 { @{ SigningRequired = [int](Get-SmbClientConfiguration).RequireSecuritySignature } }
    Add-Probe C10 {
        $defender = Get-MpComputerStatus
        @{ AntivirusEnabled = [int]$defender.AntivirusEnabled; RealTimeEnabled = [int]$defender.RealTimeProtectionEnabled }
    }
    Add-Probe C11 {
        $rdp = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
        $policy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        $denied = Get-LabRegistryNumber $policy fDenyTSConnections
        if ($denied -eq -1) { $denied = Get-LabRegistryNumber $rdp fDenyTSConnections }
        $port = Get-LabRegistryNumber "$rdp\WinStations\RDP-Tcp" PortNumber
        if ($port -lt 1) { throw 'The RDP listener port could not be determined.' }
        @{
            ConnectionsDenied = $denied
            ListenerCount = @(Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq $port).Count
        }
    }
    Add-Probe C16 {
        $key = 'HKLM:\SOFTWARE\Microsoft\Policies\LAPS'
        $log = 'Microsoft-Windows-LAPS/Operational'
        $backupEvent = $null
        try {
            $filter = @{ LogName = $log; Id = 10018; StartTime = (Get-Date).AddDays(-30) }
            $backupEvent = Get-WinEvent -FilterHashtable $filter -MaxEvents 1
        } catch {
            if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound,*') { throw }
        }
        @{
            BackupDirectory = Get-LabRegistryNumber $key BackupDirectory
            EncryptionEnabled = Get-LabRegistryNumber $key ADPasswordEncryptionEnabled
            PasswordLength = Get-LabRegistryNumber $key PasswordLength
            SuccessfulAdBackupEvent = [int][bool]$backupEvent
        }
    }
    Add-Inventory ExpectedGpoApplied {
        [int][bool](Invoke-LabNative gpresult.exe @('/r', '/scope', 'computer') | Select-String -SimpleMatch $config.WorkstationGpo)
    }
    Add-Inventory DefenderSignatureAgeDays {
        $updated = (Get-MpComputerStatus).AntivirusSignatureLastUpdated
        if ($updated) { [int][math]::Max(0, (New-TimeSpan -Start $updated).Days) } else { -1 }
    }
    Add-Inventory LocalAdminMembers { @(Get-LocalGroupMember -SID 'S-1-5-32-544').Count }
    Add-Inventory SmbServerSigning { [int](Get-SmbServerConfiguration).RequireSecuritySignature }
}

Add-Probe C05 {
    $facts = @{ ClientSigning = Get-LabRegistryNumber "$services\LDAP" LDAPClientIntegrity }
    if ($Role -eq 'DC') { $facts.ServerSigning = Get-LabRegistryNumber "$services\NTDS\Parameters" LDAPServerIntegrity }
    $facts
}
Add-Probe C08 {
    $facts = @{
        CompatibilityLevel = Get-LabRegistryNumber $lsa LmCompatibilityLevel
        IncomingAudit = Get-LabRegistryNumber "$lsa\MSV1_0" AuditReceivingNTLMTraffic
    }
    if ($Role -eq 'DC') { $facts.DomainAudit = Get-LabRegistryNumber "$services\Netlogon\Parameters" AuditNTLMInDomain }
    $facts
}
Add-Probe C09 {
    $profiles = @(Get-NetFirewallProfile -PolicyStore ActiveStore)
    @{
        EnabledProfiles = @($profiles | Where-Object { $_.Enabled -eq 'True' }).Count
        ExplicitInboundBlockProfiles = @($profiles | Where-Object DefaultInboundAction -eq 'Block').Count
    }
}
Add-Probe C12 {
    $rows = @(Get-LabAuditRows)
    $facts = @{
        LogonMask = Get-AuditMask $rows $config.AuditLogon
        SubcategoriesTakePrecedence = Get-LabRegistryNumber $lsa SCENoApplyLegacyAuditPolicy
    }
    if ($Role -eq 'DC') {
        $facts.UserManagementMask = Get-AuditMask $rows $config.AuditUserManagement
        $facts.GroupManagementMask = Get-AuditMask $rows $config.AuditGroupManagement
        $facts.KerberosServiceTicketMask = Get-AuditMask $rows $config.AuditKerberosTicket
    }
    $facts
}
Add-Inventory SecurityLogEnabled { [int](Get-WinEvent -ListLog Security).IsEnabled }
Assert-LabFactMap $inventory $catalog.Inventory[$Role]

$capture = [ordered]@{
    Schema = $catalog.SchemaVersion
    Phase = $Phase
    Role = $Role
    RunId = $RunId.ToString('D')
    Revision = $Revision
    CapturedUtc = [datetime]::UtcNow.ToString('o')
    MachineId = [string](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Cryptography').MachineGuid
    Measurements = $records
    Inventory = $inventory
}
$path = Join-Path $OutputDirectory "$Phase-$Role.json"
Write-LabNewFile -Path $path -Text ($capture | ConvertTo-Json -Depth 6)
foreach ($item in $records.GetEnumerator() | Sort-Object Key) {
    $rule = $catalog.Controls | Where-Object Id -eq $item.Key
    $status = if ($null -eq $item.Value) { 'Unmeasured' } else { Get-LabFactStatus $item.Value $rule.Rules[$Role] }
    [pscustomobject]@{ Id = $item.Key; Result = $status; Title = $rule.Title }
}
