#!/usr/bin/env pwsh
#====================================================================
# TERRAFORM WORKSPACE MANAGER
# West Brom Building Society - AWS Infrastructure
#
# Purpose: Easily manage Terraform workspaces for different environments
# Usage: 
#   .\workspace-manager.ps1 -Action create -Workspace poc
#   .\workspace-manager.ps1 -Action switch -Workspace dev
#   .\workspace-manager.ps1 -Action list
#   .\workspace-manager.ps1 -Action plan -Workspace poc
#   .\workspace-manager.ps1 -Action apply -Workspace poc
#====================================================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('list', 'create', 'switch', 'delete', 'plan', 'apply', 'destroy', 'current')]
    [string]$Action = 'list',

    [Parameter(Mandatory=$false)]
    [ValidateSet('poc', 'dev', 'staging', 'uat', 'prod')]
    [string]$Workspace,

    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove
)

# Color output functions
function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Message)
    Write-Host "`n================================================" -ForegroundColor Magenta
    Write-Host "  $Message" -ForegroundColor Magenta
    Write-Host "================================================`n" -ForegroundColor Magenta
}

# Check if terraform is installed
function Test-TerraformInstalled {
    try {
        $null = & terraform version
        return $true
    } catch {
        Write-Error "Terraform is not installed or not in PATH!"
        exit 1
    }
}

# Get current workspace
function Get-CurrentWorkspace {
    $current = (terraform workspace show 2>&1)
    return $current.Trim()
}

# List all workspaces
function Show-Workspaces {
    Write-Header "TERRAFORM WORKSPACES"
    
    $current = Get-CurrentWorkspace
    Write-Info "Current workspace: $current"
    
    Write-Host "`nAvailable workspaces:"
    terraform workspace list
    
    Write-Host "`nEnvironment-specific tfvars files:"
    Get-ChildItem -Filter "*.tfvars" | ForEach-Object {
        $envName = $_.BaseName
        $indicator = if ($envName -eq $current) { " (ACTIVE)" } else { "" }
        Write-Host "  - $($_.Name)$indicator" -ForegroundColor $(if ($envName -eq $current) { "Green" } else { "Gray" })
    }
}

# Create workspace
function New-TerraformWorkspace {
    param([string]$Name)
    
    Write-Header "CREATE WORKSPACE: $Name"
    
    # Check if tfvars file exists
    $tfvarsFile = "$Name.tfvars"
    if (-not (Test-Path $tfvarsFile)) {
        Write-Warning "tfvars file not found: $tfvarsFile"
        Write-Info "Creating workspace anyway, but you'll need to create $tfvarsFile before running plan/apply"
    }
    
    try {
        terraform workspace new $Name
        Write-Success "Workspace '$Name' created successfully!"
        
        if (Test-Path $tfvarsFile) {
            Write-Info "Using tfvars file: $tfvarsFile"
        }
    } catch {
        Write-Error "Failed to create workspace: $_"
        exit 1
    }
}

# Switch workspace
function Switch-TerraformWorkspace {
    param([string]$Name)
    
    Write-Header "SWITCH TO WORKSPACE: $Name"
    
    $current = Get-CurrentWorkspace
    if ($current -eq $Name) {
        Write-Warning "Already on workspace '$Name'"
        return
    }
    
    try {
        terraform workspace select $Name
        Write-Success "Switched to workspace '$Name'"
        
        $tfvarsFile = "$Name.tfvars"
        if (Test-Path $tfvarsFile) {
            Write-Info "tfvars file available: $tfvarsFile"
        } else {
            Write-Warning "tfvars file not found: $tfvarsFile"
        }
    } catch {
        Write-Error "Failed to switch workspace. Workspace might not exist."
        Write-Info "Available workspaces:"
        terraform workspace list
        exit 1
    }
}

# Delete workspace
function Remove-TerraformWorkspace {
    param([string]$Name)
    
    Write-Header "DELETE WORKSPACE: $Name"
    
    $current = Get-CurrentWorkspace
    if ($current -eq $Name) {
        Write-Error "Cannot delete the current workspace. Switch to another workspace first."
        exit 1
    }
    
    if ($Name -eq "default") {
        Write-Error "Cannot delete the 'default' workspace!"
        exit 1
    }
    
    Write-Warning "This will delete workspace '$Name' and its state!"
    $confirmation = Read-Host "Type 'yes' to confirm"
    
    if ($confirmation -ne "yes") {
        Write-Info "Operation cancelled"
        exit 0
    }
    
    try {
        terraform workspace delete $Name
        Write-Success "Workspace '$Name' deleted successfully!"
    } catch {
        Write-Error "Failed to delete workspace: $_"
        exit 1
    }
}

# Plan with workspace
function Invoke-TerraformPlan {
    param([string]$Name)
    
    Write-Header "TERRAFORM PLAN: $Name"
    
    # Switch to workspace if not already there
    $current = Get-CurrentWorkspace
    if ($current -ne $Name) {
        Switch-TerraformWorkspace -Name $Name
    }
    
    $tfvarsFile = "$Name.tfvars"
    if (-not (Test-Path $tfvarsFile)) {
        Write-Error "tfvars file not found: $tfvarsFile"
        exit 1
    }
    
    Write-Info "Running: terraform plan -var-file=`"$tfvarsFile`" -out=tfplan-$Name"
    
    try {
        terraform plan -var-file="$tfvarsFile" -out="tfplan-$Name"
        Write-Success "Plan completed successfully!"
        Write-Info "Plan saved to: tfplan-$Name"
        Write-Warning "Review the plan above before applying!"
    } catch {
        Write-Error "Plan failed: $_"
        exit 1
    }
}

# Apply with workspace
function Invoke-TerraformApply {
    param([string]$Name, [bool]$AutoApprove)
    
    Write-Header "TERRAFORM APPLY: $Name"
    
    # Switch to workspace if not already there
    $current = Get-CurrentWorkspace
    if ($current -ne $Name) {
        Switch-TerraformWorkspace -Name $Name
    }
    
    $planFile = "tfplan-$Name"
    
    if (Test-Path $planFile) {
        Write-Info "Using saved plan: $planFile"
        
        if (-not $AutoApprove) {
            Write-Warning "This will apply changes to the $Name environment!"
            $confirmation = Read-Host "Type 'yes' to confirm"
            
            if ($confirmation -ne "yes") {
                Write-Info "Operation cancelled"
                exit 0
            }
        }
        
        try {
            terraform apply $planFile
            Write-Success "Apply completed successfully for workspace '$Name'!"
            
            # Clean up plan file
            Remove-Item $planFile -Force
            Write-Info "Cleaned up plan file: $planFile"
        } catch {
            Write-Error "Apply failed: $_"
            exit 1
        }
    } else {
        Write-Warning "No saved plan found: $planFile"
        Write-Info "Running plan first..."
        Invoke-TerraformPlan -Name $Name
        
        Write-Warning "Plan completed. Run apply again to execute."
    }
}

# Destroy with workspace
function Invoke-TerraformDestroy {
    param([string]$Name, [bool]$AutoApprove)
    
    Write-Header "TERRAFORM DESTROY: $Name"
    
    # Switch to workspace if not already there
    $current = Get-CurrentWorkspace
    if ($current -ne $Name) {
        Switch-TerraformWorkspace -Name $Name
    }
    
    $tfvarsFile = "$Name.tfvars"
    if (-not (Test-Path $tfvarsFile)) {
        Write-Error "tfvars file not found: $tfvarsFile"
        exit 1
    }
    
    Write-Warning "⚠️  WARNING: This will DESTROY all resources in the $Name environment!"
    Write-Warning "⚠️  This action cannot be undone!"
    
    if (-not $AutoApprove) {
        $confirmation = Read-Host "Type 'DESTROY' to confirm"
        
        if ($confirmation -ne "DESTROY") {
            Write-Info "Operation cancelled"
            exit 0
        }
    }
    
    try {
        if ($AutoApprove) {
            terraform destroy -var-file="$tfvarsFile" -auto-approve
        } else {
            terraform destroy -var-file="$tfvarsFile"
        }
        Write-Success "Destroy completed for workspace '$Name'"
    } catch {
        Write-Error "Destroy failed: $_"
        exit 1
    }
}

# Main script logic
Write-Header "TERRAFORM WORKSPACE MANAGER"

# Check terraform installation
Test-TerraformInstalled | Out-Null

switch ($Action) {
    'list' {
        Show-Workspaces
    }
    'current' {
        $current = Get-CurrentWorkspace
        Write-Success "Current workspace: $current"
    }
    'create' {
        if (-not $Workspace) {
            Write-Error "Please specify -Workspace parameter"
            exit 1
        }
        New-TerraformWorkspace -Name $Workspace
    }
    'switch' {
        if (-not $Workspace) {
            Write-Error "Please specify -Workspace parameter"
            exit 1
        }
        Switch-TerraformWorkspace -Name $Workspace
    }
    'delete' {
        if (-not $Workspace) {
            Write-Error "Please specify -Workspace parameter"
            exit 1
        }
        Remove-TerraformWorkspace -Name $Workspace
    }
    'plan' {
        if (-not $Workspace) {
            Write-Error "Please specify -Workspace parameter"
            exit 1
        }
        Invoke-TerraformPlan -Name $Workspace
    }
    'apply' {
        if (-not $Workspace) {
            Write-Error "Please specify -Workspace parameter"
            exit 1
        }
        Invoke-TerraformApply -Name $Workspace -AutoApprove $AutoApprove
    }
    'destroy' {
        if (-not $Workspace) {
            Write-Error "Please specify -Workspace parameter"
            exit 1
        }
        Invoke-TerraformDestroy -Name $Workspace -AutoApprove $AutoApprove
    }
}

Write-Host "`n"
