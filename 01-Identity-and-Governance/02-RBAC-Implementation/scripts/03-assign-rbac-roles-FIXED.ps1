<#
.SYNOPSIS
    Assign RBAC roles to AQUAPINE security groups (UPDATED)
    
.DESCRIPTION
    Assigns Azure RBAC roles to departmental groups for resource access control
    Uses Azure PowerShell (Connect-AzAccount) which WORKS with personal accounts!
    
    Updates:
    - Reads storage account names from config file
    - Better error handling for missing resources
    
.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    
    IMPORTANT: Run .\01-deploy-infrastructure.ps1 FIRST to create resources!
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
    # Step 1: Connect to Azure
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
    
    # Step 2: Get Resource Groups
    Write-Log "Step 2: Validating Azure resources..." -Level Info
    
    # Get Resource Groups
    $lagosRG = Get-AzResourceGroup -Name "Lagos-HQ-RG" -ErrorAction SilentlyContinue
    $ibadanRG = Get-AzResourceGroup -Name "Ibadan-Farms-RG" -ErrorAction SilentlyContinue
    $sharedRG = Get-AzResourceGroup -Name "Shared-Services-RG" -ErrorAction SilentlyContinue
    
    if (-not $lagosRG -or -not $ibadanRG -or -not $sharedRG) {
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host "  ❌ MISSING RESOURCE GROUPS" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host ""
        Write-Log "Required resource groups not found!" -Level Error
        Write-Host ""
        Write-Host "Please run the infrastructure deployment script first:" -ForegroundColor Yellow
        Write-Host "  .\01-deploy-infrastructure.ps1" -ForegroundColor Cyan
        Write-Host ""
        throw "Missing resource groups"
    }
    
    Write-Log "✅ Found all resource groups" -Level Success
    
    # Try to load storage account config
    $configPath = Join-Path $PSScriptRoot "storage-config.json"
    $storageConfig = $null
    
    if (Test-Path $configPath) {
        $storageConfig = Get-Content $configPath | ConvertFrom-Json
        Write-Log "✅ Loaded storage account configuration" -Level Success
    }
    else {
        Write-Log "⚠️  storage-config.json not found - will search for storage accounts" -Level Warning
    }
    
    # Get Storage Accounts
    if ($storageConfig) {
        $hrStorage = Get-AzStorageAccount -ResourceGroupName "Lagos-HQ-RG" -Name $storageConfig.HRStorage -ErrorAction SilentlyContinue
        $farmStorage = Get-AzStorageAccount -ResourceGroupName "Ibadan-Farms-RG" -Name $storageConfig.FarmStorage -ErrorAction SilentlyContinue
        $cctvStorage = Get-AzStorageAccount -ResourceGroupName "Ibadan-Farms-RG" -Name $storageConfig.CCTVStorage -ErrorAction SilentlyContinue
    }
    else {
        # Search for storage accounts by pattern
        $allStorage = Get-AzStorageAccount
        $hrStorage = $allStorage | Where-Object { $_.StorageAccountName -like "hrdatastorage*" -and $_.ResourceGroupName -eq "Lagos-HQ-RG" } | Select-Object -First 1
        $farmStorage = $allStorage | Where-Object { $_.StorageAccountName -like "farmmonitoring*" -and $_.ResourceGroupName -eq "Ibadan-Farms-RG" } | Select-Object -First 1
        $cctvStorage = $allStorage | Where-Object { $_.StorageAccountName -like "securitycctv*" -and $_.ResourceGroupName -eq "Ibadan-Farms-RG" } | Select-Object -First 1
    }
    
    if (-not $hrStorage -or -not $farmStorage -or -not $cctvStorage) {
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host "  ❌ MISSING STORAGE ACCOUNTS" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host ""
        Write-Log "Required storage accounts not found!" -Level Error
        Write-Host ""
        Write-Host "Please run the infrastructure deployment script first:" -ForegroundColor Yellow
        Write-Host "  .\01-deploy-infrastructure.ps1" -ForegroundColor Cyan
        Write-Host ""
        throw "Missing storage accounts"
    }
    
    Write-Log "✅ Found all storage accounts" -Level Success
    Write-Log "   HR Storage: $($hrStorage.StorageAccountName)" -Level Info
    Write-Log "   Farm Storage: $($farmStorage.StorageAccountName)" -Level Info
    Write-Log "   CCTV Storage: $($cctvStorage.StorageAccountName)" -Level Info
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
        
        # IT Department - Contributor on subscription
        @{
            GroupName = "Lagos-IT-Security"
            Role = "Contributor"
            Scope = "/subscriptions/$($context.Subscription.Id)"
            Description = "IT team can manage resources (not users/roles)"
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
        
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        Write-Log "[$progressCount/$($assignments.Count)] $($assignment.GroupName) → $($assignment.Role)" -Level Info
        Write-Log "  Scope: $(if ($assignment.Scope -like '*/subscriptions/*') { 'Subscription' } elseif ($assignment.Scope -like '*/resourceGroups/*' -and $assignment.Scope -notlike '*/providers/*') { 'Resource Group' } else { 'Storage Account' })" -Level Info
        Write-Log "  Purpose: $($assignment.Description)" -Level Info
        
        try {
            # Get group from Entra ID
            $group = Get-AzADGroup -DisplayName $assignment.GroupName -ErrorAction SilentlyContinue
            
            if (-not $group) {
                Write-Log "  ❌ Group not found: $($assignment.GroupName)" -Level Error
                Write-Log "     Make sure to create groups first!" -Level Warning
                $script:RoleAssignmentsFailed++
                Write-Host ""
                continue
            }
            
            Write-Log "  ✓ Found group: $($group.DisplayName)" -Level Info
            
            # Check if assignment already exists
            $existing = Get-AzRoleAssignment `
                -ObjectId $group.Id `
                -RoleDefinitionName $assignment.Role `
                -Scope $assignment.Scope `
                -ErrorAction SilentlyContinue
            
            if ($existing) {
                Write-Log "  ℹ️  Role assignment already exists - skipping" -Level Warning
                Write-Host ""
                continue
            }
            
            # Create role assignment
            Write-Log "  → Creating role assignment..." -Level Info
            
            New-AzRoleAssignment `
                -ObjectId $group.Id `
                -RoleDefinitionName $assignment.Role `
                -Scope $assignment.Scope `
                -ErrorAction Stop | Out-Null
            
            Write-Log "  ✅ Assignment created successfully!" -Level Success
            $script:RoleAssignmentsCreated++
        }
        catch {
            Write-Log "  ❌ Assignment failed: $($_.Exception.Message)" -Level Error
            $script:RoleAssignmentsFailed++
        }
        
        Write-Host ""
    }
    
    # Step 4: Validation
    Write-Log "Step 4: Validating assignments..." -Level Info
    Write-Host ""
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  RBAC ASSIGNMENTS BY RESOURCE" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    # Show HR Storage assignments
    Write-Host "HR Data Storage ($($hrStorage.StorageAccountName)):" -ForegroundColor Yellow
    $hrAssignments = Get-AzRoleAssignment -Scope $hrStorage.Id | 
        Where-Object { $_.ObjectType -eq "Group" } |
        Select-Object DisplayName, RoleDefinitionName
    
    if ($hrAssignments) {
        $hrAssignments | Format-Table -AutoSize
    } else {
        Write-Host "  (No group assignments)" -ForegroundColor Gray
    }
    
    # Show Farm Monitoring assignments
    Write-Host "Farm Monitoring Storage ($($farmStorage.StorageAccountName)):" -ForegroundColor Yellow
    $farmAssignments = Get-AzRoleAssignment -Scope $farmStorage.Id | 
        Where-Object { $_.ObjectType -eq "Group" } |
        Select-Object DisplayName, RoleDefinitionName
    
    if ($farmAssignments) {
        $farmAssignments | Format-Table -AutoSize
    } else {
        Write-Host "  (No group assignments)" -ForegroundColor Gray
    }
    
    # Show CCTV assignments
    Write-Host "CCTV Security Storage ($($cctvStorage.StorageAccountName)):" -ForegroundColor Yellow
    $cctvAssignments = Get-AzRoleAssignment -Scope $cctvStorage.Id | 
        Where-Object { $_.ObjectType -eq "Group" } |
        Select-Object DisplayName, RoleDefinitionName
    
    if ($cctvAssignments) {
        $cctvAssignments | Format-Table -AutoSize
    } else {
        Write-Host "  (No group assignments)" -ForegroundColor Gray
    }
    
    # Show Subscription-level assignments
    Write-Host "Subscription-Level Assignments:" -ForegroundColor Yellow
    $subAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($context.Subscription.Id)" | 
        Where-Object { $_.ObjectType -eq "Group" -and $_.DisplayName -like "*AQUAPINE*" } |
        Select-Object DisplayName, RoleDefinitionName
    
    if ($subAssignments) {
        $subAssignments | Format-Table -AutoSize
    } else {
        Write-Host "  (No AQUAPINE group assignments)" -ForegroundColor Gray
    }
    
    # Summary
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  RBAC ASSIGNMENT SUMMARY" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Assignments Attempted: $($assignments.Count)" -ForegroundColor White
    Write-Host "Successfully Created: $script:RoleAssignmentsCreated" -ForegroundColor Green
    Write-Host "Failed: $script:RoleAssignmentsFailed" -ForegroundColor $(if ($script:RoleAssignmentsFailed -eq 0) { "Green" } else { "Red" })
    Write-Host ""
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Test access as different users:" -ForegroundColor White
    Write-Host "     - Sign in as HR user → try accessing HR storage" -ForegroundColor Gray
    Write-Host "     - Sign in as Farm worker → try accessing farm storage" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Verify in Azure Portal:" -ForegroundColor White
    Write-Host "     Portal → Storage Account → Access Control (IAM)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. ✓ Document for portfolio:" -ForegroundColor White
    Write-Host "     - Take screenshots of RBAC assignments" -ForegroundColor Gray
    Write-Host "     - Document the permission structure" -ForegroundColor Gray
    Write-Host ""
    
    if ($script:RoleAssignmentsFailed -eq 0) {
        Write-Host "🎉 All RBAC assignments completed successfully!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "⚠️  Some assignments failed - review errors above" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Common issues:" -ForegroundColor Yellow
        Write-Host "  • Groups don't exist → Run group creation script first" -ForegroundColor Gray
        Write-Host "  • Insufficient permissions → Need Owner or User Access Admin role" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "  SCRIPT EXECUTION FAILED" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    Write-Log "Fatal error: $($_.Exception.Message)" -Level Error
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Connect to Azure: Connect-AzAccount" -ForegroundColor Gray
    Write-Host "  2. Check context: Get-AzContext" -ForegroundColor Gray
    Write-Host "  3. Deploy infrastructure: .\01-deploy-infrastructure.ps1" -ForegroundColor Gray
    Write-Host "  4. Create groups: .\02-create-groups-AZCLI.ps1" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

#endregion