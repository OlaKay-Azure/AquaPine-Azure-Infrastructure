<#
.SYNOPSIS
    Deploy AQUAPINE Azure Infrastructure Foundation
    
.DESCRIPTION
    Creates resource groups and storage accounts needed for RBAC testing
    Uses Azure PowerShell (Az module)
    
.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    
    This creates:
    - 3 Resource Groups (Lagos HQ, Ibadan Farms, Shared Services)
    - 3 Storage Accounts (HR Data, Farm Monitoring, Security CCTV)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Location = "West Europe"
)

$ErrorActionPreference = "Continue"
$script:ResourcesCreated = 0
$script:ResourcesFailed = 0

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
Write-Host "  AQUAPINE CONSULT - INFRASTRUCTURE DEPLOYMENT  " -ForegroundColor Cyan
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
    Write-Log "Location: $Location" -Level Info
    Write-Host ""
    
    # Step 2: Create Resource Groups
    Write-Log "Step 2: Creating Resource Groups..." -Level Info
    Write-Host ""
    
    $resourceGroups = @(
        @{
            Name = "Lagos-HQ-RG"
            Description = "Headquarters operations in Lagos"
            Tags = @{
                Department = "Corporate"
                Location = "Lagos"
                Environment = "Production"
                CostCenter = "CC-HQ-001"
            }
        },
        @{
            Name = "Ibadan-Farms-RG"
            Description = "Fish farm operations in Ibadan"
            Tags = @{
                Department = "Operations"
                Location = "Ibadan"
                Environment = "Production"
                CostCenter = "CC-FARM-001"
            }
        },
        @{
            Name = "Shared-Services-RG"
            Description = "Shared company-wide services"
            Tags = @{
                Department = "IT"
                Location = "Shared"
                Environment = "Production"
                CostCenter = "CC-IT-001"
            }
        }
    )
    
    foreach ($rg in $resourceGroups) {
        Write-Log "Creating: $($rg.Name)..." -Level Info
        
        try {
            $existing = Get-AzResourceGroup -Name $rg.Name -ErrorAction SilentlyContinue
            
            if ($existing) {
                Write-Log "  ℹ️  Resource group already exists" -Level Warning
            }
            else {
                New-AzResourceGroup `
                    -Name $rg.Name `
                    -Location $Location `
                    -Tag $rg.Tags `
                    -ErrorAction Stop | Out-Null
                
                Write-Log "  ✅ Created successfully" -Level Success
                $script:ResourcesCreated++
            }
        }
        catch {
            Write-Log "  ❌ Failed: $_" -Level Error
            $script:ResourcesFailed++
        }
    }
    
    Write-Host ""
    
    # Step 3: Create Storage Accounts
    Write-Log "Step 3: Creating Storage Accounts..." -Level Info
    Write-Host ""
    
    # Generate unique suffix for storage account names
    $suffix = Get-Random -Minimum 1000 -Maximum 9999
    
    $storageAccounts = @(
        @{
            Name = "hrdatastorage$suffix"
            ResourceGroup = "Lagos-HQ-RG"
            Description = "HR employee data and documents"
            Tags = @{
                Purpose = "HR Data Storage"
                Department = "HR"
                DataClassification = "Confidential"
            }
        },
        @{
            Name = "farmmonitoring$suffix"
            ResourceGroup = "Ibadan-Farms-RG"
            Description = "Farm monitoring and sensor data"
            Tags = @{
                Purpose = "Farm Monitoring"
                Department = "Operations"
                DataClassification = "Internal"
            }
        },
        @{
            Name = "securitycctv$suffix"
            ResourceGroup = "Ibadan-Farms-RG"
            Description = "Security camera footage and logs"
            Tags = @{
                Purpose = "Security CCTV"
                Department = "Security"
                DataClassification = "Confidential"
            }
        }
    )
    
    $script:CreatedStorageAccounts = @()
    
    foreach ($sa in $storageAccounts) {
        Write-Log "Creating: $($sa.Name)..." -Level Info
        Write-Log "  Resource Group: $($sa.ResourceGroup)" -Level Info
        
        try {
            $existing = Get-AzStorageAccount `
                -ResourceGroupName $sa.ResourceGroup `
                -Name $sa.Name `
                -ErrorAction SilentlyContinue
            
            if ($existing) {
                Write-Log "  ℹ️  Storage account already exists" -Level Warning
                $script:CreatedStorageAccounts += $existing
            }
            else {
                $newStorage = New-AzStorageAccount `
                    -ResourceGroupName $sa.ResourceGroup `
                    -Name $sa.Name `
                    -Location $Location `
                    -SkuName Standard_LRS `
                    -Kind StorageV2 `
                    -AccessTier Hot `
                    -Tag $sa.Tags `
                    -ErrorAction Stop
                
                Write-Log "  ✅ Created successfully" -Level Success
                $script:ResourcesCreated++
                $script:CreatedStorageAccounts += $newStorage
            }
        }
        catch {
            Write-Log "  ❌ Failed: $_" -Level Error
            $script:ResourcesFailed++
        }
    }
    
    Write-Host ""
    
    # Step 4: Create sample containers in storage accounts
    Write-Log "Step 4: Creating sample containers..." -Level Info
    Write-Host ""
    
    foreach ($sa in $script:CreatedStorageAccounts) {
        Write-Log "Setting up containers in: $($sa.StorageAccountName)..." -Level Info
        
        try {
            $ctx = $sa.Context
            
            # Determine containers based on storage account purpose
            $containers = @()
            if ($sa.StorageAccountName -like "hrdatastorage*") {
                $containers = @("employee-records", "payroll", "benefits")
            }
            elseif ($sa.StorageAccountName -like "farmmonitoring*") {
                $containers = @("sensor-data", "water-quality", "fish-health")
            }
            elseif ($sa.StorageAccountName -like "securitycctv*") {
                $containers = @("gate-cameras", "pond-surveillance", "archive")
            }
            
            foreach ($containerName in $containers) {
                $existing = Get-AzStorageContainer -Name $containerName -Context $ctx -ErrorAction SilentlyContinue
                
                if (-not $existing) {
                    New-AzStorageContainer -Name $containerName -Context $ctx -Permission Off | Out-Null
                    Write-Log "  ✅ Created container: $containerName" -Level Success
                }
            }
        }
        catch {
            Write-Log "  ⚠️  Container creation warning: $_" -Level Warning
        }
    }
    
    Write-Host ""
    
    # Step 5: Verification
    Write-Log "Step 5: Verifying infrastructure..." -Level Info
    Write-Host ""
    
    Write-Host "Resource Groups:" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*HQ-RG" -or $_.ResourceGroupName -like "*Farms-RG" -or $_.ResourceGroupName -like "*Services-RG" } |
        Select-Object ResourceGroupName, Location, @{Name='Tags';Expression={($_.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; '}} |
        Format-Table -AutoSize
    
    Write-Host "Storage Accounts:" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Get-AzStorageAccount | Where-Object { $_.StorageAccountName -like "hrdatastorage*" -or $_.StorageAccountName -like "farmmonitoring*" -or $_.StorageAccountName -like "securitycctv*" } |
        Select-Object StorageAccountName, ResourceGroupName, Location, @{Name='Purpose';Expression={$_.Tags['Purpose']}} |
        Format-Table -AutoSize
    
    # Summary
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  DEPLOYMENT SUMMARY                            " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Resources Created: $script:ResourcesCreated" -ForegroundColor Green
    Write-Host "Resources Failed: $script:ResourcesFailed" -ForegroundColor $(if ($script:ResourcesFailed -eq 0) { "Green" } else { "Red" })
    Write-Host ""
    
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS                                    " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Create security groups (if not done)" -ForegroundColor White
    Write-Host "     Run: .\02-create-groups-AZCLI.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Assign RBAC roles to groups" -ForegroundColor White
    Write-Host "     Run: .\03-assign-rbac-roles.ps1" -ForegroundColor Gray
    Write-Host ""
    
    if ($script:ResourcesFailed -eq 0) {
        Write-Host "🎉 Infrastructure deployment completed successfully!" -ForegroundColor Green
        
        # Save storage account names for RBAC script
        $configPath = Join-Path $PSScriptRoot "storage-config.json"
        $config = @{
            HRStorage = ($script:CreatedStorageAccounts | Where-Object { $_.StorageAccountName -like "hrdatastorage*" }).StorageAccountName
            FarmStorage = ($script:CreatedStorageAccounts | Where-Object { $_.StorageAccountName -like "farmmonitoring*" }).StorageAccountName
            CCTVStorage = ($script:CreatedStorageAccounts | Where-Object { $_.StorageAccountName -like "securitycctv*" }).StorageAccountName
        }
        $config | ConvertTo-Json | Out-File $configPath -Encoding UTF8
        Write-Log "Storage account names saved to: $configPath" -Level Info
        
        exit 0
    }
    else {
        Write-Host "⚠️  Some resources failed - review errors above" -ForegroundColor Yellow
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
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure you're connected: Connect-AzAccount" -ForegroundColor Gray
    Write-Host "2. Check subscription: Get-AzContext" -ForegroundColor Gray
    Write-Host "3. Verify permissions: Owner or Contributor role needed" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

#endregion