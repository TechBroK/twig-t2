# TicketFlow Production Deployment Script (PowerShell)
# Run this script to deploy to production
# Usage: .\deploy.ps1

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  TicketFlow Production Deployment   " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Composer is installed
Write-Host "[1/5] Checking dependencies..." -ForegroundColor Yellow
if (-not (Get-Command composer -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Composer is not installed!" -ForegroundColor Red
    Write-Host "Please install Composer from https://getcomposer.org" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Composer found" -ForegroundColor Green

# Check if PHP is installed
if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: PHP is not installed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ PHP found ($(php -v | Select-String 'PHP' | Select-Object -First 1))" -ForegroundColor Green
Write-Host ""

# Pre-deployment checks
Write-Host "[2/5] Running pre-deployment checks..." -ForegroundColor Yellow
composer run-script pre-deploy
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Pre-deployment checks failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Backup existing vendor directory (optional)
if (Test-Path "vendor") {
    Write-Host "[3/5] Backing up existing vendor directory..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Rename-Item -Path "vendor" -NewName "vendor_backup_$timestamp"
    Write-Host "✓ Backup created: vendor_backup_$timestamp" -ForegroundColor Green
} else {
    Write-Host "[3/5] No existing vendor directory to backup" -ForegroundColor Yellow
}
Write-Host ""

# Run deployment
Write-Host "[4/5] Installing production dependencies..." -ForegroundColor Yellow
composer run-script deploy
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Deployment failed!" -ForegroundColor Red
    
    # Restore backup if exists
    $backupDirs = Get-ChildItem -Directory -Filter "vendor_backup_*" | Sort-Object -Descending
    if ($backupDirs.Count -gt 0) {
        Write-Host "Restoring backup..." -ForegroundColor Yellow
        Remove-Item -Path "vendor" -Recurse -Force -ErrorAction SilentlyContinue
        Rename-Item -Path $backupDirs[0].Name -NewName "vendor"
        Write-Host "✓ Backup restored" -ForegroundColor Green
    }
    exit 1
}
Write-Host ""

# Post-deployment verification
Write-Host "[5/5] Running post-deployment verification..." -ForegroundColor Yellow
composer run-script post-deploy
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Post-deployment checks failed!" -ForegroundColor Yellow
    Write-Host "Deployment completed but verification failed. Please review." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "  Deployment Successful! ✓           " -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
}
Write-Host ""

# Clean up old backups (keep last 3)
Write-Host "Cleaning up old backups..." -ForegroundColor Yellow
$backupDirs = Get-ChildItem -Directory -Filter "vendor_backup_*" | Sort-Object -Descending
if ($backupDirs.Count -gt 3) {
    $backupDirs | Select-Object -Skip 3 | ForEach-Object {
        Remove-Item -Path $_.FullName -Recurse -Force
        Write-Host "✓ Removed old backup: $($_.Name)" -ForegroundColor Gray
    }
}
Write-Host ""

# Display next steps
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Upload all files to your hosting server" -ForegroundColor White
Write-Host "2. Set document root to: /path/to/your/project/src" -ForegroundColor White
Write-Host "3. Ensure .htaccess is present in src/ directory" -ForegroundColor White
Write-Host "4. Configure SSL certificate (Let's Encrypt recommended)" -ForegroundColor White
Write-Host "5. Test your deployment at your domain URL" -ForegroundColor White
Write-Host ""
Write-Host "For detailed instructions, see DEPLOYMENT.md" -ForegroundColor Cyan
Write-Host ""

# Offer to create zip for upload
$response = Read-Host "Create deployment zip for upload? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    $zipName = "ticketflow_deploy_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    Write-Host "Creating deployment package..." -ForegroundColor Yellow
    
    # Exclude unnecessary files
    $exclude = @('vendor_backup_*', '*.zip', '.git', '.vscode', '.idea', 'node_modules', '*.log')
    
    Compress-Archive -Path * -DestinationPath $zipName -Force
    Write-Host "✓ Deployment package created: $zipName" -ForegroundColor Green
    Write-Host "Upload this file to your server and extract it." -ForegroundColor White
}

Write-Host ""
Write-Host "Deployment script completed!" -ForegroundColor Green
