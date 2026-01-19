# AZ-104 Domain 1: Manage Azure Identities and Governance
**Weight**: 25-30% of AZ-104 Exam  
**Author**: Olatunde Ogunti  
**Organization**: Aquapine Consult

---

## DOMAIN OVERVIEW

This domain establishes the **identity and governance foundation** for Aquapine Consult's Azure infrastructure. All subsequent domains depend on the identity architecture and governance policies implemented here.

**Business Context**: As a multi-site aquaculture operation (Ibadan farms + Lagos HQ) with 45 employees across 11 departments, Aquapine requires:
- Centralized identity management for users across locations
- Role-based access control to protect sensitive data (HR payroll, microbiology research)
- Policy enforcement for compliance and cost control
- Organizational resource structure for operational efficiency

---

## LABS IN THIS DOMAIN

### 1. Entra ID Foundation
**Objective**: Design and deploy Microsoft Entra ID identity structure  
**Business Problem**: No centralized user management, employees using personal emails  
**Solution**: 45 user accounts, 11 security groups, hierarchical organization structure  
[View Lab →](./01-Entra-ID-Foundation/)

### 2. RBAC Implementation
**Objective**: Implement least-privilege access control model  
**Business Problem**: Need to grant appropriate permissions without over-privileging users  
**Solution**: Custom RBAC roles, group-based assignments, audit logging  
[View Lab →](./02-RBAC-Implementation/)

### 3. Azure Policy Governance
**Objective**: Enforce organizational compliance through policy  
**Business Problem**: Prevent accidental resource deployment in wrong regions, ensure tagging  
**Solution**: Custom policies for location restriction, required tags, denied configurations  
[View Lab →](./03-Azure-Policy-Governance/)

### 4. Resource Organization
**Objective**: Structure resource groups and implement tagging strategy  
**Business Problem**: Track costs by department, organize resources logically  
**Solution**: Department-based resource groups, comprehensive tagging taxonomy  
[View Lab →](./04-Resource-Organization/)

### 5. Cost Management
**Objective**: Implement budgets and cost controls  
**Business Problem**: SME budget constraints, need cost visibility and alerts  
**Solution**: Department budgets, cost allocation tags, alert automation  
[View Lab →](./05-Cost-Management/)

---

## CAPSTONE PROJECT

**Title**: Complete Identity & Governance Solution for Aquapine Consult

**Challenge**: Deploy end-to-end governance infrastructure combining all domain concepts

**Requirements**:
- 45 users across 2 locations and 11 departments
- RBAC assignments for 5 different job functions
- Azure Policy enforcement (3+ custom policies)
- Resource group structure aligned to business operations
- Cost management with department-level budgets

**Deliverables**:
- Single PowerShell script deploying entire solution
- Comprehensive architecture diagram
- Validation tests proving compliance
- Interview talking points document

[View Capstone →](./CAPSTONE-PROJECT/)

---

## SKILLS DEMONSTRATED

✅ Microsoft Entra ID (Azure AD) administration  
✅ User and group lifecycle management  
✅ Role-Based Access Control (RBAC) design and implementation  
✅ Azure Policy creation and enforcement  
✅ Resource governance and organization  
✅ Cost management and optimization  
✅ PowerShell automation for identity operations  
✅ Compliance audit and reporting

---

## AZ-104 EXAM COVERAGE

**Topics Covered**:
- Configure Microsoft Entra ID (formerly Azure AD)
- Manage users and groups
- Manage subscriptions and governance
- Implement and manage storage (identity/RBAC aspects)
- Configure access control (RBAC)
- Manage Azure Policy
- Configure resource locks
- Manage resource groups
- Apply and manage tags
- Manage costs and billing

**Hands-On Skills Tested**:
- Create and manage users via PowerShell
- Assign RBAC roles at different scopes
- Create custom Azure Policy definitions
- Implement resource tagging strategies
- Configure cost alerts and budgets

---

## INTERVIEW TALKING POINTS

**Question**: *"Describe your experience with Azure identity management."*

**Answer Template**:
"At Aquapine Consult, I designed the complete Entra ID structure for 45 employees across two geographic locations—Ibadan production farms and Lagos headquarters. The challenge was [specific challenge]. My approach was [solution]. The outcome was [measurable result]."

[Full Interview Guide →](../docs/interview-prep/domain-1-talking-points.md)

---

**Domain Status**: 🚧 In Progress  
**Last Updated**: January 2026
```
