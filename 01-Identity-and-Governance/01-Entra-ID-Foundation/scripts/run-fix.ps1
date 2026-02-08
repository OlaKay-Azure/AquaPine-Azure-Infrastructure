# ==================================================
# COMPLETE FIX: Run AquaPine User Creation Script
# ==================================================

# Step 1: Clean slate - disconnect any existing sessions
Write-Host "Step 1: Cleaning existing sessions..." -ForegroundColor Cyan
Disconnect-MgGraph -ErrorAction SilentlyContinue

# Step 2: Connect with proper scopes and admin consent
Write-Host "Step 2: Connecting to Microsoft Graph with admin consent..." -ForegroundColor Cyan
Write-Host "  → A browser will open for authentication" -ForegroundColor Yellow
Write-Host "  → Sign in with a Global Administrator account" -ForegroundColor Yellow
Write-Host "  → Accept the permission consent prompt" -ForegroundColor Yellow

Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.ReadWrite.All" -UseDeviceCode

# Step 3: Verify connection and scopes
Write-Host "`nStep 3: Verifying connection..." -ForegroundColor Cyan
$context = Get-MgContext

if ($null -eq $context) {
    Write-Host "ERROR: Not connected to Microsoft Graph!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Connected successfully!" -ForegroundColor Green
Write-Host "  Tenant ID: $($context.TenantId)" -ForegroundColor Gray
Write-Host "  Account: $($context.Account)" -ForegroundColor Gray
Write-Host "  Scopes: $($context.Scopes -join ', ')" -ForegroundColor Gray

# Check for required scopes
$requiredScopes = @("User.ReadWrite.All", "Directory.ReadWrite.All")
$missingScopes = $requiredScopes | Where-Object { $_ -notin $context.Scopes }

if ($missingScopes.Count -gt 0) {
    Write-Host "`nERROR: Missing required scopes: $($missingScopes -join ', ')" -ForegroundColor Red
    Write-Host "  You may need a Global Administrator to grant admin consent" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ All required scopes are present!" -ForegroundColor Green

# Step 4: Test the connection with a simple query
Write-Host "`nStep 4: Testing Graph API access..." -ForegroundColor Cyan
try {
    $testUser = Get-MgUser -Top 1 -ErrorAction Stop
    Write-Host "✓ Graph API is accessible!" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Cannot access Graph API: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 5: Locate CSV file
Write-Host "`nStep 5: Locating CSV file..." -ForegroundColor Cyan
$csvPath = Get-ChildItem -Path "C:\Git\AquaPine-Azure-Infrastructure" -Filter "aquapine-users.csv" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName

if (-not $csvPath) {
    Write-Host "ERROR: aquapine-users.csv not found!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ CSV found: $csvPath" -ForegroundColor Green

# Step 6: Run the script
Write-Host "`nStep 6: Running user creation script..." -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Convert default password to SecureString (for the fixed script version)
$securePassword = ConvertTo-SecureString "AquaPine2025!" -AsPlainText -Force

# Run the script (assuming you've applied the fixes)
.\aquapine-bulk-user-creation.ps1 -CsvFilePath $csvPath -DefaultPassword $securePassword