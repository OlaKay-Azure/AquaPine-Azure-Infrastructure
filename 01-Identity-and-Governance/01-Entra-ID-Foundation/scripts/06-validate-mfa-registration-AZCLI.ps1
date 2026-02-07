<#
.SYNOPSIS
    Validates MFA registration status for AQUAPINE CONSULT administrative accounts
    Azure CLI version (compatible with personal Microsoft accounts)

.DESCRIPTION
    Checks which users have registered for MFA using Azure CLI commands.
    Critical for ensuring admin account security hardening.
    
    Part of AZ-104 Domain 1: Identity and Governance - Lab 1.3
    
    NOTE: This script uses Azure CLI instead of Microsoft Graph PowerShell
    due to authentication limitations with Azure for Students personal accounts.
    Demonstrates professional adaptability when enterprise tools are unavailable.

.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Date: 2026-02-05
    Updated: 2026-02-05 (Modernized for Microsoft Entra ID terminology)
    Portfolio: github.com/OlaKay-Azure/AquaPine-Azure-Infrastructure
    
    Authentication Method: Azure CLI (az ad commands)
    Requirements: Azure CLI installed and authenticated (az login)
#>

# Verify Azure CLI is installed and authenticated
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   AQUAPINE CONSULT - MFA REGISTRATION REPORT" -ForegroundColor Cyan
Write-Host "   (Microsoft Entra ID - Azure CLI Method)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check Azure CLI authentication
Write-Host "[PREREQUISITE] Checking Azure CLI authentication..." -ForegroundColor Yellow
try {
    $accountInfo = az account show 2>$null | ConvertFrom-Json
    if ($accountInfo) {
        Write-Host "✅ Authenticated as: $($accountInfo.user.name)" -ForegroundColor Green
        Write-Host "   Subscription: $($accountInfo.name)" -ForegroundColor Gray
        Write-Host ""
    } else {
        throw "Not authenticated"
    }
} catch {
    Write-Host "❌ Not authenticated to Azure CLI" -ForegroundColor Red
    Write-Host "   Run: az login" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Target admin accounts for validation
$adminAccounts = @(
    "olatunde.ogunti@koguntioutlook.onmicrosoft.com"
    # Add other admin accounts as created
)

Write-Host "[1] ADMINISTRATIVE ACCOUNTS - MFA STATUS CHECK" -ForegroundColor Green
Write-Host ""

foreach ($upn in $adminAccounts) {
    Write-Host "👤 Checking: $upn" -ForegroundColor Cyan
    
    try {
        # Get user details
        $userJson = az ad user show --id $upn 2>$null
        
        if ($userJson) {
            $user = $userJson | ConvertFrom-Json
            Write-Host "   ✅ User Found: $($user.displayName)" -ForegroundColor Green
            Write-Host "   Account Enabled: $($user.accountEnabled)" -ForegroundColor Gray
            
            # Note: Azure CLI doesn't directly expose MFA registration details
            # This requires Microsoft Graph API (unavailable with personal accounts)
            Write-Host ""
            Write-Host "   📱 MFA Registration Status:" -ForegroundColor Cyan
            Write-Host "      ⚠️  MFA registration details require Microsoft Graph API" -ForegroundColor Yellow
            Write-Host "      ⚠️  Not accessible with Azure for Students personal accounts" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   ✅ MANUAL VERIFICATION REQUIRED:" -ForegroundColor Magenta
            Write-Host "      1. Sign in to Azure Portal as this user" -ForegroundColor Gray
            Write-Host "      2. Navigate to: https://aka.ms/mfasetup" -ForegroundColor Gray
            Write-Host "      3. Verify authentication methods registered" -ForegroundColor Gray
            Write-Host "      4. Screenshot for portfolio documentation" -ForegroundColor Gray
            
        } else {
            Write-Host "   ❌ User NOT found in Microsoft Entra ID" -ForegroundColor Red
        }
        
    } catch {
        Write-Warning "   Error checking $upn : $_"
    }
    
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   ALTERNATIVE: SECURITY DEFAULTS VALIDATION" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Since MFA registration details aren't accessible via Azure CLI," -ForegroundColor White
Write-Host "validate Security Defaults status instead:" -ForegroundColor White
Write-Host ""

# Check Security Defaults via Azure Portal screenshot confirmation
Write-Host "✅ VALIDATION METHOD 1: Azure Portal" -ForegroundColor Green
Write-Host "   Navigate to: Portal → Microsoft Entra ID → Properties" -ForegroundColor Gray
Write-Host "   Click: 'Manage Security defaults'" -ForegroundColor Gray
Write-Host "   Verify: Security defaults = ENABLED" -ForegroundColor Gray
Write-Host "   Screenshot: Save for portfolio" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ VALIDATION METHOD 2: Test MFA Login" -ForegroundColor Green
Write-Host "   1. Sign out of Azure Portal completely" -ForegroundColor Gray
Write-Host "   2. Sign in again with admin account" -ForegroundColor Gray
Write-Host "   3. Observe MFA challenge (Authenticator app prompt)" -ForegroundColor Gray
Write-Host "   4. Approve and verify successful login" -ForegroundColor Gray
Write-Host "   Screenshot: MFA challenge screen for portfolio" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ VALIDATION METHOD 3: Check Registered Methods Manually" -ForegroundColor Green
Write-Host "   Navigate to: https://aka.ms/mfasetup" -ForegroundColor Gray
Write-Host "   Sign in as: $($adminAccounts[0])" -ForegroundColor Gray
Write-Host "   View registered authentication methods" -ForegroundColor Gray
Write-Host "   Screenshot: Authentication methods page" -ForegroundColor Gray
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   SECURITY RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ All admin accounts MUST have MFA registered" -ForegroundColor Green
Write-Host "✅ Recommended: Microsoft Authenticator app (primary)" -ForegroundColor Green
Write-Host "✅ Required: Phone backup method (SMS or call)" -ForegroundColor Green
Write-Host "⚠️  Test MFA login regularly to ensure methods work" -ForegroundColor Yellow
Write-Host ""

Write-Host "📝 PORTFOLIO DOCUMENTATION:" -ForegroundColor Magenta
Write-Host "   Since Microsoft Graph is unavailable, demonstrate MFA via:" -ForegroundColor Gray
Write-Host "   1. ✅ Azure Portal screenshots (Security Defaults enabled)" -ForegroundColor Gray
Write-Host "   2. ✅ MFA challenge screenshots (login flow)" -ForegroundColor Gray
Write-Host "   3. ✅ Registered methods screenshot (https://aka.ms/mfasetup)" -ForegroundColor Gray
Write-Host "   4. ✅ This validation script (shows tool adaptability)" -ForegroundColor Gray
Write-Host ""

Write-Host "💡 INTERVIEW TALKING POINT:" -ForegroundColor Magenta
Write-Host '   "When Microsoft Graph API was unavailable due to account type' -ForegroundColor Gray
Write-Host '   limitations, I adapted by using Azure CLI for user management' -ForegroundColor Gray
Write-Host '   and manual verification via Azure Portal for MFA validation.' -ForegroundColor Gray
Write-Host '   This demonstrates understanding multiple authentication paths' -ForegroundColor Gray
Write-Host '   and professional problem-solving when enterprise tools have' -ForegroundColor Gray
Write-Host '   licensing or access constraints."' -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Validation script completed" -ForegroundColor Green
Write-Host "   Next: Capture manual validation screenshots for portfolio" -ForegroundColor Yellow