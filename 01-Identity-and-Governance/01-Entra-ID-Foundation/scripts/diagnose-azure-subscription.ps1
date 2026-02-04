<#
.SYNOPSIS
    Diagnose Azure subscription and provider issues
    
.DESCRIPTION
    Checks Azure subscription status, resource provider registrations,
    and permissions to help troubleshoot deployment issues
    
.NOTES
    Author: Olatunde Ogunti
    Company: AQUAPINE CONSULT
#>

[CmdletBinding()]
param()

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AZURE SUBSCRIPTION DIAGNOSTICS                " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Check connection
    Write-Host "1. Checking Azure connection..." -ForegroundColor Yellow
    $context = Get-AzContext
    
    if (-not $context) {
        Write-Host "   ❌ Not connected to Azure" -ForegroundColor Red
        Write-Host "   Run: Connect-AzAccount" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "   ✅ Connected" -ForegroundColor Green
    Write-Host "   Account: $($context.Account.Id)" -ForegroundColor Gray
    Write-Host "   Subscription: $($context.Subscription.Name)" -ForegroundColor Gray
    Write-Host "   Subscription ID: $($context.Subscription.Id)" -ForegroundColor Gray
    Write-Host ""
    
    # Check subscription details
    Write-Host "2. Checking subscription details..." -ForegroundColor Yellow
    $subscription = Get-AzSubscription -SubscriptionId $context.Subscription.Id
    
    Write-Host "   Name: $($subscription.Name)" -ForegroundColor Gray
    Write-Host "   State: $($subscription.State)" -ForegroundColor $(if ($subscription.State -eq "Enabled") { "Green" } else { "Red" })
    Write-Host "   Tenant: $($subscription.TenantId)" -ForegroundColor Gray
    Write-Host ""
    
    if ($subscription.State -ne "Enabled") {
        Write-Host "   ⚠️  WARNING: Subscription is not enabled!" -ForegroundColor Red
        Write-Host "   This could be why storage account creation is failing." -ForegroundColor Yellow
    }
    
    # Check resource providers
    Write-Host "3. Checking Resource Provider registration..." -ForegroundColor Yellow
    
    $providers = @(
        "Microsoft.Storage",
        "Microsoft.Resources",
        "Microsoft.Authorization"
    )
    
    foreach ($providerName in $providers) {
        $provider = Get-AzResourceProvider -ProviderNamespace $providerName
        $state = $provider.RegistrationState
        
        $color = if ($state -eq "Registered") { "Green" } else { "Red" }
        Write-Host "   $providerName : $state" -ForegroundColor $color
        
        if ($state -ne "Registered") {
            Write-Host "      ⚠️  Provider not registered!" -ForegroundColor Yellow
            Write-Host "      To fix: Register-AzResourceProvider -ProviderNamespace $providerName" -ForegroundColor Gray
        }
    }
    Write-Host ""
    
    # Check permissions
    Write-Host "4. Checking your role assignments..." -ForegroundColor Yellow
    
    $roleAssignments = Get-AzRoleAssignment -SignInName $context.Account.Id -ErrorAction SilentlyContinue
    
    if ($roleAssignments) {
        foreach ($role in $roleAssignments | Select-Object -First 5) {
            Write-Host "   $($role.RoleDefinitionName) on $($role.Scope)" -ForegroundColor Gray
        }
        
        $hasOwnerOrContributor = $roleAssignments | Where-Object { 
            $_.RoleDefinitionName -eq "Owner" -or 
            $_.RoleDefinitionName -eq "Contributor" 
        }
        
        if (-not $hasOwnerOrContributor) {
            Write-Host "   ⚠️  WARNING: You don't have Owner or Contributor role!" -ForegroundColor Red
            Write-Host "   This could prevent storage account creation." -ForegroundColor Yellow
        }
        else {
            Write-Host "   ✅ You have sufficient permissions" -ForegroundColor Green
        }
    }
    else {
        Write-Host "   ⚠️  Could not retrieve role assignments" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Test storage account name availability
    Write-Host "5. Testing storage account name availability..." -ForegroundColor Yellow
    
    $testName = "aquapinetest$(Get-Random -Minimum 1000 -Maximum 9999)"
    
    try {
        $availability = Get-AzStorageAccountNameAvailability -Name $testName
        
        if ($availability.NameAvailable) {
            Write-Host "   ✅ Storage account names are available" -ForegroundColor Green
        }
        else {
            Write-Host "   ⚠️  Name: $testName" -ForegroundColor Yellow
            Write-Host "   Reason: $($availability.Reason)" -ForegroundColor Yellow
            Write-Host "   Message: $($availability.Message)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "   ❌ Error checking name availability: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
    
    # List existing storage accounts
    Write-Host "6. Checking existing storage accounts..." -ForegroundColor Yellow
    
    try {
        $storageAccounts = Get-AzStorageAccount -ErrorAction Stop
        
        if ($storageAccounts) {
            Write-Host "   Found $($storageAccounts.Count) existing storage account(s)" -ForegroundColor Green
            
            foreach ($sa in $storageAccounts | Select-Object -First 3) {
                Write-Host "   - $($sa.StorageAccountName) in $($sa.ResourceGroupName)" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "   No existing storage accounts found" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   ❌ Error listing storage accounts: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   This suggests a subscription/permission issue!" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Summary and recommendations
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  RECOMMENDATIONS                               " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if Microsoft.Storage is registered
    $storageProvider = Get-AzResourceProvider -ProviderNamespace "Microsoft.Storage"
    
    if ($storageProvider.RegistrationState -ne "Registered") {
        Write-Host "🔧 ACTION REQUIRED: Register Microsoft.Storage provider" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Run this command:" -ForegroundColor White
        Write-Host "   Register-AzResourceProvider -ProviderNamespace Microsoft.Storage" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   Then wait 2-3 minutes and run:" -ForegroundColor White
        Write-Host "   Get-AzResourceProvider -ProviderNamespace Microsoft.Storage" -ForegroundColor Cyan
        Write-Host ""
    }
    else {
        Write-Host "✅ Microsoft.Storage provider is registered" -ForegroundColor Green
        Write-Host ""
        Write-Host "   The issue might be:" -ForegroundColor Yellow
        Write-Host "   1. Temporary Azure service issue" -ForegroundColor Gray
        Write-Host "   2. Student subscription limitations" -ForegroundColor Gray
        Write-Host "   3. Network/firewall blocking Azure API" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   Try these alternatives:" -ForegroundColor Yellow
        Write-Host "   1. Use Azure Portal to create storage accounts manually" -ForegroundColor Cyan
        Write-Host "   2. Try Azure CLI instead: az storage account create" -ForegroundColor Cyan
        Write-Host "   3. Wait 30 minutes and try PowerShell again" -ForegroundColor Cyan
        Write-Host ""
    }
}
catch {
    Write-Host ""
    Write-Host "❌ Diagnostic failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}