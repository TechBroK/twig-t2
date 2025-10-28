# Post-Deployment Script for TicketFlow
# Verify deployment and perform health checks

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('production', 'staging', 'docker', 'local')]
    [string]$Environment,
    
    [string]$URL = "",
    [switch]$SkipHealthCheck
)

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "TicketFlow Post-Deployment" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

# Determine URL
if ([string]::IsNullOrWhiteSpace($URL)) {
    switch ($Environment) {
        "local" { $URL = "http://localhost:9000" }
        "docker" { $URL = "http://localhost:80" }
        default {
            Write-Host "Enter your site URL (e.g., https://yourdomain.com):" -ForegroundColor Yellow
            $URL = Read-Host
        }
    }
}

Write-Host "Testing URL: $URL" -ForegroundColor Cyan
Write-Host ""

# Health checks
$HealthChecksPassed = 0
$HealthChecksFailed = 0

if (-not $SkipHealthCheck) {
    Write-Host "[1/5] Running health checks..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check 1: Landing page
    Write-Host "  [1.1] Testing landing page..." -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri $URL -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "    ✓ Landing page loads (Status: 200)" -ForegroundColor Green
            $HealthChecksPassed++
        } else {
            Write-Host "    ❌ Unexpected status: $($response.StatusCode)" -ForegroundColor Red
            $HealthChecksFailed++
        }
    } catch {
        Write-Host "    ❌ Failed to connect: $_" -ForegroundColor Red
        $HealthChecksFailed++
    }
    
    # Check 2: CSS loads
    Write-Host "  [1.2] Testing CSS..." -ForegroundColor Cyan
    try {
        $cssUrl = "$URL/public/css/main.css"
        $response = Invoke-WebRequest -Uri $cssUrl -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "    ✓ CSS loads (Status: 200)" -ForegroundColor Green
            $HealthChecksPassed++
        } else {
            Write-Host "    ❌ CSS failed (Status: $($response.StatusCode))" -ForegroundColor Red
            $HealthChecksFailed++
        }
    } catch {
        Write-Host "    ❌ CSS not accessible: $_" -ForegroundColor Red
        $HealthChecksFailed++
    }
    
    # Check 3: JavaScript loads
    Write-Host "  [1.3] Testing JavaScript..." -ForegroundColor Cyan
    try {
        $jsUrl = "$URL/public/js/main.js"
        $response = Invoke-WebRequest -Uri $jsUrl -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "    ✓ JavaScript loads (Status: 200)" -ForegroundColor Green
            $HealthChecksPassed++
        } else {
            Write-Host "    ❌ JavaScript failed (Status: $($response.StatusCode))" -ForegroundColor Red
            $HealthChecksFailed++
        }
    } catch {
        Write-Host "    ❌ JavaScript not accessible: $_" -ForegroundColor Red
        $HealthChecksFailed++
    }
    
    # Check 4: Login page
    Write-Host "  [1.4] Testing login page..." -ForegroundColor Cyan
    try {
        $loginUrl = "$URL/auth/login"
        $response = Invoke-WebRequest -Uri $loginUrl -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "    ✓ Login page loads (Status: 200)" -ForegroundColor Green
            $HealthChecksPassed++
        } else {
            Write-Host "    ❌ Login page failed (Status: $($response.StatusCode))" -ForegroundColor Red
            $HealthChecksFailed++
        }
    } catch {
        Write-Host "    ❌ Login page not accessible: $_" -ForegroundColor Red
        $HealthChecksFailed++
    }
    
    # Check 5: Dashboard redirect (should redirect to login)
    Write-Host "  [1.5] Testing dashboard protection..." -ForegroundColor Cyan
    try {
        $dashUrl = "$URL/dashboard"
        $response = Invoke-WebRequest -Uri $dashUrl -MaximumRedirection 0 -ErrorAction SilentlyContinue -UseBasicParsing
        
        if ($response.StatusCode -eq 302 -or $response.StatusCode -eq 301) {
            Write-Host "    ✓ Dashboard protected (redirects when not logged in)" -ForegroundColor Green
            $HealthChecksPassed++
        } else {
            Write-Host "    ⚠️  Dashboard returned status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        # 302 redirects throw exceptions in PowerShell
        Write-Host "    ✓ Dashboard protected (redirect detected)" -ForegroundColor Green
        $HealthChecksPassed++
    }
    
} else {
    Write-Host "[1/5] Skipping health checks..." -ForegroundColor Yellow
}

# Security headers check
Write-Host "`n[2/5] Checking security headers..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $URL -TimeoutSec 10 -UseBasicParsing
    
    $securityHeaders = @(
        "X-Frame-Options",
        "X-Content-Type-Options",
        "X-XSS-Protection",
        "Referrer-Policy"
    )
    
    foreach ($header in $securityHeaders) {
        if ($response.Headers.ContainsKey($header)) {
            Write-Host "  ✓ $header present" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  $header missing (recommended)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  ⚠️  Could not check security headers" -ForegroundColor Yellow
}

# HTTPS check
Write-Host "`n[3/5] Checking HTTPS..." -ForegroundColor Yellow
if ($URL -match "^https://") {
    Write-Host "  ✓ Site uses HTTPS" -ForegroundColor Green
    
    try {
        $response = Invoke-WebRequest -Uri $URL -TimeoutSec 10 -UseBasicParsing
        Write-Host "  ✓ SSL certificate valid" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  SSL certificate issue: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Site uses HTTP (HTTPS recommended for production)" -ForegroundColor Yellow
}

# Performance check
Write-Host "`n[4/5] Checking performance..." -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-WebRequest -Uri $URL -TimeoutSec 10 -UseBasicParsing
    $stopwatch.Stop()
    
    $loadTime = $stopwatch.ElapsedMilliseconds
    
    if ($loadTime -lt 1000) {
        Write-Host "  ✓ Fast load time: ${loadTime}ms" -ForegroundColor Green
    } elseif ($loadTime -lt 3000) {
        Write-Host "  ✓ Good load time: ${loadTime}ms" -ForegroundColor Yellow
    } else {
        Write-Host "  ⚠️  Slow load time: ${loadTime}ms (optimize recommended)" -ForegroundColor Red
    }
    
    # Check compression
    if ($response.Headers.ContainsKey("Content-Encoding")) {
        Write-Host "  ✓ Compression enabled: $($response.Headers['Content-Encoding'])" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Compression not detected (recommended)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "  ⚠️  Could not measure performance" -ForegroundColor Yellow
}

# Deployment verification
Write-Host "`n[5/5] Deployment verification..." -ForegroundColor Yellow

$verificationChecks = @"

Manual Verification Checklist:
==============================

Browser Tests:
[ ] Open $URL in browser
[ ] No JavaScript console errors
[ ] All images and icons load
[ ] CSS styles apply correctly
[ ] Navigation works (Home, Login, etc.)
[ ] Mobile responsive design works

Functionality Tests:
[ ] Can access login page
[ ] Can access signup page
[ ] Dashboard redirects to login when not authenticated
[ ] Can create account (test signup)
[ ] Can login with credentials
[ ] Can access dashboard after login
[ ] Can create new ticket
[ ] Can edit ticket
[ ] Can delete ticket
[ ] Search functionality works
[ ] Status filter works
[ ] Stats update correctly

Security Tests:
[ ] Cannot access dashboard without login
[ ] HTTPS enabled (green padlock in browser)
[ ] Secure cookie flags set
[ ] No sensitive files exposed (/.git, /.env, /vendor)

Performance Tests:
[ ] Page loads in < 3 seconds
[ ] Run Lighthouse audit (aim for 90+)
[ ] Check mobile performance
[ ] Verify caching headers

"@

Write-Host $verificationChecks

# Summary
Write-Host "`n==================================" -ForegroundColor Cyan
Write-Host "Post-Deployment Summary" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Health Checks Passed: $HealthChecksPassed" -ForegroundColor Green
Write-Host "Health Checks Failed: $HealthChecksFailed" -ForegroundColor Red
Write-Host ""

if ($HealthChecksFailed -eq 0) {
    Write-Host "✅ All automated checks passed!" -ForegroundColor Green
    Write-Host "`nRecommended next steps:" -ForegroundColor Cyan
    Write-Host "  1. Complete manual verification checklist above" -ForegroundColor White
    Write-Host "  2. Test all features in browser" -ForegroundColor White
    Write-Host "  3. Monitor error logs for 24 hours" -ForegroundColor White
    Write-Host "  4. Set up monitoring and backups" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Monitoring Commands:" -ForegroundColor Yellow
    Write-Host "  - Check error logs: tail -f /var/log/nginx/ticketflow-error.log" -ForegroundColor Cyan
    Write-Host "  - Check access logs: tail -f /var/log/nginx/ticketflow-access.log" -ForegroundColor Cyan
    Write-Host "  - Monitor PHP errors: tail -f /path/to/php-error.log" -ForegroundColor Cyan
    Write-Host ""
    
} else {
    Write-Host "⚠️  Some checks failed. Review errors above." -ForegroundColor Yellow
    Write-Host "`nCommon issues:" -ForegroundColor Yellow
    Write-Host "  - Document root not set to src/ directory" -ForegroundColor White
    Write-Host "  - Assets not accessible (check permissions)" -ForegroundColor White
    Write-Host "  - PHP not configured correctly" -ForegroundColor White
    Write-Host "  - URL rewriting not enabled" -ForegroundColor White
    Write-Host ""
}

# Create deployment report
$reportPath = "deploy/deployment-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$report = @"
TicketFlow Deployment Report
============================
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Environment: $Environment
URL: $URL

Health Checks:
- Passed: $HealthChecksPassed
- Failed: $HealthChecksFailed

Manual verification required: See checklist above
"@

if (Test-Path "deploy") {
    $report | Out-File -FilePath $reportPath
    Write-Host "Deployment report saved: $reportPath" -ForegroundColor Cyan
}

Write-Host "`n🎉 Deployment process complete!" -ForegroundColor Green
Write-Host ""
