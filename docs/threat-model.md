# Threat model

## Scope and assumptions

Use test identities, approved Windows images and a private forest. Treat backups and relationship exports as sensitive. Review directory changes as leased lab tasks.

Use the proposed [component graph](architecture.md) as the system boundary. Assumptions and control efficacy are subject to laboratory verification.

| Threat | Trust boundary | Proposed control | Future verification |
| --- | --- | --- | --- |
| Excess delegation | Helpdesk to directory | Scoped OU ACLs and periodic group review | Reset allowed for pilot users and denied for privileged accounts |
| Privileged session exposure | Admin to member networks | Dedicated admin workstation and separate admin identity | Privileged interactive sign-in to pilot client is denied |
| Legacy auth weakness | Client to services | NTLM audit, staged exceptions, Kerberos verification | Document dependency and verify exception expiry |
| Directory outage or unsafe restore | Directory to backups | Separate backup access and isolated restore | Recover identity and DNS in clone and confirm timestamps |

## Residual risk and review triggers

Use a single forest to focus on authorization and recovery; inter-forest delegation and cloud federation are future work. Pair BloodHound relationship analysis with PowerShell exported ACLs and membership because collection scope can hide edges. Observe NTLM usage before enforcement to avoid breaking legitimate legacy services.

Revisit the model whenever the topology, identities, dataset, or deployment context changes.
