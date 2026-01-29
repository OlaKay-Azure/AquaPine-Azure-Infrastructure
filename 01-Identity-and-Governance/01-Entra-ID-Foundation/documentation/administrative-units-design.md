# AQUAPINE CONSULT - Administrative Units Architecture Design

## Executive Summary

### Business Challenge

AQUAPINE CONSULT operates a distributed aquaculture business with **45 employees across two geographic locations** separated by 24 kilometers:
- **Lagos Headquarters:** 21 employees (administrative functions: HR, IT, Sales, Logistics, Executive Management)
- **Ibadan Production Sites:** 24 employees (farm operations: Bodija Farm and Moniya Farm)

**Current State Problem:**  
All identity administration is centralized with the IT Manager in Lagos, creating a **single point of failure and operational bottleneck**. When farm employees experience account issues (password resets, account lockouts), they must contact the Lagos IT team, resulting in:
- **2-4 hour average response time** during business hours
- **Business disruptions** during off-hours (farms operate 24/7, IT support is 8am-5pm)
- **Productivity loss** estimated at 10-15 hours/month for IT Manager handling routine administrative tasks

### Solution: Administrative Units with Delegated Administration

Administrative Units enable **geographic delegation** of identity management while maintaining centralized security governance. By implementing scoped administrative roles, AQUAPINE can:

1. **Eliminate the IT bottleneck:** Site managers handle routine tasks (password resets, account unlocks) for their locations
2. **Reduce response time by 87%:** From 2-4 hours → 5 minutes (instant self-service)
3. **Maintain security boundaries:** HR Manager can only manage HR accounts (not farm operations), Farm Manager can only manage Ibadan accounts (not Lagos)
4. **Enable 24/7 support:** Farm Manager available on-site during night shift operations

### Business Problems Solved

**Problem 1: Geographic Distance & Response Delays**
- **Before:** Farm worker locked out → calls Lagos IT → waits 2-4 hours → productivity lost
- **After:** Farm worker locked out → Farm Manager unlocks account → 5 minutes → back to work

**Problem 2: Security Segregation**
- **Before:** IT Support Tech has User Administrator role (tenant-wide) → can accidentally modify HR payroll accounts (compliance risk)
- **After:** IT Support Tech has Password Administrator role scoped to Lagos-HQ Admin Unit → cannot access HR Admin Unit (segregation of duties)

**Problem 3: IT Overhead**
- **Before:** IT Manager spends 10-15 hours/month on password resets and account unlocks
- **After:** Site managers handle local issues → IT Manager focuses on strategic infrastructure work

### Return on Investment (ROI) Analysis

**License Cost:**
- Premium P1 requirement: 3 delegated administrators × $6/month = **$18/month** (~₦13,500/month)
- Annual cost: **$216/year** (~₦162,000/year)

**Time Savings:**
- IT Manager time recovered: 10-15 hours/month × 12 months = **120-180 hours/year**
- Hourly value (₦5,000/hour conservative): **₦600,000 - ₦900,000/year**

**Productivity Gains:**
- Reduced employee downtime: 50+ incidents/year × 2 hours average delay = **100 hours/year**
- Employee hourly cost (₦2,000/hour average): **₦200,000/year**

**Total Annual Benefit:**
- **₦800,000 - ₦1,100,000/year** (time + productivity)
- **Cost:** ₦162,000/year
- **Net ROI:** ₦640,000 - ₦940,000/year (**~400-580% return**)
- **Payback Period:** <1 month

### Current Implementation Limitation

**Azure for Students subscription does NOT include Premium P1 licensing** (Administrative Units feature).

**Mitigation Strategy:**
- Design and document complete Administrative Units architecture (portfolio value)
- Implement workaround using Security Groups for access control delegation
- Budget request prepared for management: ₦162,000/year for Premium P1 when moving to production subscription
- Architecture ready for immediate deployment when license acquired

**Portfolio Value:** This design demonstrates ability to architect enterprise-grade solutions within license constraints, showcasing cost-benefit analysis and strategic planning skills valued by employers.


## Dynamic Membership Rules

Administrative Units support **dynamic membership** (automated population based on user attributes), eliminating manual user assignment and ensuring the Admin Unit always reflects current organizational structure.

### Rule Syntax Requirements

**Critical:** Azure dynamic membership rules use **OData filter syntax** with specific formatting:
- Lowercase property names: `user.officeLocation` (NOT `User.OfficeLocation`)
- Operators: `-eq` (equals), `-ne` (not equals), `-contains`, `-and`, `-or`
- String values in quotes: `"Lagos HQ"`
- Boolean logic: Use parentheses for complex rules

---

### Lagos-HQ-AdminUnit (Dynamic)

**Membership Rule:**
```
(user.officeLocation -eq "Lagos HQ")
```

**Explanation:**  
Automatically includes all users where the `officeLocation` attribute equals "Lagos HQ" (exact match).

**Expected Member Count:** 21 users

**Departments Included:**
- Executive Management (4)
- IT Department (2)
- Human Resources (3)
- Sales Department (8)
- Logistics Department (4)

**Auto-Maintenance:**
- New Lagos hire with `officeLocation = "Lagos HQ"` → Auto-added to Admin Unit within 24 hours
- Employee transfers to Ibadan → `officeLocation` changes to "Bodija Farm" → Auto-removed from Lagos Admin Unit

---

### Ibadan-Farms-AdminUnit (Dynamic)

**Membership Rule:**
```
(user.officeLocation -eq "Bodija Farm") -or (user.officeLocation -eq "Moniya Farm")
```

**Explanation:**  
Includes users with `officeLocation` equal to either "Bodija Farm" OR "Moniya Farm" (logical OR).

**Expected Member Count:** 24 users

**Departments Included:**
- Farm Operations (6)
- Microbiology Lab (4)
- Feed Production (5)
- Hatchery Unit (3)
- Farm Security (4)
- Store Department (2)

**Why Two Locations in One Admin Unit:**
- Both farms are in Ibadan area (managed by same Farm Manager)
- Same delegated administrator (Adebayo Oladipo, Farm Manager)
- Operational efficiency: One Admin Unit to manage, not two separate ones

**Alternative Design (If needed in future):**
```
Split into two Admin Units:
- Bodija-Farm-AdminUnit: (user.officeLocation -eq "Bodija Farm")
- Moniya-Farm-AdminUnit: (user.officeLocation -eq "Moniya Farm")

Use case: If each farm gets dedicated site manager in Year 2+
```

---

### HR-Department-AdminUnit (Assigned/Static)

**Membership Rule:**  
`N/A - Manual assignment (Assigned membership type)`

**Why Not Dynamic:**
- Only 3 users (small, stable group)
- **Security-critical:** HR has access to sensitive payroll data
- Manual control ensures explicit approval for HR access
- Dynamic rule would be: `(user.department -eq "Human Resources")` but we prefer manual for audit trail

**Members (Manually Assigned):**
1. chioma.okoli@aquapineconsult.onmicrosoft.com (HR Manager)
2. ngozi.eze@aquapineconsult.onmicrosoft.com (HR Officer)
3. blessing.okoro@aquapineconsult.onmicrosoft.com (Payroll Administrator)

**Maintenance:**
- New HR hire: IT Manager manually adds to Admin Unit after background check
- HR employee departure: IT Manager manually removes immediately upon termination

---

### Ibadan-SecurityOps-AdminUnit (Assigned/Static)

**Membership Rule:**  
`N/A - Manual assignment (Assigned membership type)`

**Why Not Dynamic:**
- Only 4 users (small group)
- Department-based, not location-based (dynamic rule would need `department` attribute)
- Manual control ensures only authorized security personnel have access

**Members (Manually Assigned):**
1. godwin.eze@aquapineconsult.onmicrosoft.com (Chief Security Officer - Bodija)
2. suleiman.baba@aquapineconsult.onmicrosoft.com (Security Officer - Bodija)
3. rasheed.lawal@aquapineconsult.onmicrosoft.com (Security Officer - Moniya)
4. amos.adegoke@aquapineconsult.onmicrosoft.com (Security Officer - Bodija)

**Potential Dynamic Rule (Future):**
```
(user.department -eq "Farm Security")
```
Would auto-populate if all security staff have correct `department` attribute.

---

### Rule Processing & Validation

**Dynamic Membership Processing:**
- **Frequency:** Every 12-24 hours (not real-time)
- **Initial Population:** May take up to 24 hours after Admin Unit creation
- **Attribute Changes:** User's `officeLocation` change detected within 24 hours, membership updated

**Testing Dynamic Rules:**
```powershell
# Preview dynamic rule results BEFORE creating Admin Unit
$users = Get-MgUser -Filter "officeLocation eq 'Lagos HQ'"
Write-Host "Expected members: $($users.Count)"
$users | Select-Object DisplayName, UserPrincipalName, OfficeLocation

# Verify rule syntax is valid
# If this returns users, rule is correct
```

**Common Rule Errors to Avoid:**
```
❌ WRONG: User.OfficeLocation -eq "Lagos-HQ"
   (Uppercase property, hyphen in value)
   
✅ CORRECT: user.officeLocation -eq "Lagos HQ"
   (Lowercase property, space in value matches CSV)

❌ WRONG: (user.officeLocation -eq "Bodija Farm") and (user.department -eq "Farm Operations")
   (Wrong operator)
   
✅ CORRECT: (user.officeLocation -eq "Bodija Farm") -and (user.department -eq "Farm Operations")
   (Correct PowerShell operator)
```


## Role Assignments (Scoped Administrative Delegation)

Administrative Units enable **scoped role assignments** - delegated administrators can manage ONLY the users within their assigned Admin Unit, not the entire tenant.

### Complete Role Assignment Matrix

| Delegated Administrator | Entra ID Role | Scoped To Admin Unit | Permissions Granted | Business Justification |
|------------------------|---------------|---------------------|--------------------|-----------------------|
| **Tunde Bakare**<br>(IT Support Technician) | Password Administrator | Lagos-HQ-AdminUnit<br>(21 users) | - Reset passwords for Lagos users<br>- Unlock Lagos user accounts<br>- Force password change<br>- View Lagos user profiles | **Business Need:** IT Support Tech in Lagos office can handle routine password issues for Lagos employees without escalating to IT Manager. Improves response time during business hours (8am-5pm).<br><br>**Why Password Admin (not User Admin):** Cannot create/delete users (prevents accidental account deletions). Limited to password management only (least privilege). |
| **Adebayo Oladipo**<br>(Farm Manager) | Password Administrator | Ibadan-Farms-AdminUnit<br>(24 users) | - Reset passwords for all Ibadan farm employees<br>- Unlock farm worker accounts<br>- Force password change<br>- View farm user profiles | **Business Need:** Farms operate 24/7 (night shifts for pond monitoring, hatchery operations). Farm Manager on-site can resolve account lockouts immediately without waiting for Lagos IT (who may be offline after hours).<br><br>**Why Scoped:** Cannot access Lagos HQ users, cannot modify HR accounts, cannot change farm employees' job titles or departments (only password/unlock). |
| **Chioma Okoli**<br>(HR Manager) | User Administrator | HR-Department-AdminUnit<br>(3 users) | - Create new HR user accounts<br>- Modify HR user properties<br>- Disable/delete HR accounts<br>- Assign licenses to HR users<br>- Manage HR group memberships | **Business Need:** HR manages employee lifecycle for HR department (onboarding new HR hires, offboarding departures). Needs full user management within HR only (not company-wide).<br><br>**Why User Admin (not Password Admin):** Requires ability to create/modify/delete accounts for HR staff onboarding/offboarding. Scoped to HR-Department-AdminUnit prevents access to other departments (compliance: separation of duties). |
| **Godwin Eze**<br>(Chief Security Officer) | Helpdesk Administrator | Ibadan-SecurityOps-AdminUnit<br>(4 users) | - Reset passwords for security officers<br>- Manage MFA settings<br>- View security staff profiles<br>- Unlock accounts | **Business Need:** Security operates in shifts (day/night rotation). CSO can manage security personnel authentication issues during shift changes without IT dependency.<br><br>**Why Helpdesk Admin:** Includes MFA management (security officers use Microsoft Authenticator for Azure access - CSO can reset MFA if phone lost/replaced). |

---

### Role Assignment PowerShell Implementation

**When Premium P1 is available, use this script:**
```powershell
<#
.SYNOPSIS
    Assign scoped administrative roles to AQUAPINE delegated administrators
#>

# Connect with required permissions
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"

# Get Admin Units
$lagosAU = Get-MgDirectoryAdministrativeUnit -Filter "displayName eq 'Lagos-HQ-AdminUnit'"
$ibadanAU = Get-MgDirectoryAdministrativeUnit -Filter "displayName eq 'Ibadan-Farms-AdminUnit'"
$hrAU = Get-MgDirectoryAdministrativeUnit -Filter "displayName eq 'HR-Department-AdminUnit'"
$securityAU = Get-MgDirectoryAdministrativeUnit -Filter "displayName eq 'Ibadan-SecurityOps-AdminUnit'"

# Get role definitions
$passwordAdminRole = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'Password Administrator'"
$userAdminRole = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'User Administrator'"
$helpdeskAdminRole = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'Helpdesk Administrator'"

# Assign: IT Support Tech → Password Admin → Lagos AU
$itSupport = Get-MgUser -Filter "userPrincipalName eq 'tunde.bakare@aquapineconsult.onmicrosoft.com'"
New-MgRoleManagementDirectoryRoleAssignment `
    -RoleDefinitionId $passwordAdminRole.Id `
    -PrincipalId $itSupport.Id `
    -DirectoryScopeId "/administrativeUnits/$($lagosAU.Id)"

# Assign: Farm Manager → Password Admin → Ibadan AU
$farmManager = Get-MgUser -Filter "userPrincipalName eq 'adebayo.oladipo@aquapineconsult.onmicrosoft.com'"
New-MgRoleManagementDirectoryRoleAssignment `
    -RoleDefinitionId $passwordAdminRole.Id `
    -PrincipalId $farmManager.Id `
    -DirectoryScopeId "/administrativeUnits/$($ibadanAU.Id)"

# Assign: HR Manager → User Admin → HR AU
$hrManager = Get-MgUser -Filter "userPrincipalName eq 'chioma.okoli@aquapineconsult.onmicrosoft.com'"
New-MgRoleManagementDirectoryRoleAssignment `
    -RoleDefinitionId $userAdminRole.Id `
    -PrincipalId $hrManager.Id `
    -DirectoryScopeId "/administrativeUnits/$($hrAU.Id)"

# Assign: CSO → Helpdesk Admin → Security AU
$cso = Get-MgUser -Filter "userPrincipalName eq 'godwin.eze@aquapineconsult.onmicrosoft.com'"
New-MgRoleManagementDirectoryRoleAssignment `
    -RoleDefinitionId $helpdeskAdminRole.Id `
    -PrincipalId $cso.Id `
    -DirectoryScopeId "/administrativeUnits/$($securityAU.Id)"

Write-Host "✅ All scoped role assignments complete"
```

---

### Validation & Testing Procedures

**After Role Assignment, Test:**

1. **IT Support Tech Test (Tunde):**
   - Login to Azure Portal
   - Navigate to Entra ID → Users
   - Attempt to reset Lagos employee password → ✅ Should succeed
   - Attempt to reset Ibadan employee password → ❌ Should fail (not in scope)

2. **Farm Manager Test (Adebayo):**
   - Login to Azure Portal
   - Navigate to Entra ID → Users
   - Attempt to reset farm worker password → ✅ Should succeed
   - Attempt to create new user → ❌ Should fail (Password Admin cannot create users)

3. **HR Manager Test (Chioma):**
   - Login to Azure Portal
   - Navigate to Entra ID → Users
   - Attempt to create new HR user → ✅ Should succeed
   - Attempt to modify Sales employee → ❌ Should fail (not in HR Admin Unit)

**Audit & Compliance:**
- All scoped role assignments logged in Entra ID audit logs
- Monthly review: Verify delegated admins still require access
- Quarterly access review: Confirm no privilege creep