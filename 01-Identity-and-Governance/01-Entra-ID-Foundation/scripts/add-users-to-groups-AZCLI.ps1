<#
.SYNOPSIS
    Add AQUAPINE users to appropriate security groups
    
.DESCRIPTION
    Reads user data from CSV and assigns users to groups based on:
    - Department (HR, Sales, IT, etc.)
    - Office Location (Lagos HQ vs. Ibadan Farms)
    - Job Title (Managers, etc.)
    
.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Date: Week 1, Day 5
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$CsvFilePath = "..\data\aquapine-users.csv"
)

$ErrorActionPreference = "Continue"
$script:MembershipsAdded = 0
$script:MembershipsFailed = 0

#region Helper Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    
    switch ($Level) {
        "Success" { Write-Host $logMessage -ForegroundColor Green }
        "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
        "Error"   { Write-Host $logMessage -ForegroundColor Red }
        default   { Write-Host $logMessage -ForegroundColor Cyan }
    }
}

function Add-UserToGroup {
    param(
        [string]$UserPrincipalName,
        [string]$GroupName
    )
    
    try {
        # Get user ID
        $user = az ad user show --id $UserPrincipalName --output json 2>$null | ConvertFrom-Json
        if (-not $user) {
            Write-Log "    ⚠️  User not found: $UserPrincipalName" -Level Warning
            return $false
        }
        
        # Get group ID
        $group = az ad group list --filter "displayName eq '$GroupName'" --output json 2>$null | ConvertFrom-Json
        if (-not $group -or $group.Count -eq 0) {
            Write-Log "    ⚠️  Group not found: $GroupName" -Level Warning
            return $false
        }
        
        $groupId = $group[0].id
        
        # Check if already member
        $members = az ad group member list --group $groupId --output json 2>$null | ConvertFrom-Json
        if ($members.id -contains $user.id) {
            Write-Log "    ℹ️  Already member: $UserPrincipalName → $GroupName" -Level Info
            return $true
        }
        
        # Add to group
        az ad group member add --group $groupId --member-id $user.id 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "    ✅ Added: $UserPrincipalName → $GroupName" -Level Success
            $script:MembershipsAdded++
            return $true
        }
        else {
            Write-Log "    ❌ Failed: $UserPrincipalName → $GroupName" -Level Error
            $script:MembershipsFailed++
            return $false
        }
    }
    catch {
        Write-Log "    ❌ Error: $UserPrincipalName → $GroupName - $_" -Level Error
        $script:MembershipsFailed++
        return $false
    }
}

#endregion

#region Department to Group Mapping

function Get-GroupsForUser {
    param($User)
    
    $groups = @()
    
    # TIER 1: Location-based parent groups
    if ($User.OfficeLocation -eq "Lagos HQ") {
        $groups += "AQUAPINE-Lagos-AllUsers"
    }
    elseif ($User.OfficeLocation -like "*Farm*") {
        $groups += "AQUAPINE-Ibadan-AllUsers"
    }
    
    # TIER 2: Department-based groups
    switch ($User.Department) {
        "Executive Management" { $groups += "Lagos-Executive-Security" }
        "IT Department" { $groups += "Lagos-IT-Security" }
        "Human Resources" { $groups += "Lagos-HR-Security"; $groups += "HR-Department-AdminUnit-Members" }
        "Sales Department" { $groups += "Lagos-Sales-Security" }
        "Logistics Department" { $groups += "Lagos-Logistics-Security" }
        "Farm Operations" { $groups += "Ibadan-FarmOps-Security" }
        "Microbiology Lab" { $groups += "Ibadan-MicrobiologyLab-Security" }
        "Feed Production" { $groups += "Ibadan-FeedProduction-Security" }
        "Hatchery Unit" { $groups += "Ibadan-Hatchery-Security" }
        "Farm Security" { $groups += "Ibadan-FarmSecurity-Security" }
        "Store Department" { $groups += "Ibadan-Store-Security" }
    }
    
    # TIER 3: Role-based groups
    if ($User.JobTitle -like "*Manager*" -or $User.JobTitle -like "*Director*" -or $User.JobTitle -eq "CEO" -or $User.JobTitle -eq "CFO") {
        $groups += "AQUAPINE-AllManagers"
    }
    
    if ($User.JobTitle -eq "IT Manager" -or $User.JobTitle -eq "IT Support Technician") {
        $groups += "AQUAPINE-GlobalAdmins"
    }
    
    if ($User.Department -eq "Sales Department" -or $User.Department -eq "Executive Management" -or $User.JobTitle -like "*Manager*") {
        $groups += "AQUAPINE-MobileWorkers"
    }
    
    if ($User.JobTitle -eq "CFO" -or $User.JobTitle -eq "CEO" -or ($User.Department -eq "Human Resources" -and $User.JobTitle -like "*Manager*")) {
        $groups += "AQUAPINE-FinanceAccess"
    }
    
    # ALL employees group
    $groups += "AQUAPINE-AllEmployees"
    
    return $groups
}

#endregion

#region Main Script

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - ADD USERS TO GROUPS        " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Verify login
    $account = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $account) {
        throw "Not logged in to Azure. Run: az login"
    }
    
    # Load users from CSV
    if (-not (Test-Path $CsvFilePath)) {
        throw "CSV file not found: $CsvFilePath"
    }
    
    $users = Import-Csv -Path $CsvFilePath
    Write-Log "Loaded $($users.Count) users from CSV" -Level Success
    Write-Host ""
    
    # Process each user
    $progressCount = 0
    
    foreach ($user in $users) {
        $progressCount++
        
        Write-Log "[$progressCount/$($users.Count)] Processing: $($user.DisplayName)" -Level Info
        
        # Get groups this user should be in
        $userGroups = Get-GroupsForUser -User $user
        
        Write-Log "  Assigning to $($userGroups.Count) groups..." -Level Info
        
        foreach ($groupName in $userGroups) {
            Add-UserToGroup -UserPrincipalName $user.UserPrincipalName -GroupName $groupName
        }
        
        Write-Host ""
    }
    
    # Summary
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  GROUP MEMBERSHIP SUMMARY                      " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Users Processed: $($users.Count)" -ForegroundColor White
    Write-Host "Memberships Added: $script:MembershipsAdded" -ForegroundColor Green
    Write-Host "Failed: $script:MembershipsFailed" -ForegroundColor $(if ($script:MembershipsFailed -eq 0) { "Green" } else { "Red" })
    Write-Host ""
    
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS                                    " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Verify group memberships:" -ForegroundColor White
    Write-Host "   Azure Portal → Entra ID → Groups → [Group Name] → Members" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Deploy Azure infrastructure:" -ForegroundColor White
    Write-Host "   Run: ..\..\..\02-RBAC-Implementation\scripts\01-deploy-infrastructure.ps1" -ForegroundColor Gray
    Write-Host ""
    
    if ($script:MembershipsFailed -eq 0) {
        Write-Host "🎉 All group memberships assigned successfully!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "⚠️  Some assignments failed - review errors above" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Red
    Write-Host "  SCRIPT EXECUTION FAILED                       " -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Red
    Write-Host ""
    Write-Log "Fatal error: $_" -Level Error
    exit 1
}

#endregion