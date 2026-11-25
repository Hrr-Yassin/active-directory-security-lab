# Interview preparation

| Prompt | What to demonstrate |
| --- | --- |
| Why does a workstation need Active Directory DNS? | Walk through the DC locator SRV query and A record. Explain how wrong DNS or excessive time skew can resemble an account problem |
| What happens when a Finance user opens the share? | Trace the expected Windows Kerberos CIFS ticket path and the global-to-domain-local nesting. Show the live signed SMB read from Fedora and explain both cross-department denials |
| How do signing and TLS differ? | Explain integrity and confidentiality, show the signed Kerberos directory query, and describe certificate chain and name checks for LDAPS |
| How did you keep helpdesk delegation narrow? | Describe the Reset Password ACE’s object type, inheritance scope and two disabled fixture checks. Explain why a separate operator account matters |
| How did you design the hardening rollout? | Walk through measurement, staged LDAP client policy, reviewed NTLM dependencies, enforcement, effective configuration and rollback |
| How did you score the lab? | Describe the same-scope paired denominator, unchanged passes, failed probes, missing observations and protocol compatibility trade-offs |
| Why only one DC? | Explain the observed resource budget, the scope of the proof, and how two DCs, a member server and off-host recovery would change the design |

## CV bullets

### English

- Deployed an isolated Windows Server 2022 Active Directory forest on Fedora KVM/libvirt and verified AD DNS, AES-256 Kerberos service tickets, SYSVOL, NETLOGON and certificate-validated LDAPS. [Host and guest evidence](../evidence/README.md)
- Provisioned five fictional identities, six security groups and two role-scoped SMB shares. Verified signed SMB access boundaries in both directions and helpdesk password resets confined to the People OU. [Directory and share evidence](../evidence/screenshots/lab-directory-and-shares.png) · [Verification summary](assessment.md)
- Applied and measured Active Directory hardening with Windows PowerShell. Improved five comparable controls, increasing full-scope passes from three to eight, and verified twelve DC checks across the collector and native audit evidence. [Generated assessment](../evidence/assessment.md) · [Assessment console](../evidence/screenshots/dc-assessment.png)

### Français

- Déployé une forêt Active Directory isolée sous Windows Server 2022 sur Fedora KVM/libvirt. Vérifié le DNS Active Directory, les tickets de service Kerberos AES-256, SYSVOL, NETLOGON et LDAPS avec validation du certificat. [Preuves sur l’hôte et les machines virtuelles](../evidence/README.md)
- Créé cinq identités de test, six groupes de sécurité et deux partages SMB avec des droits par service. Vérifié les accès autorisés et les refus entre services avec SMB signé, ainsi que la délégation de réinitialisation des mots de passe limitée à l’unité d’organisation People. [Annuaire et partages](../evidence/screenshots/lab-directory-and-shares.png) · [Synthèse des vérifications](assessment.md)
- Appliqué et évalué le durcissement d’Active Directory avec Windows PowerShell. Amélioré cinq contrôles comparables, portant le nombre de contrôles conformes de trois à huit sur le périmètre mesuré, et vérifié douze points sur le contrôleur de domaine à l’aide du collecteur et des résultats d’audit natifs. [Rapport d’évaluation](../evidence/assessment.md) · [Capture de l’évaluation](../evidence/screenshots/dc-assessment.png)

The workstation join, endpoint Group Policy and encrypted LAPS backup await the legitimate Windows 11 Pro upgrade.

## Five-minute demonstration

Open the five linked views before presenting. Use the recorded evidence to show the results in sequence.

| Time | Show | Explain |
| --- | --- | --- |
| 0:00–0:45 | [Architecture diagram](architecture.md) | Point out the isolated libvirt bridge, the single domain controller, and the planned Windows 11 member. Identify the trust boundary and the DC’s DNS role. |
| 0:45–1:30 | [Domain controller health](../evidence/screenshots/domain-controller-health.png) | Show how DNS locates the controller and identify the checks for AD DS, KDC, SYSVOL and NETLOGON. |
| 1:30–2:30 | [Directory and shares](../evidence/screenshots/lab-directory-and-shares.png) | Trace one user through the role group, resource group and share ACL. Describe what happened when the two test users opened their own and the other department’s share. Explain the in-scope and out-of-scope helpdesk reset results. |
| 2:30–3:45 | [Effective policy](../evidence/screenshots/dc-policy-and-protocols.png) | Identify the applied DC GPO, certificate-validated Kerberos LDAPS and configured audit subcategories. Describe the result of the cleartext bind test after reboot. |
| 3:45–5:00 | [Paired assessment](../evidence/assessment.md) | Show that three of eight comparable controls passed before hardening and all eight passed afterward. Explain how twelve DC checks were verified and why workstation-dependent results remain unmeasured pending the Pro upgrade and domain enrollment. |
