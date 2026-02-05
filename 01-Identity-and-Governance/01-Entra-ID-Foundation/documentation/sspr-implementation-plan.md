# Self-Service Password Reset (SSPR) Implementation Plan
## AQUAPINE CONSULT - Identity Management Strategy

**Document Owner**: Olatunde Ogunti, Azure Administrator  
**Date**: 2026-02-05  
**Status**: Proposed (Pending Premium License Acquisition)

---

## Executive Summary

Self-Service Password Reset (SSPR) would reduce IT helpdesk burden by approximately 70% and enable 24/7 self-service capability for AQUAPINE's distributed workforce (Ibadan farms + Lagos office). However, SSPR requires **Azure AD Premium P1** licensing.

**Current State**: Azure AD Free (included with Azure for Students)  
**Target State**: Azure AD Premium P1 (when budget permits)  
**Interim Solution**: Documented manual reset procedure + basic MFA

---

## Business Need

### Operational Pain Points
1. **24/7 Hatchery Operations**: Night shift workers at Moniya farm cannot access IT support for password resets
2. **Distributed Workforce**: 24 employees in Ibadan, 21 in Lagos — no centralized helpdesk
3. **IT Resource Constraints**: 2-person IT team cannot provide round-the-clock password support
4. **Productivity Loss**: Average 45 minutes per password reset incident (user wait time + IT intervention)

### Estimated Impact
- **Current State**: ~15 password reset requests/month across 45 users
- **Time Cost**: 15 incidents × 45 min = 11.25 hours/month IT time
- **Productivity Cost**: 15 users × 45 min = 11.25 hours/month user downtime
- **Total Monthly Impact**: 22.5 hours organizational productivity loss

---

## Technical Requirements

### Azure AD Licensing Comparison

| Feature | Azure AD Free (Current) | Azure AD Premium P1 (Required) |
|---------|------------------------|--------------------------------|
| User/Group Management | ✅ Yes | ✅ Yes |
| Basic MFA | ✅ Yes | ✅ Yes |
| Self-Service Password Change | ✅ Yes | ✅ Yes |
| **Self-Service Password Reset** | ❌ **No** | ✅ **Yes** |
| Conditional Access | ❌ No | ✅ Yes |
| Identity Protection | ❌ No | ✅ Yes |
| **Monthly Cost/User** | **$0** | **~$6** |

### SSPR Configuration (Planned)

**When Premium license is acquired, configure:**
```yaml
SSPR Policy:
  Scope: All Users (45 employees)
  Authentication Methods Required: 2
  Allowed Methods:
    - Mobile phone (SMS) — Primary for farm workers
    - Email — Secondary verification
    - Mobile app notification (Microsoft Authenticator) — Recommended
  Registration Enforcement: Required on next sign-in
  Notifications:
    - User notification: Enabled
    - Admin notification: Enabled (security audit)
  Password Writeback: N/A (cloud-only deployment)
```

**Validation Checklist**:
- [ ] Users can access https://aka.ms/sspr
- [ ] Authentication methods registered (mobile + email minimum)
- [ ] Test password reset successful without IT intervention
- [ ] Admin notification received for audit trail

---

## Cost-Benefit Analysis

### Option 1: Maintain Azure AD Free
**Annual Cost**: $0  
**IT Labor Cost**: 11.25 hrs/month × $20/hr × 12 = **$2,700/year**

### Option 2: Upgrade to Azure AD Premium P1
**Annual License Cost**: 45 users × $6/month × 12 = **$3,240/year**  
**IT Labor Savings**: 70% reduction = 7.88 hrs/month × $20/hr × 12 = **$1,891/year**  
**Net Cost**: $3,240 - $1,891 = **$1,349/year**

### Option 3: Hybrid Approach (First 12 Months)
**Recommendation**: 
- Maintain Azure AD Free for first year of cloud operations
- Implement robust manual password reset procedure (documented runbook)
- Enable basic MFA for admin accounts (available in Free tier)
- Re-evaluate Premium licensing after 12 months when:
  - Cloud maturity increases
  - User adoption stabilizes
  - Budget allocated for recurring cloud costs

**Year 1 Decision**: Defer Premium P1 upgrade  
**Year 2 Decision**: Re-assess based on actual helpdesk ticket volume

---

## Implementation Approach (When Licensed)

### Phase 1: Pilot (Week 1-2)
- Enable SSPR for IT Department only (2 users)
- Test authentication methods
- Validate notification workflow
- Document user experience

### Phase 2: Departmental Rollout (Week 3-4)
- Enable for Lagos office (21 users)
- Conduct user training sessions
- Monitor adoption metrics
- Address registration issues

### Phase 3: Full Deployment (Week 5-6)
- Enable for Ibadan farms (24 users)
- On-site training at Bodija and Moniya locations
- Provide multilingual support (English + Yoruba + Igbo)
- Establish 30-day monitoring period

### Success Metrics
- 90%+ user registration within 30 days
- 70%+ reduction in IT password reset tickets
- <5 minute average self-service reset time
- Zero security incidents related to SSPR

---

## Interim Solution (Current Implementation)

**While operating on Azure AD Free:**

### Manual Password Reset Procedure

**IT Helpdesk Runbook**:
```powershell
# Manual Password Reset Script
# Location: IT-Operations/Helpdesk/password-reset.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName
)

# Connect to Azure AD
Connect-AzAccount

# Generate temporary password
$TempPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object {[char]$_})

# Reset password
Set-AzADUserPassword -ObjectId $UserPrincipalName `
    -Password (ConvertTo-SecureString $TempPassword -AsPlainText -Force) `
    -ForceChangePasswordNextSignIn $true

Write-Host "✅ Password reset successful for: $UserPrincipalName"
Write-Host "Temporary password: $TempPassword"
Write-Host "⚠️  User MUST change password on next sign-in"

# Log incident (for future SSPR ROI calculation)
$LogEntry = [PSCustomObject]@{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    User = $UserPrincipalName
    Action = "Manual Password Reset"
    Technician = $env:USERNAME
}
$LogEntry | Export-Csv -Path "C:\IT-Logs\password-resets.csv" -Append -NoTypeInformation
```

**User Communication Template**:
```
Subject: Your AQUAPINE Account Password Has Been Reset

Dear [Employee Name],

Your account password has been reset by the IT team.

Temporary Password: [TEMP_PASSWORD]

⚠️ IMPORTANT: You MUST change this password immediately upon next login.

Steps:
1. Go to https://portal.office.com
2. Enter your email: [user@koguntioutlook.onmicrosoft.com]
3. Enter temporary password above
4. Follow prompts to create new secure password

Password Requirements:
- Minimum 8 characters
- Include uppercase, lowercase, number, special character
- Cannot reuse last 5 passwords

Need help? Contact IT: it@aquapineconsult.com | +234-XXX-XXXX

- AQUAPINE IT Team
```

---

## Risk Mitigation

### Risks of NOT Implementing SSPR

| Risk | Impact | Mitigation (Without Premium) |
|------|--------|------------------------------|
| After-hours lockouts | High | Document emergency IT contact procedure |
| IT bottleneck | Medium | Train 2 backup staff on password reset |
| User frustration | Medium | Set SLA: 2-hour response time during business hours |
| Security incidents | Low | Enforce strong password policy + MFA for admins |

### Security Considerations

**With or without SSPR, implement:**
- ✅ Password complexity requirements (enabled by default)
- ✅ Account lockout policy (5 failed attempts)
- ✅ MFA for administrative accounts (available in Free tier)
- ✅ Regular password expiration reminders (90-day cycle)
- ✅ User security awareness training

---

## Recommendations for AQUAPINE Leadership

### Short-Term (0-6 months)
1. ✅ Maintain Azure AD Free tier
2. ✅ Implement manual password reset runbook
3. ✅ Enable MFA for all admin accounts
4. ✅ Track password reset incidents for ROI analysis
5. ✅ Conduct user training on password security

### Medium-Term (6-12 months)
1. 📊 Analyze 6-month password reset data
2. 💰 Calculate actual IT labor cost
3. 📈 Project SSPR ROI based on real metrics
4. 🗳️ Present business case to leadership for Premium upgrade

### Long-Term (12+ months)
1. 🚀 Migrate to Azure AD Premium P1 if ROI justifies cost
2. 🔐 Implement Conditional Access policies
3. 🛡️ Enable Identity Protection
4. 📊 Deploy advanced monitoring and reporting

---

## Interview Talking Points

**Question**: *"How do you balance security needs with budget constraints?"*

**Answer**: 
> "At AQUAPINE CONSULT, I evaluated Self-Service Password Reset (SSPR) to reduce helpdesk burden for our 45-employee organization. While SSPR would save approximately 11 hours/month of IT time, it required Azure AD Premium P1 licensing at $3,240/year.
> 
> I conducted a cost-benefit analysis and recommended deferring the Premium upgrade for the first year while the organization established cloud maturity. Instead, I implemented a robust manual password reset procedure with documented runbooks, established SLAs, and enabled free-tier MFA for administrative accounts.
> 
> I also set up incident tracking to measure actual password reset volume, allowing us to make a data-driven decision about Premium licensing after 12 months. This approach demonstrated fiscal responsibility while maintaining security and operational efficiency."

---

## Conclusion

SSPR is a valuable feature that would improve AQUAPINE's operational efficiency. However, the Premium P1 licensing cost must be justified through data-driven analysis. 

**Current Decision**: Implement interim manual procedures, track metrics, and revisit Premium licensing after demonstrating cloud value in other areas (compute, storage, networking optimization).

**This is the Azure Administrator's responsibility**: Technical capability + business acumen.

---

**Document Status**: ✅ Approved for Portfolio  
**Next Review Date**: 2026-08-05 (6 months from implementation)