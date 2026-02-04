# Test Microsoft Graph Authentication
Write-Host "Testing Device Code Authentication..." -ForegroundColor Cyan
Write-Host ""

try {
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All" -UseDeviceCode -NoWelcome
    
    Write-Host "✅ Authentication successful!" -ForegroundColor Green
    Write-Host ""
    
    $context = Get-MgContext
    Write-Host "Account: $($context.Account)" -ForegroundColor White
    Write-Host "Tenant: $($context.TenantId)" -ForegroundColor White
    Write-Host "Scopes: $($context.Scopes -join ', ')" -ForegroundColor White
    
    Write-Host ""
    Write-Host "You can now run the main script!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Authentication failed: $_" -ForegroundColor Red
}
