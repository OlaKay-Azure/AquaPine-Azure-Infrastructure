<#
.SYNOPSIS
    Create AQUAPINE CONSULT security groups in Microsoft Entra ID

.DESCRIPTION
    Production-ready PowerShell script to create a 3-tier group structure for AQUAPINE CONSULT:
    - Tier 1: Location-based groups (Lagos, Ibadan)
    - Tier 2: Department-based security groups (12 departments)
    - Tier 3: Role/function-based groups (managers, admins, mobile workers)
    
    This script:
    - Creates 20 security groups with proper naming conventions
    - Assigns users to groups based on CSV data
    - Sets meaningful descriptions for each group
    - Implements comprehensive error handling and logging
    - Generates detailed summary report

.PARAMETER CsvFilePath
    Path to the CSV file containing user data.
    Uses same CSV from user creation script.

.PARAMETER WhatIf
    Simulation mode - shows what would happen without creating groups

.EXAMPLE
    .\02-create-groups.ps1
    
    Uses default CSV path and creates all groups

.EXAMPLE
    .\02-create-groups.ps1 -WhatIf
    
    Simulation mode - validates structure without creating groups

.EXAMPLE
    .\02-create-groups.ps1 -CsvFilePath "C:\Path\To\aquapine-users.csv"
    
    Uses custom CSV file path

.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Purpose: AZ-104 Domain 1 - Identity & Governance Lab
    Date: January 2026
    Version: 1.0
    
    Prerequisites:
    - Users must be created first (run 01-homework-bulk-user-creation.ps1)
    - Microsoft.Graph PowerShell module installed
    - Groups Administrator or Global Administrator role
    - Same CSV file used for user creation
    
    Group Naming Convention:
    - Location groups: AQUAPINE-{Location}-AllUsers
    - Department groups: {Location}-{Department}-Security
    - Role groups: AQUAPINE-{Role}

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
        return $true
    })]
    [string]$CsvFilePath = "..\aquapine-users.csv",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Script configuration
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Initialize counters
$script:GroupsCreated = 0
$script:GroupsFailed = 0
$script:MembersAdded = 0
$script:MembersFailed = 0
$script:FailedOperations = @()
$script:StartTime = Get-Date

#region Group Definitions

# Define all AQUAPINE groups with metadata
$script:GroupDefinitions = @(
    # TIER 1: LOCATION GROUPS
    @{
        Name = "AQUAPINE-Lagos-AllUsers"
        Description = "All AQUAPINE employees based at Lagos Headquarters"
        Filter = { $_.OfficeLocation -eq "Lagos HQ" }
        Tier = 1
        Purpose = "Location-based access control and policies"
    },
    @{
        Name = "AQUAPINE-Ibadan-AllUsers"
        Description = "All AQUAPINE employees based at Ibadan farms (Bodija and Moniya)"
        Filter = { $_.OfficeLocation -in @("Bodija Farm", "Moniya Farm") }
        Tier = 1
        Purpose = "Location-based access control and policies"
    },
    
    # TIER 2: LAGOS DEPARTMENT GROUPS
    @{
        Name = "Lagos-HR-Security"
        Description = "Human Resources department - access to payroll, employee records, HR applications"
        Filter = { $_.Department -eq "Human Resources" }
        Tier = 2
        Purpose = "Department-specific resource access"
    },
    @{
        Name = "Lagos-IT-Security"
        Description = "IT Department - infrastructure management, security administration, technical support"
        Filter = { $_.Department -eq "IT Department" }
        Tier = 2
        Purpose = "IT resource and admin access"
    },
    @{
        Name = "Lagos-Sales-Security"
        Description = "Sales & Marketing department - CRM access, customer data, sales analytics"
        Filter = { $_.Department -eq "Sales Department" }
        Tier = 2
        Purpose = "Sales application and customer data access"
    },
    @{
        Name = "Lagos-Logistics-Security"
        Description = "Logistics department - delivery coordination, inventory management, distribution"
        Filter = { $_.Department -eq "Logistics Department" }
        Tier = 2
        Purpose = "Logistics and supply chain access"
    },
    @{
        Name = "Lagos-Executive-Security"
        Description = "Executive management - strategic dashboards, financial reports, company-wide access"
        Filter = { $_.Department -eq "Executive Management" }
        Tier = 2
        Purpose = "Executive-level reporting and decision support"
    },
    
    # TIER 2: IBADAN DEPARTMENT GROUPS
    @{
        Name = "Ibadan-FarmOps-Security"
        Description = "Farm operations team - pond management, water quality monitoring, production data"
        Filter = { $_.Department -eq "Farm Operations" }
        Tier = 2
        Purpose = "Farm operational data and IoT access"
    },
    @{
        Name = "Ibadan-MicrobiologyLab-Security"
        Description = "Microbiology lab - fish health data, test results, compliance records"
        Filter = { $_.Department -eq "Microbiology Lab" }
        Tier = 2
        Purpose = "Lab data and regulatory compliance access"
    },
    @{
        Name = "Ibadan-FeedProduction-Security"
        Description = "Feed production unit - feed formulas, quality control, production schedules"
        Filter = { $_.Department -eq "Feed Production" }
        Tier = 2
        Purpose = "Feed production and quality systems access"
    },
    @{
        Name = "Ibadan-Hatchery-Security"
        Description = "Hatchery unit - breeding records, larval management, genetics tracking"
        Filter = { $_.Department -eq "Hatchery Unit" }
        Tier = 2
        Purpose = "Hatchery operations and breeding data access"
    },
    @{
        Name = "Ibadan-Security-Security"
        Description = "Farm security team - CCTV access, access logs, incident reports"
        Filter = { $_.Department -eq "Farm Security" }
        Tier = 2
        Purpose = "Security systems and surveillance access"
    },
    @{
        Name = "Ibadan-Store-Security"
        Description = "Store/Inventory team - stock management, warehouse systems, supply tracking"
        Filter = { $_.Department -eq "Store Department" }
        Tier = 2
        Purpose = "Inventory management and warehouse access"
    },
    
    # TIER 3: ROLE/FUNCTION GROUPS
    @{
        Name = "AQUAPINE-AllManagers"
        Description = "All departmental managers and supervisors - management reporting and delegation"
        Filter = { $_.JobTitle -match "Manager|Supervisor|Director|Officer" -and $_.JobTitle -notmatch "Representative|Technician|Assistant|Coordinator" }
        Tier = 3
        Purpose = "Management tools and reporting access"
    },
    @{
        Name = "AQUAPINE-GlobalAdmins"
        Description = "Azure/Entra ID Global Administrators - full tenant management access"
        Filter = { $_.JobTitle -in @("Chief Executive Officer", "IT Manager") }
        Tier = 3
        Purpose = "Azure tenant administration"
    },
    @{
        Name = "AQUAPINE-MobileWorkers"
        Description = "Farm-based staff requiring mobile access - field data entry, offline sync"
        Filter = { $_.OfficeLocation -in @("Bodija Farm", "Moniya Farm") }
        Tier = 3
        Purpose = "Mobile device management and offline access"
    },
    @{
        Name = "AQUAPINE-RemoteAccess"
        Description = "Users authorized for VPN and remote desktop access to corporate network"
        Filter = { $_.Department -in @("IT Department", "Executive Management", "HR", "Sales Department") }
        Tier = 3
        Purpose = "VPN and remote access authorization"
    },
    @{
        Name = "AQUAPINE-FinanceAccess"
        Description = "Finance and payroll access - accounting systems, financial data, budget reports"
        Filter = { $_.JobTitle -in @("Chief Financial Officer", "Payroll Administrator") -or $_.Department -eq "Executive Management" }
        Tier = 3
        Purpose = "Financial systems and sensitive data access"
    },
    @{
        Name = "AQUAPINE-GuestUsers"
        Description = "External partners and consultants - limited guest access (currently empty)"
        Filter = { $false }  # No members initially - for future use
        Tier = 3
        Purpose = "B2B collaboration and external partner access"
    }
)

#endregion

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
        Tests if Microsoft Graph connection is active
    #>
    try {
        $context = Get-MgContext
        if ($null -eq $context) {
            return $false
        }
        
        $requiredScopes = @("Group.ReadWrite.All", "User.Read.All")
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
        if (Test-GraphConnection) {
            Write-Log "Already connected to Microsoft Graph" -Level Success
            return $true
        }
        
        $scopes = @(
            "Group.ReadWrite.All",
            "User.Read.All",
            "Directory.Read.All"
        )
        
        Connect-MgGraph -Scopes $scopes -NoWelcome
        
        if (Test-GraphConnection) {
            Write-Log "Successfully connected to Microsoft Graph" -Level Success
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

function New-AquaPineGroup {
    <#
    .SYNOPSIS
        Creates a single security group in Entra ID
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$GroupDefinition
    )
    
    try {
        Write-Log "Creating group: $($GroupDefinition.Name)" -Level Info
        
        # Check if group already exists
        $existingGroup = Get-MgGroup -Filter "displayName eq '$($GroupDefinition.Name)'" -ErrorAction SilentlyContinue
        
        if ($existingGroup) {
            Write-Log "  └─ ⚠ Group already exists, skipping creation" -Level Warning
            return $existingGroup
        }
        
        if ($WhatIf) {
            Write-Log "  └─ [WHATIF] Would create group" -Level Warning
            Write-Log "      Name: $($GroupDefinition.Name)" -Level Warning
            Write-Log "      Description: $($GroupDefinition.Description)" -Level Warning
            Write-Log "      Tier: $($GroupDefinition.Tier)" -Level Warning
            return $null
        }
        
        # Create group parameters
        $groupParams = @{
            DisplayName = $GroupDefinition.Name
            Description = $GroupDefinition.Description
            MailEnabled = $false
            MailNickname = ($GroupDefinition.Name -replace '[^a-zA-Z0-9]', '')
            SecurityEnabled = $true
            GroupTypes = @()  # Empty for security group
        }
        
        # Create the group
        $newGroup = New-MgGroup @groupParams
        
        Write-Log "  └─ ✓ Group created successfully" -Level Success
        Write-Log "      ID: $($newGroup.Id)" -Level Info
        
        return $newGroup
    }
    catch {
        Write-Log "  └─ ✗ Failed to create group: $_" -Level Error
        throw
    }
}

function Add-UsersToGroup {
    <#
    .SYNOPSIS
        Adds users to a group based on filter criteria
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        
        [Parameter(Mandatory = $true)]
        [string]$GroupName,
        
        [Parameter(Mandatory = $true)]
        [array]$AllUsers,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Filter
    )
    
    try {
        # Filter users based on criteria
        $matchingUsers = $AllUsers | Where-Object $Filter
        
        if ($matchingUsers.Count -eq 0) {
            Write-Log "  └─ No users match filter criteria" -Level Warning
            return 0
        }
        
        Write-Log "  └─ Adding $($matchingUsers.Count) members to group..." -Level Info
        
        $addedCount = 0
        $failedCount = 0
        
        foreach ($user in $matchingUsers) {
            try {
                # Get user object from Entra ID
                $entraUser = Get-MgUser -Filter "userPrincipalName eq '$($user.UserPrincipalName)'" -ErrorAction Stop
                
                if (-not $entraUser) {
                    Write-Log "      ⚠ User not found: $($user.UserPrincipalName)" -Level Warning
                    $failedCount++
                    continue
                }
                
                if ($WhatIf) {
                    Write-Log "      [WHATIF] Would add: $($user.DisplayName)" -Level Warning
                    $addedCount++
                    continue
                }
                
                # Check if already a member
                $isMember = Get-MgGroupMember -GroupId $GroupId -Filter "id eq '$($entraUser.Id)'" -ErrorAction SilentlyContinue
                
                if ($isMember) {
                    Write-Log "      ⏭ Already member: $($user.DisplayName)" -Level Info
                    $addedCount++
                    continue
                }
                
                # Add user to group
                New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $entraUser.Id -ErrorAction Stop
                
                Write-Log "      ✓ Added: $($user.DisplayName)" -Level Success
                $addedCount++
                $script:MembersAdded++
                
                # Small delay to avoid throttling
                Start-Sleep -Milliseconds 100
            }
            catch {
                Write-Log "      ✗ Failed to add $($user.DisplayName): $_" -Level Error
                $failedCount++
                $script:MembersFailed++
                
                $script:FailedOperations += [PSCustomObject]@{
                    Operation = "Add Member"
                    Group = $GroupName
                    User = $user.DisplayName
                    Error = $_.Exception.Message
                }
            }
        }
        
        Write-Log "  └─ ✓ Members added: $addedCount | Failed: $failedCount" -Level $(if ($failedCount -eq 0) { "Success" } else { "Warning" })
        
        return $addedCount
    }
    catch {
        Write-Log "  └─ ✗ Failed to add users to group: $_" -Level Error
        throw
    }
}

#endregion

#region Main Script

# Display script banner
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AQUAPINE CONSULT - GROUP STRUCTURE SETUP     " -ForegroundColor Cyan
Write-Host "  Microsoft Entra ID Security Groups           " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if ($WhatIf) {
    Write-Host "⚠️  RUNNING IN SIMULATION MODE (WhatIf)" -ForegroundColor Yellow
    Write-Host "   No actual changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

try {
    # Step 1: Connect to Microsoft Graph
    Write-Log "Step 1: Connecting to Microsoft Graph..." -Level Info
    
    if (-not (Connect-ToMicrosoftGraph)) {
        throw "Failed to connect to Microsoft Graph"
    }
    
    Write-Host ""
    
    # Step 2: Load user data from CSV
    Write-Log "Step 2: Loading user data from CSV..." -Level Info
    
    if (-not (Test-Path -Path $CsvFilePath)) {
        throw "CSV file not found: $CsvFilePath"
    }
    
    $users = Import-Csv -Path $CsvFilePath
    Write-Log "✓ Loaded $($users.Count) users from CSV" -Level Success
    
    Write-Host ""
    
    # Step 3: Display group structure overview
    Write-Log "Step 3: Group Structure Overview" -Level Info
    Write-Host ""
    Write-Host "AQUAPINE CONSULT - 3-TIER GROUP STRUCTURE" -ForegroundColor White
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    
    $tier1Groups = $script:GroupDefinitions | Where-Object { $_.Tier -eq 1 }
    $tier2Groups = $script:GroupDefinitions | Where-Object { $_.Tier -eq 2 }
    $tier3Groups = $script:GroupDefinitions | Where-Object { $_.Tier -eq 3 }
    
    Write-Host "📍 TIER 1: LOCATION GROUPS ($($tier1Groups.Count) groups)" -ForegroundColor Cyan
    foreach ($group in $tier1Groups) {
        $memberCount = ($users | Where-Object $group.Filter).Count
        Write-Host "   └─ $($group.Name) ($memberCount members)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "🏢 TIER 2: DEPARTMENT GROUPS ($($tier2Groups.Count) groups)" -ForegroundColor Cyan
    foreach ($group in $tier2Groups) {
        $memberCount = ($users | Where-Object $group.Filter).Count
        Write-Host "   └─ $($group.Name) ($memberCount members)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "👥 TIER 3: ROLE/FUNCTION GROUPS ($($tier3Groups.Count) groups)" -ForegroundColor Cyan
    foreach ($group in $tier3Groups) {
        $memberCount = ($users | Where-Object $group.Filter).Count
        Write-Host "   └─ $($group.Name) ($memberCount members)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Total Groups: $($script:GroupDefinitions.Count)" -ForegroundColor White
    Write-Host ""
    
    # Step 4: Confirmation prompt
    if (-not $WhatIf) {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host "⚠️  CONFIRMATION REQUIRED" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  You are about to create $($script:GroupDefinitions.Count) groups" -ForegroundColor White
        Write-Host "  and add members from $($users.Count) users" -ForegroundColor White
        Write-Host ""
        
        $confirmation = Read-Host "Type 'CREATE' (all caps) to proceed"
        
        if ($confirmation -ne "CREATE") {
            throw "Operation cancelled by user"
        }
        
        Write-Host ""
    }
    
    # Step 5: Create groups and add members
    Write-Log "Step 4: Creating groups and adding members..." -Level Info
    Write-Host ""
    
    $progressCount = 0
    
    foreach ($groupDef in $script:GroupDefinitions) {
        $progressCount++
        
        Write-Progress -Activity "Creating AQUAPINE groups" `
                       -Status "Processing $($groupDef.Name) ($progressCount of $($script:GroupDefinitions.Count))" `
                       -PercentComplete (($progressCount / $script:GroupDefinitions.Count) * 100)
        
        try {
            # Create group
            $group = New-AquaPineGroup -GroupDefinition $groupDef
            
            if ($group -or $WhatIf) {
                $script:GroupsCreated++
                
                # Add members to group
                if (-not $WhatIf -and $group) {
                    Add-UsersToGroup -GroupId $group.Id `
                                     -GroupName $groupDef.Name `
                                     -AllUsers $users `
                                     -Filter $groupDef.Filter
                }
                elseif ($WhatIf) {
                    $memberCount = ($users | Where-Object $groupDef.Filter).Count
                    Write-Log "  └─ [WHATIF] Would add $memberCount members" -Level Warning
                }
            }
        }
        catch {
            $script:GroupsFailed++
            
            $script:FailedOperations += [PSCustomObject]@{
                Operation = "Create Group"
                Group = $groupDef.Name
                User = "N/A"
                Error = $_.Exception.Message
            }
        }
        
        Write-Host ""
    }
    
    Write-Progress -Activity "Creating AQUAPINE groups" -Completed
    
    # Step 6: Generate summary report
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  GROUP CREATION SUMMARY                       " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $endTime = Get-Date
    $duration = $endTime - $script:StartTime
    
    Write-Host "Execution Time: " -NoNewline
    Write-Host "$($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Groups:" -ForegroundColor Cyan
    Write-Host "  Total Processed: " -NoNewline
    Write-Host "$($script:GroupDefinitions.Count)" -ForegroundColor White
    Write-Host "  Successfully Created: " -NoNewline
    Write-Host "$script:GroupsCreated" -ForegroundColor Green
    Write-Host "  Failed: " -NoNewline
    Write-Host "$script:GroupsFailed" -ForegroundColor $(if ($script:GroupsFailed -eq 0) { "Green" } else { "Red" })
    
    Write-Host ""
    Write-Host "Memberships:" -ForegroundColor Cyan
    Write-Host "  Members Added: " -NoNewline
    Write-Host "$script:MembersAdded" -ForegroundColor Green
    Write-Host "  Failed: " -NoNewline
    Write-Host "$script:MembersFailed" -ForegroundColor $(if ($script:MembersFailed -eq 0) { "Green" } else { "Red" })
    
    Write-Host ""
    
    # Display failed operations if any
    if ($script:FailedOperations.Count -gt 0) {
        Write-Host "Failed Operations:" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        
        $script:FailedOperations | Format-Table -Property Operation, Group, User, Error -AutoSize | Out-String | Write-Host
        
        $failedCsvPath = ".\failed-operations-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $script:FailedOperations | Export-Csv -Path $failedCsvPath -NoTypeInformation
        Write-Log "Failed operations exported to: $failedCsvPath" -Level Warning
    }
    
    Write-Host ""
    
    # Next steps
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEPS                                    " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. ✓ Verify groups in Azure Portal:" -ForegroundColor White
    Write-Host "   https://portal.azure.com → Entra ID → Groups" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. ✓ Check group memberships:" -ForegroundColor White
    Write-Host "   Get-MgGroup -Filter `"startswith(displayName,'AQUAPINE')`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. ✓ Assign RBAC roles to groups:" -ForegroundColor White
    Write-Host "   Run: .\03-assign-rbac.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. ✓ Test group-based access:" -ForegroundColor White
    Write-Host "   Sign in as a user and verify group memberships" -ForegroundColor Gray
    Write-Host ""
    
    if ($script:GroupsFailed -eq 0 -and $script:MembersFailed -eq 0) {
        Write-Host "🎉 All groups and memberships created successfully!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "⚠️  Some operations failed - review errors above" -ForegroundColor Yellow
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
    Write-Host "1. Verify users were created first (run 01-homework-bulk-user-creation.ps1)" -ForegroundColor Gray
    Write-Host "2. Check Microsoft Graph connection and permissions" -ForegroundColor Gray
    Write-Host "3. Ensure you have Groups Administrator role" -ForegroundColor Gray
    Write-Host "4. Review error message above for specific details" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
finally {
    # Optional: Disconnect from Microsoft Graph
    # Disconnect-MgGraph
}

#endregion

<#
VERIFICATION COMMANDS
=====================

# List all AQUAPINE groups
Get-MgGroup -Filter "startswith(displayName,'AQUAPINE')" | 
    Format-Table DisplayName, Description, @{L='Members';E={(Get-MgGroupMember -GroupId $_.Id).Count}}

# Check specific group members
$group = Get-MgGroup -Filter "displayName eq 'Lagos-IT-Security'"
Get-MgGroupMember -GroupId $group.Id | Format-Table DisplayName, UserPrincipalName

# Count groups by tier
Get-MgGroup -Filter "startswith(displayName,'AQUAPINE') or contains(displayName,'Lagos-') or contains(displayName,'Ibadan-')" | 
    Measure-Object | Select-Object -ExpandProperty Count

# Verify your (Olatunde's) group memberships
$user = Get-MgUser -Filter "userPrincipalName eq 'olatunde.ogunti@aquapineconsult.onmicrosoft.com'"
Get-MgUserMemberOf -UserId $user.Id | Format-Table DisplayName

# Expected groups for Olatunde:
# - AQUAPINE-Lagos-AllUsers
# - Lagos-IT-Security
# - AQUAPINE-AllManagers
# - AQUAPINE-GlobalAdmins
# - AQUAPINE-RemoteAccess

#>