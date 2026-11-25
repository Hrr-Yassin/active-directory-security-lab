# Host and guest requirements

| Resource | Pilot allocation | Limits |
| --- | --- | --- |
| Fedora host | Hardware virtualization, KVM, QEMU, system libvirt, virt-install and a local console | Check access to `qemu:///system` and `/dev/kvm`. Use the ordinary desktop/user session for owner sign-in |
| Windows Server | 2 vCPU, 4 GiB RAM, 60 GiB thin qcow2 disk | Budget around 20–32 GiB physical allocation after installing Desktop Experience and servicing. Track actual consumption |
| Windows 11 | Existing 4 vCPU and 8 GiB configuration on this host | Support an AD join with a compatible edition. Verify setup, activation, local administrator access, and free disk before reuse |
| ISO, rollback and evidence | About 4.7 GiB for the Server evaluation ISO, additional temporary staging and variable Windows overlay growth | Keep the datastore reserve visible. Cold backups and snapshots can require substantially more space |
| Software | Windows PowerShell 5.1 with native AD DS, Group Policy and networking modules. Current cumulative updates for LAPS | Run PowerShell 7 on Fedora for parsing and report generation only |

The initial host observation showed eight logical threads, 31 GiB RAM, around 19 GiB available memory and roughly 47 GiB free disk before Windows work. Two other guests were already running. The proposed Windows allocation is 12 GiB in total. Review host memory and storage independently of nominal guest capacities. Avoid keeping unrelated guests or duplicate full-size media under this project’s control. [Microsoft Windows Server hardware requirements](https://learn.microsoft.com/en-us/windows-server/get-started/hardware-requirements)

Obtain a legitimate Windows Server 2022 evaluation and use the normal activation path. Microsoft specifies a 180-day evaluation and Internet activation within the first 10 days. Use an approved activation and servicing connection on the standalone server before lab isolation. Use suitable Windows 11 Pro, Enterprise, Education or other supported editions with legitimate licensing. [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022)
