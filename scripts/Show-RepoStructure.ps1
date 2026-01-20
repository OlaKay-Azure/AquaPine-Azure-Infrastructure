<#
.SYNOPSIS
    Displays the folder and file structure of the current Git repository.

.DESCRIPTION
    Recursively prints the directory structure starting from the repository root.
    Intended for Azure lab documentation and GitHub portfolio verification.

.NOTES
    Author: Olatunde Ogunti
    Organization: Aquapine Consult
    Purpose: AZ-104 Infrastructure Portfolio
#>

param(
    [int]$Depth = 5
)

function Show-Tree {
    param (
        [string]$Path,
        [string]$Prefix = "",
        [int]$CurrentDepth = 0
    )

    if ($CurrentDepth -ge $Depth) { return }

    $items = Get-ChildItem -Path $Path | Sort-Object PSIsContainer -Descending, Name
    $count = $items.Count
    $index = 0

    foreach ($item in $items) {
        $index++
        $isLast = ($index -eq $count)
        $connector = if ($isLast) { "└── " } else { "├── " }

        Write-Host "$Prefix$connector$item"

        if ($item.PSIsContainer) {
            $newPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix│   " }
            Show-Tree -Path $item.FullName -Prefix $newPrefix -CurrentDepth ($CurrentDepth + 1)
        }
    }
}

Write-Host "`nRepository Structure:`n" -ForegroundColor Cyan
Show-Tree -Path (Get-Location).Path
