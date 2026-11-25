# Acceptance and evidence

1. On Fedora, confirm that the isolated network has no forwarding, that the approved guest has only the lab NIC, and that the new server uses official activated media.
2. On Windows, capture domain and workstation health, run the two seeded role tests, and export the first DC and workstation configuration captures using one run ID and one repository revision.
3. Apply the client and server hardening stages. Recheck DNS, signed LDAP, SYSVOL and firewall-dependent behavior between stages.
4. Recheck health and retest the two department identities and the delegated helpdesk account. Capture security events with timestamps and the same paired configuration scope.
5. Select evidence for display and verify screenshots against the raw results. Strip everything outside the published control schema. Record compatibility exceptions and unexecuted tests.

| Test | Acceptance and evidence |
| --- | --- |
| DC health | `Get-LabHealth.ps1 -Role DC` passes DNS SRV/A, AD services and SYSVOL/NETLOGON. Review `dcdiag` and PDC clock source |
| Client health | `Get-LabHealth.ps1 -Role Workstation` passes DNS, secure channel and SYSVOL. Review the NTP offsets and resultant computer policy |
| Domain sign-in and Kerberos | A fresh normal sign-in as each fictional worker, `klist` or `Test-LabIdentity.ps1` shows CIFS ticket acquisition, and event 4769 appears when audited |
| Authorization | Own department read/write succeeds and other department returns explicit Access Denied. Helpdesk can reset the disabled in-scope account only after delegation while the excluded test remains denied |
| Configuration | `Get-LabAssessment.ps1` on both roles. The paired report states each status and measured fact. Minimum 12 final passes supported by required operational checks |
| Recovery | Verified latest rollback and GPO backups. A production-style system-state restore rehearsal is outside the single-DC pilot scope |

Use the [before-and-after assessment](assessment.md), [evidence index](../evidence/README.md) and [per-control requirements](controls.md) to trace claims to assets. An unobserved role or probe remains Unmeasured. Report conditions and raw file hashes so another reviewer can reproduce the comparison.
