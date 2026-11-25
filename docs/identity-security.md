# Identity security practices

## Keep separate identities for separate duties

Use an ordinary account for daily work and a distinct named account for each privileged role. Reserve the built-in domain administrator for controlled recovery, with a tested secret and an owner. Perform directory administration from a trusted management boundary. Use separate local recovery identities for endpoint maintenance. Audit direct group members, nested groups and directory ACLs as different access paths.

## Give access through roles and review the result

Model department membership in global groups and apply resource permissions with domain-local groups. Include business approval before access is added, periodic review during employment, and disablement with session and membership review on departure. Treat a recent `LastLogonDate` as a signal subject to replication lag. Account age helps distinguish an old unused account from a new one. Require an owner and justification for dormant accounts and exceptions.

Delegate individual administrative actions to the narrowest OU and object class. Review whether a role can change passwords, write group membership, create computers or modify ACLs. Test a permitted operation and a denied one using disabled or disposable fixtures. Keep an audit trail for both.

## Protect service and local administrator credentials

Use gMSAs for supported workloads, restrict which computers can retrieve the credential, and grant only the service rights required for the application. Review encryption and SPNs in the service account’s real workload context. Use Windows LAPS with encrypted directory backup at supported functional levels. Check computer self-write, authorized readers and retrieval auditing after each delegation change. [Microsoft gMSA guidance](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/group-managed-service-accounts/group-managed-service-accounts/manage-group-managed-service-accounts) · [Microsoft Windows LAPS guidance](https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-scenarios-windows-server-active-directory)

## Protect authentication and measure compatibility

Use AD DNS and reliable time. Use Kerberos with the correct service names. Establish a signed-client baseline before requiring signing on directory and SMB servers. Inventory NTLM dependencies before reducing compatibility. Use trusted certificates when clients require LDAPS. Apply strong password policy, reasonable lockout criteria and stronger authentication for privileged access in enterprise deployments.

Pilot changes with positive access and deliberate denied-access tests. Maintain Windows Defender and firewall policy, track signature age, and keep advanced audit logs useful during changes. Retain only needed events and protect access to them. A production environment should forward appropriate DC and endpoint events off-host.

## Plan recovery and document exceptions

Maintain tested system-state backups isolated from the directory. Rehearse recovery in a disconnected environment. Track the owner, reason, expiry and follow-up for each exception. Compare controls using stable coverage, and preserve measurements for known gaps alongside successful results.
