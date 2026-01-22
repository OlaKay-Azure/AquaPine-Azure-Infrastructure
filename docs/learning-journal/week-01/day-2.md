# Week 1, Day 2 - [Date]

## Domain & Topic
AZ-104 Domain 1: Users, Groups, and Administrative Units

## Key Concepts Learned

### User Accounts
- **Cloud-Only vs. Synced:** [Explain why AQUAPINE uses cloud-only]: AQUAPINE currently uses cloud-only user accounts because the organization does not operate an on-premises Active Directory environment. Cloud-only accounts are created and managed entirely within Microsoft Entra ID, simplifying identity management while supporting authentication to Azure resources and SaaS applications.
- **User Properties:** [Which properties matter for AQUAPINE and why]: Display Name, Job Title, Department. Office Location, Manager, Phone Number, Usage Location, User Principal Name (UPN), Object ID. These properties support: Reporting: Identifying departments and organizational structure; Automation: Enabling future dynamic group rules; Access Design: Supporting role-based access planning; Licensing: Usage Location determines license eligibility and compliance requirements. 
- **Bulk Import:** [Why CSV method is best for 45 users]: Bulk User Import and creation via CSV is the most efficient onboarding method for AQUAPINE’s 45 employees. It reduces manual errors, ensures consistency, and significantly saves administrative time compared to individual user creation.

### Groups
- **Security Groups vs. M365 Groups:** [Key differences in my own words]: Security Groups are primarily used for access control, including Azure RBAC assignments and application permissions. While, Microsoft 365 Groups are designed for collaboration workloads such as Microsoft Teams, SharePoint, and group email. For AQUAPINE’s infrastructure-focused needs, Security Groups are the preferred option.
- **Assigned vs. Dynamic Membership:** [Trade-offs for AQUAPINE]: Assigned membership requires manual user management and is suitable for AQUAPINE’s current size and Entra ID Free licensing. While Dynamic membership automatically manages group membership using rules based on user attributes but requires Entra ID Premium P1. At the current scale, assigned groups provide sufficient control without licensing overhead.
- **Group Nesting:** [When to use, when to avoid]: Group nesting is useful when implementing hierarchical access models. For example, department-level groups can be nested into broader organization-wide groups to simplify RBAC assignments. However, excessive nesting should be avoided to prevent administrative complexity.

### AQUAPINE Group Design
- **3-Tier Structure:** [Why this hierarchy makes sense]: AQUAPINE’s group model is designed using:
Location-based groups (e.g., Lagos, Ibadan)
Department-based groups (e.g., HR, Farm Operations, IT)
Role or function-based groups (e.g., Managers, Finance Officers)
This structure supports clear separation of duties, scalable access control, and future growth.
- **Naming Convention:** [Document the pattern: [Company]-[Location]-[Type]]: Aquapine-Ibadan-SG or Aquapine-HR-SG 
- **Total Groups:** [~20 groups for 45 users - is this right sizing?]: Approximately 18–20 groups for 45 users is appropriately sized. This allows effective access separation without unnecessary complexity.

## AQUAPINE Business Context
- **Identity Challenge:** [How do groups solve the Lagos vs. Ibadan access problem?]: Groups enable clear separation between Lagos and Ibadan operations. Farm managers in Ibadan are restricted from HR payroll systems, while Lagos HR users cannot access farm operational data.
- **Security Requirement:** [Why HR needs separate group from Farm Operations]: HR data contains sensitive payroll and personnel information and must be isolated from farm operations to reduce insider risk and enforce least privilege.
- **Scale Consideration:** [Will this structure work when company grows to 100+ employees?]: This group structure is scalable and will continue to function effectively as AQUAPINE grows beyond 100 employees, with the option to introduce dynamic groups and Conditional Access when licensing permits.

## Questions for Instructor
- [ ] [Any unclear concepts about dynamic groups?]: At what growth stage should AQUAPINE introduce dynamic groups to reduce administrative overhead?
- [ ] [Doubts about our 3-tier structure?]: How critical are role/function-based groups compared to department-only grouping in small organizations?
- [ ] [Should we create more or fewer groups?]

## Pre-Lab Planning Notes
- [ ] Started drafting aquapine-users.csv
- [ ] Identified which groups need to be created first
- [ ] Questions about PowerShell syntax for Friday

## Tomorrow's Focus
- Role-Based Access Control (RBAC)
- How groups connect to Azure resource permissions