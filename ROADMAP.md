# Implementation roadmap

Phase 0 design documentation is complete. Laboratory preparation and all implementation, validation and evidence tasks remain pending.

## Phase 0 — Requirements, architecture and laboratory preparation

- [x] Complete Phase 0 design documentation.
- [ ] Draft OU, segmentation, scope and recovery plan.

| Objective | Dependencies | Expected outputs | Acceptance | Difficulty | Skills | Known risk |
| --- | --- | --- | --- | --- | --- | --- |
| Define namespace and roles | Windows evaluation terms | Topology and role matrix | Each privileged role has an owner and boundary | Medium | Identity design | Resource sizing |

## Phase 1 — Minimum viable educational prototype

- [ ] Build pilot domain.
- [ ] Provision DNS, DC and member client.

| Objective | Dependencies | Expected outputs | Acceptance | Difficulty | Skills | Known risk |
| --- | --- | --- | --- | --- | --- | --- |
| Build pilot domain | Isolated switch and images | Working pilot services | DNS and domain sign-in pass baseline | Medium | Domain administration | Time mismatch |

## Phase 2 — Core functionality

- [ ] Add delegation and policy.
- [ ] Pilot GPO, lifecycle and audit collection.

| Objective | Dependencies | Expected outputs | Acceptance | Difficulty | Skills | Known risk |
| --- | --- | --- | --- | --- | --- | --- |
| Add delegation and policy | Working identities | Versioned policy evidence | Allowed and denied permissions match matrix | High | Least privilege | Nested group ambiguity |

## Phase 3 — Security validation and controlled laboratory verification

- [ ] Compare and restore.
- [ ] Repeat review, test exceptions and isolated recovery.

| Objective | Dependencies | Expected outputs | Acceptance | Difficulty | Skills | Known risk |
| --- | --- | --- | --- | --- | --- | --- |
| Compare and restore | Baseline exports and backups | Before/after packet | Normal use passes and recovered clone resolves DNS | High | Hardening validation | Legacy compatibility |

## Phase 4 — Documentation, performance evaluation and professional presentation

- [ ] Publish design evidence.
- [ ] Redact exports and document rollback.

| Objective | Dependencies | Expected outputs | Acceptance | Difficulty | Skills | Known risk |
| --- | --- | --- | --- | --- | --- | --- |
| Publish design evidence | Reviewed artifacts | Identity audit report | Each conclusion traces to export and policy version | Medium | Enterprise reporting | Directory data leakage |
