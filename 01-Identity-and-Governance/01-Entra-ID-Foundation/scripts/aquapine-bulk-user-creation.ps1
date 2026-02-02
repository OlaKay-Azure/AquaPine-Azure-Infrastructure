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

.EXAMPLE
    .\aquapine-bulk-user-creation.ps1
    
    Uses default CSV path (.\aquapine-users.csv) and default password

.EXAMPLE
    .\aquapine-bulk-user-creation.ps1 -CsvFilePath "C:\Path\To\users.csv"
    
    Uses custom CSV file path

.EXAMPLE
    .\aquapine-bulk-user-creation.ps1 -WhatIf
    
    Simulation mode - validates CSV and shows what would be created

.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Purpose: AZ-104 Domain 1 - Identity & Governance Lab
    Date: January 2026
    Version: 1.1 (Fixed duplicate WhatIf parameter)
    
    Prerequisites:
    - Microsoft.Graph PowerShell module installed
    - Global Administrator or User Administrator role
    - Internet connection to Microsoft Graph API

.LINK
    https://github.com/Olakay-Azure/AquaPine-Azure-Infrastructure
#>

[CmdletBinding(SupportsShouldProcess=$true)]
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
    [string]$CsvFilePath = "..\aquapine-users.csv",
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')]
    [string]$DefaultPassword = "AquaPine2025!"
)

# Script configuration
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Initialize counters and logging
$script:UsersCreated = 0
$script:UsersFailed = 0
$script:FailedUsers = @()
$script:StartTime = Get-Date

#region Helper Functions

function Write-Log {
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
    try {
        $context = Get-MgContext
        if ($null -eq $context) {
            return $false
        }
        
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
    Write-Log "Connecting to Microsoft Graph..." -Level Info
    
    try {
        if (Test-GraphConnection) {
            Write-Log "Already connected to Microsoft Graph" -Level Success
            $context = Get-MgContext
            Write-Log "Tenant: $($context.TenantId)" -Level Info
            Write-Log "Account: $($context.Account)" -Level Info
            return $true
        }
        
        $scopes = @(
            "User.ReadWrite.All",
            "Directory.ReadWrite.All"
        )
        
        Connect-MgGraph -Scopes $scopes -UseDeviceCode -NoWelcome
        
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
    param([string]$Path)
    
    Write-Log "Validating CSV file: $Path" -Level Info
    
    try {
        $csvData = Import-Csv -Path $Path
        
        if ($csvData.Count -eq 0) {
            throw "CSV file is empty"
        }
        
        $requiredColumns = @(
            "FirstName", "LastName", "DisplayName", "UserPrincipalName",
            "JobTitle", "Department", "OfficeLocation", "Manager",
            "PhoneNumber", "UsageLocation"
        )
        
        $csvColumns = $csvData[0].PSObject.Properties.Name
        $missingColumns = $requiredColumns | Where-Object { $_ -notin $csvColumns }
        
        if ($missingColumns) {
            throw "CSV missing required columns: $($missingColumns -join ', ')"
        }
        
        $issues = @()
        
        foreach ($user in $csvData) {
            if ([string]::IsNullOrWhiteSpace($user.UserPrincipalName)) {
                $issues += "Row $($csvData.IndexOf($user) + 2): UserPrincipalName is empty"
            }
            
            if ($user.UserPrincipalName -notmatch '^[^@]+@[^@]+\.[^@]+$') {
                $issues += "Row $($csvData.IndexOf($user) + 2): Invalid email format: $($user.UserPrincipalName)"
            }
            
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
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UserData,
        
        [Parameter(Mandatory = $true)]
        [string]$Password
    )
    
    try {
        $passwordProfile = @{
            Password                      = $Password
            ForceChangePasswordNextSignIn = $true
        }
        
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
        
        Write-Log "Creating user: $($UserData.DisplayName) ($($UserData.UserPrincipalName))" -Level Info
        
        if ($WhatIfPreference) {
            Write-Log "[WHATIF] Would create user with parameters:" -Level Warning
            $userParams | Format-List | Out-String | Write-Host -ForegroundColor Gray
            return $true
        }
        
        $newUser = New-MgUser @userParams
        
        Write-Log "✓ User created successfully: $($UserData.DisplayName)" -Level Success
        
        if (-not [string]::IsNullOrWhiteSpace($UserData.Manager)) {
            try {
                Write-Log "  └─ Setting manager: $($UserData.Manager)" -Level Info
                
                $manager = Get-MgUser -Filter "userPrincipalName eq '$($UserData.Manager)'" -ErrorAction Stop
                
                if ($manager) {
                    $managerRef = @{
                        "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($manager.Id)"
                    }
                    
                    Set-MgUserManagerByRef -UserId $newUser.Id -BodyParameter $managerRef
                    Write-Log "  └─ ✓ Manager set successfully" -Level Success
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

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - BULK USER IMPORT          " -ForegroundColor Cyan
Write-Host "  Microsoft Entra ID User Provisioning         " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if ($WhatIfPreference) {
    Write-Host "⚠️  RUNNING IN SIMULATION MODE (WhatIf)" -ForegroundColor Yellow
    Write-Host "   No actual changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

try {
    Write-Log "Step 1: Checking prerequisites..." -Level Info
    
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        throw "Microsoft.Graph PowerShell module is not installed. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    
    Write-Log "✓ Microsoft.Graph module found" -Level Success
    
    Write-Log "Step 2: Connecting to Microsoft Graph..." -Level Info
    
    if (-not (Connect-ToMicrosoftGraph)) {
        throw "Failed to connect to Microsoft Graph"
    }
    
    Write-Host ""
    
    Write-Log "Step 3: Validating CSV file..." -Level Info
    
    $users = Test-CsvFile -Path $CsvFilePath
    
    Write-Host ""
    
    if (-not $WhatIfPreference) {
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
    
    Write-Log "Step 4: Creating users..." -Level Info
    Write-Host ""
    
    $progressCount = 0
    
    foreach ($user in $users) {
        $progressCount++
        
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
        
        if (-not $WhatIfPreference) {
            Start-Sleep -Milliseconds 500
        }
    }
    
    Write-Progress -Activity "Creating AQUAPINE users" -Completed
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
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
    
    if ($script:UsersFailed -gt 0) {
        Write-Host "Failed Users:" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        
        $script:FailedUsers | Format-Table -Property DisplayName, UserPrincipalName, Error -AutoSize | Out-String | Write-Host
        
        $failedCsvPath = ".\failed-users-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $script:FailedUsers | Export-Csv -Path $failedCsvPath -NoTypeInformation
        Write-Log "Failed users exported to: $failedCsvPath" -Level Warning
    }
    
    Write-Host ""
    
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
    # Optional: Disconnect from Microsoft Graph
    # Disconnect-MgGraph
}

#endregion