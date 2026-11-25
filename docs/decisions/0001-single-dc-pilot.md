# ADR 0001. Single-DC pilot

**Accepted**

The design phase proposed two DCs, a member server, a privileged workstation, a dedicated log store and a backup host. The measured Fedora workstation has eight logical threads and shares its storage and memory with other running labs.

Run Windows Server 2022 Standard Evaluation with Desktop Experience and one Windows 11 domain member. Use DNS and AD DS on the DC. Host two small fictional SMB shares on the DC for the authorization exercise and use its local console for directory administration. Stage a gMSA for a future member workload with an empty host group.

The system demonstrates one forest, one directory, domain membership, Group Policy and effective authorization. It has a single point of failure, limited recovery and no independent server tier. Moving the shares to a member server and adding a second DC, managed time sources, off-host logs, an admin workstation and a rehearsed recovery plan remain the production design.
