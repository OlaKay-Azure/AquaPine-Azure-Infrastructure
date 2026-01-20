# AQUAPINE CONSULT - Azure Naming Conventions

**Author**: Olatunde Ogunti  
**Last Updated**: January 2026  
**Purpose**: Standardized naming across all Azure resources

---

##  NAMING PRINCIPLES

1. **Consistency**: Same pattern across all resources
2. **Clarity**: Purpose obvious from name
3. **Brevity**: Short enough for portal UI display
4. **Scope**: Include location, environment, function
5. **Uniqueness**: Globally unique where required (storage accounts)

---

##  STANDARD FORMAT
```
[resource-type]-[organization]-[function]-[environment]-[location]
Components:

resource-type: Azure resource abbreviation (see table below)
organization: aquapine (lowercase)
function: Purpose or workload (e.g., identity, storage, network)
environment: dev | test | prod
location: Azure region code (see table below)

Examples:

rg-aquapine-identity-prod-we (Resource Group for Identity in West Europe)
st-aquapine-hrmicro-prod-we (Storage Account for HR + Microbiology)
vm-aquapine-farmops-prod-we (VM for Farm Operations)


🗂️ RESOURCE TYPE ABBREVIATIONS
Resource TypeAbbreviationExampleResource Grouprgrg-aquapine-identity-prod-weVirtual Networkvnetvnet-aquapine-ibadan-prod-weSubnetsnetsnet-aquapine-farmops-prod-weNetwork Security Groupnsgnsg-aquapine-web-prod-weVirtual Machinevmvm-aquapine-microlab-prod-weStorage Accountststaquapinehrmicro01 (no hyphens, max 24 chars)App Service Planaspasp-aquapine-web-prod-weApp Serviceappapp-aquapine-dashboard-prod-weAzure SQL Databasesqldbsqldb-aquapine-sales-prod-weAzure SQL Serversqlsql-aquapine-prod-weKey Vaultkvkv-aquapine-secrets-we (max 24 chars)Log Analytics Workspaceloglog-aquapine-monitoring-weAzure Backup Vaultrsvrsv-aquapine-backup-prod-wePublic IP Addresspippip-aquapine-vpngw-prod-weLoad Balancerlblb-aquapine-web-prod-weVPN Gatewayvpngwvpngw-aquapine-ibadan-prod-we

🌍 LOCATION CODES
Azure RegionCodeAQUAPINE UsageWest EuropewePrimary region (Netherlands - low latency to Nigeria)North EuropeneDR/Backup region (Ireland)South Africa NorthsanData residency option (Johannesburg)UK SouthuksAlternative EU region (London)
AQUAPINE Standard: Use we (West Europe) for all primary deployments unless compliance requires Africa region.

👥 USER NAMING CONVENTIONS
Format: firstname.lastname@aquapineconsult.onmicrosoft.com
Examples:

olatunde.ogunti@aquapineconsult.onmicrosoft.com
adebayo.johnson@aquapineconsult.onmicrosoft.com

Display Name Format: Firstname Lastname (Job Title - Location)
Examples:

Olatunde Ogunti (IT Manager - Lagos)
Adebayo Johnson (Farm Manager - Bodija)


👨‍👩‍👧‍👦 GROUP NAMING CONVENTIONS
Format: AQUAPINE-[Location/Function]-[Department]
Examples:

AQUAPINE-Ibadan-All (All Ibadan employees)
AQUAPINE-Ibadan-FarmOps (Farm Operations department)
AQUAPINE-Lagos-HR (HR department)
AQUAPINE-IT-Admins (IT administrators - cross-site)


🏷️ TAGGING STRATEGY
Required Tags (All resources):
Tag NamePurposeExample ValuesEnvironmentDeployment stageDev, Test, ProdCostCenterDepartment for billingIbadan-FarmOps, Lagos-HR, ITOwnerTechnical contactolatunde.ogunti@aquapineconsult.comProjectInitiative nameAZ104-Infrastructure, FarmAutomationCriticalityBusiness impactHigh, Medium, Low
Optional Tags:
Tag NamePurposeExample ValuesDataClassificationData sensitivityPublic, Internal, Confidential, RestrictedBackupPolicyRetention requirementDaily-30d, Weekly-90d, NoneComplianceRequirementRegulatory needGDPR, NigeriaDataProtection, NoneCreatedDateDeployment tracking2026-01-20MaintenanceWindowAllowed downtimeSunday-02:00-06:00
PowerShell Example:
powershell$tags = @{
    Environment = "Prod"
    CostCenter = "Lagos-HR"
    Owner = "olatunde.ogunti@aquapineconsult.com"
    Project = "AZ104-Infrastructure"
    Criticality = "High"
    DataClassification = "Confidential"
}

New-AzResourceGroup -Name "rg-aquapine-hr-prod-we" -Location "westeurope" -Tag $tags
```

---

##  PROHIBITED PATTERNS

**NEVER Use**:
- ❌ Non-descriptive names: `rg-test1`, `vm-temp`, `storage123`
- ❌ Personal names: `rg-olatunde`, `vm-johns-machine`
- ❌ Unclear abbreviations: `rg-ap-xyz-p-w` (what is xyz?)
- ❌ Inconsistent casing: `RG-AQUAPINE-identity-PROD-we`
- ❌ Special characters in storage accounts: `st-aquapine-hr-prod` (hyphens not allowed)

---

##  NAMING CHECKLIST

Before creating any resource, verify:

- [ ] Follows `[type]-[org]-[function]-[env]-[location]` pattern
- [ ] Uses approved resource type abbreviation
- [ ] Includes environment (`dev`, `test`, `prod`)
- [ ] Includes location code (`we`, `ne`, etc.)
- [ ] All lowercase with hyphens (except storage accounts)
- [ ] Meaningful function/purpose clear from name
- [ ] Does not exceed Azure limits (24 chars for storage, 64 for most resources)
- [ ] Required tags applied (`Environment`, `CostCenter`, `Owner`, `Project`, `Criticality`)

---

##  EXCEPTION PROCESS

If you need to deviate from this standard:

1. **Document reason** in deployment README
2. **Get approval** from IT Manager (Olatunde Ogunti)
3. **Add exception tag**: `NamingException = "Reason for deviation"`

**Example Exception**:
- Resource: `staquapinebackupwe01` (exceeds 24 char limit if following standard)
- Reason: Storage accounts have 24-character limit and no hyphens allowed
- Approved deviation: Remove hyphens, abbreviate function

---

**Maintained By**: IT Department, Aquapine Consult  
**Review Cycle**: Quarterly  
**Next Review**: April 2026