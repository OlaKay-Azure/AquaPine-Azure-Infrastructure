# Week 1, Day 3 - [Date]

## Domain & Topic
AZ-104 Domain 1: Role-Based Access Control (RBAC)

## Key Concepts Learned

### Azure RBAC vs. Entra ID Roles
**Azure RBAC:** [Your explanation - manages WHAT resources]: Azure Role-Based Access Control (RBAC)  is an authorization system built on Azure Resource Manager that provides fine-grained access management of Azure resources. It assigns permissions based on job responsibilities and follows the principle of least privilege, ensuring users and groups can only perform actions required for their roles. Azure RBAC operates at the subscription, resource group, or resource level.
**Entra ID Roles:** [Your explanation - manages WHO identities]: Entra ID roles are administrative roles used to manage identity-related objects within the tenant, such as users, groups, devices, and authentication settings. These roles control who can administer the directory, not who can access Azure resources
**Key Difference:** [Why you need both]: Azure RBAC controls access to Azure resources (resource plane), while Entra ID roles control administrative authority over identities (identity plane). For example, Azure RBAC includes roles such as Owner, Contributor, Reader, whereas Entra ID roles include User Administrator, Helpdesk Administrator, Global Administrator, etc. Both are required to fully secure and operate an Azure environment.

### The Three Components
**Identity (WHO):** [Users vs. Groups - why groups are better]: dentities include users, groups, service principals, and managed identities. Groups are preferred over individual users because they improve scalability, simplify administration, and reduce configuration errors.
**Role (WHAT):** [Built-in roles you'll use at AQUAPINE]: Roles define what actions an identity can perform. At AQUAPINE, the primary built-in roles used are:
Owner – full management including access delegation
Contributor – manage resources without assigning access
Reader – view-only access
**Scope (WHERE):** [Subscription vs. RG vs. Resource]: Scope defines where the role assignment applies. Azure supports three main scopes:
Subscription
Resource Group
Individual Resource
Permissions assigned at higher scopes inherit down to lower scopes.

### Least Privilege
**Definition:** [In your own words]: Least privilege is a security principle that ensures users and systems are granted only the minimum level of access necessary to perform their job functions, reducing risk and limiting the impact of security incidents.
**AQUAPINE Example:** [Why Farm Worker gets Reader, not Contributor]: Farm workers are assigned the Reader role instead of Contributor because they only need visibility into operational dashboards such as water quality logs and feeding schedules. They do not need permission to modify or delete resources, so Reader access at the resource level is sufficient.

## AQUAPINE Business Context

### RBAC Strategy
**Problem Solved:** [How RBAC eliminates IT bottleneck]: RBAC allows departments to securely manage their own resources within defined boundaries, reducing dependency on the IT team for routine access changes. This improves operational efficiency while maintaining strong security controls.
**12 Departments:** [List groups and their roles]: 
IT Department: Contributor or Owner at infrastructure scopes
Human Resources: Contributor on HR-specific storage and applications
Sales Department: Reader or Contributor on CRM-related resources
Farm Operations: Reader on monitoring and reporting resources 
Security Department: Reader role to CCTV footage
Microbiology Lab Department: Contributor role on research papers, test results etc
**Security Boundaries:** [How we prevent unauthorized access]: Security is enforced by combining authentication through Entra ID and authorization through Azure RBAC, ensuring that only authenticated identities with approved role assignments can access specific resources.

### Real-World Scenario
Describe how RBAC assignment works for ONE department:
- Group name: Lagos-HR-Security
- Role assigned: Contributor
- Scope: HR Storage Account (resource level)
- Justification: The HR department requires Contributor access to the HR storage account to upload, modify, and manage sensitive employee records while remaining restricted from unrelated Azure resources.

## Questions for Instructor
- [ ] [Any unclear concepts about role inheritance?]: 
### RBAC Implementation Questions:
1. When assigning RBAC roles via PowerShell, should I use `New-AzRoleAssignment` or `New-MgRoleManagementDirectoryRoleAssignment`? What's the difference?

2. If a user is in multiple groups (e.g., Lagos-HR-Security AND AQUAPINE-AllEmployees), and each group has different RBAC roles, do permissions stack (additive) or does one override the other?

3. For the Security Officers who need read-only CCTV access, is "Storage Blob Data Reader" the right role, or should I use just "Reader"? What's the difference in permissions?

4. Can I assign RBAC roles BEFORE creating the actual Azure resources (storage accounts, VMs), or do the resources need to exist first?

5. How do I test/verify that a role assignment worked correctly without logging in as that user? Is there a PowerShell command to check "effective permissions"?

### Friday Lab Prep Questions:
1. What Azure resources do I need to create BEFORE I can test RBAC assignments? (Do I need actual storage accounts, or can I practice on resource groups only?)

2. Should I create the groups first, THEN assign RBAC roles, or can I do it in any order?

3. How long does it take for RBAC role assignments to "take effect"? (Is it instant, or like dynamic groups, does it take hours?)

### Portfolio Documentation Questions:
1. For my README.md in the RBAC folder, should I include screenshots of role assignments in Azure Portal, or is PowerShell script + validation output sufficient?

2. When documenting "why I chose this role over that role" (e.g., Contributor vs. Owner for IT Support), how detailed should the justification be for portfolio purposes?

- [ ] [Questions about Owner vs. Contributor distinction?]: 
- [ ] [Doubts about scope selection for AQUAPINE?]: 

## Tomorrow's Focus
- Complete Priority 2/3 homework tasks
- Refine Admin Units design document
- Add CCTV cost calculations
- Prepare for Friday lab