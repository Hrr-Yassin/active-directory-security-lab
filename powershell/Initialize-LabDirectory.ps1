#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Common.psm1')
Import-Module ActiveDirectory
$config = Get-LabConfig
$layout = Get-LabLayout
$domain = Get-LabDomain

if (-not $Apply -or -not $PSCmdlet.ShouldProcess($config.Domain, 'Seed the lab OUs, groups, and fictional identities')) {
    Write-Output 'Preflight passed. Apply seeds only the dedicated forest and prompts for passwords for newly created human users.'
    return
}

function Initialize-LabOU {
    param([string]$Name, [string]$Parent)
    $existing = Get-ADOrganizationalUnit -Filter { Name -eq $Name } -SearchBase $Parent -SearchScope OneLevel
    if (-not $existing) {
        New-ADOrganizationalUnit -Name $Name -Path $Parent -ProtectedFromAccidentalDeletion $true
    }
}

function Initialize-LabGroup {
    param([string]$Name, [string]$Scope)
    $group = Get-ADGroup -Filter { SamAccountName -eq $Name } -Properties Description
    if (-not $group) {
        New-ADGroup -Name $Name -SamAccountName $Name -GroupScope $Scope -GroupCategory Security -Path $layout.Groups -Description $config.PolicyOwner
    } elseif ($group.DistinguishedName -ne "CN=$Name,$($layout.Groups)" -or $group.GroupScope -ne $Scope -or
        $group.GroupCategory -ne 'Security' -or $group.Description -ne $config.PolicyOwner) {
        throw "Existing group $Name differs from the managed seed. Review it before reseeding."
    }
}

function Initialize-LabUser {
    param([string]$Sam, [string]$Display, [string]$OU, [switch]$Sensitive, [switch]$TestOnly)
    $existing = Get-ADUser -Filter { SamAccountName -eq $Sam } -Properties Description
    if ($existing) {
        if ($existing.DistinguishedName -ne "CN=$Sam,$OU" -or $existing.Description -ne $config.PolicyOwner) {
            throw "Existing user $Sam differs from the managed seed. Review it before reseeding."
        }
        return
    }

    $user = @{
        Name = $Sam
        DisplayName = $Display
        SamAccountName = $Sam
        UserPrincipalName = "$Sam@$($config.Domain)"
        Description = $config.PolicyOwner
        Path = $OU
        AccountNotDelegated = $Sensitive.IsPresent
        Enabled = $false
    }
    if ($TestOnly) {
        New-ADUser @user
        return
    }
    $user.AccountPassword = Read-Host "Set a unique lab-only password for $Sam" -AsSecureString
    if ($user.AccountPassword.Length -lt $config.PasswordLength) {
        throw "Use a password that already meets the lab minimum length for $Sam."
    }
    $user.Enabled = $true
    New-ADUser @user
    if (-not (Get-ADUser -Identity $Sam).Enabled) {
        throw "Account $Sam was created disabled. Review the password policy, reset the password, and enable it explicitly."
    }
}

function Add-LabMember {
    param([string]$Group, [string]$Principal)
    $object = Get-ADObject -Filter { SamAccountName -eq $Principal }
    if (-not $object) { throw "Missing seed principal $Principal." }
    $members = (Get-ADGroup -Identity $Group -Properties member).member
    if ($object.DistinguishedName -notin @($members)) {
        Add-ADGroupMember -Identity $Group -Members $object.DistinguishedName
    }
}

Initialize-LabOU -Name $config.ParentOU -Parent $layout.Domain
foreach ($name in 'People', 'Operators', 'Groups', 'Service Accounts', 'Workstations') {
    Initialize-LabOU -Name $name -Parent $layout.Root
}

Initialize-LabGroup -Name $config.HelpdeskGroup -Scope Global
Initialize-LabGroup -Name $config.ServiceHosts -Scope Global
foreach ($department in $config.Departments) {
    $ou = "OU=$($department.Name),$($layout.People)"
    Initialize-LabOU -Name $department.Name -Parent $layout.People
    Initialize-LabGroup -Name $department.RoleGroup -Scope Global
    Initialize-LabGroup -Name $department.ShareGroup -Scope DomainLocal
    Initialize-LabUser -Sam $department.User -Display $department.Display -OU $ou
    Add-LabMember -Group $department.RoleGroup -Principal $department.User
    Add-LabMember -Group $department.ShareGroup -Principal $department.RoleGroup
}

Initialize-LabUser -Sam 'rina.support' -Display 'Rina West' -OU $layout.People
Initialize-LabUser -Sam $config.HelpdeskOperator -Display 'Rina West - Helpdesk' -OU $layout.Operators -Sensitive
Initialize-LabUser -Sam $config.Administrator -Display 'Casey Reed - Directory Admin' -OU $layout.Operators -Sensitive
Initialize-LabUser -Sam 'reset.inside' -Display 'Disposable Reset Test In Scope' -OU $layout.People -TestOnly
Initialize-LabUser -Sam 'reset.outside' -Display 'Disposable Reset Test Out of Scope' -OU $layout.Operators -TestOnly
Add-LabMember -Group $config.HelpdeskGroup -Principal $config.HelpdeskOperator
Add-LabMember -Group "$($domain.DomainSID.Value)-512" -Principal $config.Administrator
Write-Output 'Directory seed complete. The two reset test accounts remain disabled.'
