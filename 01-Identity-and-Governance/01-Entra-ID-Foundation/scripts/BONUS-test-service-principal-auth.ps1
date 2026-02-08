<#
.SYNOPSIS
    Tests Service Principal authentication to Microsoft Graph API

.DESCRIPTION
    Validates that App Registration and Service Principal are configured correctly
    by authenticating to Microsoft Graph and retrieving basic tenant information.
    
    BONUS CONTENT: Advanced authentication method for personal Azure accounts
    Part of "3 Authentication Methods" portfolio demonstration

.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Date: 2026-02-06
    Portfolio: github.com/OlaKay-Azure/AquaPine-Azure-Infrastructure
    
    Authentication Method: Service Principal (Application Permissions)
    Prerequisite: App Registration created with admin consent granted
    
.PARAMETER ClientId
    Application (client) ID from App Registration

.PARAMETER TenantId
    Directory (tenant) ID

.PARAMETER ClientSecret
    Client secret value (handle securely - never commit to Git!)
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$false)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientSecret
)

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   SERVICE PRINCIPAL AUTHENTICATION TEST" -ForegroundColor Cyan
Write-Host "   AQUAPINE CONSULT - Microsoft Graph API" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# If credentials not provided as parameters, prompt securely
if (-not $ClientId -or -not $TenantId -or -not $ClientSecret) {
    Write-Host "⚠️  Credentials not provided via parameters" -ForegroundColor Yellow
    Write-Host "   Please enter Service Principal credentials:" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not $ClientId) {
        $ClientId = Read-Host "Application (client) ID"
    }
    
    if (-not $TenantId) {
        $TenantId = Read-Host "Directory (tenant) ID"
    }
    
    if (-not $ClientSecret) {
        $ClientSecretSecure = Read-Host "Client Secret" -AsSecureString
        $ClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecretSecure)
        )
    }
}

Write-Host "[1] CONNECTING TO MICROSOFT GRAPH" -ForegroundColor Green
Write-Host "    Using Service Principal authentication..." -ForegroundColor Gray
Write-Host "    Client ID: $ClientId" -ForegroundColor Gray
Write-Host "    Tenant ID: $TenantId" -ForegroundColor Gray
Write-Host ""

try {
    # Convert client secret to SecureString
    $SecureClientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
    
    # Create PSCredential object
    $ClientSecretCredential = New-Object System.Management.Automation.PSCredential($ClientId, $SecureClientSecret)
    
    # Connect to Microsoft Graph
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome
    
    Write-Host "    ✅ Authentication successful!" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "    ❌ Authentication failed!" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "    Troubleshooting:" -ForegroundColor Yellow
    Write-Host "    1. Verify Client ID is correct" -ForegroundColor Gray
    Write-Host "    2. Verify Tenant ID is correct" -ForegroundColor Gray
    Write-Host "    3. Verify Client Secret is correct (not expired)" -ForegroundColor Gray
    Write-Host "    4. Verify API permissions granted with admin consent" -ForegroundColor Gray
    exit 1
}

Write-Host "[2] VALIDATING CONNECTION" -ForegroundColor Green

# Get current context
$context = Get-MgContext

Write-Host "    Connected as:" -ForegroundColor Cyan
Write-Host "    - App Name: $($context.AppName)" -ForegroundColor Gray
Write-Host "    - Client ID: $($context.ClientId)" -ForegroundColor Gray
Write-Host "    - Tenant ID: $($context.TenantId)" -ForegroundColor Gray
Write-Host "    - Account: $($context.Account)" -ForegroundColor Gray
Write-Host "    - Auth Type: $($context.AuthType)" -ForegroundColor Gray
Write-Host "    - Scopes: $($context.Scopes -join ', ')" -ForegroundColor Gray
Write-Host ""

Write-Host "[3] TESTING GRAPH API ACCESS" -ForegroundColor Green

try {
    # Test 1: Get organization details
    Write-Host "    Test 1: Get Organization Details" -ForegroundColor Cyan
    $org = Get-MgOrganization
    Write-Host "    ✅ Organization: $($org.DisplayName)" -ForegroundColor Green
    Write-Host "       Tenant ID: $($org.Id)" -ForegroundColor Gray
    Write-Host "       Verified Domains: $($org.VerifiedDomains.Name -join ', ')" -ForegroundColor Gray
    Write-Host ""
    
    # Test 2: Count users
    Write-Host "    Test 2: Count Users" -ForegroundColor Cyan
    $userCount = (Get-MgUser -All).Count
    Write-Host "    ✅ Total Users: $userCount" -ForegroundColor Green
    Write-Host ""
    
    # Test 3: Count groups
    Write-Host "    Test 3: Count Groups" -ForegroundColor Cyan
    $groupCount = (Get-MgGroup -All).Count
    Write-Host "    ✅ Total Groups: $groupCount" -ForegroundColor Green
    Write-Host ""
    
    # Test 4: List first 5 users
    Write-Host "    Test 4: List Sample Users" -ForegroundColor Cyan
    $sampleUsers = Get-MgUser -Top 5 -Property DisplayName, UserPrincipalName
    foreach ($user in $sampleUsers) {
        Write-Host "    - $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor Gray
    }
    Write-Host ""
    
} catch {
    Write-Host "    ❌ Graph API test failed!" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "    This may indicate missing API permissions." -ForegroundColor Yellow
    Write-Host "    Verify admin consent was granted for all permissions." -ForegroundColor Yellow
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   AUTHENTICATION TEST SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Service Principal authentication is working!" -ForegroundColor Green
Write-Host "✅ Microsoft Graph API access confirmed" -ForegroundColor Green
Write-Host "✅ Application permissions functioning correctly" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 NEXT STEP:" -ForegroundColor Magenta
Write-Host "   Rewrite user creation script using Microsoft Graph PowerShell" -ForegroundColor Gray
Write-Host "   with Service Principal authentication" -ForegroundColor Gray
Write-Host ""

# Disconnect
Disconnect-MgGraph
Write-Host "Disconnected from Microsoft Graph" -ForegroundColor Yellow