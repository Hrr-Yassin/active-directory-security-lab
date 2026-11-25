# Domain authentication and authorization

~~~mermaid
sequenceDiagram
    participant W as Windows 11 workstation
    participant D as AD-integrated DNS
    participant K as DC Kerberos KDC
    participant S as DC SMB service
    participant L as AD DS LDAP service
    W->>D: Query LDAP and Kerberos SRV records
    D-->>W: Return the DC FQDN and A record
    W->>K: Request a ticket-granting ticket during domain sign-in
    K-->>W: Return the TGT
    W->>K: Request a service ticket for cifs/LAB-DC01.corp.example.test
    K-->>W: Return the service ticket
    W->>S: Present the service ticket over signed SMB
    S-->>W: Evaluate token groups, share ACL and NTFS ACL
    W->>L: Bind using Kerberos with LDAP signing and sealing on TCP 389
    L-->>W: Return the scoped directory query result
~~~

Windows domain location depends on AD DNS SRV records, resolving the DC’s hostname, and clocks close enough for Kerberos. Diagnose DNS, time, the trust channel and service SPNs before changing authentication policy. Access the SMB share by its DC FQDN so the client can request the correct CIFS service ticket. Use a fresh sign-in after changing group membership so the client has a fresh token and Kerberos authorization data. [Microsoft Kerberos overview](https://learn.microsoft.com/en-us/windows-server/security/kerberos/kerberos-authentication-overview)

LDAP signing gives authenticated directory operations message integrity. The demonstration requests SASL signing and sealing with Kerberos on TCP 389. LDAPS uses TLS, normally on TCP 636, with peer identity verified through the certificate chain and DC DNS name. LDAP channel binding associates supported authentication with the TLS session. Its setting is inventoried separately. [Microsoft LDAP signing guidance](https://learn.microsoft.com/en-us/windows-server/identity/manage-ldap-signing-group-policy)

To run the optional LDAPS exercise, enroll a lab-only server certificate with Server Authentication EKU, an accessible private key and the DC FQDN in its DNS SAN. Place it in the supported DC certificate store and trust its issuing CA on the lab workstation alone. Check expiry and trust. Refresh the AD DS certificate or restart the DC, then run `Test-LabIdentity.ps1 -IncludeLdaps` as a fictional department user. Record an actual successful TLS bind or its failure separately. [Microsoft LDAPS certificate requirements](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/configure-ldap-signing-certificates)

An authenticated user’s group membership becomes part of the Windows access token. Global groups model job roles and domain-local groups apply the resource permissions. SMB access needs approval from both share and NTFS access checks. An inherited directory ACE, by contrast, applies an AD object right to the selected descendant object class. The helpdesk test attempts resets on two disabled fixture accounts placed on opposite sides of that OU boundary.
