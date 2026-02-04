# AQUAPINE CONSULT - Azure for Students Troubleshooting Guide

**Author:** Olatunde Ogunti  
**Purpose:** Document solutions to common issues encountered during Azure for Students identity management deployments  
**Audience:** Students, junior administrators, or anyone using personal Microsoft accounts with Azure

---

## 🎯 Overview

This guide documents real-world troubleshooting scenarios encountered during the AQUAPINE CONSULT identity infrastructure deployment. All solutions have been tested and validated on Azure for Students subscriptions with personal Microsoft accounts (@outlook.com, @hotmail.com, @live.com).

**Why This Guide Exists:**  
Most Azure tutorials assume enterprise Entra ID tenants with work/school accounts. Personal accounts have different limitations and authentication patterns. This guide fills that documentation gap.

---

## 🔧 Issue #1: Microsoft Graph PowerShell Authentication Failure

### Symptom
```powershell
PS> Connect-MgGraph -Scopes "User.ReadWrite.All"
Connect-MgGraph: AADSTS50020: User account 'user@outlook.com' from identity provider 
'live.com' does not exist in tenant 'Default Directory'
```

### Root Cause
Personal Microsoft accounts (@outlook.com, @hotmail.com, @live.com) used with Azure for Students do not have full Entra ID tenant capabilities. Microsoft Graph interactive authentication requires work/school accounts.

### Solution Option 1: Azure CLI (Recommended)
```powershell
# Login with Azure CLI (supports personal accounts)
az login

# Create user
az ad user create `
  --display-name "John Doe" `
  --user-principal-name "john.doe@yourdomain.onmicrosoft.com" `
  --password "TempPass123!" `
  --force-change-password-next-sign-in

# Create group
az ad group create `
  --display-name "IT-Security" `
  --mail-nickname "ITSecurity"
```

### Solution Option 2: App Registration with Service Principal (Advanced)
```powershell
# Create app registration (one-time setup)
# Azure Portal → Entra ID → App registrations → New registration

# Then authenticate with client credentials
$clientId = "your-app-id"
$clientSecret = "your-secret" | ConvertTo-SecureString -AsPlainText -Force
$tenantId = "your-tenant-id"

Connect-MgGraph -ClientId $clientId -ClientSecret $clientSecret -TenantId $tenantId

# Now Microsoft Graph commands work
New-MgUser -DisplayName "John Doe" -UserPrincipalName "john.doe@yourdomain.onmicrosoft.com" ...
```

### Prevention
For Azure for Students projects:
- **Default to Azure CLI** for user/group management
- **Use Azure PowerShell (Connect-AzAccount)** for RBAC and resource management
- **Use Microsoft Graph with service principal** only when automation/CI-CD required

---

## 🔧 Issue #2: JSON Escaping in PowerShell with Azure CLI

### Symptom
Users created but missing properties:
```powershell
# Script executes without errors
az ad user create --display-name "John Doe" --job-title "Manager" ...

# But in Azure Portal:
# ✅ DisplayName: "John Doe"
# ✅ UserPrincipalName: "john.doe@..."
# ❌ JobTitle: (empty)
# ❌ Department: (empty)
# ❌ OfficeLocation: (empty)
```

### Root Cause
PowerShell's quote escaping interferes with Azure CLI's JSON parsing when using `--body` parameter with complex nested JSON.
```powershell
# PowerShell interprets quotes before Azure CLI sees them
$json = '{"jobTitle":"Manager","department":"IT"}' # PowerShell mangles this
az ad user update --id $userId --body $json # Azure CLI receives malformed JSON
```

### Solution: Two-Phase Approach
```powershell
# Phase 1: Create user with minimal properties (works reliably)
az ad user create `
  --display-name $user.DisplayName `
  --user-principal-name $user.UserPrincipalName `
  --password $defaultPassword `
  --force-change-password-next-sign-in

# Phase 2: Update properties using REST API with file-based JSON
$userProperties = @{
    jobTitle = $user.JobTitle
    department = $user.Department
    officeLocation = $user.OfficeLocation
    mobilePhone = $user.PhoneNumber
} | ConvertTo-Json

# Save to temp file (avoids escaping issues)
$tempFile = [System.IO.Path]::GetTempFileName()
$userProperties | Out-File -FilePath $tempFile -Encoding UTF8

# Update via REST API
az rest --method PATCH `
  --uri "https://graph.microsoft.com/v1.0/users/$userId" `
  --body "@$tempFile"

# Cleanup
Remove-Item $tempFile
```

### Best Practice
For scripts that need to pass JSON to Azure CLI from PowerShell:
1. ✅ Use individual parameters when possible (`--job-title "Manager"` instead of `--body '{"jobTitle":"Manager"}'`)
2. ✅ Write JSON to file, use `@filename` syntax
3. ❌ Avoid inline JSON strings with nested quotes in PowerShell

---

## 🔧 Issue #3: Storage Account Creation - Subscription ID Mismatch

### Symptom
```powershell
PS> New-AzStorageAccount -ResourceGroupName "MyRG" -Name "mystorageacct" ...
New-AzStorageAccount: The subscription 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' 
is not registered for resource type 'Microsoft.Storage/storageAccounts'
```

**BUT** Resource Groups in same subscription created successfully!

### Root Cause
Azure PowerShell context caching issue. Two different subscription IDs active:
- **Get-AzContext** shows one subscription ID
- **New-AzStorageAccount** tries to use a different cached subscription ID

### Diagnostic Steps
```powershell
# 1. Check current context
Get-AzContext | Select-Object Name, Subscription, Tenant

# 2. List all available subscriptions
Get-AzSubscription

# 3. Check resource provider registration
Get-AzResourceProvider -ProviderNamespace Microsoft.Storage | 
  Select-Object ProviderNamespace, RegistrationState

# 4. Verify permissions
Get-AzRoleAssignment -SignInName (Get-AzContext).Account.Id
```

### Solution Option 1: Explicit Subscription Selection
```powershell
# Clear any cached contexts
Disconnect-AzAccount
Clear-AzContext -Force

# Reconnect and explicitly set subscription
Connect-AzAccount

$subscriptionId = (Get-AzContext).Subscription.Id
Set-AzContext -SubscriptionId $subscriptionId

# Verify
Write-Host "Using Subscription: $((Get-AzContext).Subscription.Name)"

# Now create storage account
New-AzStorageAccount -ResourceGroupName "MyRG" -Name "mystorageacct" `
  -Location "southafricanorth" -SkuName "Standard_LRS"
```

### Solution Option 2: Use Azure CLI
```bash
# Login
az login

# List subscriptions
az account list --output table

# Set subscription explicitly
az account set --subscription "Azure for Students"

# Verify
az account show --query "{Name:name, ID:id, State:state}"

# Create storage account (more reliable for student accounts)
az storage account create \
  --resource-group "MyRG" \
  --name "mystorageacct" \
  --location "southafricanorth" \
  --sku "Standard_LRS"
```

### Prevention
**Always** verify subscription context at start of deployment scripts:
```powershell
# Add to beginning of scripts
$context = Get-AzContext
if (-not $context) {
    throw "Not connected to Azure. Run: Connect-AzAccount"
}

Write-Host "Deploying to subscription: $($context.Subscription.Name)" -ForegroundColor Cyan
$confirmation = Read-Host "Proceed? (Y/N)"
if ($confirmation -ne "Y") {
    exit
}
```

---

## 🔧 Issue #4: RBAC Role Assignment Failures

### Symptom
```powershell
PS> New-AzRoleAssignment -ObjectId $groupId -RoleDefinitionName "Owner" ...
New-AzRoleAssignment: The client 'user@outlook.com' with object id 'XXXXX' 
does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write'
```

### Root Cause
Azure for Students subscriptions often have "Contributor" role by default, not "Owner". Contributor role **cannot** assign other roles (lacks RBAC write permissions).

### Verification
```powershell
# Check your role on subscription
$subscriptionId = (Get-AzContext).Subscription.Id
Get-AzRoleAssignment -SignInName (Get-AzContext).Account.Id -Scope "/subscriptions/$subscriptionId"
```

### Solution
If you have Contributor but need to assign RBAC:
1. ✅ Request Owner role (if in lab environment)
2. ✅ Use "User Access Administrator" role (RBAC-specific permissions)
3. ✅ Assign roles at Resource Group level (sometimes less restricted)
```powershell
# Instead of subscription-level Owner:
New-AzRoleAssignment -ObjectId $groupId -RoleDefinitionName "Contributor" `
  -Scope "/subscriptions/$subscriptionId/resourceGroups/MyRG"
```

### For AQUAPINE Project
Changed IT Security group from "Owner" to "Contributor":
```powershell
# ❌ Original (requires Owner permission to assign)
New-AzRoleAssignment -ObjectId $itGroupId -RoleDefinitionName "Owner" -Scope $subscriptionScope

# ✅ Modified (works with Contributor permission)
New-AzRoleAssignment -ObjectId $itGroupId -RoleDefinitionName "Contributor" -Scope $subscriptionScope
```

**Trade-off:** IT Security group can manage resources but cannot assign RBAC roles to other groups. Acceptable for learning environment.

---

## 📋 Quick Reference: When to Use Which Tool

| Task | Azure CLI | Azure PowerShell | Microsoft Graph |
|------|-----------|------------------|-----------------|
| **User Management** | ✅ Recommended | ❌ Complex with personal accounts | ❌ Doesn't work (personal accounts) |
| **Group Management** | ✅ Recommended | ❌ Complex | ❌ Doesn't work |
| **RBAC Assignments** | ✅ Works | ✅ **Preferred** (better syntax) | N/A |
| **Resource Groups** | ✅ Works | ✅ **Preferred** | N/A |
| **Storage Accounts** | ✅ **More Reliable** | ⚠️ Can have issues | N/A |
| **Virtual Machines** | ✅ Works | ✅ **Preferred** | N/A |
| **Script Automation** | ✅ Cross-platform | ✅ Windows-focused | ✅ (with app registration) |

---

## 🎓 Lessons Learned

1. **Have a Backup Plan:** Always know 2-3 ways to accomplish a task in Azure (CLI, PowerShell, Portal)

2. **Test Early:** Before creating 45 users, create 1 test user and validate ALL properties appear correctly

3. **Diagnostic Scripts Are Your Friend:** When something fails, write a diagnostic script before attempting fixes

4. **Document Everything:** Future you (or your teammates) will thank you for detailed troubleshooting notes

5. **Personal Accounts ≠ Work Accounts:** Be aware of authentication and permission differences

---

## 📚 Additional Resources

- [Azure CLI vs Azure PowerShell](https://learn.microsoft.com/en-us/cli/azure/azure-cli-vs-powershell)
- [Microsoft Graph Personal vs Work Accounts](https://learn.microsoft.com/en-us/graph/auth/auth-concepts#account-types)
- [Azure Subscription Limits and Quotas](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits)

---

**Last Updated:** [Date]  
**Tested On:** Azure for Students with Personal Microsoft Account (@outlook.com)  
**Azure CLI Version:** 2.x+  
**PowerShell Version:** 7.x+  
**Azure PowerShell Module:** Az 10.x+