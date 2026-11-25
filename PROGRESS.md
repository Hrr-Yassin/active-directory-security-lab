# Deployment status

- Deployed the isolated `corp.example.test` domain on Windows Server 2022 and Fedora KVM/libvirt. Verified AD DS, DNS, Kerberos, SYSVOL, NETLOGON, LDAP signing and trusted LDAPS.
- Provisioned the lab directory, scoped helpdesk delegation, and Finance and Operations shares. Verified signed access and cross-department denials.
- Verified twelve checks on the domain controller. All eight controls with comparable evidence for every required role passed after hardening, up from three at baseline. [Paired assessment](evidence/assessment.md)
- Windows 11 Pro activation is pending. Domain membership, workstation Group Policy, encrypted LAPS backup and the corresponding security measurements remain unavailable. [Deployment instructions](docs/deployment.md)
- The portfolio includes English and French CV bullets and a five-minute recorded-evidence walkthrough. [Interview and demonstration guide](docs/interview.md)

See the [evidence index](evidence/README.md) for the console captures and the [architecture diagram](docs/architecture.md) for the deployed and planned components.
