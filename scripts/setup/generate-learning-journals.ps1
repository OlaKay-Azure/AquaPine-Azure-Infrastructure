<#
.SYNOPSIS
    Generates learning journal folder structure and Markdown templates

.DESCRIPTION
    Creates weekly folders (week-01 through week-08) with daily journal templates (day-1.md through day-7.md)
    and end-of-week reflection templates. Script is idempotent and will not overwrite existing files.

.PARAMETER RepositoryRoot
    Root path of the AquaPine-Azure-Infrastructure repository
    Default: Current directory

.EXAMPLE
    .\scripts\setup\generate-learning-journals.ps1

.EXAMPLE
    .\scripts\setup\generate-learning-journals.ps1 -RepositoryRoot "C:\Git\AquaPine-Azure-Infrastructure"

.NOTES
    Author: Olatunde Ogunti
    Organization: Aquapine Consult
    Purpose: Portfolio learning journal automation for AZ-104 study program
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RepositoryRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Color constants
$ColorSuccess = "Green"
$ColorSkip = "Yellow"
$ColorInfo = "Cyan"
$ColorError = "Red"

# Script configuration
$LearningJournalBasePath = Join-Path $RepositoryRoot "docs\learning-journal"
$TotalWeeks = 8
$DaysPerWeek = 7

# Statistics tracking
$FoldersCreated = 0
$FilesCreated = 0
$FilesSkipped = 0

# Header
Write-Host "`n========================================================" -ForegroundColor $ColorInfo
Write-Host "  AQUAPINE LEARNING JOURNAL GENERATOR" -ForegroundColor $ColorInfo
Write-Host "========================================================`n" -ForegroundColor $ColorInfo
Write-Host "Repository Root: $RepositoryRoot" -ForegroundColor $ColorInfo
Write-Host "Journal Base Path: $LearningJournalBasePath`n" -ForegroundColor $ColorInfo

# Verify repository root
if (-not (Test-Path (Join-Path $RepositoryRoot "README.md"))) {
    Write-Host "❌ ERROR: Not a valid repository root (README.md not found)" -ForegroundColor $ColorError
    Write-Host "Current path: $RepositoryRoot`n" -ForegroundColor $ColorError
    exit 1
}

# Ensure learning-journal base directory exists
if (-not (Test-Path $LearningJournalBasePath)) {
    New-Item -Path $LearningJournalBasePath -ItemType Directory -Force | Out-Null
    Write-Host "✅ Created base directory: learning-journal/" -ForegroundColor $ColorSuccess
}

# Generate week folders and journal templates
for ($week = 1; $week -le $TotalWeeks; $week++) {
    $weekFolder = "week-{0:D2}" -f $week
    $weekPath = Join-Path $LearningJournalBasePath $weekFolder
    
    # Create week folder if it doesn't exist
    if (-not (Test-Path $weekPath)) {
        New-Item -Path $weekPath -ItemType Directory -Force | Out-Null
        Write-Host "✅ Created folder: $weekFolder/" -ForegroundColor $ColorSuccess
        $FoldersCreated++
    } else {
        Write-Host "⏭️  Folder exists: $weekFolder/" -ForegroundColor $ColorSkip
    }
    
    # Generate daily journal files
    for ($day = 1; $day -le $DaysPerWeek; $day++) {
        $dayFile = "day-$day.md"
        $dayFilePath = Join-Path $weekPath $dayFile
        
        if (-not (Test-Path $dayFilePath)) {
            # Create daily journal template
            $dayTemplate = @"
# Week $week, Day $day - [Topic Name]

**Date**: [Date]  
**Domain**: AZ-104 Domain [X] - [Domain Name]  
**Topic**: [Specific Topic]

---

## Key Concepts Learned

### [Concept 1 Name]
- [Key point 1]
- [Key point 2]
- [Key point 3]

### [Concept 2 Name]
- [Key point 1]
- [Key point 2]

### [Concept 3 Name]
- [Key point 1]
- [Key point 2]

---

## AQUAPINE Business Context

### [Business Challenge/Requirement]
[Describe how this technical concept addresses AQUAPINE operational needs]

### [Implementation Approach]
[Explain how you would apply this to AQUAPINE infrastructure]

---

## Security Considerations

- [Security best practice 1]
- [Security best practice 2]
- [Compliance requirement relevant to AQUAPINE]

---

## Cost Optimization

- [Cost consideration 1]
- [Cost consideration 2]
- [Budget impact for AQUAPINE]

---

## Technical Deliverables

- [ ] [Deliverable 1]
- [ ] [Deliverable 2]
- [ ] [Deliverable 3]

---

## Questions for Instructor

- [ ] [Question 1]
- [ ] [Question 2]
- [ ] [Question 3]

---

## Tomorrow's Focus

**Topic**: [Next day's topic]

**Preparation Required**:
- [Preparation task 1]
- [Preparation task 2]

**Business Questions to Answer**:
- [Question 1]
- [Question 2]

---

**Study Time**: [X hours]  
**Confidence Level**: [1-5]  
**Portfolio Readiness**: [Status description]
"@
            
            $dayTemplate | Out-File -FilePath $dayFilePath -Encoding UTF8
            Write-Host "  ✅ Created: $weekFolder/$dayFile" -ForegroundColor $ColorSuccess
            $FilesCreated++
        } else {
            Write-Host "  ⏭️  Exists: $weekFolder/$dayFile" -ForegroundColor $ColorSkip
            $FilesSkipped++
        }
    }
    
    # Generate week reflection template
    $reflectionFile = "week-reflection.md"
    $reflectionFilePath = Join-Path $weekPath $reflectionFile
    
    if (-not (Test-Path $reflectionFilePath)) {
        $reflectionTemplate = @"
# Week $week - End of Week Reflection

**Week**: [Date Range]  
**Domain**: AZ-104 Domain [X] - [Domain Name]  
**Study Hours**: [Total hours] (theory) + [Total hours] (lab)

---

## Skills Gained

### Technical Competencies Acquired
- **[Competency 1]**: [Description of skill gained]
- **[Competency 2]**: [Description of skill gained]
- **[Competency 3]**: [Description of skill gained]

### Business Acumen Development
- **[Business Understanding 1]**: [How technical skills map to business outcomes]
- **[Business Understanding 2]**: [Cost/compliance/operational insights]

### Portfolio Construction
- **[Portfolio Achievement 1]**: [GitHub commits, documentation, artifacts created]
- **[Portfolio Achievement 2]**: [Interview talking points developed]

---

## Administrative Confidence Improvement

### Week $week Baseline → Current State
- **[Skill Area 1]**: [X/5] → [Y/5] ([Confidence description])
- **[Skill Area 2]**: [X/5] → [Y/5] ([Confidence description])
- **[Skill Area 3]**: [X/5] → [Y/5] ([Confidence description])

### Operational Mindset Shifts
- **[Mindset Shift 1]**: [From X thinking to Y thinking]
- **[Mindset Shift 2]**: [Professional growth observation]

---

## Business Relevance to AQUAPINE

### Week $week Deliverables Impact on Operations

**[Project/Lab 1]**:
- **Problem Solved**: [AQUAPINE operational challenge]
- **Solution Delivered**: [Technical implementation]
- **Business Value**: [Measurable impact]

**[Project/Lab 2]**:
- **Problem Solved**: [AQUAPINE operational challenge]
- **Solution Delivered**: [Technical implementation]
- **Business Value**: [Measurable impact]

---

## Gaps to Address in Week [Next Week]

### Technical Knowledge Deficiencies
- [Gap 1]
- [Gap 2]
- [Gap 3]

### Hands-On Experience Needed
- [Practice area 1]
- [Practice area 2]

### Portfolio Enhancement Opportunities
- [Improvement 1]
- [Improvement 2]

---

## Week [Next Week] Goals

### Domain [X] [Completion/Continuation]
- [Goal 1]
- [Goal 2]

### [Next Domain] Preparation
- [Preparation task 1]
- [Preparation task 2]

### Professional Development
- [Development activity 1]
- [Development activity 2]

---

## Key Takeaways

### Technical Insights
1. [Insight 1]
2. [Insight 2]
3. [Insight 3]

### Business Wisdom
1. [Wisdom 1]
2. [Wisdom 2]

### Learning Process Observations
1. [Observation 1]
2. [Observation 2]

---

**Week $week Status**: ✅ [COMPLETED/IN PROGRESS]  
**Domain [X] Progress**: [Percentage]% ([Status description])  
**Next Milestone**: [Next major goal]

**Confidence Level Entering Week [Next Week]**: [X/5] ([Description])

---

*End of Week $week Reflection*
"@
        
        $reflectionTemplate | Out-File -FilePath $reflectionFilePath -Encoding UTF8
        Write-Host "  ✅ Created: $weekFolder/$reflectionFile" -ForegroundColor $ColorSuccess
        $FilesCreated++
    } else {
        Write-Host "  ⏭️  Exists: $weekFolder/$reflectionFile" -ForegroundColor $ColorSkip
        $FilesSkipped++
    }
    
    Write-Host "" # Blank line between weeks
}

# Summary report
Write-Host "========================================================" -ForegroundColor $ColorInfo
Write-Host "  GENERATION COMPLETE" -ForegroundColor $ColorInfo
Write-Host "========================================================`n" -ForegroundColor $ColorInfo

Write-Host "📊 Summary:" -ForegroundColor $ColorInfo
Write-Host "  - Folders Created: $FoldersCreated" -ForegroundColor $ColorSuccess
Write-Host "  - Files Created: $FilesCreated" -ForegroundColor $ColorSuccess
Write-Host "  - Files Skipped (already exist): $FilesSkipped" -ForegroundColor $ColorSkip
Write-Host "`n✅ Learning journal structure ready for AZ-104 study program!`n" -ForegroundColor $ColorSuccess