# Week 1, Day 3 - [Date]

## Domain & Topic
AZ-104 Domain 1: Role-Based Access Control (RBAC)

## Key Concepts Learned

### Azure RBAC vs. Entra ID Roles
**Azure RBAC:** [Your explanation - manages WHAT resources]: Azure Role-Based Access Control (RBAC) is an authorization system used to manage access to Azure resources. It assigns permissions based on job responsibilities and follows the principle of least privilege, ensuring users and groups can only perform actions required for their roles. Azure RBAC operates at the subscription, resource group, or resource level.
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
- [ ] [Questions about Owner vs. Contributor distinction?]: 
- [ ] [Doubts about scope selection for AQUAPINE?]: 

## Tomorrow's Focus
- Complete Priority 2/3 homework tasks
- Refine Admin Units design document
- Add CCTV cost calculations
- Prepare for Friday lab