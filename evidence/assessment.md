# IdentityLab configuration assessment

Script revision **6693f11824e76df5c5d028e5d15ae3a4788765ab**

| Phase | Pass | Fail | Unmeasured |
| --- | --- | --- | --- |
| Before | 3 | 5 | 8 |
| After | 8 | 0 | 8 |

Among the 8 controls measured for both phases, 3 passed before and 8 passed after. 5 improved and 0 regressed.

## Control observations

A value of -1 marks an absent explicit value where the probe reads a policy registry key. Probe errors and missing roles are Unmeasured. A Windows default may still provide protection when an explicit policy value is absent.

| Control | Before | Before observations | After | After observations |
| --- | --- | --- | --- | --- |
| C01 Domain password policy | Fail | DC (Complexity=1, History=24, MinimumAgeHours=24, MinimumLength=7, ReversibleEncryption=0) | Pass | DC (Complexity=1, History=24, MinimumAgeHours=24, MinimumLength=14, ReversibleEncryption=0) |
| C02 Domain account lockout | Fail | DC (DurationMinutes=10, ObservationMinutes=10, Threshold=0) | Pass | DC (DurationMinutes=15, ObservationMinutes=15, Threshold=10) |
| C03 Privileged group and role separation | Pass | DC (GroupsChecked=8, HelpdeskUsesSeparateAccount=1, SeparateProtectedAdmin=1, UnexpectedDirectMembers=0, UnexpectedEffectiveMembers=0) | Pass | DC (GroupsChecked=8, HelpdeskUsesSeparateAccount=1, SeparateProtectedAdmin=1, UnexpectedDirectMembers=0, UnexpectedEffectiveMembers=0) |
| C04 Default computer creation quota | Fail | DC (MachineAccountQuota=10) | Pass | DC (MachineAccountQuota=0) |
| C05 LDAP signing | Unmeasured | DC (ClientSigning=1, ServerSigning=1) / Workstation missing | Unmeasured | DC (ClientSigning=2, ServerSigning=2) / Workstation missing |
| C06 SMB server signing | Pass | DC (SigningRequired=1) | Pass | DC (SigningRequired=1) |
| C07 SMB client signing | Unmeasured | Workstation missing | Unmeasured | Workstation missing |
| C08 NTLMv2 policy and NTLM visibility | Unmeasured | DC (CompatibilityLevel=-1, DomainAudit=-1, IncomingAudit=-1) / Workstation missing | Unmeasured | DC (CompatibilityLevel=5, DomainAudit=7, IncomingAudit=2) / Workstation missing |
| C09 Windows Firewall profiles | Unmeasured | DC (EnabledProfiles=3, ExplicitInboundBlockProfiles=3) / Workstation missing | Unmeasured | DC (EnabledProfiles=3, ExplicitInboundBlockProfiles=3) / Workstation missing |
| C10 Workstation Defender real-time protection | Unmeasured | Workstation missing | Unmeasured | Workstation missing |
| C11 Workstation Remote Desktop disabled | Unmeasured | Workstation missing | Unmeasured | Workstation missing |
| C12 Advanced audit policy | Unmeasured | DC missing / Workstation missing | Unmeasured | DC missing / Workstation missing |
| C13 Department share least privilege | Pass | DC (GroupChainsVerified=2, NtfsAclsVerified=2, ShareAclsVerified=2, SharePathsVerified=2) | Pass | DC (GroupChainsVerified=2, NtfsAclsVerified=2, ShareAclsVerified=2, SharePathsVerified=2) |
| C14 Scoped helpdesk delegation | Fail | DC (ExactScopedResetAces=0, InScopeInheritedReset=0, OtherExplicitAces=0, OutOfScopeInheritedReset=0) | Pass | DC (ExactScopedResetAces=1, InScopeInheritedReset=1, OtherExplicitAces=0, OutOfScopeInheritedReset=0) |
| C15 Staged managed service identity | Fail | DC (AesWithoutLegacy=0, DirectRoleMemberships=0, EligibleHosts=0, ExpectedRetrieverGroup=0, ManagedAccountPresent=0, ServicePrincipalNames=0) | Pass | DC (AesWithoutLegacy=1, DirectRoleMemberships=0, EligibleHosts=0, ExpectedRetrieverGroup=1, ManagedAccountPresent=1, ServicePrincipalNames=0) |
| C16 Encrypted Windows LAPS backup | Unmeasured | DC (EncryptedBackupPresent=0, LapsSchemaPresent=0) / Workstation missing | Unmeasured | DC (EncryptedBackupPresent=0, LapsSchemaPresent=1) / Workstation missing |

## Capture timestamps and hashes

| Source capture | UTC | SHA-256 |
| --- | --- | --- |
| After-DC | 2026-11-25T20:18:34.3385503Z | cc1c125c9821e14fe46b5adf0f24e1d504b09bab3277d513e17c41a1282138cd |
| Before-DC | 2026-11-25T19:47:56.4454011Z | 0a6d774c66280d94ac42c32803c92f542199f8a77f15f2a6f51de2308c7ddb6c |

## Configuration inventory

| Role and signal | Before | After |
| --- | --- | --- |
| DC DefenderAntivirus | 1 | 1 |
| DC DefenderRealTime | 1 | 1 |
| DC DisabledUsers | 4 | 4 |
| DC EnabledDormant90Days | 0 | 0 |
| DC EnabledNeverSeen | 5 | 2 |
| DC EnabledPasswordNeverExpires | 1 | 1 |
| DC EnabledUsers | 6 | 6 |
| DC ExpectedDcLinks | 0 | 1 |
| DC ExpectedWorkstationLinks | 0 | 1 |
| DC FineGrainedPasswordPolicies | 0 | 0 |
| DC GpoCount | 2 | 4 |
| DC LdapChannelBinding | -1 | -1 |
| DC MaximumPasswordAgeDays | 42 | 42 |
| DC SecurityLogEnabled | 1 | 1 |
| DC TraditionalServiceOuUsers | 0 | 0 |
| Workstation DefenderSignatureAgeDays | Unavailable | Unavailable |
| Workstation ExpectedGpoApplied | Unavailable | Unavailable |
| Workstation LocalAdminMembers | Unavailable | Unavailable |
| Workstation SecurityLogEnabled | Unavailable | Unavailable |
| Workstation SmbServerSigning | Unavailable | Unavailable |

The comparison measures adherence to the lab baseline. Review health, authorization tests, and event evidence with the configuration results.
