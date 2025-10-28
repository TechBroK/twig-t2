# Quick Deploy Script (PowerShell)
# For rapid production deployment without backups
# Usage: .\quick-deploy.ps1

Write-Host "Starting quick deployment..." -ForegroundColor Cyan

# Run all deployment steps
composer run-script production-setup

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Quick deployment successful! ✓" -ForegroundColor Green
    Write-Host "Ready to upload to production server." -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Quick deployment failed! ✗" -ForegroundColor Red
    Write-Host "Please run .\deploy.ps1 for detailed output." -ForegroundColor Yellow
    exit 1
}
