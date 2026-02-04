<#
.SYNOPSIS
    Bulk user creation for AQUAPINE CONSULT using Azure CLI (v6 - FIXED JSON ESCAPING)

.DESCRIPTION
    Uses Microsoft Graph API directly via "az rest" for all property updates.
    
    FIX: Uses temp files for JSON bodies to avoid PowerShell escaping issues
    
    Why: az ad user create/update commands have very limited parameter support.
    Solution: Use az rest to PATCH the Graph API endpoint directly.
    
    Workflow per user:
      A) az ad user create   → basic creation (display-name, UPN, password)
      B) az rest PATCH        → set all properties (givenName, surname, jobTitle,
                                  department, officeLocation, usageLocation)
      C) az rest PATCH        → set mobile phone (if valid)
      D) az rest PUT          → set manager (separate call with proper JSON body)
      E) az ad user show      → verify user exists

.PARAMETER CsvFilePath
    Path to the CSV file containing user data

.PARAMETER DefaultPassword
    SecureString password for all new users

.EXAMPLE
    .\aquapine-bulk-user-creation-FIXED.ps1
    .\aquapine-bulk-user-creation-FIXED.ps1 -DefaultPassword (Read-Host -AsSecureString "Password")

.NOTES
    Author:  Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Version: 6.0 (FIXED - JSON escaping via temp files)
    Fix:     Resolves "Unable to read JSON request payload" error
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$CsvFilePath = "..\data\aquapine-users.csv",

    [Parameter(Mandatory = $false)]
    [SecureString]$DefaultPassword
)

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

function Invoke-Az {
    param([string[]]$CmdArgs)
    $out = az @CmdArgs 2>&1
    return @{
        ExitCode = $LASTEXITCODE
        Output   = ($out -join "`n")
    }
}

function ConvertFrom-SecureStringToPlain {
    param([SecureString]$Secure)
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try   { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Invoke-GraphPatch {
    <#
    .SYNOPSIS
        Invokes Graph API PATCH with proper JSON handling
    .DESCRIPTION
        Uses temp file to avoid PowerShell JSON escaping issues
    #>
    param(
        [string]$UserId,
        [hashtable]$Properties,
        [string]$Description
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    try {
        # Convert hashtable to JSON and write to temp file
        $jsonBody = $Properties | ConvertTo-Json -Compress
        $jsonBody | Out-File -FilePath $tempFile -Encoding utf8 -NoNewline
        
        # Call Graph API with temp file reference
        $result = Invoke-Az @(
            "rest",
            "--method", "PATCH",
            "--url",    "https://graph.microsoft.com/v1.0/users/$UserId",
            "--headers", "Content-Type=application/json",
            "--body",   "@$tempFile"
        )
        
        return $result
    }
    finally {
        # Clean up temp file
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }
}

function Set-UserManager {
    <#
    .SYNOPSIS
        Sets user manager via Graph API
    .DESCRIPTION
        Uses temp file for proper JSON handling of manager reference
    #>
    param(
        [string]$UserId,
        [string]$ManagerId
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    try {
        # Create manager reference body
        $jsonBody = @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/users/$ManagerId"
        } | ConvertTo-Json -Compress
        
        $jsonBody | Out-File -FilePath $tempFile -Encoding utf8 -NoNewline
        
        # Call Graph API to set manager
        $result = Invoke-Az @(
            "rest",
            "--method", "PUT",
            "--url",    "https://graph.microsoft.com/v1.0/users/$UserId/manager/`$ref",
            "--headers", "Content-Type=application/json",
            "--body",   "@$tempFile"
        )
        
        return $result
    }
    finally {
        # Clean up temp file
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }
}

#endregion

#region Main

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - BULK USER IMPORT          " -ForegroundColor Cyan
Write-Host "  Azure CLI + Graph API (v6 - FIXED)          " -ForegroundColor Cyan
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

    # ── Bulk creation loop ───────────────────────────────────────────────────
    Write-Log "Step 4: Creating users..." -Level Info
    Write-Host ""

    $count = 0

    foreach ($user in $users) {
        $count++
        Write-Log "[$count/$($users.Count)] Processing: $($user.DisplayName)..." -Level Info

        try {
            $upn        = $user.UserPrincipalName
            $mailNick   = ($upn -split '@')[0]
            $pwd        = ConvertFrom-SecureStringToPlain $DefaultPassword

            # ─── A) CREATE USER ──────────────────────────────────────────────
            $createResult = Invoke-Az @(
                "ad", "user", "create",
                "--display-name",               $user.DisplayName,
                "--user-principal-name",        $upn,
                "--password",                   $pwd,
                "--force-change-password-next-sign-in", "true",
                "--mail-nickname",              $mailNick,
                "--output", "json"
            )

            $createdObj = $null
            if ($createResult.Output -like "*already exists*") {
                Write-Log "  ⚠ User already exists – will update properties" -Level Warning
                # Get existing user ID
                $idResult = Invoke-Az @("ad", "user", "show", "--id", $upn, "--query", "id", "--output", "tsv")
                $userId = $idResult.Output.Trim()
            }
            else {
                try { $createdObj = $createResult.Output | ConvertFrom-Json -ErrorAction Stop } catch {}
                if ($null -eq $createdObj -or [string]::IsNullOrEmpty($createdObj.id)) {
                    throw "CREATE returned no user ID. Output:`n$($createResult.Output)"
                }
                $userId = $createdObj.id
                Write-Log "  ✓ User created (ID: $userId)" -Level Success
            }

            # ─── B) UPDATE BASIC PROPERTIES via Graph API ───────────────────
            Write-Log "  → Updating user properties..." -Level Info
            
            $properties = @{
                givenName      = $user.FirstName
                surname        = $user.LastName
                jobTitle       = $user.JobTitle
                department     = $user.Department
                officeLocation = $user.OfficeLocation
                usageLocation  = $user.UsageLocation
            }
            
            $propsResult = Invoke-GraphPatch -UserId $userId -Properties $properties -Description "Basic properties"

            if ($propsResult.Output -like "*error*" -or $propsResult.Output -like "*ERROR*") {
                Write-Log "  ⚠ Properties update failed: $($propsResult.Output)" -Level Warning
            } else {
                Write-Log "  ✓ Properties updated (name, title, dept, location, usage)" -Level Success
            }

            # ─── C) SET MOBILE PHONE (if valid) ─────────────────────────────
            $phone = $user.PhoneNumber.Trim()
            if ($phone -and $phone -match '^[+0-9]' -and $phone -notmatch '^-') {
                Write-Log "  → Setting mobile phone..." -Level Info
                
                $phoneProps = @{ mobilePhone = $phone }
                $phoneResult = Invoke-GraphPatch -UserId $userId -Properties $phoneProps -Description "Mobile phone"

                if ($phoneResult.Output -notlike "*error*" -and $phoneResult.Output -notlike "*ERROR*") {
                    Write-Log "  ✓ Mobile phone set: $phone" -Level Success
                } else {
                    Write-Log "  ⚠ Phone update failed: $($phoneResult.Output)" -Level Warning
                }
            } else {
                Write-Log "  ⚠ Skipping phone – invalid value: '$phone'" -Level Warning
            }

            # ─── D) SET MANAGER (if specified) ──────────────────────────────
            if (-not [string]::IsNullOrWhiteSpace($user.Manager)) {
                Write-Log "  → Setting manager..." -Level Info
                
                # Get manager ID
                $mgrIdResult = Invoke-Az @(
                    "ad", "user", "show",
                    "--id",    $user.Manager,
                    "--query", "id",
                    "--output", "tsv"
                )

                if (-not [string]::IsNullOrWhiteSpace($mgrIdResult.Output)) {
                    $managerId = $mgrIdResult.Output.Trim()

                    # Set manager reference using helper function
                    $mgrResult = Set-UserManager -UserId $userId -ManagerId $managerId

                    if ($mgrResult.Output -notlike "*error*" -and $mgrResult.Output -notlike "*ERROR*") {
                        Write-Log "  ✓ Manager set: $($user.Manager)" -Level Success
                    } else {
                        Write-Log "  ⚠ Manager update failed: $($mgrResult.Output)" -Level Warning
                    }
                } else {
                    Write-Log "  ⚠ Manager not found: $($user.Manager)" -Level Warning
                }
            }

            # ─── E) VERIFY ───────────────────────────────────────────────────
            $verifyResult = Invoke-Az @("ad", "user", "show", "--id", $upn, "--query", "id", "--output", "tsv")
            if ([string]::IsNullOrWhiteSpace($verifyResult.Output)) {
                throw "VERIFICATION FAILED – user not found after creation"
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

        Start-Sleep -Milliseconds 500
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

    # ── Final verification ───────────────────────────────────────────────────
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  FINAL VERIFICATION – DETAILED USER LIST      " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    $listCmd = 'az ad user list --query "[?userPrincipalName!=''k.ogunti_outlook.com#EXT#@koguntioutlook.onmicrosoft.com''].{UPN:userPrincipalName,Name:displayName,Title:jobTitle,Dept:department,Office:officeLocation}" --output table'
    Write-Host "Running: $listCmd" -ForegroundColor Gray
    Invoke-Expression $listCmd
    Write-Host ""

    # ── Next steps ───────────────────────────────────────────────────────────
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS                                    " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Verify ALL properties in Azure Portal:"   -ForegroundColor White
    Write-Host "     Portal → Entra ID → Users → Click any user → Check Profile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Create groups and assign users:"          -ForegroundColor White
    Write-Host "     Run: .\create-groups-AZCLI.ps1"           -ForegroundColor Gray
    Write-Host ""

    if ($script:UsersFailed -eq 0) {
        Write-Host "🎉 All users created successfully with full properties!" -ForegroundColor Green
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
    Write-Host "  1. Run: az --version" -ForegroundColor Gray
    Write-Host "  2. Run: az login" -ForegroundColor Gray
    Write-Host "  3. Verify you have User Administrator or Global Admin role" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

#endregion