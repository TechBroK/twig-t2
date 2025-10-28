# Quick Deploy Script - Run all deployment steps in sequence
# This is a wrapper script that runs pre-deploy, deploy, and post-deploy

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('production', 'staging', 'docker', 'render', 'local')]
    [string]$Environment,
    
    [string]$Server = "",
    [string]$Username = "",
    [string]$Path = "",
    [string]$URL = ""
)

Write-Host @"
  _____ _      _        _   _____ _                
 |_   _(_) ___| | _____| |_|  ___| | _____      __
   | | | |/ __| |/ / _ \ __| |_  | |/ _ \ \ /\ / /
   | | | | (__|   <  __/ |_|  _| | | (_) \ V  V / 
   |_| |_|\___|_|\_\___|\__|_|   |_|\___/ \_/\_/  
                                                   
"@ -ForegroundColor Cyan

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Quick Deployment to $Environment" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# Step 1: Pre-deployment checks
Write-Host "STEP 1: Pre-Deployment Checks" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow
Write-Host ""

if (Test-Path "scripts/pre-deploy.ps1") {
    & ".\scripts\pre-deploy.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n❌ Pre-deployment checks failed. Aborting deployment." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠️  Pre-deploy script not found at scripts/pre-deploy.ps1" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

Write-Host "`n✓ Pre-deployment checks passed" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 2

# Step 2: Deployment
Write-Host "`nSTEP 2: Deployment" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow
Write-Host ""

if (Test-Path "scripts/deploy.ps1") {
    $deployArgs = @{
        Environment = $Environment
    }
    
    if (-not [string]::IsNullOrWhiteSpace($Server)) { $deployArgs.Server = $Server }
    if (-not [string]::IsNullOrWhiteSpace($Username)) { $deployArgs.Username = $Username }
    if (-not [string]::IsNullOrWhiteSpace($Path)) { $deployArgs.Path = $Path }
    
    & ".\scripts\deploy.ps1" @deployArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n❌ Deployment failed. Check errors above." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ Deploy script not found at scripts/deploy.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ Deployment completed" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 2

# Step 3: Post-deployment verification (only for environments with URL)
if ($Environment -ne "production" -or -not [string]::IsNullOrWhiteSpace($URL)) {
    Write-Host "`nSTEP 3: Post-Deployment Verification" -ForegroundColor Yellow
    Write-Host "====================================" -ForegroundColor Yellow
    Write-Host ""
    
    if (Test-Path "scripts/post-deploy.ps1") {
        $postDeployArgs = @{
            Environment = $Environment
        }
        
        if (-not [string]::IsNullOrWhiteSpace($URL)) { $postDeployArgs.URL = $URL }
        
        & ".\scripts\post-deploy.ps1" @postDeployArgs
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n⚠️  Some post-deployment checks failed. Review above." -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  Post-deploy script not found at scripts/post-deploy.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nSTEP 3: Skipping Post-Deployment Verification" -ForegroundColor Yellow
    Write-Host "=============================================" -ForegroundColor Yellow
    Write-Host "For production deployments with remote servers," -ForegroundColor Cyan
    Write-Host "run post-deploy manually after uploading files:" -ForegroundColor Cyan
    Write-Host "  .\scripts\post-deploy.ps1 -Environment production -URL https://yourdomain.com" -ForegroundColor White
}

# Summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n`n==================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment: $Environment" -ForegroundColor White
Write-Host "Duration: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor White
Write-Host "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host ""

# Next steps based on environment
switch ($Environment) {
    "docker" {
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Run container: docker run -d -p 80:80 --name ticketflow ticketflow:latest" -ForegroundColor White
        Write-Host "  2. Test: http://localhost" -ForegroundColor White
        Write-Host "  3. View logs: docker logs ticketflow" -ForegroundColor White
    }
    
    "render" {
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Push to GitHub: git push origin main" -ForegroundColor White
        Write-Host "  2. Connect repository on Render.com" -ForegroundColor White
        Write-Host "  3. Deploy and monitor build logs" -ForegroundColor White
    }
    
    "production" {
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Upload deploy package to server" -ForegroundColor White
        Write-Host "  2. Extract and configure on server" -ForegroundColor White
        Write-Host "  3. Run post-deploy checks" -ForegroundColor White
        Write-Host "  4. Monitor error logs" -ForegroundColor White
    }
    
    "local" {
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Test: http://localhost:9000" -ForegroundColor White
        Write-Host "  2. Review deploy/POST_DEPLOY_CHECKLIST.txt" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "  - Full guide: DEPLOYMENT.md" -ForegroundColor White
Write-Host "  - Checklist: deploy/POST_DEPLOY_CHECKLIST.txt" -ForegroundColor White
Write-Host ""
Write-Host "🎉 Happy deploying!" -ForegroundColor Green
Write-Host ""
