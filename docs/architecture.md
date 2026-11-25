# Network and identity architecture

The pilot uses one AD DS forest and one domain. Windows Server hosts the directory, DNS and two departmental file shares. The isolated Windows 11 VM is running Home and awaits the owner’s Pro upgrade before it can join. Fedora runs both guests and is the only upstream administration boundary.

~~~mermaid
flowchart LR
    LAN["Host LAN and other virtual networks"]
    HOST["Fedora KVM and libvirt<br/>Console and evidence collection"]
    LAN --- HOST
    subgraph I["ad-identity-lab · 192.168.221.0/24 · no guest routing"]
        B["virbr-idlab<br/>192.168.221.1"]
        DC["LAB-DC01 · 192.168.221.10<br/>AD DS, DNS, KDC, SYSVOL, SMB"]
        WS["win11 · Windows 11 Home<br/>Target LAB-WS01 · 192.168.221.20"]
        B --- DC
        B --- WS
        WS -.->|"After the Pro upgrade and domain join"| DC
    end
    HOST --- B
~~~

| Boundary | Configuration |
| --- | --- |
| Namespace | `corp.example.test` with NetBIOS name `IDLAB` |
| Network | Isolated libvirt bridge with static IPv4 addresses, no default route and no external guest DNS service |
| Domain controller | `LAB-DC01` with server address `192.168.221.10`, Server 2022 Standard Evaluation with Desktop Experience and Windows Server 2016 functional levels |
| Planned domain member | `LAB-WS01` with address `192.168.221.20`, Windows 11 Pro and the DC as its DNS resolver |
| GPO scope | DC policy linked to `OU=Domain Controllers`. Endpoint policy linked to `OU=Workstations,OU=IdentityLab` |
| Management | VM console for new forest and Tier 0 operations. Local administrator for workstation configuration. Helpdesk uses an independent account |

## Organizational units and authorization

~~~mermaid
flowchart TD
    D["corp.example.test"] --> DC["Domain Controllers"]
    D --> R["IdentityLab"]
    R --> P["People"]
    R --> O["Operators"]
    R --> G["Groups"]
    R --> S["Service Accounts"]
    R --> W["Workstations"]
    P --> F["Finance"]
    P --> M["Operations"]
    O --> HD["Helpdesk operator"]
    HD -->|"Reset Password on descendant user objects"| P
    O --> A["Dedicated directory administrator"]
    W --> WK["LAB-WS01"]
~~~

| Role | Expected access |
| --- | --- |
| Finance and Operations employees | Normal domain sign-in. The employee’s global role group is nested into a domain-local group. That group grants Change on its SMB share and Modify on its NTFS folder |
| Helpdesk | A separate operator identity and a single inherited Password Reset right under People. No directory administration or department share entitlement |
| Directory operations | Dedicated `casey.t0` identity and the protected built-in Administrator retained for recovery. Use the DC console |
| Workstation maintenance | Console with the authorized local administrator. Encrypted Windows LAPS is scoped to Workstations when supported |
| Service identity | Outbound-only gMSA, AES and an empty set of eligible hosts while no workload is assigned |

Relevant Windows traffic includes DNS 53, Kerberos 88 and 464, LDAP 389, LDAPS 636, SMB 445, NTP 123, RPC endpoint mapping 135 and applicable dynamic RPC ports. The DC uses the lab-issued certificate for LDAPS. A hostname-validated TLS 1.3 connection and a native Kerberos LDAPS bind passed after the firewall changes. See the [authentication flow](technical-design.md) and [hardening matrix](controls.md).
