
# Week 1, Day 1 - [Date]

## Domain & Topic
AZ-104 Domain 1: Microsoft Entra ID Fundamentals

## Key Concepts Learned
1. **Entra ID Tenant:** [A Microsoft Entra ID tenant is a dedicated identity and security boundary for an organization. It is automatically created when an Azure account or Microsoft 365 tenant is provisioned. The tenant stores and manages users, groups, applications, and authentication policies.]
2. **Tenant vs. Subscription:** [Tenant is the centralized identity, authentication and authorization boundary while Subscription is a resource container for azure resources, billing and access boundary using RBAC. The tenant functions as the organizational headquarters for identity, while subscriptions act as secured departments where Azure resources live and are billed.]
3. **Licensing Tiers:** [AQUAPINE’s Microsoft Entra ID licensing strategy is designed to scale in line with organizational growth and security requirements. At the current stage, with approximately 45 employees, the Free license is sufficient, as it provides essential capabilities such as single sign-on (SSO), multi-factor authentication (MFA), and basic user management.

As the organization enters a short-term growth phase and begins hosting sensitive HR workloads in the cloud, upgrading to Entra ID Premium P1 becomes necessary. This tier enables Conditional Access policies and device-based access controls, ensuring that sensitive data is accessed only under approved conditions.

In the long term, when AQUAPINE expands to over 500 employees, Entra ID Premium P2 will be required to address advanced security needs. This license supports Identity Protection and Privileged Identity Management (PIM), which are critical for mitigating identity-based risks and securing administrative privileges at scale]

## AQUAPINE Business Context
- **Identity Challenge:** [What problem Entra ID solves for AQUAPINE: Identity Challenges Addressed

Microsoft Entra ID resolves the following issues at AQUAPINE:

Lack of centralized identity management

No audit trail for user access

Security risks from former employees retaining access

Use of shared passwords and personal email accounts

Difficulty managing identities across multiple operational sites]
- **Security Requirements:** [Why MFA matters for HR/IT: Security Requirements

HR Department:
MFA is required to protect sensitive payroll and employee records.

IT Administration:
MFA reduces the risk of privilege abuse and secures administrative access.]
- **Cost Consideration:** [Why start with Free tier: Cost Considerations

AQUAPINE will initially adopt the Free tier, as it meets current operational needs:

Small workforce (45 users)

Basic SSO and MFA coverage

No immediate need for PIM or risk-based access policies

Licensing will scale only as business risk and complexity increase, aligning security spend with growth]

## Key Takeaways

Identity architecture must align with organizational size and risk profile

Entra ID tenants and subscriptions serve distinct but complementary roles

Licensing decisions should be phased, not over-provisioned

## Questions for Instructor
- [ ] [Any unclear concepts?] 1. When should Conditional Access policies be introduced in small organizations? 2. What indicators justify upgrading from P1 to P2 licensing?
- [ ] [Doubts about AQUAPINE architecture?] 

## Tomorrow's Focus
- User and group creation strategies
- Department-based group structure 