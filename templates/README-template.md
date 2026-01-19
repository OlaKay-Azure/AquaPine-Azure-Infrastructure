# [LAB NUMBER] - [LAB TITLE]
**Domain**: AZ-104 Domain X - [Domain Name]  
**Author**: Olatunde Ogunti  
**Date**: [Date]  
**Estimated Time**: [X hours]

---

## 🎯 BUSINESS SCENARIO

**AQUAPINE CONSULT Challenge**:
[Describe the specific operational problem this lab solves. Example: "The Ibadan microbiology team needs secure storage for fish health test results that HR and sales teams cannot access..."]

**Stakeholders**:
- [List affected departments/roles]

**Success Criteria**:
- [Measurable outcome 1]
- [Measurable outcome 2]
- [Measurable outcome 3]

---

## 📚 LEARNING OBJECTIVES

By completing this lab, you will:
1. [Technical skill 1]
2. [Technical skill 2]
3. [Technical skill 3]

**AZ-104 Exam Coverage**:
- Objective X.Y: [Specific exam objective]
- Weight: [X%] of exam

---

## 🏗️ ARCHITECTURE OVERVIEW

**What You'll Build**:
[Brief description of the infrastructure/configuration]

**Architecture Diagram**:
![Architecture](./screenshots/architecture-diagram.png)

**Resources Deployed**:
- [Resource 1]: Purpose and configuration
- [Resource 2]: Purpose and configuration
- [Resource 3]: Purpose and configuration

---

## ✅ PREREQUISITES

**Azure Resources**:
- [ ] Active Azure for Students subscription
- [ ] Resource Group: `[name]`
- [ ] [Other required resources]

**Tools Required**:
- [ ] PowerShell 7 installed
- [ ] Azure CLI installed
- [ ] VS Code with Azure extensions

**Knowledge Prerequisites**:
- Understanding of [prerequisite concept 1]
- Familiarity with [prerequisite concept 2]

---

## 🚀 DEPLOYMENT STEPS

### Step 1: [First Step Title]

**Objective**: [What this step accomplishes]

**PowerShell Script** (`scripts/01-[script-name].ps1`):
```powershell
# [Brief description of what this script does]

# Connect to Azure
Connect-AzAccount

# Set subscription context
Set-AzContext -SubscriptionId "[Your-Subscription-ID]"

# [Main script logic with inline comments]

# Example validation
Get-AzResourceGroup -Name "aquapine-prod-rg-001" | Select-Object ResourceGroupName, Location, ProvisioningState
```

**Expected Output**:
````
ResourceGroupName         Location    ProvisioningState
-----------------         --------    -----------------
aquapine-prod-rg-001      westeurope  Succeeded
Portal Validation:

Navigate to Azure Portal → Resource Groups
Verify aquapine-prod-rg-001 exists
Screenshot saved to: ./screenshots/step1-validation.png


Step 2: [Second Step Title]
[Repeat structure above]

✅ VALIDATION & TESTING
Validation Script (scripts/99-validation.ps1):
powershell# Comprehensive validation of all deployed resources
# [Script content]
Manual Verification Checklist:

 [Verification item 1]
 [Verification item 2]
 [Verification item 3]

Expected Results:

[What success looks like]


🧹 CLEANUP (OPTIONAL)
Warning: This will delete all resources created in this lab.
powershell# Remove resource group and all contained resources
Remove-AzResourceGroup -Name "aquapine-prod-rg-001" -Force
````

---

## 🎓 KEY TAKEAWAYS

**Technical Learnings**:
1. [Key technical insight 1]
2. [Key technical insight 2]
3. [Key technical insight 3]

**Business Value**:
- [How this solves AQUAPINE's operational need]

**Production Considerations**:
- **Security**: [Security best practices applied]
- **Cost**: [Cost implications and optimization]
- **Scalability**: [How this scales with growth]

---

## 📊 AZ-104 EXAM TIPS

**Likely Exam Questions**:
- [Question pattern 1]
- [Question pattern 2]

**Key Facts to Memorize**:
- [Fact 1]
- [Fact 2]

**Hands-On Skills Tested**:
- [Skill 1]
- [Skill 2]

---

## 💼 INTERVIEW TALKING POINTS

**Scenario Question**: "Tell me about a time you implemented [this technology]."

**STAR Method Answer**:
- **Situation**: At Aquapine Consult, [context]
- **Task**: I was responsible for [your role]
- **Action**: I designed and deployed [what you built], considering [trade-offs]
- **Result**: This resulted in [measurable outcome], improving [business metric]

---

## 🔗 ADDITIONAL RESOURCES

**Microsoft Documentation**:
- [Link to official docs]

**Related Labs**:
- [Previous lab that builds on this]
- [Next lab in sequence]

**Troubleshooting**:
- Common Error 1: [Solution]
- Common Error 2: [Solution]

---

**Lab Status**: ✅ Complete | 🚧 In Progress | ❌ Not Started  
**Portfolio Ready**: Yes | No  
**GitHub Commit**: `git commit -m "feat: complete [lab name] for AQUAPINE [department]"`
````
