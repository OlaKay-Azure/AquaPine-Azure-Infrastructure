# AQUAPINE CONSULT - Azure Naming Conventions
**Author**: Olatunde Ogunti  
**Last Updated**: January 2026  
**Purpose**: Standardized naming for all Azure resources

---

## NAMING PATTERN

**Format**: `{company}-{environment}-{location}-{resource-type}-{purpose}-{instance}`

**Components**:
- **company**: `aquapine` (lowercase, no spaces)
- **environment**: `prod` | `dev` | `test`
- **location**: `wafr` (West Africa) | `saf` (South Africa) | `neu` (North Europe)
- **resource-type**: See table below
- **purpose**: Business function (e.g., `hrdata`, `sales`, `microbiology`)
- **instance**: `001`, `002` (if multiple instances needed)

---

## RESOURCE TYPE ABBREVIATIONS

| Azure Resource | Abbreviation | Example |
|----------------|--------------|---------|
| Resource Group | `rg` | `aquapine-prod-wafr-rg-identity-001` |
| Virtual Network | `vnet` | `aquapine-prod-wafr-vnet-ibadan-001` |
| Subnet | `snet` | `aquapine-prod-wafr-snet-farm-001` |
| Network Security Group | `nsg` | `aquapine-prod-wafr-nsg-web-001` |
| Storage Account | `st` | `aquapineprodwafrst001` (lowercase, no hyphens, max 24 chars) |
| Virtual Machine | `vm` | `aquapine-prod-wafr-vm-microbiology-001` |
| App Service | `app` | `aquapine-prod-wafr-app-dashboard-001` |
| Key Vault | `kv` | `aquapine-prod-wafr-kv-001` |
| Log Analytics Workspace | `law` | `aquapine-prod-wafr-law-001` |
| Recovery Services Vault | `rsv` | `aquapine-prod-wafr-rsv-001` |

---

## USER NAMING CONVENTION

**Format**: `firstname.lastname@aquapineconsult.onmicrosoft.com`

**Display Name**: `Firstname Lastname (Job Title - Location)`

**Examples**:
- `olatunde.ogunti@aquapineconsult.onmicrosoft.com` → "Olatunde Ogunti (IT Manager - Lagos)"
- `adebayo.johnson@aquapineconsult.onmicrosoft.com` → "Adebayo Johnson (Farm Manager - Bodija)"

---

## GROUP NAMING CONVENTION

**Format**: `AQUAPINE-{Location}-{Department}` or `AQUAPINE-{Function}`

**Examples**:
- `AQUAPINE-Ibadan-FarmOps`
- `AQUAPINE-Lagos-HR`
- `AQUAPINE-IT-Admins`
- `AQUAPINE-Finance-Access`

---

## TAGGING STRATEGY

**Mandatory Tags** (All Resources):
````
Environment: Production | Development | Test
Department: HR | IT | Sales | FarmOps | Microbiology | etc.
CostCenter: CC-001 (Lagos HQ) | CC-002 (Ibadan Farms)
Owner: olatunde.ogunti@aquapineconsult.onmicrosoft.com
BusinessUnit: Aquaculture Operations | Corporate Services
Optional Tags:
Project: AZ104-Infrastructure | MicrobiologyLab | SalesDashboard
DataClassification: Public | Internal | Confidential | Restricted
BackupPolicy: Daily | Weekly | Monthly

EXAMPLES BY SCENARIO
Ibadan Farm Operations
Resource Group: aquapine-prod-wafr-rg-ibadan-farms-001
VNet: aquapine-prod-wafr-vnet-ibadan-001
Storage Account: aquapineprodibadanst001
VM (Microbiology): aquapine-prod-wafr-vm-microlab-001
Lagos Headquarters
Resource Group: aquapine-prod-wafr-rg-lagos-hq-001
VNet: aquapine-prod-wafr-vnet-lagos-001
Storage Account: aquapineprodlagosst001
VM (Sales): aquapine-prod-wafr-vm-sales-001
Shared Services
Resource Group: aquapine-prod-wafr-rg-shared-services-001
Key Vault: aquapine-prod-wafr-kv-001
Log Analytics: aquapine-prod-wafr-law-001
Recovery Vault: aquapine-prod-wafr-rsv-001

Compliance Note: All names must comply with Azure naming restrictions (length, characters, uniqueness).