# Implementation Script for Performance Optimizations
# This script safely implements the optimized batch files and workflow

param(
    [switch]$DryRun = $false,
    [switch]$Backup = $true
)

function Write-Status {
    param($Message, $Color = "Green")
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color
}

function Backup-OriginalFiles {
    $backupDir = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    if (!(Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Write-Status "Created backup directory: $backupDir"
    }
    
    $filesToBackup = @("mulai.bat", "looping.bat", "up.bat")
    
    foreach ($file in $filesToBackup) {
        if (Test-Path $file) {
            Copy-Item $file -Destination "$backupDir\$file" -Force
            Write-Status "Backed up: $file"
        } else {
            Write-Status "File not found for backup: $file" -Color "Yellow"
        }
    }
    
    return $backupDir
}

function Implement-OptimizedFiles {
    # Replace original batch files with optimized versions
    $replacements = @{
        "mulai_optimized.bat" = "mulai.bat"
        "looping_optimized.bat" = "looping.bat"
    }
    
    foreach ($optimized in $replacements.Keys) {
        $original = $replacements[$optimized]
        
        if (Test-Path $optimized) {
            if ($DryRun) {
                Write-Status "DRY RUN: Would replace $original with $optimized" -Color "Cyan"
            } else {
                Copy-Item $optimized -Destination $original -Force
                Write-Status "Replaced: $original with optimized version"
            }
        } else {
            Write-Status "Optimized file not found: $optimized" -Color "Red"
        }
    }
}

function Create-WorkflowDirectory {
    $workflowDir = ".github\workflows"
    
    if (!(Test-Path $workflowDir)) {
        if ($DryRun) {
            Write-Status "DRY RUN: Would create directory: $workflowDir" -Color "Cyan"
        } else {
            New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
            Write-Status "Created workflow directory: $workflowDir"
        }
    }
    
    if (Test-Path "optimized_workflow.yml") {
        $targetPath = "$workflowDir\rdp-setup.yml"
        if ($DryRun) {
            Write-Status "DRY RUN: Would copy optimized_workflow.yml to $targetPath" -Color "Cyan"
        } else {
            Copy-Item "optimized_workflow.yml" -Destination $targetPath -Force
            Write-Status "Deployed optimized workflow: $targetPath"
        }
    }
}

function Validate-Implementation {
    Write-Status "Validating implementation..." -Color "Blue"
    
    $validationResults = @()
    
    # Check if optimized files exist and have content
    $criticalFiles = @("mulai.bat", "looping.bat", "performance_monitor.ps1")
    
    foreach ($file in $criticalFiles) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            if ($content.Length -gt 100) {  # Basic sanity check
                $validationResults += "✅ $file - OK"
            } else {
                $validationResults += "❌ $file - Content too short"
            }
        } else {
            $validationResults += "❌ $file - Missing"
        }
    }
    
    # Check workflow file
    $workflowFile = ".github\workflows\rdp-setup.yml"
    if (Test-Path $workflowFile) {
        $validationResults += "✅ GitHub Actions workflow - OK"
    } else {
        $validationResults += "❌ GitHub Actions workflow - Missing"
    }
    
    Write-Status "Validation Results:" -Color "Blue"
    foreach ($result in $validationResults) {
        if ($result.StartsWith("✅")) {
            Write-Host "  $result" -ForegroundColor Green
        } else {
            Write-Host "  $result" -ForegroundColor Red
        }
    }
}

# Main execution
Write-Status "Starting Performance Optimization Implementation" -Color "Magenta"
Write-Status "Dry Run Mode: $DryRun" -Color "Yellow"

try {
    if ($Backup) {
        $backupDir = Backup-OriginalFiles
        Write-Status "Backup completed in: $backupDir"
    }
    
    Implement-OptimizedFiles
    Create-WorkflowDirectory
    
    if (!$DryRun) {
        Validate-Implementation
        
        Write-Status "Implementation completed successfully!" -Color "Green"
        Write-Status "Next steps:" -Color "Yellow"
        Write-Host "  1. Review the optimized files" -ForegroundColor Yellow
        Write-Host "  2. Test the performance monitor: .\performance_monitor.ps1" -ForegroundColor Yellow
        Write-Host "  3. Commit changes to trigger the optimized workflow" -ForegroundColor Yellow
        Write-Host "  4. Monitor performance improvements" -ForegroundColor Yellow
    } else {
        Write-Status "Dry run completed. Use -DryRun:`$false to implement changes." -Color "Cyan"
    }
    
} catch {
    Write-Status "Error during implementation: $($_.Exception.Message)" -Color "Red"
    if ($backupDir) {
        Write-Status "Backups are available in: $backupDir" -Color "Yellow"
    }
}