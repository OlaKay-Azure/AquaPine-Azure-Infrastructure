<#
.SYNOPSIS
    Validates Security Defaults configuration for AQUAPINE CONSULT
    Azure CLI + Portal verification method

.DESCRIPTION
    Validates that Security Defaults are enabled in Microsoft Entra ID,
    providing baseline MFA enforcement for all users (especially admins).
    
    Uses Azure Portal verification since Azure CLI doesn't expose
    Security Defaults policy directly.
    
    Part of AZ-104 Domain 1: Identity and Governance - Lab 1.3

.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Date: 2026-02-05
    Updated: 2026-02-05 (Modernized terminology)
    Portfolio: github.com/OlaKay-Azure/AquaPine-Azure-Infrastructure
    
    Terminology: Microsoft Entra ID (formerly Azure AD)
    Authentication: Azure CLI + Manual Portal verification
#>

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   AQUAPINE CONSULT - SECURITY DEFAULTS VALIDATION" -ForegroundColor Cyan
Write-Host "   (Microsoft Entra ID)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check Azure CLI authentication
Write-Host "[PREREQUISITE] Verifying Azure CLI authentication..." -ForegroundColor Yellow
try {
    $accountInfo = az account show 2>$null | ConvertFrom-Json
    if ($accountInfo) {
        Write-Host "✅ Authenticated to Azure" -ForegroundColor Green
        Write-Host "   Account: $($accountInfo.user.name)" -ForegroundColor Gray
        Write-Host "   Tenant: $($accountInfo.tenantId)" -ForegroundColor Gray
        Write-Host ""
    }
} catch {
    Write-Host "❌ Not authenticated. Run: az login" -ForegroundColor Red
    exit 1
}

Write-Host "[1] SECURITY DEFAULTS STATUS CHECK" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  NOTE: Azure CLI doesn't directly expose Security Defaults policy" -ForegroundColor Yellow
Write-Host "   Manual verification via Azure Portal is required" -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 VALIDATION CHECKLIST:" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Step 1: Navigate to Azure Portal" -ForegroundColor Green
Write-Host "   URL: https://portal.azure.com" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Step 2: Open Microsoft Entra ID" -ForegroundColor Green
Write-Host "   Portal Search: 'Microsoft Entra ID' or 'Azure Active Directory'" -ForegroundColor Gray
Write-Host "   Left Menu: Click 'Properties'" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Step 3: Check Security Defaults" -ForegroundColor Green
Write-Host "   Scroll down to: 'Manage Security defaults'" -ForegroundColor Gray
Write-Host "   Click the link: 'Manage Security defaults'" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Step 4: Verify Enabled Status" -ForegroundColor Green
Write-Host "   Expected: Security defaults = ENABLED" -ForegroundColor Gray
Write-Host "   If disabled: Enable and save" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Step 5: Screenshot for Portfolio" -ForegroundColor Green
Write-Host "   Capture: Full page showing 'Security defaults: Enabled'" -ForegroundColor Gray
Write-Host "   Save as: security-defaults-enabled-verification.png" -ForegroundColor Gray
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   WHAT SECURITY DEFAULTS PROTECTS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "When enabled, Security Defaults automatically enforces:" -ForegroundColor White
Write-Host ""
Write-Host "✅ MFA for all users (especially administrators)" -ForegroundColor Green
Write-Host "   - Admins: MFA required for EVERY sign-in" -ForegroundColor Gray
Write-Host "   - Users: MFA prompted for risky sign-ins" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ MFA for privileged operations" -ForegroundColor Green
Write-Host "   - Azure Portal access" -ForegroundColor Gray
Write-Host "   - Azure PowerShell access" -ForegroundColor Gray
Write-Host "   - Azure CLI access" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Blocks legacy authentication protocols" -ForegroundColor Green
Write-Host "   - SMTP, POP3, IMAP (no MFA support)" -ForegroundColor Gray
Write-Host "   - Forces modern authentication (OAuth 2.0)" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Protects admin accounts" -ForegroundColor Green
Write-Host "   - Global Administrators" -ForegroundColor Gray
Write-Host "   - Privileged role administrators" -ForegroundColor Gray
Write-Host "   - Security administrators" -ForegroundColor Gray
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   PORTFOLIO DOCUMENTATION" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📸 Required Screenshots:" -ForegroundColor Magenta
Write-Host "   1. Azure Portal: Security defaults enabled page" -ForegroundColor Gray
Write-Host "   2. MFA challenge during admin sign-in" -ForegroundColor Gray
Write-Host "   3. Microsoft Authenticator app notification" -ForegroundColor Gray
Write-Host "   4. Registered authentication methods (https://aka.ms/mfasetup)" -ForegroundColor Gray
Write-Host ""
Write-Host "📝 Documentation to Create:" -ForegroundColor Magenta
Write-Host "   - mfa-implementation-guide.md (business context)" -ForegroundColor Gray
Write-Host "   - security-defaults-verification-checklist.md" -ForegroundColor Gray
Write-Host "   - mfa-user-training-guide.md (for AQUAPINE employees)" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Validation guidance complete" -ForegroundColor Green
Write-Host "   Next: Complete manual verification in Azure Portal" -ForegroundColor Yellow
Write-Host ""