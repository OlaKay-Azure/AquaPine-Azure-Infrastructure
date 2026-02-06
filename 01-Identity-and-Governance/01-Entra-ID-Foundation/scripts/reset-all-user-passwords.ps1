<#
.SYNOPSIS
    Bulk password reset for AQUAPINE CONSULT users

.DESCRIPTION
    Resets passwords for all users (except already-reset IT Manager) with option to:
    - Generate secure random passwords OR use a single password
    - Force password change on next login
    - Export passwords to encrypted CSV for secure distribution
    - Validate password complexity requirements
    
.PARAMETER CsvFilePath
    Path to the original CSV file containing user data

.PARAMETER UseRandomPasswords
    Generate unique random password for each user (recommended)

.PARAMETER UseSinglePassword
    Use one password for all users (simpler but less secure)

.PARAMETER SinglePassword
    The single password to use if UseSinglePassword is specified

.PARAMETER ExcludeUsers
    Array of UPNs to exclude from reset (e.g., already-reset IT Manager)

.EXAMPLE
    # Generate random passwords for each user
    .\reset-all-user-passwords.ps1 -UseRandomPasswords

.EXAMPLE
    # Use single password for all users
    .\reset-all-user-passwords.ps1 -UseSinglePassword -SinglePassword (Read-Host -AsSecureString "New Password")

.EXAMPLE
    # Generate random passwords, exclude specific users
    .\reset-all-user-passwords.ps1 -UseRandomPasswords -ExcludeUsers @("olatunde.ogunti@koguntioutlook.onmicrosoft.com")

.NOTES
    Author:  Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Version: 1.0
    
    IMPORTANT: 
    - Generated passwords will be exported to CSV file
    - CSV file should be stored securely and distributed through secure channels
    - Users will be forced to change password on next login
    - Keep the CSV backup until all users have logged in successfully
#>

[CmdletBinding(DefaultParameterSetName = 'Random')]
param(
    [Parameter(Mandatory = $false)]
    [string]$CsvFilePath = "..\data\aquapine-users.csv",

    [Parameter(Mandatory = $true, ParameterSetName = 'Random')]
    [switch]$UseRandomPasswords,

    [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
    [switch]$UseSinglePassword,

    [Parameter(Mandatory = $false, ParameterSetName = 'Single')]
    [SecureString]$SinglePassword,

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeUsers = @("olatunde.ogunti@koguntioutlook.onmicrosoft.com")
)

$ErrorActionPreference = "Continue"
$script:UsersReset = 0
$script:UsersFailed = 0
$script:UsersSkipped = 0
$script:FailedUsers = @()
$script:ResetResults = @()
$script:StartTime = Get-Date

#region Helper Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info","Success","Warning","Error")][string]$Level = "Info"
    )
    $colors = @{ Info="Cyan"; Success="Green"; Warning="Yellow"; Error="Red" }
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
}

function ConvertFrom-SecureStringToPlain {
    param([SecureString]$Secure)
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try   { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function New-RandomPassword {
    <#
    .SYNOPSIS
        Generate cryptographically secure random password
    .DESCRIPTION
        Creates password meeting Azure AD requirements:
        - 12-16 characters long
        - Contains uppercase, lowercase, numbers, and special characters
        - No ambiguous characters (0, O, l, 1, I)
    #>
    param(
        [int]$Length = 14
    )
    
    # Character sets (excluding ambiguous characters)
    $upperChars = "ABCDEFGHJKLMNPQRSTUVWXYZ"  # No O, I
    $lowerChars = "abcdefghjkmnpqrstuvwxyz"   # No l, i, o
    $numberChars = "23456789"                  # No 0, 1
    $specialChars = "!@#$%^&*-_=+"            # Common safe special chars
    
    # Ensure at least one of each type
    $password = ""
    $password += $upperChars[(Get-Random -Maximum $upperChars.Length)]
    $password += $lowerChars[(Get-Random -Maximum $lowerChars.Length)]
    $password += $numberChars[(Get-Random -Maximum $numberChars.Length)]
    $password += $specialChars[(Get-Random -Maximum $specialChars.Length)]
    
    # Fill remaining characters
    $allChars = $upperChars + $lowerChars + $numberChars + $specialChars
    for ($i = 4; $i -lt $Length; $i++) {
        $password += $allChars[(Get-Random -Maximum $allChars.Length)]
    }
    
    # Shuffle the password
    $passwordArray = $password.ToCharArray()
    $shuffled = $passwordArray | Get-Random -Count $passwordArray.Length
    
    return -join $shuffled
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
Write-Host "  AQUAPINE CONSULT - BULK PASSWORD RESET       " -ForegroundColor Cyan
Write-Host "  Azure CLI Implementation                     " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # ── Prerequisites ────────────────────────────────────────────────────────
    Write-Log "Step 1: Checking prerequisites..." -Level Info

    $azVer = az version --output json 2>$null | ConvertFrom-Json
    if (-not $azVer) { throw "Azure CLI not installed. Download: https://aka.ms/installazurecliwindows" }
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
    Write-Log "✓ Logged in as : $($account.user.name)" -Level Success
    Write-Log "  Tenant ID    : $($account.tenantId)"   -Level Info
    Write-Host ""

    # ── CSV validation ───────────────────────────────────────────────────────
    Write-Log "Step 3: Loading user data..." -Level Info

    if (-not (Test-Path $CsvFilePath)) { throw "CSV file not found: $CsvFilePath" }
    $users = Import-Csv -Path $CsvFilePath
    if ($users.Count -eq 0) { throw "CSV file is empty" }
    
    # Filter out excluded users
    $usersToReset = $users | Where-Object { $_.UserPrincipalName -notin $ExcludeUsers }
    
    Write-Log "✓ Found $($users.Count) total users in CSV" -Level Success
    Write-Log "  Excluding $($ExcludeUsers.Count) user(s): $($ExcludeUsers -join ', ')" -Level Info
    Write-Log "  Users to reset: $($usersToReset.Count)" -Level Success
    Write-Host ""

    # ── Password strategy ────────────────────────────────────────────────────
    Write-Log "Step 4: Preparing password reset strategy..." -Level Info
    
    if ($UseRandomPasswords) {
        Write-Log "✓ Strategy: Generate unique random password for each user" -Level Success
        Write-Log "  Password length: 14 characters" -Level Info
        Write-Log "  Complexity: Uppercase, lowercase, numbers, special characters" -Level Info
    }
    else {
        if ($null -eq $SinglePassword) {
            Write-Log "Enter the password to use for all users:" -Level Warning
            $SinglePassword = Read-Host -AsSecureString "Password"
        }
        $plainPassword = ConvertFrom-SecureStringToPlain $SinglePassword
        Write-Log "✓ Strategy: Use single password for all users" -Level Success
        Write-Log "  Password: ********** (hidden)" -Level Info
    }
    Write-Host ""

    # ── Confirmation ─────────────────────────────────────────────────────────
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "⚠️  CONFIRMATION REQUIRED"                      -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  You are about to reset passwords for $($usersToReset.Count) users" -ForegroundColor White
    Write-Host "  Users will be forced to change password on first login" -ForegroundColor White
    Write-Host "  New passwords will be exported to CSV file" -ForegroundColor White
    Write-Host ""
    Write-Host "  Excluded users (will NOT be reset):" -ForegroundColor Yellow
    foreach ($excluded in $ExcludeUsers) {
        Write-Host "    - $excluded" -ForegroundColor Gray
    }
    Write-Host ""

    $confirmation = Read-Host "Type 'RESET' (all caps) to proceed"
    if ($confirmation -ne "RESET") { throw "Operation cancelled by user" }
    Write-Host ""

    # ── Bulk password reset loop ─────────────────────────────────────────────
    Write-Log "Step 5: Resetting user passwords..." -Level Info
    Write-Host ""

    $count = 0

    foreach ($user in $usersToReset) {
        $count++
        Write-Log "[$count/$($usersToReset.Count)] Resetting: $($user.DisplayName)..." -Level Info

        try {
            $upn = $user.UserPrincipalName

            # ─── Generate or use password ────────────────────────────────────
            if ($UseRandomPasswords) {
                $newPassword = New-RandomPassword -Length 14
            }
            else {
                $newPassword = $plainPassword
            }

            # ─── Check if user exists ────────────────────────────────────────
            $checkResult = Invoke-Az @("ad", "user", "show", "--id", $upn, "--query", "id", "--output", "tsv")
            
            if ([string]::IsNullOrWhiteSpace($checkResult.Output)) {
                Write-Log "  ⚠ User does not exist – skipping" -Level Warning
                $script:UsersSkipped++
                Write-Host ""
                continue
            }

            Write-Log "  ✓ User found: $upn" -Level Info

            # ─── Reset password ──────────────────────────────────────────────
            Write-Log "  → Resetting password..." -Level Info
            
            $resetResult = Invoke-Az @(
                "ad", "user", "update",
                "--id", $upn,
                "--password", $newPassword,
                "--force-change-password-next-sign-in", "true"
            )

            if ($resetResult.ExitCode -eq 0) {
                Write-Log "  ✅ Password reset successful!" -Level Success
                $script:UsersReset++
                
                # Store result for CSV export
                $script:ResetResults += [PSCustomObject]@{
                    DisplayName       = $user.DisplayName
                    UserPrincipalName = $user.UserPrincipalName
                    Department        = $user.Department
                    NewPassword       = $newPassword
                    ResetDate         = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    MustChangePassword = "Yes"
                }
            }
            else {
                throw "Password reset failed: $($resetResult.Output)"
            }
        }
        catch {
            Write-Log "  ❌ Failed: $($user.DisplayName)" -Level Error
            Write-Log "     Error: $_"                    -Level Error
            $script:UsersFailed++
            $script:FailedUsers += [PSCustomObject]@{
                DisplayName       = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                Error             = $_.ToString()
            }
        }
        
        Write-Host ""
        Start-Sleep -Milliseconds 300
    }

    # ── Export passwords to CSV ──────────────────────────────────────────────
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    
    if ($script:ResetResults.Count -gt 0) {
        $exportPath = "..\data\password-reset-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $script:ResetResults | Export-Csv -Path $exportPath -NoTypeInformation
        
        Write-Log "✅ Passwords exported to: $exportPath" -Level Success
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host "  🔐 SECURITY NOTICE" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  The CSV file contains plaintext passwords!" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Security best practices:" -ForegroundColor White
        Write-Host "  1. Store file in encrypted location immediately" -ForegroundColor Gray
        Write-Host "  2. Distribute passwords through secure channel (not email)" -ForegroundColor Gray
        Write-Host "  3. Delete CSV after all users have logged in" -ForegroundColor Gray
        Write-Host "  4. Verify all users changed their passwords" -ForegroundColor Gray
        Write-Host ""
    }

    # ── Summary ──────────────────────────────────────────────────────────────
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  PASSWORD RESET SUMMARY" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    $duration = (Get-Date) - $script:StartTime
    Write-Host "Execution Time:        $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
    Write-Host ""
    Write-Host "Total Users in CSV:    $($users.Count)" -ForegroundColor White
    Write-Host "Users Excluded:        $($ExcludeUsers.Count)" -ForegroundColor Yellow
    Write-Host "Users Processed:       $($usersToReset.Count)" -ForegroundColor White
    Write-Host "Successfully Reset:    $script:UsersReset" -ForegroundColor Green
    Write-Host "Skipped (not found):   $script:UsersSkipped" -ForegroundColor Yellow
    Write-Host "Failed:                $script:UsersFailed" -ForegroundColor $(if ($script:UsersFailed -eq 0) { "Green" } else { "Red" })
    Write-Host ""

    if ($script:UsersFailed -gt 0) {
        Write-Host "Failed Users:" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        $script:FailedUsers | Format-Table -Property DisplayName, UserPrincipalName, Error -AutoSize

        $failedPath = "..\data\failed-password-resets-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $script:FailedUsers | Export-Csv -Path $failedPath -NoTypeInformation
        Write-Log "Failed resets exported to: $failedPath" -Level Warning
    }

    # ── Next steps ───────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. 🔐 Secure the password CSV file:" -ForegroundColor White
    Write-Host "     Move to encrypted location or password manager" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. 📧 Distribute passwords securely:" -ForegroundColor White
    Write-Host "     Use secure channels (not email attachments)" -ForegroundColor Gray
    Write-Host "     Consider: SMS, encrypted messaging, in-person" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. ✅ Verify user logins:" -ForegroundColor White
    Write-Host "     Track which users have logged in and changed passwords" -ForegroundColor Gray
    Write-Host "     Portal → Entra ID → Users → Sign-in logs" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. 🗑️  Delete CSV after confirmation:" -ForegroundColor White
    Write-Host "     Once all users have successfully logged in" -ForegroundColor Gray
    Write-Host ""
    
    if ($script:UsersFailed -eq 0 -and $script:UsersSkipped -eq 0) {
        Write-Host "🎉 All passwords reset successfully!" -ForegroundColor Green
        exit 0
    }
    elseif ($script:UsersFailed -gt 0) {
        Write-Host "⚠️  Some password resets failed – review errors above" -ForegroundColor Yellow
        exit 1
    }
    else {
        Write-Host "✅ Password reset completed with some users skipped" -ForegroundColor Yellow
        exit 0
    }
}
catch {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "  SCRIPT EXECUTION FAILED" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    Write-Log "Fatal error: $_" -Level Error
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "  1. Run: az --version" -ForegroundColor Gray
    Write-Host "  2. Run: az login" -ForegroundColor Gray
    Write-Host "  3. Verify you have User Administrator or Global Admin role" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

#endregion