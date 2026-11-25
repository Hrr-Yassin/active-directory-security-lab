#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
Import-Module ActiveDirectory
$config = Get-LabConfig
$null = Get-LabDomain
$root = 'C:\IdentityLabShares'
$ownerMarker = Join-Path $root '.idlab-owned'

if (-not $Apply -or -not $PSCmdlet.ShouldProcess($root, 'Create the two department shares and their scoped ACLs')) {
    Write-Output 'Preflight passed. Apply creates only the fixture shares under C:\IdentityLabShares.'
    return
}

function Assert-RealLabDirectory {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.PSIsContainer -or $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) {
        throw "$Path is outside the supported fixture layout."
    }
}

$admin = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
$system = [Security.Principal.SecurityIdentifier]::new('S-1-5-18')
$adminName = $admin.Translate([Security.Principal.NTAccount]).Value

if (-not (Test-Path -LiteralPath $root)) {
    New-Item -ItemType Directory -Path $root | Out-Null
    Set-Content -LiteralPath $ownerMarker -Value $config.PolicyOwner
}
Assert-RealLabDirectory -Path $root
if (-not (Test-Path -LiteralPath $ownerMarker -PathType Leaf) -or (Get-Content -LiteralPath $ownerMarker -Raw).Trim() -ne $config.PolicyOwner) {
    throw 'The resource root exists without the expected lab ownership marker.'
}

foreach ($department in $config.Departments) {
    $name = $department.Name
    $path = Join-Path $root $name
    $role = Get-ADGroup $department.ShareGroup
    $roleName = $role.SID.Translate([Security.Principal.NTAccount]).Value
    $share = Get-SmbShare -Special $false | Where-Object Name -eq $name
    if ($share -and ($share.Path -ne $path -or $share.Description -ne $config.PolicyOwner)) {
        throw "Existing share $name differs from the managed fixture."
    }
    if (-not (Test-Path -LiteralPath $path)) { New-Item -ItemType Directory -Path $path | Out-Null }
    Assert-RealLabDirectory -Path $path

    $acl = Get-Acl -LiteralPath $path
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($old in @($acl.GetAccessRules($true, $false, [Security.Principal.SecurityIdentifier]))) {
        $acl.RemoveAccessRuleSpecific($old)
    }
    $flags = [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
    $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($admin, 'FullControl', $flags, 'None', 'Allow'))
    $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($system, 'FullControl', $flags, 'None', 'Allow'))
    $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($role.SID, 'Modify', $flags, 'None', 'Allow'))
    Set-Acl -LiteralPath $path -AclObject $acl

    $fixture = Join-Path $path 'welcome.txt'
    if (-not (Test-Path -LiteralPath $fixture)) {
        Set-Content -LiteralPath $fixture -Value "Fictional IdentityLab $name data."
    }
    if (-not $share) {
        New-SmbShare -Name $name -Path $path -FullAccess $adminName -ChangeAccess $roleName -Description $config.PolicyOwner | Out-Null
    }
}
Write-Output 'Department shares are ready. Measure the share and filesystem ACLs before sign-in tests.'
