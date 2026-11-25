# Evidence index

## Host and workstation setup

| Capture | Observation |
| --- | --- |
| [Sanitized libvirt inventory](host-setup.txt) | Dedicated bridge has no forwarding or DHCP. The approved workstation’s single NIC changed to that bridge and its disk backs onto the original image |
| [Windows 11 console](screenshots/win11-approved-boot.png) | Direct libvirt screenshot after the network change shows Windows reached its lock screen on 2026-11-25. It establishes guest boot |
| [Windows edition and membership](screenshots/win11-home-edition.png) | Elevated Windows PowerShell reported `Core` and `PartOfDomain: False`. The original VM required a supported edition upgrade before the join |
| [Server installation](screenshots/server-evaluation-setup.png) | Windows Setup wrote to the new server’s disk after booting the official evaluation media |
| [Server installation and activation](screenshots/server-evaluation-activated.png) | Authenticated console reported `LAB-DC01`, `ServerStandardEval`, and time-based activation through 2027-05-24 |
| [Windows PowerShell runtime](screenshots/windows-powershell-layout.png) | The Windows PowerShell 5.1 console loaded the common module and displayed the configured directory layout. The 18 copied files passed the native parser separately |

The English x64 Server 2022 evaluation ISO used in this run measured 5,044,094,976 bytes. The locally computed SHA-256 was `3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325`. [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022)

## Windows validation

The 2026-11-25 DC console capture shows the successful native AD DS, DNS, KDC, SYSVOL and NETLOGON checks and the discovered forest name and mode. [Domain controller health](screenshots/domain-controller-health.png)

The directory and shares capture shows the configured OUs, fictional user enablement, groups and live shares. [Directory and shares](screenshots/lab-directory-and-shares.png)

The policy capture shows the applied DC GPO, certificate-validated Kerberos LDAPS, running directory services, real-time Defender and the four effective audit subcategories. The assessment capture shows the final DC results, the repaired audit collector and the paired totals. Raw measurements remain private. [Effective policy](screenshots/dc-policy-and-protocols.png) · [Assessment console](screenshots/dc-assessment.png) · [Generated report](assessment.md)

Keep source capture files in the private `artifacts/` directory. Review screenshots for credentials, activation identifiers and unrelated personal information. Record the capture time, role, control ID and the matching report evidence for each published image.
