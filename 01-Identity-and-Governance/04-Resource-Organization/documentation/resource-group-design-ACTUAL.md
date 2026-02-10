# AQUAPINE CONSULT - Resource Group Design (Production Implementation)
## Azure Resource Organization Strategy

**Author**: Olatunde Ogunti  
**Date**: 2026-02-08  
**Status**: ✅ Deployed and Operational  
**Last Updated**: Week 2 Day 1

---

## Design Philosophy

**Location-First Organization**: Resource groups align with AQUAPINE's physical locations and organizational structure rather than technical workload types.

**Rationale**:
1. **Business Alignment**: Employees think "Lagos office" and "Ibadan farms," not "storage workload" and "compute workload"
2. **Operational Reality**: Resources at each location share similar lifecycle and management needs
3. **Clear Ownership**: Location-based managers (Lagos IT Manager, Ibadan Farm Manager) naturally map to resource groups
4. **Future Scalability**: New locations (Ghana office, Kenya operations) follow same pattern

---

## Production Resource Groups

### 1. Lagos-HQ-RG (Lagos Office - Administrative)

**Location**: West Africa (metadata), Resources in Nigeria regions  
**Purpose**: Corporate headquarters administrative systems  
**Owner**: Lagos IT Manager (Olatunde Ogunti)

**Resources**:
| Resource | Type | Purpose | Primary Users |
|----------|------|---------|---------------|
| `hrdata-storage` | Storage Account | HR records, payroll data | HR Department (3 staff) |
| `sales-crm-db` | SQL Database | Customer relationship management | Sales Department (4 staff) |
| `logistics-inventory` | Storage Account | Inventory tracking, shipment logs | Logistics Department (6 staff) |

**RBAC Assignments**:
- **Resource-Level**:
  - `hrdata-storage` → Owner: HR Manager (individual)
  - `hrdata-storage` → Storage Blob Data Contributor: Lagos-HR-Security (group)
  - `sales-crm-db` → SQL DB Contributor: Lagos-Sales-Security (group)
  - `logistics-inventory` → Storage Blob Data Contributor: Lagos-Logistics-Security (group)

**Cost Allocation**:
- Department: Lagos Office (shared costs)
- Individual resource tags identify specific department (HR, Sales, Logistics)

---

### 2. Ibadan-Farms-RG (Ibadan Operations - Production)

**Location**: West Africa  
**Purpose**: Fish farm production operations (Bodija + Moniya farms)  
**Owner**: Farm Manager (Adebayo Oladipo)

**Resources**:
| Resource | Type | Purpose | Primary Users |
|----------|------|---------|---------------|
| `farm-monitoring` | Storage Account | Water quality logs, feeding schedules | Farm Operations (2 managers) |
| `lab-research` | Storage Account | Biological test results, fish health data | Microbiology Lab (4 staff) |
| `security-cctv` | Storage Account | CCTV footage, access logs | Farm Security (4 staff) |

**RBAC Assignments**:
- **Resource Group Level**:
  - Contributor: Farm Manager (Adebayo Oladipo) - full farm management
  
- **Resource-Level**:
  - `farm-monitoring` → Storage Blob Data Reader: Ibadan-FarmOps-Security (read-only)
  - `lab-research` → Storage Blob Data Contributor: Ibadan-MicrobiologyLab-Security (read-write)
  - `security-cctv` → Storage Blob Data Contributor: IT Manager (upload new footage)
  - `security-cctv` → Storage Blob Data Reader: Ibadan-FarmSecurity-Security (view footage)

**Security Considerations**:
- **Lab data**: Write access only to lab technicians (sensitive biological research)
- **CCTV footage**: IT uploads, security team views (separation of duties)
- **Farm monitoring**: Read-only for farm ops (prevent accidental deletion)

---

### 3. Shared-Services-RG (Organization-Wide Resources)

**Location**: West Africa  
**Purpose**: Resources shared across all AQUAPINE locations  
**Owner**: Global Admins (IT Management)

**Resources**:
| Resource | Type | Purpose | Primary Users |
|----------|------|---------|---------------|
| (Future) | Log Analytics | Centralized logging and monitoring | IT Department |
| (Future) | Key Vault | Secrets, certificates, keys | IT Department + Automation |
| (Future) | Virtual Network | Shared network infrastructure | All locations |

**RBAC Assignments**:
- **Resource Group Level**:
  - Reader: AQUAPINE-AllEmployees (45 users - view access for transparency)
  - Contributor: Lagos-IT-Security (manage shared infrastructure)

**Purpose**: Resources that don't belong to a specific location (networking, monitoring, security)

---

## Naming Convention

### Resource Group Naming

**Format**: `{Location}-{Purpose}-RG`

**Examples**:
- `Lagos-HQ-RG` — Lagos headquarters administrative resources
- `Ibadan-Farms-RG` — Ibadan farm production resources
- `Shared-Services-RG` — Organization-wide shared resources

**Rationale**:
- **Location-first**: Aligns with organizational thinking
- **Descriptive purpose**: Clear what the RG contains
- **-RG suffix**: Distinguishes resource groups from resources

---

### Resource Naming (Inside Resource Groups)

**Format**: `{purpose}-{type}` (lowercase, hyphen-separated)

**Examples**:
- `hrdata-storage` — HR data storage account
- `sales-crm-db` — Sales CRM database
- `farm-monitoring` — Farm monitoring data storage

**Rationale**:
- **Purpose-first**: What the resource does (not just "storage1")
- **Type suffix**: Identifies resource type at a glance
- **Lowercase + hyphens**: Azure naming best practice (some resources don't allow uppercase)

---

## RBAC Strategy

### Subscription-Level RBAC

**Philosophy**: Minimize subscription-level permissions; use resource group and resource scopes instead.

| Role | Assignment | Justification |
|------|------------|---------------|
| **Owner** | Lagos-IT-Security (2 users) | IT management team - emergency access, subscription configuration |
| **Contributor** | IT Support Tech (1 user) | Day-to-day infrastructure management without billing access |
| **Reader** | Lagos-Executive-Security (4 users) | Executives view all resources for budgeting and oversight |

**Key Decision**: No subscription-level Contributor for department managers → Forces resource-specific RBAC (more secure)

---

### Resource Group-Level RBAC

| Resource Group | Role | Assignment | Justification |
|----------------|------|------------|---------------|
| **Lagos-HQ-RG** | (None at RG level) | - | RBAC assigned at resource level for granularity |
| **Ibadan-Farms-RG** | Contributor | Farm Manager (individual) | Farm Manager oversees all farm resources |
| **Shared-Services-RG** | Reader | AQUAPINE-AllEmployees (45 users) | Company-wide transparency |
| **Shared-Services-RG** | Contributor | Lagos-IT-Security (2 users) | IT manages shared infrastructure |

---

### Resource-Level RBAC (Granular Control)

**Example: hrdata-storage (HR Storage Account)**
```powershell
# Owner: HR Manager (full control including access management)
New-AzRoleAssignment `
    -SignInName "funmilayo.ajayi@koguntioutlook.onmicrosoft.com" `
    -RoleDefinitionName "Owner" `
    -ResourceName "hrdata-storage" `
    -ResourceType "Microsoft.Storage/storageAccounts" `
    -ResourceGroupName "Lagos-HQ-RG"

# Storage Blob Data Contributor: HR Security Group (read-write data)
$hrGroup = Get-AzADGroup -DisplayName "Lagos-HR-Security"
New-AzRoleAssignment `
    -ObjectId $hrGroup.Id `
    -RoleDefinitionName "Storage Blob Data Contributor" `
    -ResourceName "hrdata-storage" `
    -ResourceType "Microsoft.Storage/storageAccounts" `
    -ResourceGroupName "Lagos-HQ-RG"
```

**Why Resource-Level?**
- HR Manager manages HR storage, but NOT sales database (even though both in Lagos-HQ-RG)
- Sales team accesses sales database, but NOT HR storage
- Principle of least privilege: Only the access needed, nothing more

---

## Cost Allocation Strategy

### Tagging Hierarchy

**Resource Group Tags** (inherited by resources):
```json
{
  "Environment": "Production",
  "ManagedBy": "IT-Department",
  "CostCenter": "CC-001-IT"
}
```

**Resource-Specific Tags** (override/supplement RG tags):
```json
{
  "Department": "HR",
  "DataClassification": "Confidential",
  "Owner": "funmilayo.ajayi@koguntioutlook.onmicrosoft.com",
  "CostCenter": "CC-002-HR"
}
```

**Cost Reporting Query** (by department):
```kusto
Resources
| where resourceGroup in ("Lagos-HQ-RG", "Ibadan-Farms-RG")
| extend Department = tostring(tags.Department)
| extend CostCenter = tostring(tags.CostCenter)
| summarize ResourceCount = count() by Department, CostCenter
| order by Department asc
```

---

## Design Decisions (Architecture Decision Records)

### ADR-001: Location-Based vs. Workload-Based Resource Groups

**Decision**: Use location-based resource groups (Lagos-HQ-RG, Ibadan-Farms-RG)  
**Alternatives Considered**: Workload-based (RG-Storage-HR, RG-Compute-Lagos)

**Rationale**:
- AQUAPINE's organizational structure is location-first (Lagos office, Ibadan farms)
- Employees naturally think "Lagos resources" vs "HR storage workload"
- Aligns with physical infrastructure and management structure
- Simplifies communication with non-technical stakeholders

**Trade-offs**:
- ✅ **Pro**: Business alignment, clear ownership, scalable to new locations
- ❌ **Con**: Mixed resource types in one RG (storage + databases + VMs)
- ✅ **Mitigation**: Use resource-level RBAC for granular control

---

### ADR-002: Resource-Level RBAC vs. Resource Group-Level

**Decision**: Implement resource-level RBAC for sensitive resources (HR data, lab research)

**Rationale**:
- HR Manager should manage HR storage but NOT sales database (even though both in Lagos-HQ-RG)
- Principle of least privilege requires resource-specific permissions
- Azure supports resource-level RBAC (use the capability)

**Trade-offs**:
- ✅ **Pro**: Maximum security, granular control, clear audit trail
- ❌ **Con**: More RBAC assignments to manage (complexity)
- ✅ **Mitigation**: Document all assignments, use groups where possible

---

### ADR-003: Individual vs. Group RBAC Assignments

**Decision**: Hybrid approach (individuals for managers, groups for teams)

**Rationale**:
- **Individuals**: Clear accountability (HR Manager owns HR data)
- **Groups**: Scalability (add new HR staff to group, instant access)
- **Hybrid**: Best of both worlds

**Examples**:
- HR Manager (individual) → Owner of hrdata-storage
- Lagos-HR-Security (group) → Storage Blob Data Contributor on hrdata-storage
- Farm Manager (individual) → Contributor on Ibadan-Farms-RG
- Ibadan-FarmOps-Security (group) → Reader on farm-monitoring

**Trade-offs**:
- ✅ **Pro**: Accountability + scalability
- ❌ **Con**: Must manage both individual and group assignments
- ✅ **Mitigation**: Use individuals sparingly (only managers with ownership)

---

## Migration Path (Future State)

### When to Create New Resource Groups

**Scenario 1: New Location**
- **Trigger**: AQUAPINE opens Ghana office
- **Action**: Create `Ghana-Office-RG` following same pattern
- **Example**:
```powershell
  New-AzResourceGroup -Name "Ghana-Office-RG" -Location "southafricanorth"
```

**Scenario 2: Environment Separation**
- **Trigger**: Need separate Dev/Test environment
- **Action**: Create `Lagos-HQ-Dev-RG`, `Ibadan-Farms-Test-RG`
- **Benefit**: Isolate production from testing

**Scenario 3: Workload Growth**
- **Trigger**: Lagos HQ exceeds 50 resources (hard to manage)
- **Action**: Split into `Lagos-HQ-Administrative-RG` and `Lagos-HQ-Applications-RG`

---

## Security Considerations

### Resource Locks (Future Implementation)

**Production Resource Groups**: Apply `CanNotDelete` lock
```powershell
New-AzResourceLock `
    -LockName "Prevent-Accidental-Deletion" `
    -LockLevel CanNotDelete `
    -ResourceGroupName "Lagos-HQ-RG"
```

**Why**: Prevent accidental deletion of production resources (requires lock removal first)

---

### Azure Policy Enforcement (Week 2 Implementation)

**Required Tags Policy**:
- All resources MUST have: `Department`, `Owner`, `CostCenter`
- Enforced at resource group scope
- Blocks resource creation if tags missing

**Allowed Locations Policy**:
- Resources MUST be in: West Africa, South Africa North, Nigeria regions
- Prevents accidental deployment to expensive regions (e.g., US East)

---

## Interview Talking Points

### Question 1: *"How did you design resource organization for AQUAPINE?"*

**Answer**:
> "I designed a location-based resource group structure that mirrors AQUAPINE's physical organization: Lagos-HQ-RG for headquarters, Ibadan-Farms-RG for production farms, and Shared-Services-RG for company-wide infrastructure.
> 
> This approach aligns with how employees think about the business—'Lagos office' vs 'Ibadan farms'—making it intuitive for non-technical stakeholders. Each resource group maps to a clear manager: I manage Lagos IT resources, the Farm Manager owns Ibadan farm resources.
> 
> I implemented granular RBAC at the resource level, not just resource group level. For example, the HR Manager has Owner permissions on the HR storage account but no access to the sales database, even though both are in the same Lagos-HQ-RG. This follows the principle of least privilege with surgical precision."

---

### Question 2: *"Why resource-level RBAC instead of just resource group-level?"*

**Answer**:
> "RBAC at the resource group level is simpler to manage, but it violates the principle of least privilege in AQUAPINE's case. If I gave the HR Manager 'Contributor' on the entire Lagos-HQ-RG, they'd have access to the sales CRM database and logistics inventory—data they don't need.
> 
> By implementing resource-level RBAC, I ensure the HR Manager has full control (Owner) over HR storage but zero access to other department systems in the same resource group. This required more granular RBAC assignments, but the security benefit outweighs the administrative overhead.
> 
> I use a hybrid approach: individuals for clear accountability (HR Manager owns HR data) and groups for scalability (Lagos-HR-Security group gives the HR team access). This combines the best of both worlds."

---

### Question 3: *"How would you scale this design if AQUAPINE expands to Ghana?"*

**Answer**:
> "The location-based pattern makes expansion straightforward. I'd create a new resource group called 'Ghana-Office-RG' following the same naming convention and RBAC structure. The Ghana Office Manager would get Contributor access to their resource group, and I'd assign Ghana department security groups to their respective resources.
> 
> If AQUAPINE grows large enough to need environment separation (Dev/Test/Prod), I'd introduce environment suffixes: 'Lagos-HQ-Prod-RG' and 'Lagos-HQ-Dev-RG'. At that scale, I'd also implement management groups to organize multiple subscriptions—Production subscription vs. Development subscription—with different Azure Policy enforcement at each level.
> 
> The architecture is designed to scale from 45 employees in two locations to hundreds of employees across multiple countries without a major restructure."

---

**Document Status**: ✅ Production Implementation (Deployed Week 1)  
**Next Update**: Week 2 Day 2 (Azure Policy implementation)