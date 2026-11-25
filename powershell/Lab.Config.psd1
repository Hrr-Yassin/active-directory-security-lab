@{
    Domain = 'corp.example.test'
    NetBIOS = 'IDLAB'
    DcName = 'LAB-DC01'
    WorkstationName = 'LAB-WS01'
    DcAddress = '192.168.221.10'
    WorkstationAddress = '192.168.221.20'
    ParentOU = 'IdentityLab'
    PolicyOwner = 'Managed by the IdentityLab repository'
    DcGpo = 'IDLAB - Domain Controller Security'
    WorkstationGpo = 'IDLAB - Workstation Security'
    Administrator = 'casey.t0'
    HelpdeskOperator = 'rina.hd'
    HelpdeskGroup = 'GG-Lab-Helpdesk'
    ServiceName = 'svc-lab-batch'
    ServiceHosts = 'GG-Lab-ServiceHosts'
    ResetRight = '00299570-246d-11d0-a768-00aa006e0529'
    UserClass = 'bf967aba-0de6-11d0-a285-00aa003049e2'
    Departments = @(
        @{ Name = 'Finance'; User = 'maia.fin'; Display = 'Maia North'; RoleGroup = 'GG-Lab-Finance'; ShareGroup = 'DL-Lab-Finance-Modify' }
        @{ Name = 'Operations'; User = 'owen.ops'; Display = 'Owen Vale'; RoleGroup = 'GG-Lab-Operations'; ShareGroup = 'DL-Lab-Operations-Modify' }
    )
    AuditLogon = '{0CCE9215-69AE-11D9-BED3-505054503030}'
    AuditUserManagement = '{0CCE9235-69AE-11D9-BED3-505054503030}'
    AuditGroupManagement = '{0CCE9237-69AE-11D9-BED3-505054503030}'
    AuditKerberosTicket = '{0CCE9240-69AE-11D9-BED3-505054503030}'
    PasswordLength = 14
    PasswordHistory = 24
    LockoutThreshold = 10
    LockoutMinutes = 15
}
