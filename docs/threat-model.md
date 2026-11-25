# Threat model

| Exposure | Boundary | Treatment and verification |
| --- | --- | --- |
| Compromise of a domain administrator session | Directory management and workstation | Use a designated administrator at the DC console. Review direct and transitive privilege separately |
| Dormant identities and unmanaged service credentials | Directory lifecycle | Review age indicators and exceptions. Stage an AES-enabled gMSA with narrowly scoped retrieval |
| Repeated password guessing | Domain sign-in | Apply a length and history baseline, a limited lockout window and sign-in auditing. Review availability impact of lockouts |
| Unsigned protocols or incompatible clients | Active Directory and SMB | Pilot client signing and observe usage. Require LDAP and SMB signing and test legitimate domain traffic |
| Cross-department access | Authorization groups and share/NTFS ACLs | Use scoped role groups and apply both ACLs. Test cross-department Access Denied from each ordinary user |
| Over-broad password reset | Helpdesk delegation | Scope one ACE to People user objects. Prove allowed and denied cases with disabled fixtures |
| Spread to another network | Fedora bridge and guest routes | Dedicated host-only network with no guest default route. Observe libvirt and Windows network configuration |
| Loss of service or evidence | Single DC and local datastore | Protect the rollback assets and grow into supported system-state recovery and separate log storage |

Fedora and its hypervisor administrators can access guest state. Treat guest disks, domain backups, activation details and raw evidence as private. The single-server pilot cannot demonstrate DC redundancy, resilient off-host logging or production administrative tiering.
