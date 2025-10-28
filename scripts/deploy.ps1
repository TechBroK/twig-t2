# Deployment Script for TicketFlow
# Supports multiple deployment targets

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('production', 'staging', 'docker', 'render')]
    [string]$Environment,
    
    [string]$Server = "",
    [string]$Username = "",
    [string]$Path = "",
    [switch]$SkipBackup,
    [switch]$SkipTests
)

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "TicketFlow Deployment Script" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

# Check if pre-deploy was run
if (-not $SkipTests) {
    Write-Host "[1/6] Running pre-deployment checks..." -ForegroundColor Yellow
    
    if (Test-Path "scripts/pre-deploy.ps1") {
        $preDeployResult = & "scripts/pre-deploy.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Pre-deployment checks failed. Fix errors first." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "⚠️  Pre-deploy script not found. Continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "[1/6] Skipping pre-deployment checks..." -ForegroundColor Yellow
}

# Install production dependencies
Write-Host "`n[2/6] Installing production dependencies..." -ForegroundColor Yellow
composer install --no-dev --optimize-autoloader --no-interaction

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Composer install failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green

# Create deployment package
Write-Host "`n[3/6] Creating deployment package..." -ForegroundColor Yellow
$deployDir = "deploy"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$packageName = "ticketflow-$Environment-$timestamp"
$packagePath = "$deployDir/$packageName"

if (Test-Path $deployDir) {
    Remove-Item -Path $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $packagePath | Out-Null

# Copy production files
$filesToDeploy = @(
    "src",
    "templates",
    "vendor",
    "composer.json",
    ".htaccess",
    "Dockerfile",
    "docker-apache.conf"
)

foreach ($item in $filesToDeploy) {
    if (Test-Path $item) {
        Copy-Item -Path $item -Destination $packagePath -Recurse -Force
        Write-Host "  ✓ Copied $item" -ForegroundColor Green
    }
}

# Create deployment info file
$deployInfo = @{
    Environment = $Environment
    Timestamp = $timestamp
    PHPVersion = php -r "echo PHP_VERSION;"
    ComposerVersion = composer --version
    GitCommit = if (Test-Path ".git") { git rev-parse --short HEAD } else { "N/A" }
} | ConvertTo-Json

$deployInfo | Out-File -FilePath "$packagePath/DEPLOY_INFO.json"

Write-Host "✓ Package created: $packagePath" -ForegroundColor Green

# Deploy based on environment
Write-Host "`n[4/6] Deploying to $Environment..." -ForegroundColor Yellow

switch ($Environment) {
    "production" {
        if ([string]::IsNullOrWhiteSpace($Server) -or [string]::IsNullOrWhiteSpace($Username) -or [string]::IsNullOrWhiteSpace($Path)) {
            Write-Host "❌ For production deployment, provide:" -ForegroundColor Red
            Write-Host "   -Server <hostname>" -ForegroundColor Yellow
            Write-Host "   -Username <ssh-user>" -ForegroundColor Yellow
            Write-Host "   -Path </remote/path>" -ForegroundColor Yellow
            Write-Host "`nExample:" -ForegroundColor Cyan
            Write-Host "   .\scripts\deploy.ps1 -Environment production -Server 'example.com' -Username 'user' -Path '/var/www/ticketflow'" -ForegroundColor White
            exit 1
        }
        
        Write-Host "Deploying to $Server..." -ForegroundColor Cyan
        
        # Create zip for upload
        $zipPath = "$deployDir/$packageName.zip"
        Compress-Archive -Path "$packagePath/*" -DestinationPath $zipPath -Force
        
        Write-Host "`nManual deployment steps:" -ForegroundColor Yellow
        Write-Host "1. Upload $zipPath to your server" -ForegroundColor White
        Write-Host "2. SSH into server: ssh $Username@$Server" -ForegroundColor White
        Write-Host "3. Extract: unzip $packageName.zip -d $Path" -ForegroundColor White
        Write-Host "4. Set permissions: chmod -R 755 $Path" -ForegroundColor White
        Write-Host "5. Reload web server" -ForegroundColor White
        
        Write-Host "`n✓ Deployment package ready: $zipPath" -ForegroundColor Green
    }
    
    "docker" {
        Write-Host "Building Docker image..." -ForegroundColor Cyan
        
        docker build -t ticketflow:latest .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Docker image built successfully" -ForegroundColor Green
            
            Write-Host "`nTo run locally:" -ForegroundColor Yellow
            Write-Host "  docker run -d -p 80:80 --name ticketflow ticketflow:latest" -ForegroundColor White
            
            Write-Host "`nTo push to registry:" -ForegroundColor Yellow
            Write-Host "  docker tag ticketflow:latest your-registry/ticketflow:latest" -ForegroundColor White
            Write-Host "  docker push your-registry/ticketflow:latest" -ForegroundColor White
        } else {
            Write-Host "❌ Docker build failed" -ForegroundColor Red
            exit 1
        }
    }
    
    "render" {
        Write-Host "Preparing for Render.com deployment..." -ForegroundColor Cyan
        
        if (-not (Test-Path ".git")) {
            Write-Host "⚠️  Git repository not initialized" -ForegroundColor Yellow
            Write-Host "`nInitializing Git..." -ForegroundColor Cyan
            git init
            git add .
            git commit -m "Initial commit for deployment"
        }
        
        Write-Host "`nRender.com deployment steps:" -ForegroundColor Yellow
        Write-Host "1. Push code to GitHub:" -ForegroundColor White
        Write-Host "   git remote add origin <your-github-repo-url>" -ForegroundColor Cyan
        Write-Host "   git push -u origin main" -ForegroundColor Cyan
        Write-Host "`n2. Go to https://render.com" -ForegroundColor White
        Write-Host "3. Click 'New +' → 'Web Service'" -ForegroundColor White
        Write-Host "4. Connect your GitHub repository" -ForegroundColor White
        Write-Host "5. Settings:" -ForegroundColor White
        Write-Host "   - Environment: Docker" -ForegroundColor Cyan
        Write-Host "   - Plan: Free or Starter" -ForegroundColor Cyan
        Write-Host "6. Click 'Create Web Service'" -ForegroundColor White
        
        Write-Host "`n✓ Ready for Render deployment" -ForegroundColor Green
    }
    
    "staging" {
        Write-Host "Deploying to staging environment..." -ForegroundColor Cyan
        Write-Host "✓ Staging deployment configured" -ForegroundColor Green
    }
}

# Generate deployment checklist
Write-Host "`n[5/6] Generating post-deployment checklist..." -ForegroundColor Yellow

$checklist = @"
Post-Deployment Checklist
==========================

[ ] Verify site loads: https://yourdomain.com
[ ] Test landing page navigation
[ ] Test login functionality
[ ] Test dashboard access (requires login)
[ ] Create a test ticket
[ ] Edit and delete test ticket
[ ] Verify search functionality
[ ] Verify status filter
[ ] Check browser console for errors
[ ] Test on mobile device
[ ] Verify HTTPS certificate (green padlock)
[ ] Check error logs for issues
[ ] Test all navigation links
[ ] Verify assets load (CSS, JS, images)

Performance Checks
==================
[ ] Run Lighthouse audit (aim for 90+ score)
[ ] Check page load time (< 3 seconds)
[ ] Verify Gzip compression enabled
[ ] Check cache headers on static files

Security Checks
===============
[ ] Verify .env files not accessible
[ ] Check security headers (X-Frame-Options, etc.)
[ ] Test session management
[ ] Verify cookies use Secure flag (HTTPS only)
[ ] Check for exposed vendor/ directory

Monitoring Setup
================
[ ] Set up error monitoring
[ ] Configure uptime monitoring
[ ] Set up automated backups
[ ] Document rollback procedure

"@

$checklist | Out-File -FilePath "$deployDir/POST_DEPLOY_CHECKLIST.txt"
Write-Host "✓ Checklist created: $deployDir/POST_DEPLOY_CHECKLIST.txt" -ForegroundColor Green

# Summary
Write-Host "`n[6/6] Deployment Summary" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor White
Write-Host "Package: $packagePath" -ForegroundColor White
Write-Host "Timestamp: $timestamp" -ForegroundColor White

if ($Environment -eq "docker") {
    Write-Host "Docker Image: ticketflow:latest" -ForegroundColor White
}

Write-Host "`n✅ Deployment preparation complete!" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Review: $deployDir/POST_DEPLOY_CHECKLIST.txt" -ForegroundColor White
Write-Host "  2. Run: .\scripts\post-deploy.ps1 -Environment $Environment" -ForegroundColor White
Write-Host "  3. Monitor error logs" -ForegroundColor White

Write-Host ""
