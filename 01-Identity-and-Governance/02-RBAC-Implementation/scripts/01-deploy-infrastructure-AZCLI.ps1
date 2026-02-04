<#
.SYNOPSIS
    Deploy AQUAPINE Infrastructure using Azure CLI (Alternative to PowerShell)
    
.DESCRIPTION
    Creates storage accounts using Azure CLI instead of Azure PowerShell
    to work around the subscription detection issue
    
.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    
    Why: Azure PowerShell is having subscription issues with storage accounts.
    Solution: Use Azure CLI (az) which has better subscription handling.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Location = "westeurope"
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

function Invoke-Az {
    param([string[]]$CmdArgs)
    $out = az @CmdArgs 2>&1
    return @{
        ExitCode = $LASTEXITCODE
        Output   = ($out -join "`n")
    }
}

#endregion

#region Main Script

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - INFRASTRUCTURE DEPLOYMENT  " -ForegroundColor Cyan
Write-Host "  Azure CLI Implementation                     " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Check Azure CLI
    Write-Log "Step 1: Checking Azure CLI..." -Level Info
    
    $azVersion = az version --output json 2>$null | ConvertFrom-Json
    if (-not $azVersion) {
        throw "Azure CLI not installed. Download from: https://aka.ms/installazurecliwindows"
    }
    
    Write-Log "✅ Azure CLI version: $($azVersion.'azure-cli')" -Level Success
    
    # Check login
    $account = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Log "Not logged in. Opening browser..." -Level Warning
        az login
        $account = az account show --output json 2>$null | ConvertFrom-Json
    }
    
    Write-Log "✅ Logged in as: $($account.user.name)" -Level Success
    Write-Log "   Subscription: $($account.name)" -Level Info
    Write-Log "   Subscription ID: $($account.id)" -Level Info
    Write-Host ""
    
    # Step 2: Create Storage Accounts (Resource Groups already exist)
    Write-Log "Step 2: Creating Storage Accounts..." -Level Info
    Write-Host ""
    
    # Generate unique suffix
    $suffix = Get-Random -Minimum 1000 -Maximum 9999
    
    $storageAccounts = @(
        @{
            Name = "hrdatastorage$suffix"
            ResourceGroup = "Lagos-HQ-RG"
            Description = "HR employee data and documents"
            Tags = "Purpose='HR Data Storage' Department=HR DataClassification=Confidential"
        },
        @{
            Name = "farmmonitoring$suffix"
            ResourceGroup = "Ibadan-Farms-RG"
            Description = "Farm monitoring and sensor data"
            Tags = "Purpose='Farm Monitoring' Department=Operations DataClassification=Internal"
        },
        @{
            Name = "securitycctv$suffix"
            ResourceGroup = "Ibadan-Farms-RG"
            Description = "Security camera footage and logs"
            Tags = "Purpose='Security CCTV' Department=Security DataClassification=Confidential"
        }
    )
    
    $script:CreatedStorageAccounts = @()
    
    foreach ($sa in $storageAccounts) {
        Write-Log "Creating: $($sa.Name)..." -Level Info
        Write-Log "  Resource Group: $($sa.ResourceGroup)" -Level Info
        Write-Log "  Description: $($sa.Description)" -Level Info
        
        try {
            # Check if exists
            $checkResult = Invoke-Az @(
                "storage", "account", "show",
                "--name", $sa.Name,
                "--resource-group", $sa.ResourceGroup,
                "--output", "json"
            )
            
            if ($checkResult.ExitCode -eq 0) {
                Write-Log "  ℹ️  Storage account already exists" -Level Warning
                $existing = $checkResult.Output | ConvertFrom-Json
                $script:CreatedStorageAccounts += $existing
            }
            else {
                # Create storage account
                Write-Log "  → Creating (this may take 30-60 seconds)..." -Level Info
                
                $createResult = Invoke-Az @(
                    "storage", "account", "create",
                    "--name", $sa.Name,
                    "--resource-group", $sa.ResourceGroup,
                    "--location", $Location,
                    "--sku", "Standard_LRS",
                    "--kind", "StorageV2",
                    "--access-tier", "Hot",
                    "--allow-blob-public-access", "false",
                    "--min-tls-version", "TLS1_2",
                    "--tags", $sa.Tags,
                    "--output", "json"
                )
                
                if ($createResult.ExitCode -eq 0) {
                    Write-Log "  ✅ Created successfully!" -Level Success
                    $created = $createResult.Output | ConvertFrom-Json
                    $script:CreatedStorageAccounts += $created
                    $script:ResourcesCreated++
                }
                else {
                    throw "Creation failed: $($createResult.Output)"
                }
            }
        }
        catch {
            Write-Log "  ❌ Failed: $_" -Level Error
            $script:ResourcesFailed++
        }
        
        Write-Host ""
    }
    
    # Step 3: Create containers
    Write-Log "Step 3: Creating blob containers..." -Level Info
    Write-Host ""
    
    foreach ($sa in $script:CreatedStorageAccounts) {
        $saName = $sa.name
        Write-Log "Setting up containers in: $saName..." -Level Info
        
        try {
            # Determine containers based on purpose
            $containers = @()
            if ($saName -like "hrdatastorage*") {
                $containers = @("employee-records", "payroll", "benefits")
            }
            elseif ($saName -like "farmmonitoring*") {
                $containers = @("sensor-data", "water-quality", "fish-health")
            }
            elseif ($saName -like "securitycctv*") {
                $containers = @("gate-cameras", "pond-surveillance", "archive")
            }
            
            foreach ($containerName in $containers) {
                $createContainer = Invoke-Az @(
                    "storage", "container", "create",
                    "--name", $containerName,
                    "--account-name", $saName,
                    "--public-access", "off",
                    "--output", "none"
                )
                
                if ($createContainer.ExitCode -eq 0) {
                    Write-Log "  ✅ Created container: $containerName" -Level Success
                }
                else {
                    Write-Log "  ℹ️  Container exists or created: $containerName" -Level Info
                }
            }
        }
        catch {
            Write-Log "  ⚠️  Container creation warning: $_" -Level Warning
        }
        
        Write-Host ""
    }
    
    # Step 4: Verification
    Write-Log "Step 4: Verifying infrastructure..." -Level Info
    Write-Host ""
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  RESOURCE GROUPS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    $rgList = az group list --query "[?name=='Lagos-HQ-RG' || name=='Ibadan-Farms-RG' || name=='Shared-Services-RG'].[name,location,properties.provisioningState]" --output table
    Write-Host $rgList
    Write-Host ""
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  STORAGE ACCOUNTS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    $saList = az storage account list --query "[?contains(name, 'hrdatastorage') || contains(name, 'farmmonitoring') || contains(name, 'securitycctv')].[name,resourceGroup,location]" --output table
    Write-Host $saList
    Write-Host ""
    
    # Save config
    if ($script:CreatedStorageAccounts.Count -gt 0) {
        $configPath = Join-Path $PSScriptRoot "storage-config.json"
        $config = @{
            HRStorage = ($script:CreatedStorageAccounts | Where-Object { $_.name -like "hrdatastorage*" }).name
            FarmStorage = ($script:CreatedStorageAccounts | Where-Object { $_.name -like "farmmonitoring*" }).name
            CCTVStorage = ($script:CreatedStorageAccounts | Where-Object { $_.name -like "securitycctv*" }).name
        }
        $config | ConvertTo-Json | Out-File $configPath -Encoding UTF8
        Write-Log "✅ Storage account names saved to: $configPath" -Level Success
        Write-Host ""
    }
    
    # Summary
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  DEPLOYMENT SUMMARY" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Resources Created: $script:ResourcesCreated" -ForegroundColor Green
    Write-Host "Resources Failed: $script:ResourcesFailed" -ForegroundColor $(if ($script:ResourcesFailed -eq 0) { "Green" } else { "Red" })
    Write-Host ""
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Assign RBAC roles to groups" -ForegroundColor White
    Write-Host "     Run: .\03-assign-rbac-roles-FIXED.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Verify in Azure Portal" -ForegroundColor White
    Write-Host "     Portal → Storage Accounts → Check all 3 accounts exist" -ForegroundColor Gray
    Write-Host ""
    
    if ($script:ResourcesFailed -eq 0) {
        Write-Host "🎉 Infrastructure deployment completed successfully!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "⚠️  Some resources failed - review errors above" -ForegroundColor Yellow
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
    Write-Host "1. Install Azure CLI: https://aka.ms/installazurecliwindows" -ForegroundColor Gray
    Write-Host "2. Login: az login" -ForegroundColor Gray
    Write-Host "3. Check subscription: az account show" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

#endregion