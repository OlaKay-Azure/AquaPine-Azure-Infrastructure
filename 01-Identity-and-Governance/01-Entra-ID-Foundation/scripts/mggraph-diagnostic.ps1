# Diagnostic commands
Write-Host "=== PowerShell Diagnostic ===" -ForegroundColor Cyan
Write-Host "1. Execution Policy:" -ForegroundColor Yellow
Get-ExecutionPolicy

Write-Host "`n2. Current Directory:" -ForegroundColor Yellow
pwd

Write-Host "`n3. PowerShell Version:" -ForegroundColor Yellow
$PSVersionTable.PSVersion

Write-Host "`n4. Script Exists?" -ForegroundColor Yellow
Test-Path "C:\Git\AquaPine-Azure-Infrastructure\01-Identity-and-Governance\01-Entra-ID-Foundation\scripts\aquapine-bulk-user-creation.ps1"

Write-Host "`n5. Files in Scripts Folder:" -ForegroundColor Yellow
Get-ChildItem "C:\Git\AquaPine-Azure-Infrastructure\01-Identity-and-Governance\01-Entra-ID-Foundation\scripts\" -Filter *.ps1 | Select-Object Name, Extension

Write-Host "`n=== End Diagnostic ===" -ForegroundColor Cyan