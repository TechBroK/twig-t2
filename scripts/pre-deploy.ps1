# Pre-Deployment Script for TicketFlow
# Run this script before deploying to production

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "TicketFlow Pre-Deployment Checks" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$ErrorCount = 0

# Check if running in project root
if (-not (Test-Path "composer.json")) {
    Write-Host "❌ Error: composer.json not found. Run this script from project root." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Project root verified" -ForegroundColor Green

# Check PHP version
Write-Host "`n[1/8] Checking PHP version..." -ForegroundColor Yellow
try {
    $phpVersion = php -r "echo PHP_VERSION;"
    $phpMajor = [int]($phpVersion.Split('.')[0])
    $phpMinor = [int]($phpVersion.Split('.')[1])
    
    if ($phpMajor -lt 8) {
        Write-Host "❌ PHP version $phpVersion is too old. Requires PHP 8.0+" -ForegroundColor Red
        $ErrorCount++
    } else {
        Write-Host "✓ PHP version $phpVersion OK" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ PHP not found or not in PATH" -ForegroundColor Red
    $ErrorCount++
}

# Check Composer
Write-Host "`n[2/8] Checking Composer..." -ForegroundColor Yellow
try {
    $composerVersion = composer --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Composer installed" -ForegroundColor Green
    } else {
        Write-Host "❌ Composer not found" -ForegroundColor Red
        $ErrorCount++
    }
} catch {
    Write-Host "❌ Composer not found or not in PATH" -ForegroundColor Red
    $ErrorCount++
}

# Check required files
Write-Host "`n[3/8] Checking required files..." -ForegroundColor Yellow
$requiredFiles = @(
    "src/index.php",
    "src/bootstrap.php",
    "src/routes.php",
    "templates/base.html.twig",
    "templates/landing.html.twig",
    "templates/dashboard.html.twig",
    "src/public/css/main.css",
    "src/public/js/main.js"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Missing: $file" -ForegroundColor Red
        $ErrorCount++
    }
}

# Check PHP syntax
Write-Host "`n[4/8] Checking PHP syntax..." -ForegroundColor Yellow
$phpFiles = Get-ChildItem -Path "src" -Filter "*.php" -Recurse

foreach ($file in $phpFiles) {
    $result = php -l $file.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Syntax error in $($file.Name): $result" -ForegroundColor Red
        $ErrorCount++
    }
}

if ($ErrorCount -eq 0) {
    Write-Host "  ✓ All PHP files have valid syntax" -ForegroundColor Green
}

# Check vendor directory
Write-Host "`n[5/8] Checking dependencies..." -ForegroundColor Yellow
if (Test-Path "vendor") {
    Write-Host "  ✓ vendor/ directory exists" -ForegroundColor Green
    
    if (Test-Path "vendor/autoload.php") {
        Write-Host "  ✓ Composer autoloader present" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Composer autoloader missing" -ForegroundColor Red
        $ErrorCount++
    }
    
    if (Test-Path "vendor/twig/twig") {
        Write-Host "  ✓ Twig installed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Twig not installed" -ForegroundColor Red
        $ErrorCount++
    }
} else {
    Write-Host "  ⚠️  vendor/ directory not found. Will install dependencies..." -ForegroundColor Yellow
}

# Create backup
Write-Host "`n[6/8] Creating backup..." -ForegroundColor Yellow
$backupDir = "backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = "$backupDir/ticketflow-backup-$timestamp.zip"

try {
    Compress-Archive -Path "src", "templates", "composer.json", "composer.lock" -DestinationPath $backupFile -Force
    Write-Host "  ✓ Backup created: $backupFile" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Backup failed: $_" -ForegroundColor Yellow
}

# Check deployment files
Write-Host "`n[7/8] Checking deployment artifacts..." -ForegroundColor Yellow
$deployFiles = @(
    ".htaccess",
    "Dockerfile",
    "src/.user.ini"
)

foreach ($file in $deployFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Missing: $file (optional)" -ForegroundColor Yellow
    }
}

# Test local server
Write-Host "`n[8/8] Testing local server..." -ForegroundColor Yellow
Write-Host "  Starting test server on localhost:9999..." -ForegroundColor Cyan

$serverJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    php -S localhost:9999 -t src 2>&1 | Out-Null
}

Start-Sleep -Seconds 2

try {
    $response = Invoke-WebRequest -Uri "http://localhost:9999" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✓ Server started successfully" -ForegroundColor Green
        Write-Host "  ✓ Landing page responds" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ Server test failed: $_" -ForegroundColor Red
    $ErrorCount++
} finally {
    Stop-Job -Job $serverJob
    Remove-Job -Job $serverJob
}

# Summary
Write-Host "`n==================================" -ForegroundColor Cyan
Write-Host "Pre-Deployment Summary" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

if ($ErrorCount -eq 0) {
    Write-Host "`n✅ All checks passed! Ready to deploy." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: .\scripts\deploy.ps1 -Environment production" -ForegroundColor White
    Write-Host "  2. Or manually deploy files to your server" -ForegroundColor White
    exit 0
} else {
    Write-Host "`n❌ $ErrorCount error(s) found. Fix them before deploying." -ForegroundColor Red
    Write-Host "`nCommon fixes:" -ForegroundColor Yellow
    Write-Host "  - Install dependencies: composer install" -ForegroundColor White
    Write-Host "  - Fix syntax errors in PHP files" -ForegroundColor White
    Write-Host "  - Ensure all required files exist" -ForegroundColor White
    exit 1
}
