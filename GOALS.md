# Goals

Build and verify a reproducible enterprise identity security lab on Fedora with KVM, QEMU and libvirt.

| Outcome | Evidence required |
| --- | --- |
| An isolated, functional AD DS domain | Libvirt XML, Windows role state, `dcdiag`, AD DNS SRV resolution and console capture |
| An approved Windows 11 workstation joined to the forest | Secure-channel and SYSVOL checks, actual sign-in, Kerberos service ticket and console capture |
| Role-based identity operations | Fictional identity inventory, department access in both directions, scoped helpdesk password resets and staged group managed service account configuration |
| At least 12 independently validated controls | Paired native measurements plus operational evidence where the control is meant to affect access or logging |
| A measurable comparison | Dated same-scope captures, a reproducible report, explicit unknowns and control-level changes |
| A portfolio-ready handoff | English README, runbook, diagrams, decisions, interview guide, evidence-based CV bullets in English and French, and a five-minute demonstration |

The readiness target is 9/10. The remaining acceptance criteria are a domain-user workstation sign-in, effective endpoint Group Policy, encrypted LAPS backup and the corresponding endpoint measurements. See the [execution log](PROGRESS.md) and [recorded assessment](docs/assessment.md).
