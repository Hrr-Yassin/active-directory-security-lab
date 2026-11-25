# Security assessment

## Initial recorded state

The initial inspection recovered the original Phase 0 repository. Fedora was running two other guests. The authorized `win11` workstation was powered off with one NIC on the pre-existing `network` libvirt network. After the owner approved the pilot changes, its original disk was retained as the base of an external copy-on-write rollback disk. The one NIC now attaches to the active host-only `ad-identity-lab` bridge. A console capture shows the guest reached the Windows lock screen.

The authorized workstation console reported edition `Core` (Windows 11 Home), build `10.0.26200`, and standalone membership. The live activation console confirmed Home and reported `0x800704CF` while isolated from Microsoft activation servers. The owner selected the legitimate Pro upgrade path. The DC baseline was captured after promotion and directory provisioning, before security policy rollout. [Host evidence and screenshots](../evidence/README.md) · [Microsoft Pro upgrade instructions](https://support.microsoft.com/en-us/windows/deployment/install-upgrade/upgrade-windows-home-to-windows-pro)

## Before-and-after control status

The generated report measured eight controls across all their required roles. Three passed before and all eight passed after. Five improved and zero regressed. The eight controls requiring workstation evidence remain unmeasured at the full catalog scope. Eleven DC checks passed in the original collector. Independent native audit verification brings the total to twelve verified DC checks, with encrypted LAPS backup pending workstation enrollment. [Generated report](../evidence/assessment.md) · [Control matrix](controls.md)

The original collector marked C12 unmeasured because native `auditpol /get /r` omitted the numeric fields it expected. The preserved baseline audit export recorded success-only auditing for user account management, security group management and Kerberos service ticket operations. The DC now records success and failure for those three subcategories and logon, and advanced audit policy takes precedence. The repaired collector read all four effective masks as `3` on Windows PowerShell 5.1. The original capture revision is retained for both phases of the generated report. [Effective policy and audit evidence](../evidence/screenshots/dc-policy-and-protocols.png) · [Assessment console](../evidence/screenshots/dc-assessment.png)

Operational checks verified an AES-256 Kerberos LDAP service ticket, a signed and sealed LDAP bind, a hostname-validated LDAPS connection and an authenticated LDAPS RootDSE lookup. After a clean reboot, a disposable lab fixture successfully authenticated through LDAPS, received Strong Authentication Required for a cleartext simple bind on guest loopback, and was restored to disabled. Each department user could read only their own share over signed SMB. Before delegation, both helpdesk reset attempts were denied. After delegation, the in-scope disabled fixture accepted the reset and the out-of-scope fixture still denied it. [Evidence index](../evidence/README.md)

## Comparison method

The report assembler accepts captures with the same run ID and script revision, and each role’s pair must have the same installation identifier in chronological order. Report totals show Pass, Fail and Unmeasured. The measured delta compares the intersection of controls with evidence from both phases. This denominator supports a reproducible baseline comparison across these specific Windows settings.

The inventory uses the replicated `LastLogonDate` as a screening signal plus account creation time. A 90-day dormant candidate remains subject to owner review. Raw logs, GPO reports and identifier-bearing exports stay private. PingCastle is optional, and this report relies on native tooling when a compatible release and license are unavailable.
