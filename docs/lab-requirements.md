# Laboratory requirements

Estimate 8 logical cores, 24–32 GB RAM and 200 GB SSD for two DCs, one server, a client and an on-demand admin workstation. Use valid Windows evaluation terms, private virtual switching, internal name resolution and clean snapshots.

## Setup decisions before implementation

Use an isolated corp.example.test forest, two domain controllers on an identity segment, one member server and a Windows 11 client on a member segment. Add a dedicated management workstation and restricted backup/log repository. Domain controllers handle protected directory, DNS and time services. Route only needed domain traffic across segments. Separate privileged administration from normal member access, restrict backups to recovery custodians, and perform system-state restore in a disconnected clone.

## Release boundaries

Use test identities, approved Windows images and a private forest. Treat backups and relationship exports as sensitive. Review directory changes as leased lab tasks.

Check available CPU, memory, storage, version compatibility and approval before provisioning. Record actual allocations in the first validated run.
