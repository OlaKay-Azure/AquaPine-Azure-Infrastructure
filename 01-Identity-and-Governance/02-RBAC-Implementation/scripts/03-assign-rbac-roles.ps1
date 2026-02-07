<#
.SYNOPSIS
    Assign RBAC roles to AQUAPINE security groups
    
.DESCRIPTION
    Assigns Azure RBAC roles to departmental groups for resource access control
    Uses Azure PowerShell (Connect-AzAccount) which WORKS with personal accounts!
    
.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Date: Week 1, Day 5
    
    IMPORTANT: This uses Azure PowerShell (Az module), NOT Microsoft Graph
    Azure RBAC authentication works with personal Microsoft accounts!
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$script:RoleAssignmentsCreated = 0
$script:RoleAssignmentsFailed = 0

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

#region Main Script

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - RBAC ASSIGNMENTS            " -ForegroundColor Cyan
Write-Host "  Azure PowerShell Implementation               " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Connect to Azure (Azure PowerShell - NOT Microsoft Graph!)
    Write-Log "Step 1: Connecting to Azure..." -Level Info
    
    $context = Get-AzContext
    if (-not $context) {
        Write-Log "Not connected. Opening browser for authentication..." -Level Warning
        Connect-AzAccount
        $context = Get-AzContext
    }
    
    Write-Log "Connected as: $($context.Account.Id)" -Level Success
    Write-Log "Subscription: $($context.Subscription.Name)" -Level Info
    Write-Host ""
    
    # Step 2: Get Resource Groups and Storage Accounts
    Write-Log "Step 2: Getting Azure resources..." -Level Info
    
    # Get Resource Groups
    $lagosRG = Get-AzResourceGroup -Name "Lagos-HQ-RG" -ErrorAction SilentlyContinue
    $ibadanRG = Get-AzResourceGroup -Name "Ibadan-Farms-RG" -ErrorAction SilentlyContinue
    $sharedRG = Get-AzResourceGroup -Name "Shared-Services-RG" -ErrorAction SilentlyContinue
    
    if (-not $lagosRG -or -not $ibadanRG -or -not $sharedRG) {
        Write-Log "⚠️  Some resource groups not found. Create them first!" -Level Warning
        Write-Log "   Run: .\01-deploy-infrastructure.ps1" -Level Warning
        throw "Missing resource groups"
    }
    
    Write-Log "✅ Found resource groups" -Level Success
    
    # Get Storage Accounts
    $hrStorage = Get-AzStorageAccount -ResourceGroupName "Lagos-HQ-RG" -Name "hrdatastorage" -ErrorAction SilentlyContinue
    $farmStorage = Get-AzStorageAccount -ResourceGroupName "Ibadan-Farms-RG" -Name "farmmonitoring" -ErrorAction SilentlyContinue
    $cctvStorage = Get-AzStorageAccount -ResourceGroupName "Ibadan-Farms-RG" -Name "securitycctv" -ErrorAction SilentlyContinue
    
    if (-not $hrStorage -or -not $farmStorage -or -not $cctvStorage) {
        Write-Log "⚠️  Some storage accounts not found. Create them first!" -Level Warning
        throw "Missing storage accounts"
    }
    
    Write-Log "✅ Found storage accounts" -Level Success
    Write-Host ""
    
    # Step 3: Define RBAC Assignments
    Write-Log "Step 3: Assigning RBAC roles..." -Level Info
    Write-Host ""
    
    $assignments = @(
        # HR Department - Full access to HR storage
        @{
            GroupName = "Lagos-HR-Security"
            Role = "Storage Blob Data Contributor"
            Scope = $hrStorage.Id
            Description = "HR team can manage HR files (read/write/delete)"
        },
        
        # Farm Operations - Read-only access to farm monitoring
        @{
            GroupName = "Ibadan-FarmOps-Security"
            Role = "Storage Blob Data Reader"
            Scope = $farmStorage.Id
            Description = "Farm workers can view monitoring data (read-only)"
        },
        
        # Security Department - Read-only access to CCTV
        @{
            GroupName = "Ibadan-FarmSecurity-Security"
            Role = "Storage Blob Data Reader"
            Scope = $cctvStorage.Id
            Description = "Security officers can view CCTV footage (read-only)"
        },
        
        # IT Department - Full control (Owner)
        @{
            GroupName = "Lagos-IT-Security"
            Role = "Owner"
            Scope = "/subscriptions/$($context.Subscription.Id)"
            Description = "IT team has full infrastructure control"
        },
        
        # Executive - Read access to subscription
        @{
            GroupName = "Lagos-Executive-Security"
            Role = "Reader"
            Scope = "/subscriptions/$($context.Subscription.Id)"
            Description = "Executives can view all resources (strategic oversight)"
        },
        
        # All Employees - Read access to Shared Services
        @{
            GroupName = "AQUAPINE-AllEmployees"
            Role = "Reader"
            Scope = $sharedRG.ResourceId
            Description = "All employees can view company-wide resources"
        }
    )
    
    # Process assignments
    $progressCount = 0
    
    foreach ($assignment in $assignments) {
        $progressCount++
        
        Write-Log "[$progressCount/$($assignments.Count)] $($assignment.GroupName) → $($assignment.Role)" -Level Info
        Write-Log "  Scope: $($assignment.Scope)" -Level Info
        Write-Log "  Purpose: $($assignment.Description)" -Level Info
        
        try {
            # Get group from Entra ID
            $group = Get-AzADGroup -DisplayName $assignment.GroupName
            
            if (-not $group) {
                Write-Log "  ❌ Group not found: $($assignment.GroupName)" -Level Error
                $script:RoleAssignmentsFailed++
                continue
            }
            
            # Check if assignment already exists
            $existing = Get-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName $assignment.Role -Scope $assignment.Scope -ErrorAction SilentlyContinue
            
            if ($existing) {
                Write-Log "  ℹ️  Assignment already exists" -Level Warning
                continue
            }
            
            # Create role assignment
            New-AzRoleAssignment `
                -ObjectId $group.Id `
                -RoleDefinitionName $assignment.Role `
                -Scope $assignment.Scope `
                -ErrorAction Stop | Out-Null
            
            Write-Log "  ✅ Assignment created successfully" -Level Success
            $script:RoleAssignmentsCreated++
        }
        catch {
            Write-Log "  ❌ Assignment failed: $_" -Level Error
            $script:RoleAssignmentsFailed++
        }
        
        Write-Host ""
    }
    
    # Step 4: Validation
    Write-Log "Step 4: Validating assignments..." -Level Info
    Write-Host ""
    
    Write-Host "RBAC Assignments by Resource:" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    # Show HR Storage assignments
    Write-Host "`nHR Data Storage (hrdatastorage):" -ForegroundColor Cyan
    Get-AzRoleAssignment -Scope $hrStorage.Id | 
        Where-Object { $_.ObjectType -eq "Group" } |
        Select-Object DisplayName, RoleDefinitionName |
        Format-Table -AutoSize
    
    # Show Farm Monitoring assignments
    Write-Host "Farm Monitoring Storage (farmmonitoring):" -ForegroundColor Cyan
    Get-AzRoleAssignment -Scope $farmStorage.Id | 
        Where-Object { $_.ObjectType -eq "Group" } |
        Select-Object DisplayName, RoleDefinitionName |
        Format-Table -AutoSize
    
    # Show CCTV assignments
    Write-Host "CCTV Security Storage (securitycctv):" -ForegroundColor Cyan
    Get-AzRoleAssignment -Scope $cctvStorage.Id | 
        Where-Object { $_.ObjectType -eq "Group" } |
        Select-Object DisplayName, RoleDefinitionName |
        Format-Table -AutoSize
    
    # Summary
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  RBAC ASSIGNMENT SUMMARY                       " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Assignments: $($assignments.Count)" -ForegroundColor White
    Write-Host "Successfully Created: $script:RoleAssignmentsCreated" -ForegroundColor Green
    Write-Host "Failed: $script:RoleAssignmentsFailed" -ForegroundColor $(if ($script:RoleAssignmentsFailed -eq 0) { "Green" } else { "Red" })
    Write-Host ""
    
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS                                    " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Test access as different users" -ForegroundColor White
    Write-Host "2. ✓ Take screenshots for portfolio" -ForegroundColor White
    Write-Host "3. ✓ Document architecture in README.md" -ForegroundColor White
    Write-Host ""
    
    if ($script:RoleAssignmentsFailed -eq 0) {
        Write-Host "🎉 All RBAC assignments completed successfully!" -ForegroundColor Green
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