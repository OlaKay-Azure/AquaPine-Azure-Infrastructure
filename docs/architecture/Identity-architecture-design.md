# AQUAPINE CONSULT - Identity Architecture Design
**Date**: January 2026.  
**Author**: Olatunde Ogunti, Azure Administrator  
**Purpose**: Production identity structure for Azure deployment

---

## 1. ORGANIZATIONAL OVERVIEW

**Total Employees**: 45
- Ibadan Operations: 24 employees (Bodija Farm, Moniya Farm)
- Lagos Headquarters: 21 employees (Allen Avenue, Ikeja)

**Operational Requirements**:
- Multi-site access (Ibadan ↔ Lagos)
- 24/7 operations (Moniya Hatchery)
- Data sensitivity tiers (HR payroll, microbiology research)
- Seasonal workforce scaling

---

## 2. USER NAMING CONVENTION

**Format**: `firstname.lastname@aquapineconsult.onmicrosoft.com`

**Display Name Format**: `Firstname Lastname (Job Title - Location)`

**Examples**:
- `olatunde.ogunti@aquapineconsult.onmicrosoft.com` → "Olatunde Ogunti (IT Manager - Lagos)"
- `adebayo.johnson@aquapineconsult.onmicrosoft.com` → "Adebayo Johnson (Farm Manager - Bodija)"

---

## 3. GROUP STRUCTURE

### Location-Based Groups
| Group Name | Purpose | Member Count |
|------------|---------|--------------|
| `AQUAPINE-Ibadan-All` | All Ibadan employees | 24 |
| `AQUAPINE-Lagos-All` | All Lagos employees | 21 |

### Department Groups (IBADAN)
| Group Name | Department | Member Count |
|------------|------------|--------------|
| `AQUAPINE-Ibadan-FarmOps` | Farm Operations | 6 |
| `AQUAPINE-Ibadan-Microbiology` | Microbiology Lab | 4 |
| `AQUAPINE-Ibadan-FishFeed` | Feed Production | 5 |
| `AQUAPINE-Ibadan-Hatchery` | Hatchery Unit | 3 |
| `AQUAPINE-Ibadan-Security` | Security | 4 |
| `AQUAPINE-Ibadan-Store` | Store/Inventory | 2 |

### Department Groups (LAGOS)
| Group Name | Department | Member Count |
|------------|------------|--------------|
| `AQUAPINE-Lagos-HR` | Human Resources | 3 |
| `AQUAPINE-Lagos-IT` | IT Department | 2 |
| `AQUAPINE-Lagos-Sales` | Sales & Marketing | 8 |
| `AQUAPINE-Lagos-Logistics` | Logistics | 4 |
| `AQUAPINE-Lagos-Executive` | Executive Management | 4 |

### Cross-Functional Groups
| Group Name | Purpose | Member Count |
|------------|---------|--------------|
| `AQUAPINE-Managers-All` | Department heads | ~10 |
| `AQUAPINE-IT-Admins` | Azure administrators | 2 |
| `AQUAPINE-Finance-Access` | Financial data access | 5 |

---

## 4. SAMPLE USER LIST (10 Key Employees)

| UPN | Display Name | Department | Location | Manager |
|-----|--------------|------------|----------|---------|
| olatunde.ogunti@... | Olatunde Ogunti (IT Manager - Lagos) | IT | Lagos HQ | CEO |
| [Fill in 9 more - include at least 1 from each major department] |

---

## 5. LICENSE ALLOCATION

**Entra ID Free**: 45 users (all employees)  
**Entra ID Premium P1**: 2 users (IT Admins - future)  
**Total Monthly Cost**: $0 (current), $12 (future with Premium)

**Justification**: Free tier sufficient for basic identity and access control. Premium features (Conditional Access, Self-Service Password Reset) only needed for IT administrators managing Azure resources.

---

## 6. BULK IMPORT WORKFLOW

**Process**:
1. HR provides new hire details via shared Excel template
2. IT exports to CSV format (`aquapine-users-import.csv`)
3. Run PowerShell bulk creation script
4. Validate user creation and group membership
5. Send welcome email with temporary password

**CSV Fields Required**:
- FirstName, LastName, Department, JobTitle, OfficeLocation, Manager, MobilePhone

---

## 7. SECURITY CONSIDERATIONS

**Password Policy**:
- Minimum 12 characters
- Complexity required (uppercase, lowercase, number, symbol)
- Force password change on first login
- 90-day expiration (or self-service reset for Premium users)

**MFA Strategy** (Future):
- Phase 1: IT Admins only (you + IT Support)
- Phase 2: HR and Finance (payroll/sensitive data access)
- Phase 3: All employees (company-wide rollout)

**Audit Requirements**:
- Track all user creations/deletions
- Log group membership changes
- Monitor privileged access (Azure Portal login attempts)

---

## 8. OPERATIONAL RUNBOOKS

### New Employee Onboarding
1. HR sends hire notification (Name, Department, Start Date)
2. IT creates user account (PowerShell script)
3. IT adds user to appropriate groups (Department + Location)
4. IT sends welcome email with credentials
5. User completes first-login password change
6. (Future) IT configures MFA for user

### Employee Offboarding
1. HR sends termination notification
2. IT immediately disables user account
3. IT removes from all groups (revokes access)
4. After 30 days: Delete account permanently
5. Audit log review (ensure no unauthorized access post-termination)

---

## 9. FRIDAY LAB TASKS

**What I'll Build**:
- [ ] PowerShell script: Create 10 sample users from CSV
- [ ] PowerShell script: Create all 11 security groups
- [ ] PowerShell script: Assign users to groups based on department
- [ ] Validation script: List all users and group memberships
- [ ] Documentation: Deployment guide and troubleshooting notes

**Success Criteria**:
- ✅ All 10 users created with correct naming convention
- ✅ All 11 groups created with appropriate members
- ✅ No errors in PowerShell execution
- ✅ Portal verification screenshots captured
- ✅ GitHub repository updated with production-ready code

---

## 10. INTERVIEW TALKING POINTS

**Question**: "Tell me about a time you designed an identity architecture."

**Answer**: 
"At AQUAPINE CONSULT, I designed the Entra ID structure for 45 employees across two locations—Ibadan production farms and Lagos headquarters. The challenge was balancing security with operational efficiency, especially for our 24/7 hatchery operations. I implemented a two-tier group strategy: location-based groups for broad access control, and department-specific groups for fine-grained permissions. This allowed us to onboard seasonal workers in under 30 seconds via CSV bulk import, while maintaining strict access control for sensitive data like HR payroll and microbiology research. The architecture scaled from 45 to 60+ employees during harvest season without requiring any redesign."

---

**END OF DESIGN DOCUMENT**