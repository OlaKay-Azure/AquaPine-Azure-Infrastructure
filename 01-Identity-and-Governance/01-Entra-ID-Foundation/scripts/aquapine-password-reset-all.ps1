<#
.SYNOPSIS
    Reset all AQUAPINE employee passwords (excludes admin)

.DESCRIPTION
    Resets passwords for all 44 employees.
    Excludes: olatunde.ogunti@koguntioutlook.onmicrosoft.com
    
    Uses Azure CLI + Graph API (Azure for Students compatible)

.PARAMETER UseCommonPassword
    Use same password for all users (you'll be prompted)
    If not specified, generates unique random password per user

.EXAMPLE
    .\aquapine-password-reset-all.ps1
    Generates unique random passwords for each user

.EXAMPLE
    .\aquapine-password-reset-all.ps1 -UseCommonPassword
    Prompts for single password to use for all users

.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
#>

[CmdletBinding()]
param(
    [switch]$UseCommonPassword
)

$ErrorActionPreference = "Continue"

# Admin to exclude
$ADMIN_UPN = "olatunde.ogunti@koguntioutlook.onmicrosoft.com"

# Counters
$successCount = 0
$failCount = 0
$resetLog = @()

Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  AQUAPINE - RESET ALL EMPLOYEE PASSWORDS     " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check authentication
Write-Host "[1/4] Verifying Azure CLI..." -ForegroundColor Yellow
$account = az account show --output json 2>$null | ConvertFrom-Json

if (-not $account) {
    Write-Host "ERROR: Not logged in. Run: az login" -ForegroundColor Red
    exit 1
}

Write-Host "      ✓ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host ""

# Get all users
Write-Host "[2/4] Fetching users from Entra ID..." -ForegroundColor Yellow

$usersJson = az rest --method GET --url "https://graph.microsoft.com/v1.0/users" --output json
$allUsers = ($usersJson | ConvertFrom-Json).value

# Filter: exclude admin and external accounts
$users = $allUsers | Where-Object {
    $_.userPrincipalName -ne $ADMIN_UPN -and
    $_.userPrincipalName -notlike "*#EXT#*"
}

Write-Host "      ✓ Found $($users.Count) employees (admin excluded)" -ForegroundColor Green
Write-Host ""

# Get password
Write-Host "[3/4] Password configuration..." -ForegroundColor Yellow

$commonPwd = $null

if ($UseCommonPassword) {
    Write-Host "      Mode: Common password for all users" -ForegroundColor Cyan
    $securePwd = Read-Host "      Enter password for all users" -AsSecureString
    
    # Convert SecureString to plain text
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd)
    $commonPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}
else {
    Write-Host "      Mode: Unique random password per user" -ForegroundColor Cyan
}

Write-Host ""

# Confirmation
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  ⚠️  CONFIRMATION REQUIRED" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Users to reset:  $($users.Count)" -ForegroundColor White
Write-Host "  Admin excluded:  $ADMIN_UPN" -ForegroundColor Green
Write-Host "  Force change:    YES (on next login)" -ForegroundColor White
Write-Host ""
Write-Host "  First 5 users:" -ForegroundColor Cyan
$users | Select-Object -First 5 | ForEach-Object {
    Write-Host "    • $($_.displayName)" -ForegroundColor Gray
}
Write-Host "    ... and $($users.Count - 5) more" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Type 'YES' to proceed"

if ($confirm -ne "YES") {
    Write-Host ""
    Write-Host "Operation cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "[4/4] Resetting passwords..." -ForegroundColor Yellow
Write-Host ""

# Generate random password function
function New-RandomPassword {
    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$%'
    $pwd = -join ((1..16) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    # Ensure complexity
    return "Aq" + $pwd.Substring(2, 12) + "9!"
}

# Reset each user
$count = 0

foreach ($user in $users) {
    $count++
    
    # Generate or use common password
    $newPwd = if ($UseCommonPassword) { $commonPwd } else { New-RandomPassword }
    
    Write-Host "  [$count/$($users.Count)] $($user.displayName)..." -NoNewline
    
    try {
        # Build JSON body
        $body = @{
            passwordProfile = @{
                password = $newPwd
                forceChangePasswordNextSignIn = $true
            }
        } | ConvertTo-Json -Compress
        
        # Call Graph API
        $result = az rest `
            --method PATCH `
            --url "https://graph.microsoft.com/v1.0/users/$($user.id)" `
            --headers "Content-Type=application/json" `
            --body $body `
            2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✓" -ForegroundColor Green
            $successCount++
            
            # Log
            $resetLog += [PSCustomObject]@{
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                UPN = $user.userPrincipalName
                DisplayName = $user.displayName
                Department = $user.department
                JobTitle = $user.jobTitle
                NewPassword = $newPwd
                Status = "Success"
            }
        }
        else {
            throw "API returned error: $result"
        }
    }
    catch {
        Write-Host " ✗ FAILED" -ForegroundColor Red
        $failCount++
        
        $resetLog += [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            UPN = $user.userPrincipalName
            DisplayName = $user.displayName
            Department = $user.department
            JobTitle = $user.jobTitle
            NewPassword = "FAILED"
            Status = "Error: $_"
        }
    }
    
    Start-Sleep -Milliseconds 200
}

# Summary
Write-Host ""
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "  -------" -ForegroundColor Cyan
Write-Host "  Total:    $($users.Count)" -ForegroundColor White
Write-Host "  Success:  $successCount" -ForegroundColor Green
Write-Host "  Failed:   $failCount" -ForegroundColor $(if ($failCount -eq 0) {"Green"} else {"Red"})
Write-Host ""

# Save log
$logDir = "..\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = "$logDir\password-reset-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$resetLog | Export-Csv -Path $logFile -NoTypeInformation

Write-Host "  📄 Log saved: $logFile" -ForegroundColor Cyan
Write-Host ""

# Security warning
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  🔐 SECURITY WARNING" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "  The CSV file contains PLAIN TEXT PASSWORDS." -ForegroundColor Red
Write-Host ""
Write-Host "  Required actions:" -ForegroundColor Yellow
Write-Host "  1. Encrypt the CSV file immediately" -ForegroundColor White
Write-Host "  2. Do NOT email it" -ForegroundColor White
Write-Host "  3. Delete after distribution" -ForegroundColor White
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "✅ All $successCount passwords reset successfully!" -ForegroundColor Green
}
else {
    Write-Host "⚠️  $failCount users failed - check log file" -ForegroundColor Yellow
}

Write-Host ""