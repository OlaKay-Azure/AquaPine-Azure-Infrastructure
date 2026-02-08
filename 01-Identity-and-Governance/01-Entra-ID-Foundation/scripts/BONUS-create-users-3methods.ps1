<#
.SYNOPSIS
    BONUS: User creation demonstrating 3 authentication methods
    
.DESCRIPTION
    Creates Microsoft Entra ID users from CSV using three different authentication approaches:
    
    METHOD 1: Azure CLI (az ad user create)
    - Works with personal Microsoft accounts
    - Cross-platform, command-line based
    - Requires interactive sign-in
    
    METHOD 2: Microsoft Graph Interactive (Connect-MgGraph delegated)
    - Works with work/school accounts
    - Requires user consent
    - Limited with personal accounts ❌
    
    METHOD 3: Microsoft Graph Service Principal (Connect-MgGraph app-only)
    - Works with personal accounts ✅
    - Application permissions (non-interactive)
    - Production-standard approach
    
    This script demonstrates advanced authentication concepts and tool adaptability.
    
.PARAMETER CSVPath
    Path to CSV file with user details
    
.PARAMETER AuthMethod
    Authentication method: "AzureCLI", "GraphInteractive", or "GraphServicePrincipal"
    
.PARAMETER ClientId
    Application (client) ID (required for GraphServicePrincipal)
    
.PARAMETER TenantId
    Directory (tenant) ID (required for GraphServicePrincipal)
    
.PARAMETER ClientSecret
    Client secret value (required for GraphServicePrincipal)

.EXAMPLE
    # Method 1: Azure CLI
    .\BONUS-create-users-3methods.ps1 -CSVPath "users.csv" -AuthMethod "AzureCLI"
    
    # Method 3: Service Principal
    .\BONUS-create-users-3methods.ps1 -CSVPath "users.csv" -AuthMethod "GraphServicePrincipal" `
        -ClientId "xxx" -TenantId "xxx" -ClientSecret "xxx"

.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
    Date: 2026-02-06
    Portfolio: github.com/OlaKay-Azure/AquaPine-Azure-Infrastructure
    
    BONUS CONTENT: Advanced authentication methods beyond AZ-104 curriculum
    Demonstrates OAuth2 flows, Service Principal, and tool adaptability
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CSVPath,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("AzureCLI", "GraphInteractive", "GraphServicePrincipal")]
    [string]$AuthMethod,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$false)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientSecret,
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultPassword = "AquaPine2026!Temp"
)

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   AQUAPINE CONSULT - BULK USER CREATION" -ForegroundColor Cyan
Write-Host "   Demonstrating 3 Authentication Methods" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Authentication Method: $AuthMethod" -ForegroundColor Magenta
Write-Host "📂 CSV File: $CSVPath" -ForegroundColor Gray
Write-Host ""

# Validate CSV exists
if (-not (Test-Path $CSVPath)) {
    Write-Error "CSV file not found: $CSVPath"
    exit 1
}

# Import CSV
Write-Host "[1] LOADING USER DATA FROM CSV" -ForegroundColor Green
try {
    $users = Import-Csv -Path $CSVPath
    Write-Host "    ✅ Loaded $($users.Count) users from CSV" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Error "Failed to import CSV: $_"
    exit 1
}

# Validate required columns
$requiredColumns = @("DisplayName", "GivenName", "Surname", "UserPrincipalName", "Department", "JobTitle", "Location")
$csvColumns = $users[0].PSObject.Properties.Name

foreach ($col in $requiredColumns) {
    if ($csvColumns -notcontains $col) {
        Write-Error "CSV missing required column: $col"
        exit 1
    }
}

Write-Host "    ✅ CSV structure validated" -ForegroundColor Green
Write-Host ""

#region Authentication

Write-Host "[2] AUTHENTICATING - METHOD: $AuthMethod" -ForegroundColor Green

switch ($AuthMethod) {
    "AzureCLI" {
        Write-Host "    🔧 Azure CLI Authentication" -ForegroundColor Cyan
        Write-Host "    - Cross-platform command-line tool" -ForegroundColor Gray
        Write-Host "    - Works with personal Microsoft accounts" -ForegroundColor Gray
        Write-Host "    - Requires interactive sign-in (az login)" -ForegroundColor Gray
        Write-Host ""
        
        # Verify Azure CLI is authenticated
        $azAccount = az account show 2>$null | ConvertFrom-Json
        if (-not $azAccount) {
            Write-Host "    ❌ Not authenticated to Azure CLI" -ForegroundColor Red
            Write-Host "    Run: az login" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "    ✅ Authenticated as: $($azAccount.user.name)" -ForegroundColor Green
        Write-Host "    ✅ Tenant: $($azAccount.tenantId)" -ForegroundColor Green
        Write-Host ""
    }
    
    "GraphInteractive" {
        Write-Host "    🔧 Microsoft Graph Interactive Authentication" -ForegroundColor Cyan
        Write-Host "    - Delegated permissions (user context)" -ForegroundColor Gray
        Write-Host "    - Browser-based sign-in and consent" -ForegroundColor Gray
        Write-Host "    - ⚠️  Limited with personal accounts" -ForegroundColor Yellow
        Write-Host ""
        
        try {
            # Import Graph modules (avoiding conflicts)
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Import-Module Microsoft.Graph.Users -ErrorAction Stop
            
            # Connect interactively
            Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome
            
            $context = Get-MgContext
            Write-Host "    ✅ Authenticated as: $($context.Account)" -ForegroundColor Green
            Write-Host "    ✅ Scopes: $($context.Scopes -join ', ')" -ForegroundColor Green
            Write-Host ""
            
        } catch {
            Write-Host "    ❌ Interactive authentication failed" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Red
            Write-Host ""
            Write-Host "    This is expected with personal Microsoft accounts." -ForegroundColor Yellow
            Write-Host "    Use -AuthMethod 'GraphServicePrincipal' instead." -ForegroundColor Yellow
            exit 1
        }
    }
    
    "GraphServicePrincipal" {
        Write-Host "    🔧 Microsoft Graph Service Principal Authentication" -ForegroundColor Cyan
        Write-Host "    - Application permissions (app-only context)" -ForegroundColor Gray
        Write-Host "    - Non-interactive (client credentials flow)" -ForegroundColor Gray
        Write-Host "    - ✅ Works with personal Microsoft accounts" -ForegroundColor Green
        Write-Host ""
        
        # Validate required parameters
        if (-not $ClientId -or -not $TenantId -or -not $ClientSecret) {
            Write-Error "Service Principal method requires: -ClientId, -TenantId, -ClientSecret"
            exit 1
        }
        
        try {
            # Import Graph modules (fresh session to avoid conflicts)
            Remove-Module Microsoft.Graph.* -ErrorAction SilentlyContinue
            Import-Module Microsoft.Graph.Authentication -RequiredVersion 2.35.1 -ErrorAction Stop
            Import-Module Microsoft.Graph.Users -ErrorAction Stop
            
            Write-Host "    Connecting with Application ID: $ClientId" -ForegroundColor Gray
            
            # Convert secret to SecureString
            $SecureClientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
            $ClientSecretCredential = New-Object System.Management.Automation.PSCredential($ClientId, $SecureClientSecret)
            
            # Connect
            Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome
            
            $context = Get-MgContext
            Write-Host "    ✅ Authenticated as: $($context.AppName)" -ForegroundColor Green
            Write-Host "    ✅ Auth Type: $($context.AuthType)" -ForegroundColor Green
            Write-Host "    ✅ Scopes: $($context.Scopes -join ', ')" -ForegroundColor Green
            Write-Host ""
            
        } catch {
            Write-Host "    ❌ Service Principal authentication failed" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Red
            Write-Host ""
            Write-Host "    Troubleshooting:" -ForegroundColor Yellow
            Write-Host "    1. Verify ClientId, TenantId, ClientSecret are correct" -ForegroundColor Gray
            Write-Host "    2. Verify API permissions granted with admin consent" -ForegroundColor Gray
            Write-Host "    3. Verify client secret has not expired" -ForegroundColor Gray
            exit 1
        }
    }
}

#endregion

#region User Creation

Write-Host "[3] CREATING USERS" -ForegroundColor Green
Write-Host ""
$successCount = 0
$failCount = 0
$skippedCount = 0
$results = @()
foreach ($user in $users) {
    $upn = $user.UserPrincipalName
    Write-Host "    Processing: ((
(user.DisplayName) ($upn)" -ForegroundColor Cyan

# Create password profile (hashtable for Microsoft Graph)
$passwordProfile = @{
    Password = $DefaultPassword
    ForceChangePasswordNextSignIn = $true
}

try {
    switch ($AuthMethod) {
        "AzureCLI" {
            # Check if user already exists
            $existingUser = az ad user show --id $upn 2>$null
            if ($existingUser) {
                Write-Host "       ⚠️  User already exists - skipping" -ForegroundColor Yellow
                $skippedCount++
                
                $results += [PSCustomObject]@{
                    DisplayName = $user.DisplayName
                    UserPrincipalName = $upn
                    Status = "Skipped"
                    Method = $AuthMethod
                    Error = "Already exists"
                }
                continue
            }
            
            # Build mailNickname
            $mailNickname = $upn.Split('@')[0]
            
            # Create user via Azure CLI
            $createResult = az ad user create `
                --display-name $user.DisplayName `
                --user-principal-name $upn `
                --mail-nickname $mailNickname `
                --password $DefaultPassword `
                --force-change-password-next-sign-in true `
                --given-name $user.GivenName `
                --surname $user.Surname `
                --department $user.Department `
                --job-title $user.JobTitle `
                --usage-location "NG" `
                2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "       ✅ Created successfully (Azure CLI)" -ForegroundColor Green
                $successCount++
                
                $results += [PSCustomObject]@{
                    DisplayName = $user.DisplayName
                    UserPrincipalName = $upn
                    Status = "Success"
                    Method = $AuthMethod
                    Error = ""
                }
            } else {
                throw "Azure CLI error: $createResult"
            }
        }
        
        "GraphInteractive" {
            # Check if user exists
            $existingUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
            if ($existingUser) {
                Write-Host "       ⚠️  User already exists - skipping" -ForegroundColor Yellow
                $skippedCount++
                
                $results += [PSCustomObject]@{
                    DisplayName = $user.DisplayName
                    UserPrincipalName = $upn
                    Status = "Skipped"
                    Method = $AuthMethod
                    Error = "Already exists"
                }
                continue
            }
            
            # ✅ FIXED: -AccountEnabled is a switch parameter (no value)
            $newUser = New-MgUser `
                -DisplayName $user.DisplayName `
                -UserPrincipalName $upn `
                -MailNickname ($upn.Split('@')[0]) `
                -GivenName $user.GivenName `
                -Surname $user.Surname `
                -Department $user.Department `
                -JobTitle $user.JobTitle `
                -UsageLocation "NG" `
                -PasswordProfile $passwordProfile `
                -AccountEnabled
            
            Write-Host "       ✅ Created successfully (Microsoft Graph)" -ForegroundColor Green
            $successCount++
            
            $results += [PSCustomObject]@{
                DisplayName = $user.DisplayName
                UserPrincipalName = $upn
                Status = "Success"
                Method = $AuthMethod
                Error = ""
            }
        }
        
        "GraphServicePrincipal" {
            # Check if user exists
            $existingUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
            if ($existingUser) {
                Write-Host "       ⚠️  User already exists - skipping" -ForegroundColor Yellow
                $skippedCount++
                
                $results += [PSCustomObject]@{
                    DisplayName = $user.DisplayName
                    UserPrincipalName = $upn
                    Status = "Skipped"
                    Method = $AuthMethod
                    Error = "Already exists"
                }
                continue
            }
            
            # ✅ FIXED: -AccountEnabled is a switch parameter (no value)
            $newUser = New-MgUser `
                -DisplayName $user.DisplayName `
                -UserPrincipalName $upn `
                -MailNickname ($upn.Split('@')[0]) `
                -GivenName $user.GivenName `
                -Surname $user.Surname `
                -Department $user.Department `
                -JobTitle $user.JobTitle `
                -UsageLocation "NG" `
                -PasswordProfile $passwordProfile `
                -AccountEnabled
            
            Write-Host "       ✅ Created successfully (Service Principal)" -ForegroundColor Green
            $successCount++
            
            $results += [PSCustomObject]@{
                DisplayName = $user.DisplayName
                UserPrincipalName = $upn
                Status = "Success"
                Method = $AuthMethod
                Error = ""
            }
        }
    }
    
} catch {
    Write-Host "       ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
    $failCount++
    
    $results += [PSCustomObject]@{
        DisplayName = $user.DisplayName
        UserPrincipalName = $upn
        Status = "Failed"
        Method = $AuthMethod
        Error = $_.Exception.Message
    }
}
}
#endregion

#region Summary

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   USER CREATION SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Authentication Method: $AuthMethod" -ForegroundColor Magenta
Write-Host ""
Write-Host "✅ Successful: $successCount" -ForegroundColor Green
Write-Host "⚠️  Skipped (already exist): $skippedCount" -ForegroundColor Yellow
Write-Host "❌ Failed: $failCount" -ForegroundColor Red
Write-Host "📊 Total processed: $($users.Count)" -ForegroundColor Cyan
Write-Host ""

# Display results table
if ($results.Count -gt 0) {
    Write-Host "Detailed Results:" -ForegroundColor Cyan
    $results | Format-Table DisplayName, UserPrincipalName, Status, Method -AutoSize
}

# Export results to CSV
$resultsPath = Join-Path (Split-Path $CSVPath -Parent) "user-creation-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$results | Export-Csv -Path $resultsPath -NoTypeInformation
Write-Host "📁 Results exported to: $resultsPath" -ForegroundColor Gray
Write-Host ""

#endregion

#region Cleanup

if ($AuthMethod -in @("GraphInteractive", "GraphServicePrincipal")) {
    Disconnect-MgGraph
    Write-Host "Disconnected from Microsoft Graph" -ForegroundColor Yellow
}

#endregion

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   PORTFOLIO DEMONSTRATION COMPLETE" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎤 INTERVIEW TALKING POINT:" -ForegroundColor Magenta
Write-Host '   "I demonstrated 3 authentication methods for Microsoft Entra ID:' -ForegroundColor Gray
Write-Host '   Azure CLI for personal account compatibility, Microsoft Graph' -ForegroundColor Gray
Write-Host '   interactive for work accounts, and Service Principal with OAuth2' -ForegroundColor Gray
Write-Host '   client credentials flow for production automation. This shows' -ForegroundColor Gray
Write-Host '   understanding of delegated vs. application permissions and tool' -ForegroundColor Gray
Write-Host '   adaptability when facing authentication constraints."' -ForegroundColor Gray
Write-Host ""