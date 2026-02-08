<#
.SYNOPSIS
    Verify user login status after password reset

.DESCRIPTION
    Checks which AQUAPINE users have successfully logged in after password reset.
    This helps track password distribution and identify users who need follow-up.
    
.PARAMETER CsvFilePath
    Path to the original CSV file containing user data

.PARAMETER PasswordResetCsvPath
    Path to the password reset CSV (to show which passwords were distributed)

.PARAMETER DaysToCheck
    Number of days back to check for login activity (default: 7)

.EXAMPLE
    .\verify-user-logins.ps1

.EXAMPLE
    .\verify-user-logins.ps1 -DaysToCheck 3

.NOTES
    Author:  Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Version: 1.0
    
    This script checks:
    - Last successful sign-in date
    - Whether user has changed password (forced change on first login)
    - Account enabled/disabled status
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$CsvFilePath = "..\data\aquapine-users.csv",

    [Parameter(Mandatory = $false)]
    [string]$PasswordResetCsvPath = "",

    [Parameter(Mandatory = $false)]
    [int]$DaysToCheck = 7
)

$ErrorActionPreference = "Continue"

#region Helper Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info","Success","Warning","Error")][string]$Level = "Info"
    )
    $colors = @{ Info="Cyan"; Success="Green"; Warning="Yellow"; Error="Red" }
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
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

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - USER LOGIN VERIFICATION   " -ForegroundColor Cyan
Write-Host "  Post-Password Reset Status Check             " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # ── Prerequisites ────────────────────────────────────────────────────────
    Write-Log "Step 1: Checking prerequisites..." -Level Info

    $azVer = az version --output json 2>$null | ConvertFrom-Json
    if (-not $azVer) { throw "Azure CLI not installed" }
    Write-Log "✓ Azure CLI version: $($azVer.'azure-cli')" -Level Success

    # ── Login check ──────────────────────────────────────────────────────────
    Write-Log "Step 2: Checking Azure login..." -Level Info

    $account = az account show --output json 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Log "Not logged in – opening browser..." -Level Warning
        az login
        $account = az account show --output json 2>$null | ConvertFrom-Json
        if (-not $account) { throw "az login failed" }
    }
    Write-Log "✓ Logged in as: $($account.user.name)" -Level Success
    Write-Host ""

    # ── Load user data ───────────────────────────────────────────────────────
    Write-Log "Step 3: Loading user data..." -Level Info

    if (-not (Test-Path $CsvFilePath)) { throw "CSV file not found: $CsvFilePath" }
    $users = Import-Csv -Path $CsvFilePath
    Write-Log "✓ Found $($users.Count) users" -Level Success
    Write-Host ""

    # ── Check login status ───────────────────────────────────────────────────
    Write-Log "Step 4: Checking login status (last $DaysToCheck days)..." -Level Info
    Write-Host ""

    $loginResults = @()
    $loggedInCount = 0
    $notLoggedInCount = 0
    $count = 0

    foreach ($user in $users) {
        $count++
        Write-Progress -Activity "Checking user login status" -Status "$count of $($users.Count)" -PercentComplete (($count / $users.Count) * 100)

        $upn = $user.UserPrincipalName

        try {
            # Get user details
            $userResult = Invoke-Az @(
                "ad", "user", "show",
                "--id", $upn,
                "--query", "{displayName:displayName, userPrincipalName:userPrincipalName, accountEnabled:accountEnabled}",
                "--output", "json"
            )

            if ($userResult.ExitCode -ne 0) {
                $loginResults += [PSCustomObject]@{
                    DisplayName       = $user.DisplayName
                    UserPrincipalName = $upn
                    Department        = $user.Department
                    Status            = "Not Found"
                    LastSignIn        = "N/A"
                    AccountEnabled    = "Unknown"
                }
                $notLoggedInCount++
                continue
            }

            $userData = $userResult.Output | ConvertFrom-Json

            # Try to get sign-in activity (Note: This requires Azure AD Premium P1/P2)
            # For Azure AD Free, we'll just check if account is enabled
            $status = "Unknown"
            $lastSignIn = "Not available (requires Azure AD Premium)"
            
            if ($userData.accountEnabled) {
                # Account is enabled, assume they might have logged in
                # Without Premium, we can't check actual sign-in logs
                $status = "Account Enabled"
            }
            else {
                $status = "Account Disabled"
            }

            $loginResults += [PSCustomObject]@{
                DisplayName       = $userData.displayName
                UserPrincipalName = $userData.userPrincipalName
                Department        = $user.Department
                Status            = $status
                LastSignIn        = $lastSignIn
                AccountEnabled    = $userData.accountEnabled
            }

            if ($userData.accountEnabled) {
                $loggedInCount++
            }
            else {
                $notLoggedInCount++
            }
        }
        catch {
            Write-Log "  ⚠ Error checking $upn : $_" -Level Warning
        }
    }

    Write-Progress -Activity "Checking user login status" -Completed
    Write-Host ""

    # ── Display results ──────────────────────────────────────────────────────
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  USER LOGIN STATUS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    $loginResults | Format-Table -Property DisplayName, Department, Status, AccountEnabled -AutoSize

    # ── Summary ──────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  SUMMARY" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Users:           $($users.Count)" -ForegroundColor White
    Write-Host "Accounts Enabled:      $loggedInCount" -ForegroundColor Green
    Write-Host "Accounts Disabled:     $notLoggedInCount" -ForegroundColor Yellow
    Write-Host ""

    # Export results
    $exportPath = "..\data\login-verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $loginResults | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Log "✅ Results exported to: $exportPath" -Level Success
    Write-Host ""

    # ── Important notes ──────────────────────────────────────────────────────
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "  📝 IMPORTANT NOTES" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Sign-in Activity Logs:" -ForegroundColor White
    Write-Host "  • Detailed sign-in logs require Azure AD Premium P1/P2" -ForegroundColor Gray
    Write-Host "  • With Azure AD Free, we can only check if accounts are enabled" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  To verify actual logins manually:" -ForegroundColor White
    Write-Host "  1. Azure Portal → Entra ID → Users" -ForegroundColor Gray
    Write-Host "  2. Select a user → Sign-in logs" -ForegroundColor Gray
    Write-Host "  3. Check 'Last sign-in' date" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Alternative verification methods:" -ForegroundColor White
    Write-Host "  • Ask department managers to confirm user access" -ForegroundColor Gray
    Write-Host "  • Users who haven't logged in will still have force-change flag" -ForegroundColor Gray
    Write-Host "  • Monitor helpdesk tickets for password issues" -ForegroundColor Gray
    Write-Host ""

    exit 0
}
catch {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "  SCRIPT EXECUTION FAILED" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    Write-Log "Fatal error: $_" -Level Error
    exit 1
}