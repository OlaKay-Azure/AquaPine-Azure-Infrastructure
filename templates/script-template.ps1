<#
.SYNOPSIS
    [Brief one-line description]

.DESCRIPTION
    [Detailed description of what this script does]
    
    Business Context (AQUAPINE CONSULT):
    [How this script addresses operational needs]

.PARAMETER [ParameterName]
    [Parameter description]

.EXAMPLE
    .\[script-name].ps1 -ResourceGroupName "aquapine-prod-rg-001"
    
.NOTES
    Author: Olatunde Ogunti
    Organization: Aquapine Consult
    Date: [Date]
    AZ-104 Domain: [Domain Number]
    
.LINK
    GitHub: https://github.com/[YourUsername]/AquaPine-Azure-Infrastructure
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "westeurope",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.Resources

# ============================================================================
# CONFIGURATION
# ============================================================================

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Script constants
$SCRIPT_NAME = "script-name"
$SCRIPT_VERSION = "1.0.0"
$AQUAPINE_PREFIX = "aquapine"
$ENVIRONMENT = "prod"

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

function Test-AzureConnection {
    Write-Log "Validating Azure connection..." -Level Info
    
    try {
        $context = Get-AzContext
        if (-not $context) {
            throw "Not connected to Azure. Run Connect-AzAccount first."
        }
        Write-Log "Connected to Azure subscription: $($context.Subscription.Name)" -Level Success
        return $true
    }
    catch {
        Write-Log "Azure connection validation failed: $_" -Level Error
        return $false
    }
}

# ============================================================================
# MAIN DEPLOYMENT LOGIC
# ============================================================================

function Deploy-AquapineResource {
    param(
        [string]$ResourceGroupName,
        [string]$Location
    )
    
    Write-Log "Starting deployment for AQUAPINE CONSULT..." -Level Info
    
    try {
        # Step 1: Create Resource Group
        Write-Log "Creating resource group: $ResourceGroupName" -Level Info
        
        if ($WhatIf) {
            Write-Log "[WHATIF] Would create resource group: $ResourceGroupName in $Location" -Level Warning
        }
        else {
            $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
            Write-Log "Resource group created successfully" -Level Success
        }
        
        # Step 2: Apply tags
        $tags = @{
            Environment        = $ENVIRONMENT
            Organization       = "Aquapine Consult"
            Department         = "IT"
            ManagedBy          = "Olatunde Ogunti"
            CreatedDate        = (Get-Date -Format "yyyy-MM-dd")
            Project            = "AZ104-Infrastructure"
        }
        
        if (-not $WhatIf) {
            Set-AzResourceGroup -Name $ResourceGroupName -Tag $tags
            Write-Log "Tags applied successfully" -Level Success
        }
        
        # [Additional deployment steps here]
        
        Write-Log "Deployment completed successfully!" -Level Success
        return $true
    }
    catch {
        Write-Log "Deployment failed: $_" -Level Error
        Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error
        return $false
    }
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

Write-Log "========================================" -Level Info
Write-Log "$SCRIPT_NAME v$SCRIPT_VERSION" -Level Info
Write-Log "AQUAPINE CONSULT - Azure Infrastructure" -Level Info
Write-Log "========================================" -Level Info

# Validate Azure connection
if (-not (Test-AzureConnection)) {
    Write-Log "Please connect to Azure using Connect-AzAccount" -Level Error
    exit 1
}

# Execute deployment
$deploymentResult = Deploy-AquapineResource -ResourceGroupName $ResourceGroupName -Location $Location

# Exit with appropriate code
if ($deploymentResult) {
    Write-Log "Script completed successfully" -Level Success
    exit 0
}
else {
    Write-Log "Script completed with errors" -Level Error
    exit 1
}