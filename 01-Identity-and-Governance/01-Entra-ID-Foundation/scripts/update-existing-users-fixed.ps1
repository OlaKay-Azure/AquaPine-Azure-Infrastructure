<#
.SYNOPSIS
    Update existing AQUAPINE CONSULT users with missing properties

.DESCRIPTION
    Reads the same CSV file and updates all user properties that are currently missing
    in Azure AD. Uses temp files to avoid JSON escaping issues.
    
    This script:
    - Updates givenName, surname, jobTitle, department, officeLocation, usageLocation
    - Sets mobile phone (if valid)
    - Sets manager (if specified)
    - Skips users that don't exist

.PARAMETER CsvFilePath
    Path to the CSV file containing user data

.EXAMPLE
    .\update-existing-users-FIXED.ps1
    .\update-existing-users-FIXED.ps1 -CsvFilePath "..\data\aquapine-users.csv"

.NOTES
    Author:  Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Version: 1.0 (Update existing users only)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$CsvFilePath = "..\data\aquapine-users.csv"
)

$ErrorActionPreference = "Continue"
$script:UsersUpdated  = 0
$script:UsersFailed   = 0
$script:UsersSkipped  = 0
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
        
        Write-Verbose "JSON Body for $Description : $jsonBody"
        
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
        
        Write-Verbose "Manager JSON Body: $jsonBody"
        
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
Write-Host "  AQUAPINE CONSULT - UPDATE EXISTING USERS     " -ForegroundColor Cyan
Write-Host "  Fix Missing Properties                       " -ForegroundColor Cyan
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
    Write-Host "  You are about to UPDATE $($users.Count) users in Entra ID" -ForegroundColor White
    Write-Host "  This will set: First/Last Name, Job Title, Department,"    -ForegroundColor White
    Write-Host "                 Office Location, Usage Location, Manager"   -ForegroundColor White
    Write-Host ""

    $confirmation = Read-Host "Type 'UPDATE' (all caps) to proceed"
    if ($confirmation -ne "UPDATE") { throw "Operation cancelled by user" }
    Write-Host ""

    # ── Bulk update loop ─────────────────────────────────────────────────────
    Write-Log "Step 4: Updating users..." -Level Info
    Write-Host ""

    $count = 0

    foreach ($user in $users) {
        $count++
        Write-Log "[$count/$($users.Count)] Processing: $($user.DisplayName)..." -Level Info

        try {
            $upn = $user.UserPrincipalName

            # ─── CHECK IF USER EXISTS ────────────────────────────────────────
            $idResult = Invoke-Az @("ad", "user", "show", "--id", $upn, "--query", "id", "--output", "tsv")
            
            if ([string]::IsNullOrWhiteSpace($idResult.Output)) {
                Write-Log "  ⚠ User does not exist – skipping" -Level Warning
                $script:UsersSkipped++
                Write-Host ""
                continue
            }
            
            $userId = $idResult.Output.Trim()
            Write-Log "  ✓ User found (ID: $userId)" -Level Info

            # ─── UPDATE BASIC PROPERTIES ─────────────────────────────────────
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
                Write-Log "  ❌ Properties update failed: $($propsResult.Output)" -Level Error
                throw "Properties update failed"
            } else {
                Write-Log "  ✓ Properties updated successfully" -Level Success
            }

            # ─── SET MOBILE PHONE (if valid) ─────────────────────────────────
            $phone = $user.PhoneNumber.Trim()
            if ($phone -and $phone -match '^[+0-9]' -and $phone -notmatch '^-') {
                Write-Log "  → Setting mobile phone..." -Level Info
                
                $phoneProps = @{ mobilePhone = $phone }
                $phoneResult = Invoke-GraphPatch -UserId $userId -Properties $phoneProps -Description "Mobile phone"

                if ($phoneResult.Output -notlike "*error*" -and $phoneResult.Output -notlike "*ERROR*") {
                    Write-Log "  ✓ Mobile phone set: $phone" -Level Success
                } else {
                    Write-Log "  ⚠ Phone update warning: $($phoneResult.Output)" -Level Warning
                }
            } else {
                Write-Log "  ⚠ Skipping phone – invalid value: '$phone'" -Level Warning
            }

            # ─── SET MANAGER (if specified) ──────────────────────────────────
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

                    # Set manager reference
                    $mgrResult = Set-UserManager -UserId $userId -ManagerId $managerId

                    if ($mgrResult.Output -notlike "*error*" -and $mgrResult.Output -notlike "*ERROR*") {
                        Write-Log "  ✓ Manager set: $($user.Manager)" -Level Success
                    } else {
                        Write-Log "  ⚠ Manager update warning: $($mgrResult.Output)" -Level Warning
                    }
                } else {
                    Write-Log "  ⚠ Manager not found: $($user.Manager)" -Level Warning
                }
            }

            $script:UsersUpdated++
            Write-Log "  ✅ Update completed: $($user.DisplayName)" -Level Success
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
    Write-Host "  UPDATE SUMMARY                               " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    $duration = (Get-Date) - $script:StartTime
    Write-Host "Execution Time:        $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
    Write-Host ""
    Write-Host "Total Users Processed: $($users.Count)"       -ForegroundColor White
    Write-Host "Successfully Updated:  $script:UsersUpdated"  -ForegroundColor Green
    Write-Host "Skipped (not found):   $script:UsersSkipped"  -ForegroundColor Yellow
    Write-Host "Failed:                $script:UsersFailed"   -ForegroundColor $(if ($script:UsersFailed -eq 0) { "Green" } else { "Red" })
    Write-Host ""

    if ($script:UsersFailed -gt 0) {
        Write-Host "Failed Users:" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        $script:FailedUsers | Format-Table -Property DisplayName, UserPrincipalName, Error -AutoSize

        $failedPath = "..\data\failed-updates-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $script:FailedUsers | Export-Csv -Path $failedPath -NoTypeInformation
        Write-Log "Failed updates exported to: $failedPath" -Level Warning
    }

    # ── Final verification ───────────────────────────────────────────────────
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  VERIFICATION – UPDATED USER LIST             " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    $listCmd = 'az ad user list --query "[?userPrincipalName!=''k.ogunti_outlook.com#EXT#@koguntioutlook.onmicrosoft.com''].{UPN:userPrincipalName,Name:displayName,First:givenName,Last:surname,Title:jobTitle,Dept:department,Office:officeLocation,Location:usageLocation}" --output table'
    Write-Host "Running verification query..." -ForegroundColor Gray
    Invoke-Expression $listCmd
    Write-Host ""

    # ── Next steps ───────────────────────────────────────────────────────────
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS                                    " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Verify properties in Azure Portal:"       -ForegroundColor White
    Write-Host "     Portal → Entra ID → Users → Select user → Profile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Check manager relationships:"             -ForegroundColor White
    Write-Host "     Portal → Entra ID → Users → Select user → Direct reports" -ForegroundColor Gray
    Write-Host ""

    if ($script:UsersFailed -eq 0) {
        Write-Host "🎉 All users updated successfully!" -ForegroundColor Green
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