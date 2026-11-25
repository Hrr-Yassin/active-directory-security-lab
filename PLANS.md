# Execution plan

| Stage | Work and entry point | Exit evidence |
| --- | --- | --- |
| Host | Inventory Fedora and libvirt, recover Phase 0 on a feature branch, verify official media and create the dedicated network | Upstream parent, measured resources, media provenance, bridge XML and route review |
| Domain | Install and activate the evaluation on a new guest, isolate it, promote AD DS and DNS, seed the identity tree and shares | A healthy DC, DNS SRV records, groups, test users and a protected recovery account |
| Client | Use owner-approved local sign-in, static DNS and the scoped join script | Signed-in department user, secure channel, SYSVOL and successful domain DNS lookup |
| Initial assessment | Capture the two unchanged Windows guests using the same run ID and script revision, and exercise baseline authorization | Before JSON, source hashes, screenshot links and observed gaps |
| Hardening | Pilot client signing, review compatibility, enforce lab controls, apply advanced auditing and configure optional LAPS | Effective GPO and settings, DC and workstation still healthy |
| Validation | Measure after state, run positive and negative access tests, review event and protocol evidence | Paired score, at least 12 evidenced controls, authentication and policy screenshots |
| Handoff | Reconcile docs and portfolio claims with the evidence, and verify the dedicated Git branch | Reproducible instructions, technical rating and verified release branch |

Keep one operator at a time for forest and VM configuration. Recheck host capacity before adding a guest. Keep existing VMs on their original networks except for the approved `win11` pilot. See [deployment](docs/deployment.md) and [control verification](docs/controls.md).
