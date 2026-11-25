# ADR 0002. Host-only libvirt network

**Accepted**

Use `ad-identity-lab` with a dedicated host-only bridge, a private IPv4 subnet, static guests and no default gateway. Keep the Phase 0 namespace `corp.example.test`, use `IDLAB` for short sign-in names and resolve domain records through the DC. The Fedora host can reach the bridge for administration and evidence collection.

An unjoined evaluation guest may use a temporary provisioning connection for official activation and servicing. Remove the connection before configuring the domain. Review both hypervisor and guest networks before each deployment stage. The bridge separates the guests from the LAN and provides no guest egress by design. The Fedora root and hypervisor administrators remain inside the trust boundary.
