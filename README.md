# Enterprise Active Directory Security Lab

This project builds a Windows domain on Fedora KVM/libvirt to demonstrate identity administration, role-based access, Group Policy and defensive security verification. It uses a dedicated host-only network, fictional users in Finance and Operations, and a planned Windows 11 domain member.

**Current status**

`LAB-DC01` runs `corp.example.test` on the isolated libvirt network. Native checks verified AD DS, DNS, Kerberos, SYSVOL, NETLOGON and certificate-validated LDAPS. Both department users passed the signed SMB access checks, and the helpdesk reset succeeded only within its assigned scope. Five of eight fully measured controls improved, taking the paired total from three to eight passes. The approved workstation still runs Windows 11 Home. Its domain join and endpoint measurements require the owner's Pro upgrade. [Paired assessment](evidence/assessment.md) · [Screenshots and verification](evidence/README.md)

## Architecture

| Component | Pilot scope |
| --- | --- |
| Fedora host | KVM/QEMU, system libvirt and a dedicated bridge with no forwarding |
| Directory | Windows Server 2022 Evaluation, AD DS and DNS for `corp.example.test` |
| Workstation | Approved Windows 11 guest on the isolated bridge, with domain membership and DC DNS configured after the Pro upgrade |
| Identities | Fictional department users, dedicated directory and helpdesk roles, bounded service identity and departmental resource groups |
| Security validation | 16 defined controls, native state collection, positive and denied authorization checks, and paired sanitized reporting |

The [network and identity architecture](docs/architecture.md) shows the trust boundaries, OUs and access groups. The [authentication flow](docs/technical-design.md) traces DNS, Kerberos, LDAP and SMB.

## Reproduce and verify

1. Check the [resource and licensing requirements](docs/lab-requirements.md) and follow the [deployment runbook](docs/deployment.md).
2. Provision AD DS, DNS, the fictional identity tree and two scoped SMB shares. Capture the DC baseline and verify the approved client’s secure channel when its edition supports the join.
3. Review the [control matrix](docs/controls.md) and apply hardening in stages. Verify effective settings, compatibility and authorized access.
4. Generate the [before-and-after assessment](docs/assessment.md) from paired native measurements and retain relevant [screenshots and evidence](evidence/README.md).

| Entry point | Purpose |
| --- | --- |
| `host/Inspect-LabHost.sh` | Read host capacity, routes and libvirt inventory |
| `powershell/Install-LabDomain.ps1`, `Join-LabWorkstation.ps1` | Create the lab forest and join the approved workstation |
| `powershell/Initialize-LabDirectory.ps1`, `Initialize-LabShares.ps1` | Create fictional identities, OUs, groups and resource ACLs |
| `powershell/Set-LabHardening.ps1`, `Set-LabAuditPolicy.ps1` | Stage and apply security settings |
| `powershell/Get-LabHealth.ps1`, `Test-LabIdentity.ps1`, `Test-LabDelegation.ps1` | Exercise DNS, the secure channel, authentication and permission boundaries |
| `powershell/Get-LabAssessment.ps1`, `New-LabAssessmentReport.ps1` | Capture before/after state and generate a sanitized evidence report |

Mutation scripts require explicit application and an exact lab scope. Read-only captures and public summaries omit credentials. Windows setup and activation use legitimate media and supported procedures.

## Portfolio material

- [Goals](GOALS.md), [execution plan](PLANS.md), and [status](PROGRESS.md)
- [Architecture decisions](docs/decisions/0001-single-dc-pilot.md), [network isolation](docs/decisions/0002-host-only-network.md), and [assessment method](docs/decisions/0003-native-measurement.md)
- [Threat model](docs/threat-model.md), [identity security practices](docs/identity-security.md), and [interview guide and CV bullets in English and French](docs/interview.md)
- [Five-minute demonstration](docs/interview.md#five-minute-demonstration)
