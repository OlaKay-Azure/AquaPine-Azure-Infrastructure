<#
.SYNOPSIS
    Displays the folder and file structure of the repository.
#>

function ShowRepoStructure {
    param (
        [string]$Path,
        [int]$IndentLevel = 0
    )

    $items = Get-ChildItem -Path $Path | Sort-Object `
        @{ Expression = 'PSIsContainer'; Descending = $true }, `
        Name

    foreach ($item in $items) {
        $indent = ' ' * ($IndentLevel * 2)

        if ($item.PSIsContainer) {
            Write-Host "$indent[DIR]  $($item.Name)" -ForegroundColor Cyan
            ShowRepoStructure -Path $item.FullName -IndentLevel ($IndentLevel + 1)
        }
        else {
            Write-Host "$indent[FILE] $($item.Name)" -ForegroundColor Gray
        }
    }
}

# Start from repository root
ShowRepoStructure -Path (Get-Location)
