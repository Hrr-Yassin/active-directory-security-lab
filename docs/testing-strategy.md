# Future testing and acceptance

All results are pending implementation. The following criteria are proposed for a controlled educational environment.

Capture DNS health, time skew, privileged group membership, delegated ACLs, service account properties, effective GPO, log availability, NTLM use and backup age before change. Re-run using the same scope and config revisions after pilot hardening. Require normal sign-in, service ticket issuance, least-privilege helpdesk, audited group changes and protected account denial. Record signed exceptions for each legacy dependency with expiry. Future recovery trial must restore a disconnected clone, validate DNS and obtain a ticket for a fictional test account before timing the recovery.

## Control checks

| Control objective | Check and expected behavior |
| --- | --- |
| Excess delegation | Reset allowed for pilot users and denied for privileged accounts |
| Privileged session exposure | Privileged interactive sign-in to pilot client is denied |
| Legacy auth weakness | Document dependency and verify exception expiry |
| Directory outage or unsafe restore | Recover identity and DNS in clone and confirm timestamps |

## Evidence and disposition

Use the [structured evidence template](../templates/baseline-review.md). Record fixture or revision, operator, expected and observed outcomes, timestamps, and supporting evidence. Use pass, fail, blocked or unexecuted and preserve the first result on retest.
