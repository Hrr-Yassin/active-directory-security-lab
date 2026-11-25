# ADR 0003. Native configuration and behavior evidence

**Accepted**

The baseline uses ActiveDirectory, GroupPolicy, NetSecurity, SmbShare, Defender, native audit and event tooling, and direct protocol and access tests. Keep the first capture from the real assembled domain. Record the accepted target, observable facts and measurement status for each control. Passes already present in the baseline remain passes in both phases.

PingCastle may be an additional evidence source if its compatible release and applicable license are available. The portfolio comparison uses the repository’s published control catalog. It measures configuration adherence among comparable controls and records runtime checks separately, since successful application behavior and a compliant setting answer different questions.

The private captures retain a per-installation identifier for pairing. The public report contains only allowlisted numeric facts, phase times, source hashes, known role labels and a code revision.
