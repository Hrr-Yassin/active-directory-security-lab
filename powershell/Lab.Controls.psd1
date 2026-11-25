@{
    SchemaVersion = 1
    Controls = @(
        @{ Id = 'C01'; Title = 'Domain password policy'; Rules = @{
            DC = @{ MinimumLength = '-ge:14'; History = '-ge:24'; Complexity = '-eq:1'; ReversibleEncryption = '-eq:0'; MinimumAgeHours = '-ge:24' }
        } }
        @{ Id = 'C02'; Title = 'Domain account lockout'; Rules = @{
            DC = @{ Threshold = '-eq:10'; DurationMinutes = '-eq:15'; ObservationMinutes = '-eq:15' }
        } }
        @{ Id = 'C03'; Title = 'Privileged group and role separation'; Rules = @{
            DC = @{ GroupsChecked = '-eq:8'; UnexpectedDirectMembers = '-eq:0'; UnexpectedEffectiveMembers = '-eq:0'; SeparateProtectedAdmin = '-eq:1'; HelpdeskUsesSeparateAccount = '-eq:1' }
        } }
        @{ Id = 'C04'; Title = 'Default computer creation quota'; Rules = @{
            DC = @{ MachineAccountQuota = '-eq:0' }
        } }
        @{ Id = 'C05'; Title = 'LDAP signing'; Rules = @{
            DC = @{ ServerSigning = '-eq:2'; ClientSigning = '-eq:2' }
            Workstation = @{ ClientSigning = '-eq:2' }
        } }
        @{ Id = 'C06'; Title = 'SMB server signing'; Rules = @{
            DC = @{ SigningRequired = '-eq:1' }
        } }
        @{ Id = 'C07'; Title = 'SMB client signing'; Rules = @{
            Workstation = @{ SigningRequired = '-eq:1' }
        } }
        @{ Id = 'C08'; Title = 'NTLMv2 policy and NTLM visibility'; Rules = @{
            DC = @{ CompatibilityLevel = '-eq:5'; IncomingAudit = '-eq:2'; DomainAudit = '-eq:7' }
            Workstation = @{ CompatibilityLevel = '-eq:5'; IncomingAudit = '-eq:2' }
        } }
        @{ Id = 'C09'; Title = 'Windows Firewall profiles'; Rules = @{
            DC = @{ EnabledProfiles = '-eq:3'; ExplicitInboundBlockProfiles = '-eq:3' }
            Workstation = @{ EnabledProfiles = '-eq:3'; ExplicitInboundBlockProfiles = '-eq:3' }
        } }
        @{ Id = 'C10'; Title = 'Workstation Defender real-time protection'; Rules = @{
            Workstation = @{ AntivirusEnabled = '-eq:1'; RealTimeEnabled = '-eq:1' }
        } }
        @{ Id = 'C11'; Title = 'Workstation Remote Desktop disabled'; Rules = @{
            Workstation = @{ ConnectionsDenied = '-eq:1'; ListenerCount = '-eq:0' }
        } }
        @{ Id = 'C12'; Title = 'Advanced audit policy'; Rules = @{
            DC = @{ LogonMask = '-eq:3'; UserManagementMask = '-eq:3'; GroupManagementMask = '-eq:3'; KerberosServiceTicketMask = '-eq:3'; SubcategoriesTakePrecedence = '-eq:1' }
            Workstation = @{ LogonMask = '-eq:3'; SubcategoriesTakePrecedence = '-eq:1' }
        } }
        @{ Id = 'C13'; Title = 'Department share least privilege'; Rules = @{
            DC = @{ SharePathsVerified = '-eq:2'; ShareAclsVerified = '-eq:2'; NtfsAclsVerified = '-eq:2'; GroupChainsVerified = '-eq:2' }
        } }
        @{ Id = 'C14'; Title = 'Scoped helpdesk delegation'; Rules = @{
            DC = @{ ExactScopedResetAces = '-eq:1'; OtherExplicitAces = '-eq:0'; InScopeInheritedReset = '-eq:1'; OutOfScopeInheritedReset = '-eq:0' }
        } }
        @{ Id = 'C15'; Title = 'Staged managed service identity'; Rules = @{
            DC = @{ ManagedAccountPresent = '-eq:1'; AesWithoutLegacy = '-eq:1'; ExpectedRetrieverGroup = '-eq:1'; EligibleHosts = '-eq:0'; DirectRoleMemberships = '-eq:0'; ServicePrincipalNames = '-eq:0' }
        } }
        @{ Id = 'C16'; Title = 'Encrypted Windows LAPS backup'; Rules = @{
            DC = @{ LapsSchemaPresent = '-eq:1'; EncryptedBackupPresent = '-eq:1' }
            Workstation = @{ BackupDirectory = '-eq:2'; EncryptionEnabled = '-eq:1'; PasswordLength = '-ge:20'; SuccessfulAdBackupEvent = '-eq:1' }
        } }
    )
    Inventory = @{
        DC = @('EnabledUsers', 'DisabledUsers', 'EnabledDormant90Days', 'EnabledNeverSeen', 'EnabledPasswordNeverExpires',
            'FineGrainedPasswordPolicies', 'MaximumPasswordAgeDays', 'GpoCount', 'ExpectedDcLinks', 'ExpectedWorkstationLinks',
            'DefenderAntivirus', 'DefenderRealTime', 'LdapChannelBinding', 'SecurityLogEnabled', 'TraditionalServiceOuUsers')
        Workstation = @('ExpectedGpoApplied', 'DefenderSignatureAgeDays', 'LocalAdminMembers', 'SmbServerSigning', 'SecurityLogEnabled')
    }
}
