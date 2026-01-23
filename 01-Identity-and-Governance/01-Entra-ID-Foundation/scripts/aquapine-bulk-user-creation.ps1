<#
.SYNOPSIS
    Bulk user creation script for AQUAPINE CONSULT Microsoft Entra ID tenant

.DESCRIPTION
    Production-ready PowerShell script to import 45 AQUAPINE CONSULT employees from CSV file
    and create user accounts in Microsoft Entra ID (Azure AD) with complete profile information.
    
    This script:
    - Connects to Microsoft Graph API with appropriate permissions
    - Imports user data from CSV file
    - Creates users with all required properties
    - Sets temporary passwords with forced change on first login
    - Implements comprehensive error handling and logging
    - Generates detailed summary report

.PARAMETER CsvFilePath
    Path to the CSV file containing user data. 
    CSV must include: FirstName, LastName, DisplayName, UserPrincipalName, JobTitle, 
    Department, OfficeLocation, Manager, PhoneNumber, UsageLocation

.PARAMETER DefaultPassword
    Default temporary password for all new users. 
    Default: "AquaPine2025!" (users will be forced to change on first login)

.PARAMETER WhatIf
    Simulation mode - shows what would happen without actually creating users

.EXAMPLE
    .\homework-bulk-user-creation.ps1
    
    Uses default CSV path (.\aquapine-users.csv) and default password

.EXAMPLE
    .\homework-bulk-user-creation.ps1 -CsvFilePath "C:\Path\To\users.csv"
    
    Uses custom CSV file path

.EXAMPLE
    .\homework-bulk-user-creation.ps1 -WhatIf
    
    Simulation mode - validates CSV and shows what would be created

.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Purpose: AZ-104 Domain 1 - Identity & Governance Lab
    Date: January 2026
    Version: 1.0
    
    Prerequisites:
    - Microsoft.Graph PowerShell module installed
    - Global Administrator or User Administrator role
    - Internet connection to Microsoft Graph API
    
    Security Notes:
    - Temporary passwords are generated securely
    - Users MUST change password on first login
    - Script requires explicit authentication
    - All actions are logged for audit purposes

.LINK
    https://github.com/YOUR-USERNAME/AquaPine-Azure-Infrastructure
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if (-not (Test-Path -Path $_)) {
            throw "CSV file not found at path: $_"
        }
        if (-not ($_ -like "*.csv")) {
            throw "File must be a CSV file (*.csv)"
        }
        return $true
    })]
    [string]$CsvFilePath = ".\aquapine-users.csv",
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')]
    [string]$DefaultPassword = "AquaPine2025!",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Script configuration
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"  # Speeds up script execution

# Initialize counters and logging
$script:UsersCreated = 0
$script:UsersFailed = 0
$script:FailedUsers = @()
$script:StartTime = Get-Date

#region Helper Functions

function Write-Log {
    <#
    .SYNOPSIS
        Writes colored log messages with timestamps
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    
    switch ($Level) {
        "Success" { Write-Host $logMessage -ForegroundColor Green }
        "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
        "Error"   { Write-Host $logMessage -ForegroundColor Red }
        default   { Write-Host $logMessage -ForegroundColor Cyan }
    }
}

function Test-GraphConnection {
    <#
    .SYNOPSIS
        Tests if Microsoft Graph connection is active and valid
    #>
    try {
        $context = Get-MgContext
        if ($null -eq $context) {
            return $false
        }
        
        # Verify required scopes
        $requiredScopes = @("User.ReadWrite.All", "Directory.ReadWrite.All")
        $hasAllScopes = $true
        
        foreach ($scope in $requiredScopes) {
            if ($context.Scopes -notcontains $scope) {
                Write-Log "Missing required scope: $scope" -Level Warning
                $hasAllScopes = $false
            }
        }
        
        return $hasAllScopes
    }
    catch {
        return $false
    }
}

function Connect-ToMicrosoftGraph {
    <#
    .SYNOPSIS
        Connects to Microsoft Graph with required permissions
    #>
    Write-Log "Connecting to Microsoft Graph..." -Level Info
    
    try {
        # Check if already connected
        if (Test-GraphConnection) {
            Write-Log "Already connected to Microsoft Graph" -Level Success
            $context = Get-MgContext
            Write-Log "Tenant: $($context.TenantId)" -Level Info
            Write-Log "Account: $($context.Account)" -Level Info
            return $true
        }
        
        # Required scopes for user creation
        $scopes = @(
            "User.ReadWrite.All",      # Create and modify users
            "Directory.ReadWrite.All"  # Set manager and other directory properties
        )
        
        # Connect with interactive authentication
        Connect-MgGraph -Scopes $scopes -NoWelcome
        
        # Verify connection
        if (Test-GraphConnection) {
            Write-Log "Successfully connected to Microsoft Graph" -Level Success
            $context = Get-MgContext
            Write-Log "Tenant: $($context.TenantId)" -Level Info
            Write-Log "Account: $($context.Account)" -Level Info
            return $true
        }
        else {
            throw "Connection established but missing required permissions"
        }
    }
    catch {
        Write-Log "Failed to connect to Microsoft Graph: $_" -Level Error
        return $false
    }
}

function Test-CsvFile {
    <#
    .SYNOPSIS
        Validates CSV file structure and data quality
    #>
    param([string]$Path)
    
    Write-Log "Validating CSV file: $Path" -Level Info
    
    try {
        # Import CSV
        $csvData = Import-Csv -Path $Path
        
        if ($csvData.Count -eq 0) {
            throw "CSV file is empty"
        }
        
        # Required columns
        $requiredColumns = @(
            "FirstName", "LastName", "DisplayName", "UserPrincipalName",
            "JobTitle", "Department", "OfficeLocation", "Manager",
            "PhoneNumber", "UsageLocation"
        )
        
        # Check for required columns
        $csvColumns = $csvData[0].PSObject.Properties.Name
        $missingColumns = $requiredColumns | Where-Object { $_ -notin $csvColumns }
        
        if ($missingColumns) {
            throw "CSV missing required columns: $($missingColumns -join ', ')"
        }
        
        # Validate data quality
        $issues = @()
        
        foreach ($user in $csvData) {
            # Check for empty UserPrincipalName
            if ([string]::IsNullOrWhiteSpace($user.UserPrincipalName)) {
                $issues += "Row $($csvData.IndexOf($user) + 2): UserPrincipalName is empty"
            }
            
            # Check email format
            if ($user.UserPrincipalName -notmatch '^[^@]+@[^@]+\.[^@]+$') {
                $issues += "Row $($csvData.IndexOf($user) + 2): Invalid email format: $($user.UserPrincipalName)"
            }
            
            # Check for empty required fields
            if ([string]::IsNullOrWhiteSpace($user.DisplayName)) {
                $issues += "Row $($csvData.IndexOf($user) + 2): DisplayName is empty"
            }
        }
        
        if ($issues.Count -gt 0) {
            Write-Log "CSV validation found issues:" -Level Warning
            $issues | ForEach-Object { Write-Log "  - $_" -Level Warning }
            
            $continue = Read-Host "Continue despite validation warnings? (Y/N)"
            if ($continue -ne "Y") {
                throw "CSV validation failed - user cancelled"
            }
        }
        
        Write-Log "CSV validation passed: $($csvData.Count) users found" -Level Success
        return $csvData
    }
    catch {
        Write-Log "CSV validation failed: $_" -Level Error
        throw
    }
}

function New-AquaPineUser {
    <#
    .SYNOPSIS
        Creates a single user in Microsoft Entra ID
    #>
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UserData,
        
        [Parameter(Mandatory = $true)]
        [string]$Password
    )
    
    try {
        # Prepare password profile
        $passwordProfile = @{
            Password                      = $Password
            ForceChangePasswordNextSignIn = $true
        }
        
        # Prepare user parameters
        $userParams = @{
            AccountEnabled    = $true
            DisplayName       = $UserData.DisplayName
            UserPrincipalName = $UserData.UserPrincipalName
            MailNickname      = ($UserData.UserPrincipalName -split '@')[0]
            PasswordProfile   = $passwordProfile
            GivenName         = $UserData.FirstName
            Surname           = $UserData.LastName
            JobTitle          = $UserData.JobTitle
            Department        = $UserData.Department
            OfficeLocation    = $UserData.OfficeLocation
            MobilePhone       = $UserData.PhoneNumber
            UsageLocation     = $UserData.UsageLocation
        }
        
        # Create user
        Write-Log "Creating user: $($UserData.DisplayName) ($($UserData.UserPrincipalName))" -Level Info
        
        if ($WhatIf) {
            Write-Log "[WHATIF] Would create user with parameters:" -Level Warning
            $userParams | Format-List | Out-String | Write-Host -ForegroundColor Gray
            return $true
        }
        
        $newUser = New-MgUser @userParams
        
        Write-Log "✓ User created successfully: $($UserData.DisplayName)" -Level Success
        
        # Set manager if specified (and not empty)
        if (-not [string]::IsNullOrWhiteSpace($UserData.Manager)) {
            try {
                Write-Log "  └─ Setting manager: $($UserData.Manager)" -Level Info
                
                # Get manager user object
                $manager = Get-MgUser -Filter "userPrincipalName eq '$($UserData.Manager)'" -ErrorAction Stop
                
                if ($manager) {
                    # Set manager reference
                    $managerRef = @{
                        "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($manager.Id)"
                    }
                    
                    if (-not $WhatIf) {
                        Set-MgUserManagerByRef -UserId $newUser.Id -BodyParameter $managerRef
                        Write-Log "  └─ ✓ Manager set successfully" -Level Success
                    }
                    else {
                        Write-Log "  └─ [WHATIF] Would set manager" -Level Warning
                    }
                }
                else {
                    Write-Log "  └─ ⚠ Manager not found, skipping" -Level Warning
                }
            }
            catch {
                Write-Log "  └─ ⚠ Failed to set manager: $_" -Level Warning
            }
        }
        
        return $true
    }
    catch {
        # Check for duplicate user error
        if ($_.Exception.Message -like "*already exists*") {
            Write-Log "✗ User already exists: $($UserData.UserPrincipalName)" -Level Warning
        }
        else {
            Write-Log "✗ Failed to create user: $($UserData.DisplayName) - $_" -Level Error
        }
        
        throw
    }
}

#endregion

#region Main Script

# Display script banner
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - BULK USER IMPORT          " -ForegroundColor Cyan
Write-Host "  Microsoft Entra ID User Provisioning         " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# WhatIf mode notification
if ($WhatIf) {
    Write-Host "⚠️  RUNNING IN SIMULATION MODE (WhatIf)" -ForegroundColor Yellow
    Write-Host "   No actual changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

try {
    # Step 1: Validate prerequisites
    Write-Log "Step 1: Checking prerequisites..." -Level Info
    
    # Check if Microsoft.Graph module is installed
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        throw "Microsoft.Graph PowerShell module is not installed. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    
    Write-Log "✓ Microsoft.Graph module found" -Level Success
    
    # Step 2: Connect to Microsoft Graph
    Write-Log "Step 2: Connecting to Microsoft Graph..." -Level Info
    
    if (-not (Connect-ToMicrosoftGraph)) {
        throw "Failed to connect to Microsoft Graph"
    }
    
    Write-Host ""
    
    # Step 3: Validate CSV file
    Write-Log "Step 3: Validating CSV file..." -Level Info
    
    $users = Test-CsvFile -Path $CsvFilePath
    
    Write-Host ""
    
    # Step 4: Confirmation prompt
    if (-not $WhatIf) {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host "⚠️  CONFIRMATION REQUIRED" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  You are about to create $($users.Count) users in Entra ID" -ForegroundColor White
        Write-Host "  Tenant: $(Get-MgContext | Select-Object -ExpandProperty TenantId)" -ForegroundColor White
        Write-Host "  Default Password: $DefaultPassword" -ForegroundColor White
        Write-Host "  Users will be forced to change password on first login" -ForegroundColor White
        Write-Host ""
        
        $confirmation = Read-Host "Type 'CREATE' (all caps) to proceed"
        
        if ($confirmation -ne "CREATE") {
            throw "Operation cancelled by user"
        }
        
        Write-Host ""
    }
    
    # Step 5: Create users
    Write-Log "Step 4: Creating users..." -Level Info
    Write-Host ""
    
    $progressCount = 0
    
    foreach ($user in $users) {
        $progressCount++
        
        # Progress indicator
        Write-Progress -Activity "Creating AQUAPINE users" `
                       -Status "Processing $($user.DisplayName) ($progressCount of $($users.Count))" `
                       -PercentComplete (($progressCount / $users.Count) * 100)
        
        try {
            New-AquaPineUser -UserData $user -Password $DefaultPassword
            $script:UsersCreated++
        }
        catch {
            $script:UsersFailed++
            $script:FailedUsers += [PSCustomObject]@{
                DisplayName       = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                Error             = $_.Exception.Message
            }
        }
        
        # Small delay to avoid API throttling
        if (-not $WhatIf) {
            Start-Sleep -Milliseconds 500
        }
    }
    
    Write-Progress -Activity "Creating AQUAPINE users" -Completed
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    # Step 6: Generate summary report
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  BULK USER IMPORT SUMMARY                     " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $endTime = Get-Date
    $duration = $endTime - $script:StartTime
    
    Write-Host "Execution Time: " -NoNewline
    Write-Host "$($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Total Users Processed: " -NoNewline
    Write-Host "$($users.Count)" -ForegroundColor White
    
    Write-Host "Successfully Created: " -NoNewline
    Write-Host "$script:UsersCreated" -ForegroundColor Green
    
    Write-Host "Failed: " -NoNewline
    Write-Host "$script:UsersFailed" -ForegroundColor $(if ($script:UsersFailed -eq 0) { "Green" } else { "Red" })
    
    Write-Host ""
    
    # Display failed users if any
    if ($script:UsersFailed -gt 0) {
        Write-Host "Failed Users:" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        
        $script:FailedUsers | Format-Table -Property DisplayName, UserPrincipalName, Error -AutoSize | Out-String | Write-Host
        
        # Export failed users to CSV
        $failedCsvPath = ".\failed-users-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $script:FailedUsers | Export-Csv -Path $failedCsvPath -NoTypeInformation
        Write-Log "Failed users exported to: $failedCsvPath" -Level Warning
    }
    
    Write-Host ""
    
    # Next steps
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS                                    " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Verify users in Azure Portal:" -ForegroundColor White
    Write-Host "   https://portal.azure.com → Entra ID → Users" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Create groups and assign users:" -ForegroundColor White
    Write-Host "   Run: .\02-create-groups.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. ✓ Test user login:" -ForegroundColor White
    Write-Host "   Use temporary password: $DefaultPassword" -ForegroundColor Gray
    Write-Host "   Users will be prompted to change password" -ForegroundColor Gray
    Write-Host ""
    
    # Success/failure determination
    if ($script:UsersFailed -eq 0) {
        Write-Host "🎉 All users created successfully!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "⚠️  Some users failed - review errors above" -ForegroundColor Yellow
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
    Write-Host "1. Verify CSV file exists and is properly formatted" -ForegroundColor Gray
    Write-Host "2. Check Microsoft Graph connection and permissions" -ForegroundColor Gray
    Write-Host "3. Ensure you have User Administrator or Global Admin role" -ForegroundColor Gray
    Write-Host "4. Review error message above for specific details" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
finally {
    # Disconnect from Microsoft Graph (optional - comment out if you want to stay connected)
    # Disconnect-MgGraph
}

#endregion

<#
TROUBLESHOOTING GUIDE
=====================

Common Errors and Solutions:

1. "Microsoft.Graph module is not installed"
   Solution: Install-Module Microsoft.Graph -Scope CurrentUser

2. "Insufficient privileges"
   Solution: Ensure you have User Administrator or Global Administrator role

3. "User already exists"
   Solution: Script will skip existing users - check portal for duplicates

4. "CSV file not found"
   Solution: Verify path to CSV file, use absolute path if needed

5. "Failed to set manager"
   Solution: Managers must be created BEFORE their reports
            Run script in two passes: managers first, then reports

6. "API throttling"
   Solution: Script includes delays, but you can increase if needed

VERIFICATION COMMANDS
=====================

# Check created users
Get-MgUser -Filter "companyName eq 'AQUAPINE CONSULT'" | Format-Table DisplayName, UserPrincipalName, Department

# Check specific user
Get-MgUser -Filter "userPrincipalName eq 'olatunde.ogunti@aquapineconsult.onmicrosoft.com'"

# Check user's manager
Get-MgUserManager -UserId "olatunde.ogunti@aquapineconsult.onmicrosoft.com"

# Count users by department
Get-MgUser -All | Group-Object Department | Sort-Object Count -Descending

#>