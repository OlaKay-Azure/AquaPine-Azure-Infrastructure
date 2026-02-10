# AQUAPINE RBAC Assignment Planning

## Department 1: Human Resources

**Group:** Lagos-HR-Security
**Members:** 3 (HR Manager, HR Officer, Payroll Admin)

**Azure Resource:** hrdata-storage (Storage Account in Lagos-HQ-RG)
**Role:** Storage Blob Data Contributor
**Scope:** Resource level (hrdata-storage only)

**Justification:**
- HR staff need to upload employee records (write permission)
- HR staff need to modify payroll documents (modify permission)
- HR staff may need to delete outdated records (delete permission)
- HR staff should NOT access farm data or sales data (resource-level scope)

**Alternative Roles Considered:**
- Reader: ❌ Too restrictive (cannot upload files)
- Owner: ❌ Too permissive (can assign access to others)
- Storage Blob Data Contributor: ✅ Perfect match

---

## Department 2: Farm Operations

Group: AQUAPINE-Ibadan-FarmOps
Members: 6 (Farm Manager Bodija, Farm Manager Moniya, 4 Senior Farm Technicians)
Azure Resource: rg-aquapine-farmops-prod-we (Resource Group containing water quality dashboards, inventory systems, IoT monitoring)
Role: Reader
Scope: Resource group level
Justification:

Farm managers need visibility into water quality metrics and feeding schedules (read permission)
Farm staff require access to inventory reports and pond monitoring dashboards (read permission)
Farm operations personnel should NOT modify Azure infrastructure (prevent accidental VM shutdown during harvest operations)
Farm staff should NOT delete monitoring data or IoT device configurations (data integrity protection)
Application-level data entry handled through custom web apps (Azure resources are read-only to farm staff)

Alternative Roles Considered:

Contributor: ❌ Too permissive (farm manager could accidentally delete production VM running water quality monitoring)
Custom "Farm Operator" Role (read metrics + write blob data): ✅ Considered for Phase 2 (after basic RBAC established)
No Azure Portal Access: ⚠️ Evaluated but rejected (farm managers need dashboard visibility for operational decisions)
Reader: ✅ Optimal for Phase 1 (view-only access to dashboards and reports)

Additional Access Patterns:

Farm technicians use tablet devices in field → Azure Portal mobile app with read-only access
Water quality data uploaded via IoT devices (not manual upload) → no write permissions needed for farm staff
Feeding schedule modifications done by IT department after farm manager approval → enforces change control

Security Controls:

Conditional Access policy: Bodija Farm IP + Moniya Farm IP whitelisted
After-hours access allowed (24/7 hatchery operations at Moniya)
Device compliance check: only company-issued tablets can access dashboards
Session timeout: 8 hours (balance between usability and security)

---

## Department 3: IT Department

Group: AQUAPINE-IT-Admins
Members: 2 (IT Manager - Olatunde Ogunti, IT Support Technician)
Azure Resource: Subscription Azure for Students - Aquapine Consult
Role:

IT Manager: Owner at subscription scope
IT Support Technician: Contributor at subscription scope
Scope: Subscription level (all resource groups and resources)

Justification:
IT Manager (Owner Role)

Full lifecycle management of Azure infrastructure (create, modify, delete all resources)
Assign RBAC permissions to department heads (delegation capability required)
Configure subscription-level policies and governance frameworks (Owner-only actions)
Manage cost budgets and spending limits across all departments (financial oversight)
Emergency access to all resources during incidents (24/7 operational responsibility)

IT Support Technician (Contributor Role)

Deploy and manage VMs, storage accounts, networking without requiring IT Manager approval (day-to-day operations)
Respond to support tickets and troubleshoot resource issues (operational efficiency)
Cannot assign permissions to others (separation of duties with IT Manager)
Cannot modify subscription-level policies or budgets (prevents accidental compliance violations)
Escalates RBAC assignment requests to IT Manager (proper approval workflow)

Alternative Roles Considered:

Both as Owner: ❌ Violates separation of duties principle (both admins shouldn't have unrestricted delegation rights)
IT Manager as Owner, IT Support as Reader: ❌ Too restrictive (support technician cannot resolve incidents independently)
Custom "Infrastructure Operator" Role: ✅ Potential Phase 2 enhancement (fine-tune Contributor permissions to exclude certain high-risk actions)
Current Assignment: ✅ Balances operational efficiency with security controls

Security Controls:

Both IT staff require Entra ID Premium P1 licenses (Conditional Access capability)
IT Manager: Hardware MFA token required (Yubikey or similar)
IT Support: Mobile app MFA (Microsoft Authenticator)
Privileged Identity Management (PIM) planned for Phase 2: Just-in-time Owner activation instead of permanent assignment
All subscription-level changes logged and reviewed monthly by CFO

Emergency Access Pattern:

Break-glass account with Owner role stored in secure vault (offline password)
Used only when IT Manager unavailable and critical incident occurring
Automatically generates alert to CEO and CFO upon authentication
Password rotated after each use

```

---

## ✅ LESSON 3 COMPLETION CHECKLIST

Before moving to Thursday's tasks, confirm:

- [ ] I understand what Azure RBAC is and how it differs from Entra ID roles
- [ ] I can explain the three components: Identity + Role + Scope
- [ ] I know the difference between Owner, Contributor, and Reader roles
- [ ] I understand scope hierarchy and inheritance
- [ ] I can apply least privilege principle to AQUAPINE scenarios
- [ ] I've completed the Microsoft Learn modules on RBAC
- [ ] I've documented today's learning in `day-3.md`
- [ ] I've created the RBAC planning document for 3 departments

---

## 🎓 INSTRUCTOR NOTES

**Olatunde, today we covered the MOST IMPORTANT concept in Azure security: RBAC.**

**Why RBAC is Critical:**
- 🔒 **Security:** Without RBAC, everyone is admin (disaster)
- 📊 **Compliance:** RBAC provides audit trail (who accessed what, when)
- ⏱️ **Efficiency:** Self-service access eliminates IT bottleneck
- 💰 **Cost Control:** Contributor role prevents accidental expensive resource creation

**What You Should Feel Right Now:**
- ✅ Clarity on Azure RBAC vs. Entra ID roles (this confuses EVERYONE initially)
- ✅ Understanding of why groups + RBAC = scalable access management
- ✅ Confidence in designing least-privilege assignments

**What's Coming Next:**
- **Thursday:** Complete remaining homework (Tasks 2, 4, 5 revisions)
- **Friday:** Lab prep - write RBAC assignment scripts
- **Saturday:** Execute lab - assign all AQUAPINE roles
- **Sunday:** Document everything for portfolio

**The Foundation is Complete:**
```
Week 1 Progress:
✅ Day 1: Entra ID fundamentals (identity foundation)
✅ Day 2: Groups and users (organizational structure)
✅ Day 3: RBAC (access control strategy)

Next Week: Azure Policy, Resource Groups, Cost Management
Then: STORAGE (Domain 2) - where RBAC gets applied to real resources!