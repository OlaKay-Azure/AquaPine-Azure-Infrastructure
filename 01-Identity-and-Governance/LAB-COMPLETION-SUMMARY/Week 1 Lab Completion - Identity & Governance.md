# Week 1 Lab Completion - Identity & Governance

**Status:** ✅ Complete  
**Date:** [Friday Date] - [Saturday Date]  
**Duration:** 6 hours (including troubleshooting)  
**Grade:** A+ with Honors

---

## 🎯 Objectives Achieved

### Primary Goals
- [x] Create 45 AQUAPINE user accounts in Microsoft Entra ID
- [x] Establish 20 security groups (3-tier hierarchy)
- [x] Assign users to appropriate groups (department + role-based)
- [x] Deploy Azure infrastructure (Resource Groups + Storage Accounts)
- [x] Implement RBAC role assignments for access control

### Bonus Achievements
- [x] Overcame Microsoft Graph authentication limitations
- [x] Developed Azure CLI alternative implementations
- [x] Created diagnostic and remediation scripts
- [x] Documented troubleshooting procedures for future reference

---

## 🏗️ Infrastructure Deployed

### Entra ID Resources
- **Users:** 45 (all departments, Lagos + Ibadan)
- **Security Groups:** 20 (location-based, department-based, role-based)
- **Group Memberships:** 150+ assignments

### Azure Resources
- **Resource Groups:** 3
  - Lagos-HQ-RG (Lagos administrative resources)
  - Ibadan-Farms-RG (Ibadan farm operations resources)
  - Shared-Services-RG (company-wide resources)

- **Storage Accounts:** 3
  - hrdatastorage (HR department - payroll, employee records)
  - farmmonitoring (Farm operations - sensor data, pond logs)
  - securitycctv (Security department - CCTV footage archive)

### RBAC Assignments
- **Lagos-HR-Security** → Storage Blob Data Contributor (hrdatastorage)
- **Ibadan-FarmOps-Security** → Storage Blob Data Reader (farmmonitoring)
- **Ibadan-FarmSecurity-Security** → Storage Blob Data Reader (securitycctv)
- **Lagos-IT-Security** → Contributor (Subscription)
- **Lagos-Executive-Security** → Reader (Subscription)
- **AQUAPINE-AllEmployees** → Reader (Shared-Services-RG)

---

## 🔧 Technical Challenges & Solutions

### Challenge 1: Microsoft Graph Authentication with Personal Account

**Problem:**  
Azure for Students with personal Microsoft account (@outlook.com) does not support interactive Microsoft Graph PowerShell authentication.

**Error:**
```
Connect-MgGraph: Authentication failed - personal accounts not supported for delegated permissions
```

**Solution:**  
Implemented Azure CLI alternative for user/group management:
- Created `aquapine-bulk-user-creation-AZCLI.ps1`
- Created `create-groups-AZCLI.ps1`
- Created `add-users-to-groups-AZCLI.ps1`

**Learning Outcome:**  
Discovered multiple authentication methods for Azure (Azure CLI, Azure PowerShell, Microsoft Graph). Gained understanding of when each tool is appropriate.

---

### Challenge 2: JSON Escaping in PowerShell + Azure CLI

**Problem:**  
When using `az ad user create` with complex JSON in PowerShell, quote escaping was causing parameter parsing failures. Users were created with only DisplayName and UserPrincipalName - all other properties (JobTitle, Department, OfficeLocation, etc.) were missing.

**Error:**
```
Invalid JSON - unexpected character at position 47
```

**Root Cause:**  
PowerShell's handling of nested quotes in `--body` parameter conflicted with Azure CLI's JSON parser.

**Solution:**  
Created two-phase approach:
1. Phase 1: Create users with minimal properties (DisplayName, UPN, Password)
2. Phase 2: Update users with full properties using separate script (`update-existing-users-FIXED.ps1`)

**Code Example:**
```powershell
# Instead of complex JSON in one command:
az ad user create --display-name "..." --user-principal-name "..." `
  --password "..." --job-title "..." --department "..." # ❌ Failed

# Use simple creation + separate update:
az ad user create --display-name "..." --user-principal-name "..." --password "..." # ✅ Works
# Then update properties:
az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/users/{id}" `
  --body "@user-properties.json" # ✅ Works
```

**Learning Outcome:**  
Learned JSON escaping challenges across different shells (PowerShell vs. Bash). Developed modular scripting approach - separation of concerns makes troubleshooting easier.

---

### Challenge 3: Subscription ID Mismatch for Storage Account Creation

**Problem:**  
Resource Groups created successfully, but Storage Account creation failed with subscription validation errors.

**Error:**
```
New-AzStorageAccount: The subscription 'XXXXXXXX' is not registered for resource type 'Microsoft.Storage'
```

**Root Cause:**  
Azure PowerShell context was using different subscription ID than intended. Resource provider not registered in target subscription.

**Solution:**  
1. Created diagnostic script (`diagnose-azure-subscription.ps1`) to identify:
   - Active subscription context
   - Resource provider registration status
   - Permission level on subscription

2. Microsoft.Storage provider needs to be registered, If Provider Not Registered but it wasnt registered so used powershell to Register the provider using,
   - Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
   - Wait 2-3 minutes, then check Get-AzResourceProvider -ProviderNamespace Microsoft.Storage

3. Implemented Azure CLI alternative (`01-deploy-infrastructure-AZCLI.ps1`):
   - More reliable subscription handling for student accounts
   - Explicit subscription selection: `az account set --subscription "..."`
   - Resource provider auto-registration

**Learning Outcome:**  
Understood Azure subscription context management, resource provider registration requirements, and when to use Azure CLI vs. Azure PowerShell for different tasks.

---

## 📈 Skills Demonstrated

### Technical Skills
- ✅ Microsoft Entra ID user/group management
- ✅ Azure CLI scripting and automation
- ✅ Azure PowerShell for RBAC management
- ✅ JSON data handling and escaping
- ✅ Troubleshooting authentication issues
- ✅ Subscription and context management
- ✅ Storage account configuration
- ✅ RBAC role assignment implementation

### Problem-Solving Skills
- ✅ Root cause analysis (diagnostic scripting)
- ✅ Workaround development (alternative implementations)
- ✅ Modular solution design (separate scripts for each concern)
- ✅ Documentation of troubleshooting procedures

### Professional Skills
- ✅ Persistence through technical challenges
- ✅ Independent learning and research
- ✅ Systematic debugging approach
- ✅ Clear documentation for future reference

---

## 🎓 Key Takeaways

1. **Authentication Methods Matter:**  
   Personal Microsoft accounts have limitations with Microsoft Graph. Azure CLI provides a reliable alternative for student/personal scenarios.

2. **Multiple Paths to Success:**  
   When one approach fails (Microsoft Graph PowerShell), alternative tools (Azure CLI) can achieve the same outcome. Knowing multiple tools = versatility.

3. **Troubleshooting is a Skill:**  
   Creating diagnostic scripts to understand problems is more valuable than just fixing symptoms. Diagnostic approach: Identify → Isolate → Solve → Document.

4. **Modular Design Wins:**  
   Breaking complex operations into smaller scripts (create users → update properties → assign groups) makes troubleshooting and iteration faster.

5. **Documentation is Portfolio Gold:**  
   Challenges encountered and solved demonstrate real-world skills. In interviews, discussing "how I overcame X" is more impressive than "I followed tutorial Y."

---

## 📂 Repository Structure
```
AquaPine-Azure-Infrastructure/
├── 01-Identity-and-Governance/
│   ├── 01-Entra-ID-Foundation/
│   │   ├── scripts/
│   │   │   ├── aquapine-bulk-user-creation-AZCLI.ps1
│   │   │   ├── update-existing-users-FIXED.ps1
│   │   │   ├── create-groups-AZCLI.ps1
│   │   │   ├── add-users-to-groups-AZCLI.ps1
│   │   │   └── diagnose-azure-subscription.ps1
│   │   ├── data/
│   │   │   └── aquapine-users.csv
│   │   └── documentation/
│   │       ├── administrative-units-design.md
│   │       ├── security-operations-plan.md
│   │       └── troubleshooting-guide.md (NEW)
│   ├── 02-RBAC-Implementation/
│   │   ├── scripts/
│   │   │   ├── 01-deploy-infrastructure-AZCLI.ps1
│   │   │   ├── 03-assign-rbac-roles-FIXED.ps1
│   │   │   └── storage-config.json
│   │   ├── screenshots/
│   │   │   ├── 01-users-created.png
│   │   │   ├── 02-groups-created.png
│   │   │   ├── 03-rbac-assignments.png
│   │   │   └── 04-validation-output.png
│   │   └── README.md
│   └── LAB-COMPLETION-SUMMARY.md (THIS FILE)
└── docs/
    └── learning-journal/
        └── week-01/
            ├── day-1.md
            ├── day-2.md
            ├── day-3.md
            ├── day-4.md
            └── day-5-lab.md (NEW)
```

---

## 🎯 Interview Talking Points

**When Asked: "Tell me about a challenging technical problem you solved"**

> "During my Azure Administrator training, I implemented identity management for a 45-employee organization using Microsoft Entra ID and Azure RBAC. I encountered authentication limitations with personal Microsoft accounts and Microsoft Graph API - a common issue for Azure for Students subscriptions.
>
> Rather than abandoning the project, I researched alternative approaches and implemented the solution using Azure CLI. I also discovered JSON escaping issues between PowerShell and Azure CLI, which I solved by creating a two-phase user provisioning process: initial account creation with minimal properties, followed by a separate update script for full profile population.
>
> Additionally, I built diagnostic scripts to troubleshoot subscription context mismatches during storage account deployment. This systematic approach - identify the problem, create diagnostic tools, implement solutions, document findings - taught me that troubleshooting is a skill that's as valuable as knowing the 'happy path' procedures.
>
> The project was completed successfully with all 45 users, 20 groups, and RBAC assignments deployed. More importantly, I documented the entire troubleshooting process, which other students with personal accounts can now reference."

**Impact:** This demonstrates problem-solving, adaptability, and documentation skills - all critical for IT operations roles.

---

## 📚 References & Resources

- [Azure CLI User Management](https://learn.microsoft.com/en-us/cli/azure/ad/user)
- [Microsoft Graph API Limitations with Personal Accounts](https://learn.microsoft.com/en-us/graph/auth-v2-user)
- [Azure RBAC Built-in Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [PowerShell JSON Escaping Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-pscustomobject)


---

**Lab Completed By:** Olatunde Ogunti  
**Date:** [January 2026]  
**Portfolio Status:** ✅ Ready for Review
