## Security Department Organizational Chart
```
┌─────────────────────────────────────────────────────┐
│     Operations Director (Emeka Nwosu)               │
│              (Lagos HQ)                              │
└──────────────────┬──────────────────────────────────┘
                   │
       ┌───────────┴────────────┐
       │                        │
┌──────▼──────────────┐  ┌──────▼──────────────┐
│ Chief Security      │  │ Chief Security      │
│ Officer             │  │ Officer             │
│ Godwin Eze          │  │ Rasheed Lawal       │
│ (Bodija Farm)       │  │ (Moniya Farm)       │
└──────┬──────────────┘  └──────┬──────────────┘
       │                        │
   ┌───┴────┐              ┌────┴────┐
   │        │              │         │
┌──▼──┐  ┌──▼──┐       ┌──▼──┐   ┌──▼──┐
│ SO  │  │ SO  │       │ SO  │   │ SO  │
│Sulei│  │Amos │       │(TBD)│   │(TBD)│
│man  │  │Adeg │       │     │   │     │
│Baba │  │oke  │       │     │   │     │
└─────┘  └─────┘       └─────┘   └─────┘

Legend:
SO = Security Officer
CSO = Chief Security Officer

Reporting Structure:
- Daily: Security Officers → CSO (site level)
- Weekly: CSO → Operations Director (company level)
- Emergency: Direct escalation to Operations Director + CEO

Shift Schedule:
- Bodija Farm: 2 officers per 12-hour shift (day/night rotation)
- Moniya Farm: 2 officers per 12-hour shift (day/night rotation)
- Coverage: 24/7/365 (farm operations never stop)
```

### CCTV Storage Cost Estimation

**Current Setup:**
- **Farms:** Bodija (4 cameras) + Moniya (4 cameras) = 8 cameras total
- **Resolution:** 1080p (2 Megabits per second per camera)
- **Recording Mode:** 24/7 continuous (critical for security compliance)
- **Retention:** 30 days (insurance requirement)

**Storage Calculation:**
```
Per Camera:
- Bitrate: 2 Mbps = 0.25 MB/s
- Per Hour: 0.25 MB/s × 3,600 seconds = 900 MB/hour
- Per Day: 900 MB × 24 hours = 21,600 MB = 21.6 GB/day
- Per Month (30 days): 21.6 GB × 30 = 648 GB/camera

Total Storage:
- 8 cameras × 648 GB = 5,184 GB = 5.2 TB per month
```

**Azure Blob Storage Pricing (Nigeria South Region):**

| Tier | Storage Cost (per GB/month) | Total Monthly Cost (5.2 TB) | Use Case |
|------|----------------------------|----------------------------|----------|
| **Hot** | $0.0208/GB | $108.16/month (~₦81,000) | Frequent access (last 7 days) |
| **Cool** | $0.0152/GB | $78.99/month (~₦59,000) | Infrequent access (8-30 days) |
| **Archive** | $0.00099/GB | $5.15/month (~₦3,900) | Long-term retention (31+ days) |

**AQUAPINE Recommended Strategy (Lifecycle Management):**
```
Tier 1 (Days 0-7): Hot Storage
- Recent footage for active investigations
- Storage: 1.2 TB
- Cost: $24.96/month (~₦18,700)

Tier 2 (Days 8-30): Cool Storage
- Historical footage for compliance
- Storage: 4.0 TB  
- Cost: $60.80/month (~₦45,600)

Total Cost: $85.76/month (~₦64,300/month or ~₦772,000/year)
```

**Cost Optimization Options:**

1. **Motion Detection Recording (Recommended):**
   - Record only when motion detected
   - Reduces storage by 60-70%
   - **New Cost:** ~$26/month (~₦19,500)
   - **Savings:** $60/month (~₦45,000)

2. **Lower Resolution (720p instead of 1080p):**
   - Reduces storage by 50%
   - May not meet insurance requirements
   - **Not recommended** for security compliance

3. **Archive Tier After 30 Days:**
   - Move to Archive tier after retention period
   - Retrieval cost: $0.02/GB (only if needed for legal/insurance)
   - **Additional Savings:** Minimal ongoing cost for long-term archival

**Final Recommendation:**
- **Month 1-3:** Full 24/7 recording (establish baseline, test system) = $86/month
- **Month 4+:** Switch to motion detection recording = $26/month
- **Annual Budget:** ~$400/year (~₦300,000/year) - cost-effective for farm security


### Complete Incident Management Workflow

#### Step 1: Incident Detection & Immediate Response (0-5 minutes)

**Security Officer Actions:**
1. Observes incident (theft attempt, trespassing, equipment damage, fire, injury)
2. Immediate radio call to CSO: "Code [Type] at [Location]"
3. Takes photo with phone/tablet
4. Secures scene if safe to do so

**CSO Actions:**
1. Logs incident time in notebook (temporary)
2. Dispatches additional officers if needed
3. Contacts emergency services if required (fire, medical, police)

---

#### Step 2: Digital Incident Logging (Within 30 minutes)

**Tool:** Microsoft Power Apps (mobile form)

**Security Officer Opens Power Apps Form:**

**Form Fields:**
```
┌─────────────────────────────────────────────┐
│  AQUAPINE SECURITY INCIDENT REPORT          │
├─────────────────────────────────────────────┤
│ Date/Time: [Auto-filled - Current timestamp]│
│                                              │
│ Location: [Dropdown]                        │
│   ☐ Bodija Farm - Gate                     │
│   ☐ Bodija Farm - Pond Area                │
│   ☐ Bodija Farm - Storage                  │
│   ☐ Moniya Farm - Gate                     │
│   ☐ Moniya Farm - Hatchery                 │
│   ☐ Moniya Farm - Feed Production          │
│                                              │
│ Incident Type: [Dropdown]                   │
│   ☐ Theft/Attempted Theft                  │
│   ☐ Trespassing                             │
│   ☐ Equipment Damage                        │
│   ☐ Safety Incident (Injury)                │
│   ☐ Fire                                     │
│   ☐ Unauthorized Vehicle                    │
│   ☐ Other                                    │
│                                              │
│ Severity: [Required]                         │
│   ○ LOW (Routine observation)               │
│   ○ MEDIUM (Property damage, minor incident)│
│   ○ HIGH (Attempted theft, safety risk)     │
│   ○ CRITICAL (Active threat, injury, fire)  │
│                                              │
│ Description: [Text area, min 50 characters] │
│ [Describe what happened, who involved, etc.]│
│                                              │
│ CCTV Reference: [Dropdown]                  │
│   ☐ Camera 1 (Bodija Gate)                 │
│   ☐ Camera 2 (Bodija Pond)                 │
│   [etc.]                                     │
│                                              │
│ Photos: [Upload from tablet/phone camera]   │
│   [+] Add Photo                             │
│                                              │
│ Witnesses: [Text]                           │
│ [List any farm staff who witnessed incident]│
│                                              │
│ Action Taken: [Text]                        │
│ [What did you do in response?]              │
│                                              │
│ Officer Name: [Auto-filled from login]      │
│ Officer Signature: [Digital signature pad]  │
│                                              │
│        [SUBMIT REPORT]                       │
└─────────────────────────────────────────────┘
```

**Backend:** Power Apps saves to SharePoint list + sends email to CSO

---

#### Step 3: CSO Review & Validation (Within 1 hour)

**CSO Receives:**
- Email notification: "New Security Incident - [Severity] - [Location]"
- Teams message (if high/critical severity)

**CSO Actions in SharePoint:**
1. Opens incident report in SharePoint list
2. Reviews details, photos, CCTV reference
3. Validates information accuracy
4. Adds notes/comments
5. Determines escalation level

---

#### Step 4: Escalation Process (Based on Severity)
```
┌────────────────────────────────────────────────┐
│         ESCALATION DECISION TREE               │
├────────────────────────────────────────────────┤
│                                                │
│ SEVERITY: LOW                                  │
│ ├─ Examples:                                   │
│ │  • Unauthorized parking                     │
│ │  • Minor equipment wear                     │
│ │  • Routine visitor log                      │
│ ├─ Action:                                     │
│ │  • Document only                            │
│ │  • No escalation                            │
│ │  • CSO reviews weekly                       │
│ └─ Response Time: None required                │
│                                                │
├────────────────────────────────────────────────┤
│ SEVERITY: MEDIUM                               │
│ ├─ Examples:                                   │
│ │  • Minor property damage (<₦50,000)         │
│ │  • Suspicious activity (no threat)          │
│ │  • Equipment malfunction                    │
│ ├─ Action:                                     │
│ │  • CSO investigates                         │
│ │  • Email report to Operations Director      │
│ │  • Update incident status in SharePoint     │
│ └─ Response Time: Within 24 hours              │
│                                                │
├────────────────────────────────────────────────┤
│ SEVERITY: HIGH                                 │
│ ├─ Examples:                                   │
│ │  • Attempted theft                          │
│ │  • Significant property damage (>₦50,000)   │
│ │  • Security breach                          │
│ │  • Aggressive trespasser                    │
│ ├─ Action:                                     │
│ │  • Immediate phone call: CSO → Ops Director │
│ │  • Written report within 4 hours            │
│ │  • Police report filed (if applicable)      │
│ │  • CCTV footage preserved                   │
│ └─ Response Time: Immediate (phone + email)    │
│                                                │
├────────────────────────────────────────────────┤
│ SEVERITY: CRITICAL                             │
│ ├─ Examples:                                   │
│ │  • Active security threat                   │
│ │  • Fire/explosion                           │
│ │  • Employee injury                          │
│ │  • Major theft in progress                  │
│ ├─ Action:                                     │
│ │  • 911/Emergency services (immediate)       │
│ │  • Phone: CSO → Ops Director → CEO         │
│ │  • All hands response                       │
│ │  • Incident command center activated        │
│ │  • External authorities notified            │
│ └─ Response Time: Immediate (within 5 min)     │
└────────────────────────────────────────────────┘
```

---

#### Step 5: Documentation & Investigation

**CSO Actions:**
1. Links CCTV footage to incident report in SharePoint
2. Adds investigation notes
3. Attaches external documents (police report, insurance claim)
4. Updates incident status:
   - Open
   - Under Investigation
   - Resolved
   - Closed

**Azure Storage Integration:**
- CCTV footage: `security-cctv` blob container (read-only link in SharePoint)
- Incident photos: SharePoint library (auto-uploaded from Power Apps)
- Documents: SharePoint library (police reports, insurance forms)

---

#### Step 6: Resolution & Closure

**Required Before Closing:**
- [ ] Root cause identified
- [ ] Corrective action taken (repair, policy change, training)
- [ ] CCTV footage reviewed and linked
- [ ] Police report filed (if required)
- [ ] Insurance claim submitted (if applicable)
- [ ] Lessons learned documented
- [ ] Preventive measures implemented

**CSO Updates SharePoint:**
```
Status: Closed
Resolution Date: [Date]
Resolution Notes: [Corrective actions taken]
Follow-up Required: Yes/No
Follow-up Date: [If yes, when to review]
```

---

#### Step 7: Monthly Reporting & Analytics

**Automated Reports (Power BI Dashboard):**

**Metrics Tracked:**
- Total incidents by month
- Incidents by type (theft, trespassing, damage, etc.)
- Incidents by location (Bodija vs. Moniya)
- Incidents by severity
- Average response time
- Repeat incidents (patterns)
- Cost impact (damage, theft value)

**Monthly Meeting (CSO + Operations Director):**
- Review Power BI dashboard
- Discuss trends
- Identify risk areas
- Budget for security improvements
- Update security policies

---

### Azure Integration Architecture
```
INCIDENT WORKFLOW DATA FLOW:

Security Officer (Tablet/Phone)
    ↓
Power Apps (Mobile Form)
    ↓
Microsoft SharePoint Online (Incident List)
    ↓ (triggers)
Power Automate Flow
    ↓
    ├→ Send Email to CSO
    ├→ Send Teams Message (if High/Critical)
    ├→ Log to Azure Monitor (audit trail)
    └→ Update Power BI Dataset
    ↓
Power BI Dashboard
    ↓
Operations Director (Monthly Review)

CCTV Integration:
Azure Blob Storage (security-cctv)
    ↓
SharePoint (Hyperlink to footage)
    ↓
Security Officer (Playback in browser)
```

**Azure Services Used:**
- **Power Apps:** Incident reporting form
- **SharePoint Online:** Incident database and document library
- **Power Automate:** Workflow automation (notifications, escalations)
- **Azure Blob Storage:** CCTV footage archive
- **Power BI:** Analytics dashboard
- **Azure Monitor:** Audit logging and compliance


### Devices Issued to Security Personnel

**Hardware Procurement:**

| Device Type | Model | Quantity | Assignment | Purpose |
|-------------|-------|----------|------------|---------|
| **Rugged Tablet** | Samsung Galaxy Tab Active3 | 4 units | 1 per site gate office | Incident reporting, visitor logs, CCTV playback |
| **Mobile Phone** | Nokia G20 (Rugged) | 4 units | 1 per CSO/SO on duty | Emergency calls, Teams notifications, photo capture |
| **Tablet Charging Stations** | Multi-device dock | 2 units | Bodija + Moniya security offices | Keep devices charged 24/7 |

**Total Cost:** ~₦400,000 one-time (tablets + phones + accessories)

---

**Device Configuration (Azure/Intune Management):**

**Enrollment:**
1. Devices enrolled in Microsoft Intune (Mobile Device Management)
2. Corporate account required for device activation
3. Security policies enforced automatically

**Security Policies Applied:**
```
Device Requirements:
- 6-digit PIN or biometric unlock (mandatory)
- Screen lock after 2 minutes of inactivity
- Failed unlock attempts (10 max) → device wipe
- Encryption enabled (full device)
- Location tracking enabled (if lost/stolen)

App Restrictions:
- Only approved apps can be installed:
  ✅ Power Apps
  ✅ Microsoft Teams
  ✅ Azure Authenticator (MFA)
  ✅ SharePoint
  ✅ Edge browser (CCTV playback)
  ✅ Camera (incident photos)
  ❌ Personal email clients
  ❌ Social media apps
  ❌ Games/entertainment apps

Network Access:
- Farm WiFi only (guest WiFi blocked)
- VPN required for CCTV access from outside farm
- Data usage monitored (alert if >5GB/month - unusual)
```

**Pre-Installed Apps:**
1. **Microsoft Power Apps:** Incident reporting form
2. **Microsoft Teams:** Communication with CSO and Operations Director
3. **Microsoft Authenticator:** Multi-factor authentication for Azure login
4. **SharePoint Mobile:** Access incident history, view documents
5. **Microsoft Edge:** CCTV footage playback (Azure Blob Storage URLs)

---

**User Access Configuration:**

**Entra ID Account Setup:**
```
Example: Suleiman Baba (Security Officer - Bodija)

User Principal Name: suleiman.baba@aquapineconsult.onmicrosoft.com
Group Membership: Ibadan-FarmSecurity-Security
MFA Enabled: Yes (Microsoft Authenticator app)
Conditional Access: 
  - Require MFA for Azure Portal access
  - Allow access only from enrolled devices
  - Block access from unrecognized locations
```

**Azure RBAC Permissions (via Group):**
```
Ibadan-FarmSecurity-Security Group:
  └─ Storage Blob Data Reader
      └─ Scope: security-cctv storage account
      └─ Effect: Can view CCTV footage (read-only)
      └─ Cannot: Upload, modify, or delete footage
```

**SharePoint Permissions:**
```
Ibadan-FarmSecurity-Security Group:
  └─ Contribute
      └─ Scope: SecurityIncidents SharePoint list
      └─ Effect: Can create incident reports, view all incidents
      └─ Cannot: Delete others' reports (only their own drafts)
```

---

**Device Operational Procedures:**

**Daily Checklist (Start of Shift):**
- [ ] Retrieve tablet from charging dock (100% battery)
- [ ] Verify Power Apps opens (internet connection working)
- [ ] Check Teams for overnight messages
- [ ] Test camera function (incident photo capability)

**End of Shift:**
- [ ] Submit any pending incident reports
- [ ] Return tablet to charging dock
- [ ] Handover notes to incoming officer (Teams message)

**Lost/Stolen Device Protocol:**
1. Security Officer reports to CSO immediately
2. CSO contacts IT Manager (Olatunde Ogunti)
3. IT Manager remotely wipes device via Intune
4. All data erased (cannot be accessed if stolen)
5. Replacement device issued from spare inventory
6. Incident logged (for insurance and audit)

---

**Training Program:**

**Week 1 (Onboarding):**
- Azure account setup and MFA enrollment
- Power Apps incident reporting (hands-on practice)
- CCTV playback procedure
- Teams communication basics

**Monthly Refresher:**
- Review incident reporting accuracy
- Update procedures if changed
- Practice emergency escalation workflow