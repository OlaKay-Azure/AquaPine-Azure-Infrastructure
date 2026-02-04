# =====================================================
# CHECK WHICH MICROSOFT GRAPH POWERSHELL APP YOU'RE USING
# =====================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  CHECKING YOUR GRAPH APP CONFIGURATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Try to connect and see which app ID is being used
Write-Host "Step 1: Connecting to check app ID..." -ForegroundColor Yellow
Write-Host "(This might timeout - that's okay, we just need to see the app ID)" -ForegroundColor Gray

try {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    
    # Connect with minimal scope
    Connect-MgGraph -Scopes "User.Read" -NoWelcome -ErrorAction Stop
    
    $context = Get-MgContext
    
    if ($null -ne $context) {
        Write-Host "`n✓ Connection successful!" -ForegroundColor Green
        Write-Host "`nCurrent Connection Details:" -ForegroundColor Cyan
        Write-Host "===========================" -ForegroundColor Cyan
        Write-Host "Client ID (App ID): $($context.ClientId)" -ForegroundColor Yellow
        Write-Host "Tenant ID:          $($context.TenantId)" -ForegroundColor White
        Write-Host "Account:            $($context.Account)" -ForegroundColor White
        Write-Host "Auth Type:          $($context.AuthType)" -ForegroundColor White
        
        # Check if it's the standard public app or a custom one
        if ($context.ClientId -eq "14d82eec-204b-4c2f-b7e8-296a70dab67e") {
            Write-Host "`nℹ️  You're using the STANDARD Microsoft Graph PowerShell app" -ForegroundColor Cyan
            $appToUse = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
        }
        else {
            Write-Host "`nℹ️  You're using a CUSTOM or REGIONAL Graph PowerShell app" -ForegroundColor Yellow
            Write-Host "   This is okay! Just use YOUR app ID for consent." -ForegroundColor Gray
            $appToUse = $context.ClientId
        }
    }
}
catch {
    Write-Host "`n⚠️  Could not establish connection: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   But we can still determine your app ID from previous connection attempts..." -ForegroundColor Gray
    
    # Try to get from any cached context
    $context = Get-MgContext
    if ($null -ne $context -and $null -ne $context.ClientId) {
        $appToUse = $context.ClientId
        Write-Host "`nℹ️  Found app ID from previous connection:" -ForegroundColor Cyan
        Write-Host "   Client ID: $appToUse" -ForegroundColor Yellow
    }
    else {
        Write-Host "`nℹ️  No cached context found. Using standard app ID." -ForegroundColor Cyan
        $appToUse = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  INSTRUCTIONS FOR YOUR SPECIFIC APP" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "YOUR APP ID (Client ID): " -NoNewline
Write-Host "$appToUse" -ForegroundColor Yellow

Write-Host "`nFOLLOW THESE STEPS IN AZURE PORTAL:" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

Write-Host "`n1. Go to: " -NoNewline -ForegroundColor White
Write-Host "https://portal.azure.com" -ForegroundColor Yellow

Write-Host "`n2. Navigate to:" -ForegroundColor White
Write-Host "   Microsoft Entra ID → App registrations → All applications" -ForegroundColor Gray

Write-Host "`n3. Search for app with ID:" -ForegroundColor White
Write-Host "   $appToUse" -ForegroundColor Yellow
Write-Host "   (Copy this ID and paste it in the search box)" -ForegroundColor Gray

Write-Host "`n4. Click on the app when you find it" -ForegroundColor White

Write-Host "`n5. In the left menu, click:" -ForegroundColor White
Write-Host "   API permissions" -ForegroundColor Gray

Write-Host "`n6. Add permissions if needed:" -ForegroundColor White
Write-Host "   If you don't see 'User.ReadWrite.All' and 'Directory.ReadWrite.All':" -ForegroundColor Gray
Write-Host "   a. Click '+ Add a permission'" -ForegroundColor Gray
Write-Host "   b. Click 'Microsoft Graph'" -ForegroundColor Gray
Write-Host "   c. Click 'Delegated permissions'" -ForegroundColor Gray
Write-Host "   d. Search and add: User.ReadWrite.All" -ForegroundColor Gray
Write-Host "   e. Search and add: Directory.ReadWrite.All" -ForegroundColor Gray
Write-Host "   f. Click 'Add permissions'" -ForegroundColor Gray

Write-Host "`n7. GRANT ADMIN CONSENT:" -ForegroundColor Yellow
Write-Host "   At the top, click the button:" -ForegroundColor Gray
Write-Host "   'Grant admin consent for [Your Organization]'" -ForegroundColor Cyan
Write-Host "   Then click 'Yes'" -ForegroundColor Gray

Write-Host "`n8. Verify:" -ForegroundColor White
Write-Host "   Each permission should show a green checkmark ✓" -ForegroundColor Gray
Write-Host "   Status: 'Granted for [Your Organization]'" -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ALTERNATIVE: DIRECT ADMIN CONSENT URL" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$adminConsentUrl = "https://login.microsoftonline.com/organizations/v2.0/adminconsent?client_id=$appToUse&scope=User.ReadWrite.All%20Directory.ReadWrite.All"

Write-Host "You can also try opening this URL in your browser:" -ForegroundColor White
Write-Host $adminConsentUrl -ForegroundColor Yellow
Write-Host "`n(Copy the URL above and paste it in your browser while signed into Azure)" -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  AFTER GRANTING CONSENT, RUN THIS:" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "# Test the connection" -ForegroundColor Gray
Write-Host "Disconnect-MgGraph" -ForegroundColor Yellow
Write-Host "Connect-MgGraph -Scopes 'User.ReadWrite.All','Directory.ReadWrite.All'" -ForegroundColor Yellow
Write-Host "Get-MgContext | Select-Object ClientId, Account, Scopes" -ForegroundColor Yellow

Write-Host ""