<#
.SYNOPSIS
    Validates AquaPine Azure Infrastructure repository structure

.DESCRIPTION
    Scans the repository and generates a report showing:
    - Complete folder structure (tree view)
    - Missing required files and folders
    - Git status
    - Validation checklist
    
.PARAMETER RepositoryPath
    Path to the AquaPine-Azure-Infrastructure repository
    Default: Current directory

.PARAMETER ExportReport
    Export validation report to text file

.EXAMPLE
    .\validate-repository-structure.ps1
    
.EXAMPLE
    .\validate-repository-structure.ps1 -RepositoryPath "C:\GitHub\AquaPine-Azure-Infrastructure" -ExportReport

.NOTES
    Author: Olatunde Ogunti
    Organization: Aquapine Consult
    Purpose: Repository structure validation for AZ-104 portfolio
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportReport
)

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Colors for output
$colorHeader = "Cyan"
$colorExists = "Green"
$colorMissing = "Yellow"
$colorError = "Red"
$colorInfo = "White"

# Clear screen for clean output
Clear-Host

# Report header
Write-Host "`n========================================================" -ForegroundColor $colorHeader
Write-Host "  AQUAPINE AZURE INFRASTRUCTURE - REPOSITORY VALIDATOR" -ForegroundColor $colorHeader
Write-Host "========================================================`n" -ForegroundColor $colorHeader

Write-Host "Repository Path: " -NoNewline -ForegroundColor $colorInfo
Write-Host "$RepositoryPath`n" -ForegroundColor $colorExists

# Validate repository path exists
if (-not (Test-Path $RepositoryPath)) {
    Write-Host "❌ ERROR: Repository path does not exist!" -ForegroundColor $colorError
    Write-Host "Please provide correct path to your repository.`n" -ForegroundColor $colorError
    exit 1
}

# Change to repository directory
Set-Location $RepositoryPath

# Initialize report array
$report = @()
$report += "========================================================="
$report += "  AQUAPINE AZURE INFRASTRUCTURE - VALIDATION REPORT"
$report += "========================================================="
$report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "Repository: $RepositoryPath"
$report += ""

# --------------------------
# SECTION 1: REQUIRED ROOT FILES
# --------------------------

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "📄 REQUIRED ROOT FILES" -ForegroundColor $colorHeader
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colorHeader

$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "📄 REQUIRED ROOT FILES"
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += ""

$requiredRootFiles = @(
    @{File = "README.md"; Description = "Main portfolio landing page"},
    @{File = ".gitignore"; Description = "Git ignore rules (secrets, logs, temp files)"},
    @{File = "LICENSE"; Description = "MIT or appropriate license"}
)

$rootFilesCount = 0
foreach ($item in $requiredRootFiles) {
    $exists = Test-Path (Join-Path $RepositoryPath $item.File)
    if ($exists) {
        Write-Host "  ✅ " -ForegroundColor $colorExists -NoNewline
        Write-Host "$($item.File)" -ForegroundColor $colorExists -NoNewline
        Write-Host " - $($item.Description)" -ForegroundColor $colorInfo
        $report += "  ✅ $($item.File) - $($item.Description)"
        $rootFilesCount++
    } else {
        Write-Host "  ❌ " -ForegroundColor $colorMissing -NoNewline
        Write-Host "$($item.File)" -ForegroundColor $colorMissing -NoNewline
        Write-Host " - $($item.Description) [MISSING]" -ForegroundColor $colorMissing
        $report += "  ❌ $($item.File) - $($item.Description) [MISSING]"
    }
}

Write-Host "`n  Status: $rootFilesCount / $($requiredRootFiles.Count) files present`n" -ForegroundColor $colorInfo
$report += ""
$report += "  Status: $rootFilesCount / $($requiredRootFiles.Count) files present"
$report += ""

# --------------------------
# SECTION 2: DOMAIN FOLDERS (MAIN STRUCTURE)
# --------------------------

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "📁 DOMAIN FOLDERS (AZ-104 Structure)" -ForegroundColor $colorHeader
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colorHeader

$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "📁 DOMAIN FOLDERS (AZ-104 Structure)"
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += ""

$requiredDomains = @(
    @{Folder = "01-Identity-and-Governance"; Description = "Domain 1 (25-30% of AZ-104)"},
    @{Folder = "02-Storage-Solutions"; Description = "Domain 2 (15-20% of AZ-104)"},
    @{Folder = "03-Compute-Resources"; Description = "Domain 3 (20-25% of AZ-104)"},
    @{Folder = "04-Virtual-Networking"; Description = "Domain 4 (20-25% of AZ-104)"},
    @{Folder = "05-Monitoring-and-Backup"; Description = "Domain 5 (10-15% of AZ-104)"},
    @{Folder = "docs"; Description = "Cross-domain documentation"},
    @{Folder = "scripts"; Description = "Utility scripts"},
    @{Folder = "templates"; Description = "Reusable templates"}
)

$domainCount = 0
foreach ($domain in $requiredDomains) {
    $exists = Test-Path (Join-Path $RepositoryPath $domain.Folder)
    if ($exists) {
        Write-Host "  ✅ " -ForegroundColor $colorExists -NoNewline
        Write-Host "$($domain.Folder)/" -ForegroundColor $colorExists -NoNewline
        Write-Host " - $($domain.Description)" -ForegroundColor $colorInfo
        $report += "  ✅ $($domain.Folder)/ - $($domain.Description)"
        $domainCount++
    } else {
        Write-Host "  ❌ " -ForegroundColor $colorMissing -NoNewline
        Write-Host "$($domain.Folder)/" -ForegroundColor $colorMissing -NoNewline
        Write-Host " - $($domain.Description) [MISSING]" -ForegroundColor $colorMissing
        $report += "  ❌ $($domain.Folder)/ - $($domain.Description) [MISSING]"
    }
}

Write-Host "`n  Status: $domainCount / $($requiredDomains.Count) domain folders present`n" -ForegroundColor $colorInfo
$report += ""
$report += "  Status: $domainCount / $($requiredDomains.Count) domain folders present"
$report += ""

# --------------------------
# SECTION 3: DOMAIN 1 DETAILED STRUCTURE
# --------------------------

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "📂 DOMAIN 1: Identity and Governance (Detailed)" -ForegroundColor $colorHeader
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colorHeader

$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "📂 DOMAIN 1: Identity and Governance (Detailed)"
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += ""

$domain1Structure = @(
    "01-Identity-and-Governance/README.md",
    "01-Identity-and-Governance/01-Entra-ID-Foundation",
    "01-Identity-and-Governance/01-Entra-ID-Foundation/README.md",
    "01-Identity-and-Governance/01-Entra-ID-Foundation/scripts",
    "01-Identity-and-Governance/01-Entra-ID-Foundation/data",
    "01-Identity-and-Governance/01-Entra-ID-Foundation/documentation",
    "01-Identity-and-Governance/01-Entra-ID-Foundation/screenshots"
)

$domain1Count = 0
foreach ($path in $domain1Structure) {
    $fullPath = Join-Path $RepositoryPath $path
    $exists = Test-Path $fullPath
    $indent = "  " * ([regex]::Matches($path, "/").Count)
    $name = Split-Path $path -Leaf
    
    if ($exists) {
        Write-Host "$indent✅ $name" -ForegroundColor $colorExists
        $report += "$indent✅ $name"
        $domain1Count++
    } else {
        Write-Host "$indent❌ $name [MISSING]" -ForegroundColor $colorMissing
        $report += "$indent❌ $name [MISSING]"
    }
}

Write-Host "`n  Status: $domain1Count / $($domain1Structure.Count) items present`n" -ForegroundColor $colorInfo
$report += ""
$report += "  Status: $domain1Count / $($domain1Structure.Count) items present"
$report += ""

# --------------------------
# SECTION 4: DOCS FOLDER STRUCTURE
# --------------------------

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "📚 DOCS FOLDER STRUCTURE" -ForegroundColor $colorHeader
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colorHeader

$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "📚 DOCS FOLDER STRUCTURE"
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += ""

$docsStructure = @(
    "docs/architecture",
    "docs/standards",
    "docs/standards/naming-conventions.md",
    "docs/runbooks",
    "docs/interview-prep",
    "docs/learning-journal",
    "docs/learning-journal/week-01"
)

$docsCount = 0
foreach ($path in $docsStructure) {
    $fullPath = Join-Path $RepositoryPath $path
    $exists = Test-Path $fullPath
    $indent = "  " * ([regex]::Matches($path, "/").Count - 1)
    $name = Split-Path $path -Leaf
    
    if ($exists) {
        Write-Host "$indent✅ $name" -ForegroundColor $colorExists
        $report += "$indent✅ $name"
        $docsCount++
    } else {
        Write-Host "$indent❌ $name [MISSING]" -ForegroundColor $colorMissing
        $report += "$indent❌ $name [MISSING]"
    }
}

Write-Host "`n  Status: $docsCount / $($docsStructure.Count) items present`n" -ForegroundColor $colorInfo
$report += ""
$report += "  Status: $docsCount / $($docsStructure.Count) items present"
$report += ""

# --------------------------
# SECTION 5: TEMPLATE FILES
# --------------------------

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "📋 TEMPLATE FILES" -ForegroundColor $colorHeader
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colorHeader

$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "📋 TEMPLATE FILES"
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += ""

$templateFiles = @(
    @{File = "templates/README-template.md"; Description = "Lab documentation template"},
    @{File = "templates/script-template.ps1"; Description = "PowerShell script boilerplate"},
    @{File = "templates/bicep-template.bicep"; Description = "Bicep file template (create later)"},
    @{File = "templates/terraform-template.tf"; Description = "Terraform template (create later)"}
)

$templateCount = 0
foreach ($item in $templateFiles) {
    $exists = Test-Path (Join-Path $RepositoryPath $item.File)
    if ($exists) {
        Write-Host "  ✅ " -ForegroundColor $colorExists -NoNewline
        Write-Host "$($item.File)" -ForegroundColor $colorExists -NoNewline
        Write-Host " - $($item.Description)" -ForegroundColor $colorInfo
        $report += "  ✅ $($item.File) - $($item.Description)"
        $templateCount++
    } else {
        Write-Host "  ⚠️  " -ForegroundColor $colorMissing -NoNewline
        Write-Host "$($item.File)" -ForegroundColor $colorMissing -NoNewline
        Write-Host " - $($item.Description) [PENDING]" -ForegroundColor $colorMissing
        $report += "  ⚠️  $($item.File) - $($item.Description) [PENDING]"
    }
}

Write-Host "`n  Status: $templateCount / $($templateFiles.Count) template files present`n" -ForegroundColor $colorInfo
$report += ""
$report += "  Status: $templateCount / $($templateFiles.Count) template files present"
$report += ""

# --------------------------
# SECTION 6: GIT STATUS
# --------------------------

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "🔧 GIT REPOSITORY STATUS" -ForegroundColor $colorHeader
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colorHeader

$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "🔧 GIT REPOSITORY STATUS"
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += ""

# Check if .git folder exists
$gitInitialized = Test-Path (Join-Path $RepositoryPath ".git")
if ($gitInitialized) {
    Write-Host "  ✅ Git repository initialized" -ForegroundColor $colorExists
    $report += "  ✅ Git repository initialized"
    
    # Try to get git status
    try {
        $gitStatus = git status --porcelain 2>&1
        $gitBranch = git branch --show-current 2>&1
        $gitRemote = git remote -v 2>&1
        
        Write-Host "  ✅ Current branch: " -NoNewline -ForegroundColor $colorExists
        Write-Host "$gitBranch" -ForegroundColor $colorInfo
        $report += "  ✅ Current branch: $gitBranch"
        
        if ($gitRemote -match "github.com") {
            $remoteUrl = ($gitRemote -split "`n")[0] -replace "origin\s+", "" -replace "\s+\(fetch\)", ""
            Write-Host "  ✅ GitHub remote configured: " -NoNewline -ForegroundColor $colorExists
            Write-Host "$remoteUrl" -ForegroundColor $colorInfo
            $report += "  ✅ GitHub remote configured: $remoteUrl"
        } else {
            Write-Host "  ⚠️  No GitHub remote configured" -ForegroundColor $colorMissing
            $report += "  ⚠️  No GitHub remote configured"
        }
        
        # Count files staged, modified, untracked
        $stagedFiles = ($gitStatus | Where-Object { $_ -match "^[AMDR]" }).Count
        $modifiedFiles = ($gitStatus | Where-Object { $_ -match "^ M" }).Count
        $untrackedFiles = ($gitStatus | Where-Object { $_ -match "^\?\?" }).Count
        
        Write-Host "`n  Git Working Directory:" -ForegroundColor $colorInfo
        Write-Host "    - Staged files: $stagedFiles" -ForegroundColor $colorInfo
        Write-Host "    - Modified files: $modifiedFiles" -ForegroundColor $colorInfo
        Write-Host "    - Untracked files: $untrackedFiles" -ForegroundColor $colorInfo
        
        $report += ""
        $report += "  Git Working Directory:"
        $report += "    - Staged files: $stagedFiles"
        $report += "    - Modified files: $modifiedFiles"
        $report += "    - Untracked files: $untrackedFiles"
        
    } catch {
        Write-Host "  ⚠️  Unable to read git status" -ForegroundColor $colorMissing
        $report += "  ⚠️  Unable to read git status"
    }
} else {
    Write-Host "  ❌ Git repository NOT initialized" -ForegroundColor $colorError
    Write-Host "     Run: git init" -ForegroundColor $colorMissing
    $report += "  ❌ Git repository NOT initialized"
    $report += "     Run: git init"
}

Write-Host ""
$report += ""

# --------------------------
# SECTION 7: COMPLETE FOLDER TREE
# --------------------------

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "🌳 COMPLETE FOLDER TREE" -ForegroundColor $colorHeader
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colorHeader

$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "🌳 COMPLETE FOLDER TREE"
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += ""

# Function to generate tree structure
function Get-DirectoryTree {
    param (
        [string]$Path,
        [string]$Prefix = "",
        [int]$MaxDepth = 4,
        [int]$CurrentDepth = 0
    )
    
    if ($CurrentDepth -ge $MaxDepth) { return }
    
    $items = Get-ChildItem -Path $Path -Force | Where-Object { 
        $_.Name -notmatch "^\.git$" -and 
        $_.Name -notmatch "^node_modules$" 
    } | Sort-Object { $_.PSIsContainer }, Name
    
    $itemCount = $items.Count
    $counter = 0
    
    foreach ($item in $items) {
        $counter++
        $isLast = ($counter -eq $itemCount)
        $connector = if ($isLast) { "└── " } else { "├── " }
        $newPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix│   " }
        
        $displayName = if ($item.PSIsContainer) { "$($item.Name)/" } else { $item.Name }
        
        Write-Host "$Prefix$connector$displayName" -ForegroundColor $(if ($item.PSIsContainer) { $colorExists } else { $colorInfo })
        $report += "$Prefix$connector$displayName"
        
        if ($item.PSIsContainer) {
            Get-DirectoryTree -Path $item.FullName -Prefix $newPrefix -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
        }
    }
}

Write-Host "AquaPine-Azure-Infrastructure/" -ForegroundColor $colorHeader
$report += "AquaPine-Azure-Infrastructure/"

Get-DirectoryTree -Path $RepositoryPath -MaxDepth 3

Write-Host ""
$report += ""

# --------------------------
# SECTION 8: VALIDATION SUMMARY
# --------------------------

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "✅ VALIDATION SUMMARY" -ForegroundColor $colorHeader
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colorHeader

$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "✅ VALIDATION SUMMARY"
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += ""

$totalChecks = $requiredRootFiles.Count + $requiredDomains.Count + $domain1Structure.Count + $docsStructure.Count + $templateFiles.Count
$totalPassed = $rootFilesCount + $domainCount + $domain1Count + $docsCount + $templateCount
$completionPercent = [math]::Round(($totalPassed / $totalChecks) * 100, 1)

$summary = @(
    @{Category = "Required Root Files"; Passed = $rootFilesCount; Total = $requiredRootFiles.Count},
    @{Category = "Domain Folders"; Passed = $domainCount; Total = $requiredDomains.Count},
    @{Category = "Domain 1 Structure"; Passed = $domain1Count; Total = $domain1Structure.Count},
    @{Category = "Docs Structure"; Passed = $docsCount; Total = $docsStructure.Count},
    @{Category = "Template Files"; Passed = $templateCount; Total = $templateFiles.Count}
)

foreach ($item in $summary) {
    $percentage = [math]::Round(($item.Passed / $item.Total) * 100, 1)
    $status = if ($item.Passed -eq $item.Total) { "✅" } else { "⚠️ " }
    
    Write-Host "  $status $($item.Category): " -NoNewline -ForegroundColor $colorInfo
    Write-Host "$($item.Passed)/$($item.Total)" -NoNewline -ForegroundColor $(if ($item.Passed -eq $item.Total) { $colorExists } else { $colorMissing })
    Write-Host " ($percentage%)" -ForegroundColor $colorInfo
    
    $report += "  $status $($item.Category): $($item.Passed)/$($item.Total) ($percentage%)"
}

Write-Host "`n  " -NoNewline
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "  OVERALL COMPLETION: " -NoNewline -ForegroundColor $colorHeader
Write-Host "$totalPassed / $totalChecks" -NoNewline -ForegroundColor $(if ($completionPercent -ge 80) { $colorExists } elseif ($completionPercent -ge 50) { "Yellow" } else { $colorError })
Write-Host " ($completionPercent%)" -ForegroundColor $colorHeader
Write-Host "  " -NoNewline
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader

$report += ""
$report += "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "  OVERALL COMPLETION: $totalPassed / $totalChecks ($completionPercent%)"
$report += "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --------------------------
# SECTION 9: NEXT STEPS
# --------------------------

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colorHeader
Write-Host "📋 RECOMMENDED NEXT STEPS" -ForegroundColor $colorHeader
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colorHeader

$report += ""
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += "📋 RECOMMENDED NEXT STEPS"
$report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$report += ""

$nextSteps = @()

if ($rootFilesCount -lt $requiredRootFiles.Count) {
    $nextSteps += "1. Create missing root files (README.md, .gitignore, LICENSE)"
}
if ($domainCount -lt $requiredDomains.Count) {
    $nextSteps += "2. Create missing domain folders (5 domains + docs/scripts/templates)"
}
if ($domain1Count -lt $domain1Structure.Count) {
    $nextSteps += "3. Complete Domain 1 folder structure (Entra-ID-Foundation subfolders)"
}
if ($docsCount -lt $docsStructure.Count) {
    $nextSteps += "4. Create docs/ subdirectories (architecture, standards, runbooks, etc.)"
}
if ($templateCount -lt 2) {
    $nextSteps += "5. Create template files (README-template.md, script-template.ps1)"
}
if (-not $gitInitialized) {
    $nextSteps += "6. Initialize Git repository: git init"
}
if ($gitInitialized -and $gitRemote -notmatch "github.com") {
    $nextSteps += "7. Push repository to GitHub and add remote"
}

if ($nextSteps.Count -eq 0) {
    Write-Host "  🎉 All required structure is in place!" -ForegroundColor $colorExists
    Write-Host "  Ready to begin Week 1 labs!`n" -ForegroundColor $colorExists
    $report += "  🎉 All required structure is in place!"
    $report += "  Ready to begin Week 1 labs!"
} else {
    foreach ($step in $nextSteps) {
        Write-Host "  $step" -ForegroundColor $colorMissing
        $report += "  $step"
    }
}

$report += ""
$report += "========================================================="
$report += "END OF VALIDATION REPORT"
$report += "========================================================="

Write-Host ""

# --------------------------
# EXPORT REPORT
# --------------------------

if ($ExportReport) {
    $reportPath = Join-Path $RepositoryPath "validation-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "📄 Report exported to: $reportPath`n" -ForegroundColor $colorExists
}

Write-Host "========================================================`n" -ForegroundColor $colorHeader

# Return to original directory