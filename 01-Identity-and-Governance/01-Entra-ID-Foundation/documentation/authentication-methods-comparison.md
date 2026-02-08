# Microsoft Entra ID Authentication Methods Comparison
## AQUAPINE CONSULT - OAuth2 Flows & Tool Adaptability

**Author**: Olatunde Ogunti  
**Date**: 2026-02-06  
**Portfolio**: BONUS Content - Advanced Authentication Concepts

---

## Executive Summary

When deploying Microsoft Entra ID infrastructure for AQUAPINE CONSULT, I encountered authentication limitations with Microsoft Graph PowerShell due to using an Azure for Students personal account instead of a work/school organizational account.

Rather than accepting this constraint, I researched and implemented **three different authentication methods** to accomplish user provisioning:

1. **Azure CLI** (immediate workaround)
2. **Microsoft Graph Interactive** (for educational understanding)
3. **Microsoft Graph Service Principal** (production-standard solution)

This demonstrates understanding of **OAuth 2.0 flows**, **delegated vs. application permissions**, and **tool adaptability** when facing real-world constraints.

---

## Authentication Methods Detailed Comparison

### Method 1: Azure CLI (Cross-Platform Command-Line)

**Technical Approach**:
```bash
az login  # Interactive browser authentication
az ad user create --display-name "..." --user-principal-name "..."
```

**Authentication Flow**:
```
User → Browser Sign-In → Azure AD OAuth Token → Azure CLI → REST API
```

**OAuth 2.0 Grant Type**: Authorization Code (delegated, interactive)

**Strengths**:
- ✅ Works with personal Microsoft accounts
- ✅ Cross-platform (Windows, Linux, macOS)
- ✅ Direct Microsoft Entra ID commands (`az ad`)
- ✅ No app registration required
- ✅ Simple for manual/scripted operations

**Limitations**:
- ❌ Less programmatic (JSON parsing required)
- ❌ Requires interactive sign-in (not ideal for unattended automation)
- ❌ PowerShell users prefer native objects over CLI JSON output

**Use Cases**:
- ✅ Manual operations during initial deployment
- ✅ Personal accounts with Azure for Students
- ✅ Quick scripting without authentication complexity
- ❌ Scheduled/unattended automation (requires persistent auth)

**AQUAPINE Implementation**:
- Used for initial 45-user bulk provisioning
- Scripted in PowerShell with JSON handling
- Documented in portfolio as "Method 1"

---

### Method 2: Microsoft Graph PowerShell (Interactive Delegated)

**Technical Approach**:
```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All"  # Browser consent
New-MgUser -DisplayName "..." -UserPrincipalName "..."
```

**Authentication Flow**:
```
User → Browser Consent → Azure AD → Delegated Token → Microsoft Graph SDK → Graph API
```

**OAuth 2.0 Grant Type**: Authorization Code with Delegated Permissions

**Strengths**:
- ✅ Native PowerShell objects (no JSON parsing)
- ✅ Rich SDK (cmdlets for all Graph operations)
- ✅ Type-safe parameters and IntelliSense
- ✅ Microsoft-recommended approach

**Limitations**:
- ❌ **Requires work/school account** (organizational tenant admin)
- ❌ **Personal accounts have limited delegated permission support**
- ❌ Requires interactive consent for each scope
- ❌ User context (actions performed "as you")

**Use Cases**:
- ✅ Development/testing with organizational accounts
- ✅ Enterprise environments with Conditional Access policies
- ❌ **Personal Microsoft accounts** (Azure for Students) — **This is my constraint**

**AQUAPINE Challenge**:
- Initial attempt failed: "This account type is not supported"
- Personal account (k.ogunti@outlook.com) lacks organizational consent capability
- Educational value: Documented as "Method 2 - Not Viable" in portfolio

---

### Method 3: Microsoft Graph Service Principal (Application Permissions)

**Technical Approach**:
```powershell
# One-time setup: Create App Registration, grant API permissions, admin consent

# Authentication
$cred = New-Object PSCredential($clientId, $secureSecret)
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $cred

# User creation (same as Method 2)
New-MgUser -DisplayName "..." -UserPrincipalName "..."
```

**Authentication Flow**:
```
App Registration → Client Credentials (ID + Secret) → Azure AD → Application Token → Graph SDK → Graph API
```

**OAuth 2.0 Grant Type**: **Client Credentials** (non-interactive, app-only)

**Permissions Model**: **Application Permissions** (not delegated)
- Actions performed by the APPLICATION, not a user
- Requires admin consent (one-time)
- Operates organization-wide

**Strengths**:
- ✅ **Works with personal Microsoft accounts** (tenant-level consent)
- ✅ Non-interactive (unattended automation, scheduled tasks)
- ✅ Production-standard approach (same as enterprise CI/CD)
- ✅ Full Microsoft Graph SDK support (PowerShell native objects)
- ✅ Granular permission control (grant only what's needed)
- ✅ Certificate-based auth option (more secure than secrets)

**Considerations**:
- ⚠️ Higher privilege (application acts organization-wide, not user-scoped)
- ⚠️ Client secret must be secured (never commit to Git, use Key Vault)
- ⚠️ Requires one-time setup (App Registration, permissions, consent)
- ⚠️ Secret rotation required (expires after 12-24 months)

**Use Cases**:
- ✅ **Bulk operations** (user provisioning, group management) — **My scenario**
- ✅ **Scheduled automation** (nightly tasks, monitoring)
- ✅ **CI/CD pipelines** (infrastructure as code deployments)
- ✅ **Production environments** (enterprise standard)

**AQUAPINE Implementation**:
- Created App Registration: `AQUAPINE-UserManagement-ServicePrincipal`
- Granted API permissions: User.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All
- Admin consent: Self-granted (I'm Global Administrator)
- Client secret: 12-month expiration, stored securely
- Successfully created test users via Microsoft Graph PowerShell
- **Solved authentication constraint permanently**

---

## OAuth 2.0 Flows Comparison

| OAuth Flow | User Interaction | Token Type | Use Case |
|------------|------------------|------------|----------|
| **Authorization Code** (Azure CLI, Graph Interactive) | Required (browser) | Delegated | Development, manual operations |
| **Client Credentials** (Service Principal) | None | Application | Automation, scheduled tasks |

**Delegated Permissions** = "I (user) give this app permission to act on my behalf"  
**Application Permissions** = "This app has permission to act on behalf of the organization"

**Key Difference for AQUAPINE**:
- Delegated: Personal account = limited Graph API access ❌
- Application: Personal account can grant tenant-level consent ✅

---

## Security Considerations

### Client Secret Management

**❌ NEVER**:
- Commit secrets to Git repositories
- Store secrets in plain text files
- Share secrets in emails or chat
- Hardcode secrets in scripts

**✅ ALWAYS**:
- Use Azure Key Vault (production standard)
- Use PowerShell SecureString / EncryptedXML (local development)
- Use environment variables (temporary testing only)
- Rotate secrets before expiration
- Audit secret access

**AQUAPINE Implementation**:
- Development: PowerShell EncryptedXML (user-scoped encryption)
- Production (future): Azure Key Vault with Managed Identity
- Git: `.gitignore` includes `*credentials*`, `*secret*` patterns

### Application Permission Scope

**Principle of Least Privilege**:
- Only grant permissions the application actually needs
- Regularly audit and remove unused permissions
- Use separate service principals for different workloads

**AQUAPINE Permissions Granted**:
- `User.ReadWrite.All` — Required for user provisioning
- `Group.ReadWrite.All` — Required for security group management
- `Directory.ReadWrite.All` — Required for organizational structure changes

**NOT Granted** (examples of excessive permissions):
- `RoleManagement.ReadWrite.Directory` — Not needed (manual role assignments)
- `Application.ReadWrite.All` — Not needed (single app registration)
- `Mail.ReadWrite` — Not needed (no mailbox operations in scripts)

---

## Performance & Reliability Comparison

| Method | Speed | Reliability | Error Handling | Logging |
|--------|-------|-------------|----------------|---------|
| Azure CLI | Moderate | High | CLI error codes | stdout/stderr |
| Graph Interactive | Fast | Medium | PowerShell exceptions | Verbose streams |
| Graph Service Principal | Fast | **High** | PowerShell exceptions | Verbose streams |

**Service Principal Advantages**:
- No browser redirects (faster execution)
- No user interaction (reliable in automation)
- Rich error objects (better troubleshooting)
- Consistent performance (not dependent on user session)

---

## Code Quality Comparison

### Azure CLI (Method 1)
```powershell
# JSON escaping challenges
$jsonUser = @{
    displayName = $user.DisplayName
    userPrincipalName = $user.UserPrincipalName
    # ... escape special characters
} | ConvertTo-Json -Compress

# CLI execution with error handling
$result = az ad user create --parameters $jsonUser 2>&1
if ($LASTEXITCODE -ne 0) {
    # Parse stderr for errors
}
```

**Issues**:
- JSON escaping complexity
- Error messages in stderr (harder to parse)
- Exit codes instead of exceptions

---

### Microsoft Graph Service Principal (Method 3)
```powershell
# Native PowerShell objects
try {
    $newUser = New-MgUser `
        -DisplayName $user.DisplayName `
        -UserPrincipalName $user.UserPrincipalName `
        -PasswordProfile $passwordProfile `
        -AccountEnabled $true
    
    Write-Host "✅ Created: $($newUser.DisplayName)"
    
} catch {
    Write-Error "Failed to create $($user.DisplayName): $_"
    # Rich exception object with details
}
```

**Advantages**:
- Type-safe parameters
- IntelliSense support
- Rich exception objects
- PowerShell-native error handling

---

## Portfolio Evidence

### Scripts Demonstrating All 3 Methods

**Created**:
1. `01-create-users-bulk-AZCLI.ps1` — Azure CLI implementation (Week 1)
2. `BONUS-test-service-principal-auth.ps1` — Service Principal validation
3. `BONUS-create-users-3methods.ps1` — Unified script with method selection

**Test Results**:
```
Method 1 (Azure CLI):         ✅ 45 users created successfully
Method 2 (Graph Interactive): ❌ Authentication failed (personal account)
Method 3 (Service Principal): ✅ 2 test users created successfully
```

### App Registration Evidence

**Screenshots**:
- App Registration overview page
- API permissions (6 permissions granted)
- Admin consent confirmation (green checkmarks)
- Client secret created (redacted value)

---

## Interview Talking Points

### Question 1: *"Describe a technical challenge you overcame."*

**Answer**:
> "While deploying Microsoft Entra ID for AQUAPINE CONSULT, I hit an authentication limitation: Microsoft Graph PowerShell required a work/school account, but I was using Azure for Students with a personal Microsoft account. Delegated permissions wouldn't work.
> 
> I researched OAuth 2.0 flows and discovered that while delegated permissions (Authorization Code grant) have personal account restrictions, application permissions (Client Credentials grant) work with tenant-level consent—which I could grant myself as Global Administrator.
> 
> I created an App Registration, configured a Service Principal with User.ReadWrite.All application permissions, granted admin consent, and authenticated using client credentials. This gave me full Microsoft Graph PowerShell SDK support with my personal account.
> 
> The result: I demonstrated three authentication methods in my portfolio—Azure CLI (immediate workaround), Graph Interactive (educational), and Service Principal (production solution). This showed tool adaptability and deep understanding of identity protocols."

---

### Question 2: *"How do you handle authentication in automated scripts?"*

**Answer**:
> "For production automation, I use Service Principals with the OAuth 2.0 Client Credentials flow. At AQUAPINE, I created an App Registration with granular Microsoft Graph API permissions (User.ReadWrite.All, Group.ReadWrite.All) and granted application-level permissions with admin consent.
> 
> For security, I never hardcode secrets in scripts. In development, I use PowerShell's EncryptedXML for user-scoped encryption. In production, I'd store secrets in Azure Key Vault and reference them via Managed Identity.
> 
> Service Principal authentication is non-interactive, making it ideal for scheduled tasks, CI/CD pipelines, and bulk operations. It's also more reliable than delegated auth since it doesn't depend on user sessions or browser interactions."

---

### Question 3: *"What's the difference between delegated and application permissions?"*

**Answer**:
> "Delegated permissions mean the app acts on behalf of a signed-in user—'I (user) give this app permission to do X on my behalf.' The app inherits the user's permissions and can only access what the user can access. This requires user consent and interactive sign-in.
> 
> Application permissions mean the app acts on behalf of itself—'This app has permission to do X organization-wide.' The app operates independently of any user, which is necessary for unattended automation. This requires admin consent.
> 
> At AQUAPINE, I needed to create users in bulk without manual intervention. Delegated permissions wouldn't work with my personal account, and even if they did, they'd require my browser session. Application permissions via Service Principal solved both issues—tenant-level consent I could grant myself, and non-interactive authentication for automation."

---

## Conclusion

By implementing and documenting three authentication methods, I demonstrated:

✅ **Technical depth**: OAuth 2.0 flows, delegated vs. application permissions, Service Principal concepts  
✅ **Problem-solving**: When Method 2 failed, researched and implemented Method 3  
✅ **Tool adaptability**: Azure CLI → Microsoft Graph → Service Principal  
✅ **Security awareness**: Secret management, least privilege, permission scoping  
✅ **Production readiness**: Chose enterprise-standard approach (Service Principal) over workarounds  

**This goes beyond AZ-104 curriculum** and shows initiative to solve real-world constraints with advanced identity concepts.

---

**Document Status**: ✅ Portfolio-Ready  
**Skill Level**: Advanced (beyond AZ-104 scope)  
**Business Impact**: Unblocked Microsoft Graph automation for AQUAPINE infrastructure deployment