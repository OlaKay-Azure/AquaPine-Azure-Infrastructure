<#
.SYNOPSIS
    Create AQUAPINE security groups using Azure CLI
    
.DESCRIPTION
    Creates all 20 departmental security groups for AQUAPINE CONSULT
    Adds users to appropriate groups based on department/location
    
.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Date: Week 1, Day 5
    Version: 1.0 (Azure CLI)
    
    Prerequisites:
    - Azure CLI installed and logged in (az login)
    - Users already created in Entra ID
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$script:GroupsCreated = 0
$script:GroupsFailed = 0
$script:StartTime = Get-Date

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

#endregion

#region Group Definitions

# AQUAPINE Group Structure (3-Tier Hierarchy)
$groups = @(
    # TIER 1: LOCATION-BASED PARENT GROUPS
    @{
        Name = "AQUAPINE-Lagos-AllUsers"
        Description = "All Lagos HQ employees (21 users). Includes Executive, IT, HR, Sales, Logistics departments."
    },
    @{
        Name = "AQUAPINE-Ibadan-AllUsers"
        Description = "All Ibadan farm employees (24 users). Includes Farm Ops, Microbiology, Feed Production, Hatchery, Security, Store."
    },
    
    # TIER 2: DEPARTMENT-BASED GROUPS (Lagos)
    @{
        Name = "Lagos-Executive-Security"
        Description = "Lagos Executive Management (4 users). CEO, CFO, Operations Director, Business Development Manager. Access: Company-wide visibility (Reader on subscription)."
    },
    @{
        Name = "Lagos-IT-Security"
        Description = "Lagos IT Department (2 users). IT Manager, IT Support Technician. Access: Full infrastructure control (Owner/Contributor on subscription)."
    },
    @{
        Name = "Lagos-HR-Security"
        Description = "Lagos Human Resources (3 users). HR Manager, HR Officer, Payroll Administrator. Access: HR data storage (Storage Blob Data Contributor on hrdata-storage). Sensitivity: HIGH."
    },
    @{
        Name = "Lagos-Sales-Security"
        Description = "Lagos Sales Department (8 users). Sales Manager, Sales Reps, Marketing Officers, Customer Service. Access: CRM database, sales analytics."
    },
    @{
        Name = "Lagos-Logistics-Security"
        Description = "Lagos Logistics Department (4 users). Logistics Manager, Delivery Coordinators. Access: Inventory tracking, delivery schedules."
    },
    
    # TIER 2: DEPARTMENT-BASED GROUPS (Ibadan)
    @{
        Name = "Ibadan-FarmOps-Security"
        Description = "Ibadan Farm Operations (6 users). Farm Manager, Supervisors, Pond Technicians. Access: Farm monitoring data (Reader on farm-monitoring storage)."
    },
    @{
        Name = "Ibadan-MicrobiologyLab-Security"
        Description = "Ibadan Microbiology Lab (4 users). Microbiology Manager, Lab Technicians. Access: Lab research data (Storage Blob Data Contributor on lab-research storage)."
    },
    @{
        Name = "Ibadan-FeedProduction-Security"
        Description = "Ibadan Feed Production (5 users). Feed Production Supervisor, Mill Operators, Quality Control. Access: Production schedules (Reader)."
    },
    @{
        Name = "Ibadan-Hatchery-Security"
        Description = "Ibadan Hatchery Unit (3 users). Hatchery Supervisor, Technicians, Breeding Specialist. Access: Breeding records (Storage Blob Data Contributor)."
    },
    @{
        Name = "Ibadan-FarmSecurity-Security"
        Description = "Ibadan Farm Security (4 users). Chief Security Officers, Security Officers. Access: CCTV footage (Storage Blob Data Reader on security-cctv). 24/7 operations."
    },
    @{
        Name = "Ibadan-Store-Security"
        Description = "Ibadan Store Department (2 users). Store Keeper, Inventory Officer. Access: Inventory management system."
    },
    
    # TIER 3: ROLE-BASED/FUNCTION GROUPS
    @{
        Name = "AQUAPINE-AllManagers"
        Description = "All managers company-wide (10+ users). Cross-departmental leadership group. Access: Management dashboards, company-wide reports."
    },
    @{
        Name = "AQUAPINE-GlobalAdmins"
        Description = "Global Administrators (2 users). IT Manager, IT Support Tech. Full tenant control. Membership: ALWAYS assigned (never dynamic - security critical)."
    },
    @{
        Name = "AQUAPINE-MobileWorkers"
        Description = "Employees requiring mobile access (15+ users). Sales team, Farm Managers, Executives. Access: Mobile-optimized apps, remote connectivity."
    },
    @{
        Name = "AQUAPINE-RemoteAccess"
        Description = "Users authorized for remote work/VPN access. Varies based on operational needs and security policies."
    },
    @{
        Name = "AQUAPINE-FinanceAccess"
        Description = "Finance data access (3 users). CFO, HR Manager (payroll), CEO. Access: Financial reports, budgets. Sensitivity: CRITICAL."
    },
    @{
        Name = "AQUAPINE-AllEmployees"
        Description = "All AQUAPINE employees (45 users). Company-wide group for shared resources. Access: Shared Services resource group (Reader), company policies, announcements."
    },
    @{
        Name = "AQUAPINE-GuestUsers"
        Description = "External collaborators (future use). Consultants, auditors, vendors. Access: Limited, time-bound. Requires explicit approval."
    },
    @{
        Name = "HR-Department-AdminUnit-Members"
        Description = "HR Department for Administrative Unit (3 users). Future use when Premium P1 acquired. Manual assignment only (security-critical)."
    }
)

#endregion

#region Main Script

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - GROUP CREATION             " -ForegroundColor Cyan
Write-Host "  Azure CLI Implementation                     " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Verify Azure CLI login
    Write-Log "Step 1: Verifying Azure login..." -Level Info
    
    $account = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $account) {
        throw "Not logged in to Azure. Run: az login"
    }
    
    Write-Log "Logged in as: $($account.user.name)" -Level Success
    Write-Host ""
    
    # Step 2: Create groups
    Write-Log "Step 2: Creating security groups..." -Level Info
    Write-Host ""
    
    $progressCount = 0
    
    foreach ($group in $groups) {
        $progressCount++
        
        Write-Log "[$progressCount/$($groups.Count)] Creating: $($group.Name)..." -Level Info
        
        try {
            # Check if group already exists
            $existing = az ad group list --filter "displayName eq '$($group.Name)'" --output json 2>$null | ConvertFrom-Json
            
            if ($existing -and $existing.Count -gt 0) {
                Write-Log "  ⚠️  Group already exists: $($group.Name)" -Level Warning
                continue
            }
            
            # Create group
            $result = az ad group create `
                --display-name $group.Name `
                --mail-nickname ($group.Name -replace '[^a-zA-Z0-9]', '') `
                --description $group.Description `
                --output json 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "  ✅ Created: $($group.Name)" -Level Success
                $script:GroupsCreated++
            }
            else {
                throw $result
            }
        }
        catch {
            Write-Log "  ❌ Failed: $($group.Name)" -Level Error
            Write-Log "     Error: $_" -Level Error
            $script:GroupsFailed++
        }
        
        Start-Sleep -Milliseconds 300
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    # Step 3: Summary
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  GROUP CREATION SUMMARY                        " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $endTime = Get-Date
    $duration = $endTime - $script:StartTime
    
    Write-Host "Execution Time: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
    Write-Host ""
    Write-Host "Total Groups: $($groups.Count)" -ForegroundColor White
    Write-Host "Successfully Created: $script:GroupsCreated" -ForegroundColor Green
    Write-Host "Failed: $script:GroupsFailed" -ForegroundColor $(if ($script:GroupsFailed -eq 0) { "Green" } else { "Red" })
    Write-Host ""
    
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS                                    " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Add users to groups:" -ForegroundColor White
    Write-Host "   Run: .\add-users-to-groups-AZCLI.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Assign RBAC roles to groups:" -ForegroundColor White
    Write-Host "   Run: .\assign-rbac-roles.ps1 (uses Azure PowerShell - works!)" -ForegroundColor Gray
    Write-Host ""
    
    if ($script:GroupsFailed -eq 0) {
        Write-Host "🎉 All groups created successfully!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "⚠️  Some groups failed - review errors above" -ForegroundColor Yellow
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