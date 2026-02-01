<#
.SYNOPSIS
    Validate RBAC assignments for AQUAPINE groups
#>

function Test-RBACAssignment {
    param(
        [string]$GroupName,
        [string]$ExpectedRole,
        [string]$ResourceName
    )
    
    $group = Get-AzADGroup -DisplayName $GroupName
    if (-not $group) {
        Write-Host "❌ Group not found: $GroupName" -ForegroundColor Red
        return $false
    }
    
    $assignments = Get-AzRoleAssignment -ObjectId $group.Id
    $hasRole = $assignments | Where-Object {
        $_.RoleDefinitionName -eq $ExpectedRole -and
        $_.Scope -like "*$ResourceName*"
    }
    
    if ($hasRole) {
        Write-Host "✅ $GroupName has $ExpectedRole on $ResourceName" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "❌ $GroupName missing $ExpectedRole on $ResourceName" -ForegroundColor Red
        return $false
    }
}

# Test all AQUAPINE assignments
Test-RBACAssignment -GroupName "Lagos-HR-Security" -ExpectedRole "Storage Blob Data Contributor" -ResourceName "hrdatastorage"
Test-RBACAssignment -GroupName "Ibadan-FarmSecurity-Security" -ExpectedRole "Storage Blob Data Reader" -ResourceName "securitycctv"