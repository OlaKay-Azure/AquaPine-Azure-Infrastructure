<#
.SYNOPSIS
    Bulk user creation script for AQUAPINE CONSULT using Azure CLI (v4)

.DESCRIPTION
    Fixes from v3:
      - Renamed $Args parameter to $CmdArgs.  $Args is a PowerShell automatic
        variable; using it as a parameter name causes silent splatting failures.
      - Every user creation is now VERIFIED with "az ad user show" immediately
        after the create call.  Exit codes alone are not trusted.
      - Raw az output is printed on any failure so issues are visible.
      - A final user-list is printed at the end so you can confirm in the
        terminal without touching the Portal.

    Workflow per user:
      A) az ad user create   – display-name, UPN, password, mail-nickname
      B) az ad user update   – given-name, surname, job-title, dept, location
      C) az rest PATCH       – manager (no --manager flag exists in az ad)
      D) az ad user show     – VERIFY the user actually exists

.PARAMETER CsvFilePath
    Path to the CSV file containing user data

.PARAMETER DefaultPassword
    SecureString password for all new users

.EXAMPLE
    .\aquapine-bulk-user-creation-AZCLI.ps1
    .\aquapine-bulk-user-creation-AZCLI.ps1 -DefaultPassword (Read-Host -AsSecureString "Password")

.NOTES
    Author:  Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Version: 4.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$CsvFilePath = "..\data\aquapine-users.csv",

    [Parameter(Mandatory = $false)]
    [SecureString]$DefaultPassword
)

# ── Default password ─────────────────────────────────────────────────────────
if ($null -eq $DefaultPassword) {
    $DefaultPassword = ConvertTo-SecureString "AquaPine2025!" -AsPlainText -Force
}

$ErrorActionPreference = "Continue"
$script:UsersCreated  = 0
$script:UsersFailed   = 0
$script:FailedUsers   = @()
$script:StartTime     = Get-Date

#region Helper Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info","Success","Warning","Error")][string]$Level = "Info"
    )
    $colors = @{ Info="Cyan"; Success="Green"; Warning="Yellow"; Error="Red" }
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
}

# ── FIXED: parameter renamed from $Args to $CmdArgs ─────────────────────────
# $Args is a PowerShell automatic variable.  Naming a parameter $Args shadows
# it unpredictably; the splat @Args inside the function may resolve to the
# automatic (empty) variable instead of your declared parameter.
function Invoke-Az {
    param([string[]]$CmdArgs)
    $out = az @CmdArgs 2>&1          # capture stdout + stderr together
    return @{
        ExitCode = $LASTEXITCODE
        Output   = ($out -join "`n")
    }
}

# Converts SecureString → plain text only at the instant az needs it,
# then zeroes the BSTR so plain text does not linger in memory.
function ConvertFrom-SecureStringToPlain {
    param([SecureString]$Secure)
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try   { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

#endregion

#region Main

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - BULK USER IMPORT          " -ForegroundColor Cyan
Write-Host "  Azure CLI Implementation (v4 - Verified)    " -ForegroundColor Cyan
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
    Write-Log "  Subscription : $($account.name)"       -Level Info

    # ── CSV validation ───────────────────────────────────────────────────────
    Write-Log "Step 3: Validating CSV file..." -Level Info

    if (-not (Test-Path $CsvFilePath)) { throw "CSV file not found: $CsvFilePath" }
    $users = Import-Csv -Path $CsvFilePath
    if ($users.Count -eq 0) { throw "CSV file is empty" }
    Write-Log "✓ Found $($users.Count) users in CSV" -Level Success
    Write-Host ""

    # ── Confirmation ─────────────────────────────────────────────────────────
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "⚠️  CONFIRMATION REQUIRED"                      -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  You are about to create $($users.Count) users in Entra ID" -ForegroundColor White
    Write-Host "  Default Password: [SecureString - hidden]"                  -ForegroundColor White
    Write-Host "  Users will be forced to change password on first login"     -ForegroundColor White
    Write-Host ""

    $confirmation = Read-Host "Type 'CREATE' (all caps) to proceed"
    if ($confirmation -ne "CREATE") { throw "Operation cancelled by user" }
    Write-Host ""

    # ── Sanity check – create ONE user and VERIFY it exists ──────────────────
    Write-Log "Step 4: Sanity check – creating and verifying first user..." -Level Info

    $firstUser   = $users[0]
    $firstUpn    = $firstUser.UserPrincipalName
    $firstNick   = ($firstUpn -split '@')[0]
    $plainPwd    = ConvertFrom-SecureStringToPlain $DefaultPassword

    $sanityCreate = Invoke-Az @(
        "ad", "user", "create",
        "--display-name",               $firstUser.DisplayName,
        "--user-principal-name",        $firstUpn,
        "--password",                   $plainPwd,
        "--force-change-password-next-sign-in", "true",
        "--mail-nickname",              $firstNick,
        "--output", "json"
    )

    # Check: did we get a valid JSON object with an "id" field?
    $sanityObj = $null
    if ($sanityCreate.Output -notlike "*already exists*") {
        try { $sanityObj = $sanityCreate.Output | ConvertFrom-Json -ErrorAction Stop } catch {}

        if ($null -eq $sanityObj -or [string]::IsNullOrEmpty($sanityObj.id)) {
            throw "Sanity-check CREATE returned no user ID.  Raw az output:`n$($sanityCreate.Output)"
        }
    }

    # Hard verify – does the user actually exist in the directory?
    $sanityVerify = Invoke-Az @("ad", "user", "show", "--id", $firstUpn, "--query", "id", "--output", "tsv")
    if ([string]::IsNullOrWhiteSpace($sanityVerify.Output)) {
        throw "Sanity-check VERIFICATION failed – user '$firstUpn' does not exist after create.`nCreate output:`n$($sanityCreate.Output)"
    }

    Write-Log "✓ Sanity check passed – user verified in directory (ID: $($sanityVerify.Output.Trim()))" -Level Success
    Write-Host ""

    # ── Bulk creation loop ───────────────────────────────────────────────────
    Write-Log "Step 5: Creating users..." -Level Info
    Write-Host ""

    $count = 0

    foreach ($user in $users) {
        $count++
        Write-Log "[$count/$($users.Count)] Processing: $($user.DisplayName)..." -Level Info

        try {
            $upn        = $user.UserPrincipalName
            $mailNick   = ($upn -split '@')[0]
            $pwd        = ConvertFrom-SecureStringToPlain $DefaultPassword

            # ─── A) CREATE ───────────────────────────────────────────────────
            $createResult = Invoke-Az @(
                "ad", "user", "create",
                "--display-name",               $user.DisplayName,
                "--user-principal-name",        $upn,
                "--password",                   $pwd,
                "--force-change-password-next-sign-in", "true",
                "--mail-nickname",              $mailNick,
                "--output", "json"
            )

            # Parse the JSON response – this is the real success check
            $createdObj = $null
            if ($createResult.Output -like "*already exists*") {
                Write-Log "  ⚠ User already exists – will update properties" -Level Warning
            }
            else {
                try { $createdObj = $createResult.Output | ConvertFrom-Json -ErrorAction Stop } catch {}

                if ($null -eq $createdObj -or [string]::IsNullOrEmpty($createdObj.id)) {
                    throw "CREATE returned no valid user ID.  Raw output:`n$($createResult.Output)"
                }
                Write-Log "  ✓ User created (ID: $($createdObj.id))" -Level Success
            }

            # ─── D) VERIFY ── run immediately after create, before anything else
            $verifyResult = Invoke-Az @("ad", "user", "show", "--id", $upn, "--query", "id", "--output", "tsv")
            if ([string]::IsNullOrWhiteSpace($verifyResult.Output)) {
                throw "VERIFICATION FAILED – '$upn' does not exist after create.`nCreate output:`n$($createResult.Output)"
            }
            Write-Log "  ✓ Verified – user exists in directory" -Level Success

            # ─── B) UPDATE – properties not supported by create ─────────────
            $updateResult = Invoke-Az @(
                "ad", "user", "update",
                "--id",              $upn,
                "--given-name",      $user.FirstName,
                "--surname",         $user.LastName,
                "--job-title",       $user.JobTitle,
                "--department",      $user.Department,
                "--office-location", $user.OfficeLocation,
                "--usage-location",  $user.UsageLocation,
                "--output", "json"
            )

            if ($updateResult.Output -like "*ERROR*" -or $updateResult.Output -like "*error*") {
                Write-Log "  ⚠ Update warning: $($updateResult.Output)" -Level Warning
            } else {
                Write-Log "  ✓ Properties updated (name, title, dept, location)" -Level Success
            }

            # ─── B2) Mobile phone – skip placeholder values starting with "-"
            $phone = $user.PhoneNumber.Trim()
            if ($phone -and $phone -match '^[+0-9]') {
                $phoneResult = Invoke-Az @(
                    "ad", "user", "update",
                    "--id",     $upn,
                    "--mobile", $phone,
                    "--output", "json"
                )
                if ($phoneResult.Output -notlike "*ERROR*") {
                    Write-Log "  ✓ Mobile phone set" -Level Success
                } else {
                    Write-Log "  ⚠ Mobile phone update failed (non-fatal)" -Level Warning
                }
            } else {
                Write-Log "  ⚠ Skipping phone – placeholder value: '$phone'" -Level Warning
            }

            # ─── C) MANAGER – via az rest (no --manager flag in az ad) ──────
            if (-not [string]::IsNullOrWhiteSpace($user.Manager)) {
                $mgrIdResult = Invoke-Az @(
                    "ad", "user", "show",
                    "--id",    $user.Manager,
                    "--query", "id",
                    "--output", "tsv"
                )

                if (-not [string]::IsNullOrWhiteSpace($mgrIdResult.Output)) {
                    $managerId = $mgrIdResult.Output.Trim()

                    $userIdResult = Invoke-Az @(
                        "ad", "user", "show",
                        "--id",    $upn,
                        "--query", "id",
                        "--output", "tsv"
                    )

                    if (-not [string]::IsNullOrWhiteSpace($userIdResult.Output)) {
                        $userId = $userIdResult.Output.Trim()
                        $body    = '{"manager":{"@odata.id":"https://graph.microsoft.com/v1.0/users/' + $managerId + '"}}'

                        $restResult = Invoke-Az @(
                            "rest",
                            "--method", "PATCH",
                            "--url",    "https://graph.microsoft.com/v1.0/users/$userId",
                            "--body",   $body
                        )

                        if ($restResult.Output -notlike "*ERROR*" -and $restResult.Output -notlike "*error*") {
                            Write-Log "  ✓ Manager set: $($user.Manager)" -Level Success
                        } else {
                            Write-Log "  ⚠ Manager set failed (non-fatal): $($restResult.Output)" -Level Warning
                        }
                    }
                } else {
                    Write-Log "  ⚠ Manager not found: $($user.Manager)" -Level Warning
                }
            }

            $script:UsersCreated++
            Write-Log "  ✅ Completed: $($user.DisplayName)" -Level Success
            Write-Host ""
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
            Write-Host ""
        }

        Start-Sleep -Milliseconds 300
    }

    # ── Summary ──────────────────────────────────────────────────────────────
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  BULK USER IMPORT SUMMARY                     " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    $duration = (Get-Date) - $script:StartTime
    Write-Host "Execution Time:        $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
    Write-Host ""
    Write-Host "Total Users Processed: $($users.Count)"       -ForegroundColor White
    Write-Host "Successfully Created:  $script:UsersCreated"  -ForegroundColor Green
    Write-Host "Failed:                $script:UsersFailed"   -ForegroundColor $(if ($script:UsersFailed -eq 0) { "Green" } else { "Red" })
    Write-Host ""

    if ($script:UsersFailed -gt 0) {
        Write-Host "Failed Users:" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        $script:FailedUsers | Format-Table -Property DisplayName, UserPrincipalName, Error -AutoSize

        $failedPath = "..\data\failed-users-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $script:FailedUsers | Export-Csv -Path $failedPath -NoTypeInformation
        Write-Log "Failed users exported to: $failedPath" -Level Warning
    }

    # ── Final directory listing – ground truth confirmation ──────────────────
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  FINAL VERIFICATION – ALL USERS IN DIRECTORY  " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    $listResult = Invoke-Az @("ad", "user", "list", "--query", "[].userPrincipalName", "--output", "table")
    Write-Host $listResult.Output -ForegroundColor White
    Write-Host ""

    # ── Next steps ───────────────────────────────────────────────────────────
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS                                    " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Verify users in Azure Portal:"            -ForegroundColor White
    Write-Host "     https://portal.azure.com → Entra ID → Users" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Create groups and assign users:"          -ForegroundColor White
    Write-Host "     Run: .\create-groups-AZCLI.ps1"           -ForegroundColor Gray
    Write-Host ""

    if ($script:UsersFailed -eq 0) {
        Write-Host "🎉 All users created successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "⚠️  Some users failed – review errors above" -ForegroundColor Yellow
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
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "  1. Run: az --version   (confirm CLI is installed)"   -ForegroundColor Gray
    Write-Host "  2. Run: az login       (re-authenticate)"            -ForegroundColor Gray
    Write-Host "  3. Verify CSV path is correct"                       -ForegroundColor Gray
    Write-Host "  4. Check you have Global Administrator role"        -ForegroundColor Gray
    Write-Host ""
    exit 1
}

#endregion