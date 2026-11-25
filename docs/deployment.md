# Deployment runbook

Commands target the dedicated pilot. Obtain approval before changing an existing VM. Use fresh, distinct lab passwords and store them in the lab owner’s password manager. Run guest scripts from Windows PowerShell 5.1 with the privileges specified by each script.

## 1. Prepare Fedora and the network

~~~bash
bash host/Inspect-LabHost.sh
virt-xml-validate host/ad-identity-lab.xml network
virsh -c qemu:///system net-define host/ad-identity-lab.xml
virsh -c qemu:///system net-start ad-identity-lab
virsh -r -c qemu:///system net-dumpxml ad-identity-lab
~~~

Before defining the network, compare `192.168.221.0/24` with host routes and existing virtual networks. If this lab network already exists, inspect its live XML and use it only if it matches the plan. Keep the bridge without a forwarding or DHCP element. Record actual guest and host capacities. See [requirements](lab-requirements.md).

Download the official Windows Server 2022 evaluation ISO. Record its origin and SHA-256. Use a host path readable by libvirt under the local SELinux and file-permission policy. [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022)

## 2. Install and activate the new server

Create a new VM named `idlab-dc01` with a thin disk.

~~~bash
virt-install --connect qemu:///system --name idlab-dc01 \
  --osinfo win2k22 --virt-type kvm --memory 4096 --vcpus 2 --cpu host-model \
  --disk pool=default,size=60,format=qcow2,bus=sata \
  --network network=ad-identity-lab,model=e1000e \
  --boot uefi --cdrom "$SERVER_ISO" --graphics spice,listen=none --noautoconsole
virt-viewer --connect qemu:///system idlab-dc01
~~~

In Windows Setup select **Windows Server 2022 Standard Evaluation (Desktop Experience)** and the new disk. Complete the license and password prompts. Before AD promotion, activate and service the standalone evaluation over an approved temporary provisioning connection. Switch only the unjoined new guest onto the provisioning network, verify licensing using `slmgr.vbs /xpr`, and return its only NIC to the isolated network before setting the lab IP. Server 2022 needs the Windows LAPS cumulative update or later for the built-in LAPS module. Verify pending updates and reboot before proceeding.

Use removable media to copy the `powershell/` directory to `C:\IdentityLab` on the guests. Prepare a read-only ISO on Fedora and keep private keys and passwords in separate owner-controlled storage.

~~~bash
mkdir -p artifacts/media
xorriso -as mkisofs -J -R -V IDLAB_SCRIPTS -o artifacts/media/IdentityLab-Scripts.iso powershell
~~~

Keep the approved source ISO and working scripts in known paths. Use an authorized console for any policy governing local script execution.

## 3. Promote the DC and provision the directory

Rename the new server from an elevated console.

~~~powershell
Rename-Computer -NewName LAB-DC01 -Restart
~~~

After the reboot, configure the lab network and promote the server.

~~~powershell
Set-Location C:\IdentityLab
.\Set-LabNetwork.ps1 -Role DC -Apply
.\Install-LabDomain.ps1 -Apply
~~~

Use a distinct DSRM secret. After promotion and restart, sign in through the DC console as the authorized directory administrator. Record DC time and validate DNS before joining a client.

~~~powershell
Set-Location C:\IdentityLab
.\Get-LabHealth.ps1 -Role DC
.\Initialize-LabDirectory.ps1 -Apply
.\Initialize-LabShares.ps1 -Apply
~~~

For this isolated single-DC environment, ensure the PDC advertises a reliable lab time source and review guest clock offsets. With an accurate Fedora clock and a consistent guest RTC, the lab PDC can use its local clock. A production PDC should use managed authoritative time sources. Confirm that the server points at its own lab DNS service.

~~~powershell
w32tm /config /syncfromflags:NO /reliable:YES /update
Restart-Service W32Time
w32tm /query /source
~~~

## 4. Prepare and join Windows 11

Use the owner-approved VM only after saving its inactive XML and recording rollback assets. Retain its MAC, original backing disk and original network name. For `win11`, the approved deployment used an external disk snapshot before the network change. The snapshot is disk-only. Handle UEFI variables, TPM state, BitLocker recovery and backups through the owner’s normal process.

Inspect the approved VM’s NIC from Fedora. It must attach only to `ad-identity-lab`. Sign in through the local admin console and ensure the machine is standalone and has a domain-join-capable Windows edition. Review current IP and DNS before editing them.

An authenticated inventory of this pilot’s original VM identified Windows 11 Home. If Microsoft Activation is unreachable from the isolated network, get explicit owner approval to move only `win11`’s existing NIC to an authorized activation network. Keep a record of its original attachment and retain the same NIC and MAC. The owner completes the Pro upgrade privately in Windows Activation using their entitlement. After the upgrade and any restart, confirm Windows 11 Pro and an active license, restore the single NIC to `ad-identity-lab`, and confirm the live and persistent attachment before configuring the lab address. [Microsoft Home-to-Pro instructions](https://support.microsoft.com/en-us/windows/deployment/install-upgrade/upgrade-windows-home-to-windows-pro)

~~~powershell
Rename-Computer -NewName LAB-WS01 -Restart
# Run the following after reboot as the authorized local administrator.
Set-Location C:\IdentityLab
.\Set-LabNetwork.ps1 -Role Workstation -Apply
.\Join-LabWorkstation.ps1 -Apply
Restart-Computer
~~~

After restarting, use the local admin console for workstation maintenance and a fictional ordinary domain sign-in for workflow checks. Verify the secure channel and SYSVOL. The join script takes credentials for the designated account through the normal credential prompt. Keep domain administrative logons on the DC.

~~~powershell
.\Get-LabHealth.ps1 -Role Workstation
~~~

## 5. Measure, apply, verify

If endpoint enrollment happens after DC hardening, preserve the original DC capture pair. Record the workstation’s actual post-enrollment measurements after the policy refresh and mark unavailable historical workstation measurements unmeasured. Record LAPS processing and encrypted backup presence without retrieving a password. [Measurement scope](assessment.md)

Create one run ID and use the Git revision containing the copied scripts. Use one private capture directory per run. Capture each available role before rolling out any control settings. If the workstation upgrade is pending, proceed with the DC captures and rollout. The combined report marks controls that require workstation evidence as unmeasured.

~~~powershell
$runId = [guid]::NewGuid()
# Record this value and use the same GUID on the other guest.
$runId
$capture = 'C:\IdentityLabEvidence'
$revision = 'REPLACE_WITH_COMMIT_SHA'
.\Get-LabAssessment.ps1 -Role DC -Phase Before -RunId $runId -Revision $revision -OutputDirectory $capture
~~~

If the workstation is eligible and joined before rollout, run the corresponding `-Role Workstation` command on the client using the same run ID and revision. Compare the initial captures with the [control matrix](controls.md). Run `Test-LabDelegation.ps1 -Phase Before -Apply` on the DC and exercise share access from the workstation when available. On the DC back up the Default Domain Policy and any existing managed GPOs before editing them. Record the original password, lockout, audit and registry settings for rollback.

~~~powershell
# DC console. Stage compatible client settings.
.\Set-LabHardening.ps1 -Stage PrepareClients -Apply
~~~

Run `gpupdate /force` locally on the DC and on the workstation if joined. Exercise Kerberos and signed LDAP, and review the NTLM Operational log. Align the centrally managed account settings in GPMC as described in [the control matrix](controls.md). Then apply the enforcement phase on the DC.

~~~powershell
.\Set-LabHardening.ps1 -Stage Enforce -Apply
~~~

On Server 2022, inspect **Default Domain Controllers Policy → Computer Configuration → Policies → Windows Settings → Security Settings → Local Policies → Security Options** after enforcement. The existing **Domain controller: LDAP server signing requirements** security option can override the managed registry value during refresh. After the signed client checks above, set this security option to **Require signing**, refresh policy, and verify both a signed bind and the expected rejection of a cleartext simple bind. [Microsoft LDAP signing procedure](https://learn.microsoft.com/en-us/windows-server/identity/manage-ldap-signing-group-policy)

Refresh Group Policy and apply the native audit script on each available role, then verify the settings after another refresh. On the DC, stage the KDS key if needed and allow the Microsoft propagation time before creating the gMSA. Use the normal supported LAPS path on a patched server, extending only the disposable lab forest schema when necessary. [Microsoft KDS root key guidance](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/group-managed-service-accounts/group-managed-service-accounts/create-the-key-distribution-services-kds-root-key)

~~~powershell
# Dedicated single-DC pilot only, use this when no KDS key exists.
.\Initialize-LabServiceAccount.ps1 -Apply -InitializeKds -SingleDcLab
# Apply after the key becomes effective.
.\Initialize-LabServiceAccount.ps1 -Apply
# DC, supported builds only and after confirming schema change scope.
.\Enable-LabLaps.ps1 -Apply -ExtendSchema
~~~

Omit `-SingleDcLab` when using the normal KDS procedure and allow the 10-hour propagation window before creating the gMSA.

When the managed workstation is available, refresh and run `Invoke-LapsPolicyProcessing` and review the LAPS event and backup-presence evidence. Once the controls have reached stable effective state, capture `-Phase After` for each role with a baseline and rerun its health, identity and delegated reset tests. Record each verified role’s console screenshot, UTC times and supporting Security and Operational event IDs.

Collect the available paired JSON captures into one private directory using approved offline media or a lab-only transfer. Generate the sanitized report from the repository root.

~~~powershell
.\powershell\New-LabAssessmentReport.ps1 -CaptureDirectory .\artifacts\captures -OutputPath .\artifacts\assessment.md
~~~

## Rollback

Review the scoped GPO and AD attribute changes against the private Before exports. Restore specific values and recheck policy and health after each change. Unlinking a registry-backed policy may leave values in place. Reverse the helpdesk ACE and confirm the previously allowed operation becomes denied. Windows LAPS schema additions on the lab forest persist.

For the existing Windows 11 VM, the rollback record includes the original inactive XML and its original backing disk setting. Coordinate with the owner before restoring VM state or exiting the lab. Verify Windows TPM and BitLocker recovery readiness, and retain the overlay until its contents and any post-snapshot work have been reviewed.
