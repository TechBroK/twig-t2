# TicketFlow - Deployment Scripts Guide

This document explains the deployment scripts and workflows available for TicketFlow.

## Available Scripts

### 1. Composer Scripts (Cross-Platform)

Run these commands from your project root:

#### Pre-Deployment Checks
```powershell
composer run-script pre-deploy
```
- Validates `composer.json` syntax
- Checks PHP version
- Runs PHP lint on core files
- Verifies project structure

#### Deploy
```powershell
composer run-script deploy
```
- Installs production dependencies (no dev packages)
- Optimizes Composer autoloader
- Clears Twig cache

#### Post-Deploy Verification
```powershell
composer run-script post-deploy
```
- Verifies Composer autoload exists
- Confirms Twig is installed
- Checks security settings
- Validates production configuration

#### Complete Production Setup
```powershell
composer run-script production-setup
```
Runs all three scripts in sequence: `pre-deploy` → `deploy` → `post-deploy`

---

### 2. PowerShell Deployment Script (Windows)

**File**: `deploy.ps1`

**Usage**:
```powershell
.\deploy.ps1
```

**Features**:
- ✅ Automated pre-deployment checks
- ✅ Backs up existing `vendor/` directory
- ✅ Installs production dependencies
- ✅ Post-deployment verification
- ✅ Automatic backup cleanup (keeps last 3)
- ✅ Optional: Creates deployment ZIP file
- ✅ Detailed colored output
- ✅ Error handling with rollback

**When to Use**: Full production deployment on Windows with safety features.

---

### 3. Bash Deployment Script (Linux/Mac)

**File**: `deploy.sh`

**Usage**:
```bash
chmod +x deploy.sh
./deploy.sh
```

**Features**:
- Same as PowerShell script but for Unix-based systems
- Creates `.tar.gz` archive instead of ZIP
- Uses bash-native commands

**When to Use**: Deploying on Linux VPS or Mac development machine.

---

### 4. Quick Deploy Script (Windows)

**File**: `quick-deploy.ps1`

**Usage**:
```powershell
.\quick-deploy.ps1
```

**Features**:
- Runs `composer run-script production-setup`
- No backups or interactive prompts
- Fast execution
- Minimal output

**When to Use**: Rapid redeployment when you're confident in changes.

---

## Deployment Workflows

### Workflow 1: Initial Production Deployment

**On Windows**:
```powershell
# Step 1: Run full deployment script
.\deploy.ps1

# Step 2: Answer prompts
# - Create deployment zip? → y

# Step 3: Upload generated ZIP to hosting
# Step 4: Extract on server
# Step 5: Configure web server (see DEPLOYMENT.md)
```

**On Linux/Mac**:
```bash
# Step 1: Make script executable
chmod +x deploy.sh

# Step 2: Run deployment
./deploy.sh

# Step 3: Answer prompts
# - Create deployment archive? → y

# Step 4: Upload to server
scp ticketflow_deploy_*.tar.gz user@server:/var/www/

# Step 5: Extract on server
ssh user@server
cd /var/www
tar -xzf ticketflow_deploy_*.tar.gz
```

---

### Workflow 2: Subsequent Updates

**Quick Method**:
```powershell
# After making changes
.\quick-deploy.ps1

# Upload changed files only (via FTP/SCP)
```

**Safe Method**:
```powershell
# Full deployment with backups
.\deploy.ps1
```

---

### Workflow 3: Manual Step-by-Step

If you prefer manual control:

```powershell
# 1. Validate project
composer validate --strict

# 2. Check syntax
composer run-script lint

# 3. Install dependencies
composer install --no-dev --optimize-autoloader --no-interaction

# 4. Clear cache
composer run-script clear-cache

# 5. Verify installation
composer run-script verify-installation

# 6. Security check
composer run-script security-check
```

---

### Workflow 4: Docker Deployment

**Build and run locally**:
```powershell
# Build image
docker build -t ticketflow:latest .

# Run container
docker run -d -p 80:80 --name ticketflow ticketflow:latest

# Test
Start-Process "http://localhost"
```

**Deploy to Render.com**:
```powershell
# 1. Commit changes
git add .
git commit -m "Prepare for deployment"
git push origin main

# 2. Render auto-deploys from GitHub
# Monitor at https://dashboard.render.com
```

---

## Script Output Examples

### Successful Deployment
```
======================================
  TicketFlow Production Deployment   
======================================

[1/5] Checking dependencies...
✓ Composer found
✓ PHP found (PHP 8.1.12)

[2/5] Running pre-deployment checks...
> php -v
PHP 8.1.12 (cli)
> composer validate --strict
./composer.json is valid
> php -l src/index.php
No syntax errors detected
Pre-deployment checks passed!

[3/5] Backing up existing vendor directory...
✓ Backup created: vendor_backup_20251028_143522

[4/5] Installing production dependencies...
Loading composer repositories with package information
Installing dependencies from lock file
Deployment complete!

[5/5] Running post-deployment verification...
Verifying installation...
Composer autoload: OK
Twig installed: OK
Running security checks...
display_errors: OFF (OK)
No .env file (OK)
Post-deployment verification complete!

======================================
  Deployment Successful! ✓           
======================================

Create deployment zip for upload? (y/n): y
Creating deployment package...
✓ Deployment package created: ticketflow_deploy_20251028_143530.zip

Deployment script completed!
```

---

## Troubleshooting

### Error: "Composer is not installed"
**Solution**: Install Composer from https://getcomposer.org

### Error: "Pre-deployment checks failed"
**Solution**: Run `composer run-script lint` to see specific syntax errors

### Error: "Deployment failed"
**Solution**: 
1. Check internet connection (Composer needs to download packages)
2. Delete `composer.lock` and try again
3. Run `composer update` locally first

### Warning: "display_errors is ON"
**Solution**: 
- Copy `src/.user.ini` to your server
- Or edit `php.ini` and set `display_errors = Off`

---

## Security Best Practices

Before deployment, ensure:

1. ✅ `composer.json` doesn't include dev dependencies in production
2. ✅ `src/.user.ini` is uploaded and configured
3. ✅ `.htaccess` is present in `src/` directory
4. ✅ No `.env` or sensitive files are uploaded
5. ✅ File permissions: 755 for directories, 644 for files
6. ✅ `display_errors` is OFF in production
7. ✅ HTTPS/SSL is configured

---

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.1'
    
    - name: Install Composer dependencies
      run: composer install --no-dev --optimize-autoloader --no-interaction
    
    - name: Run pre-deploy checks
      run: composer run-script pre-deploy
    
    - name: Deploy to server
      uses: easingthemes/ssh-deploy@main
      env:
        SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
        REMOTE_HOST: ${{ secrets.REMOTE_HOST }}
        REMOTE_USER: ${{ secrets.REMOTE_USER }}
        TARGET: /var/www/ticketflow
```

---

## Additional Commands

### Development Server
```powershell
composer run-script dev-server
# Opens http://localhost:9000
```

### Clear Cache Only
```powershell
composer run-script clear-cache
```

### Lint PHP Files
```powershell
composer run-script lint
```

### Security Check Only
```powershell
composer run-script security-check
```

---

## Next Steps

1. Choose your deployment method
2. Run the appropriate script
3. Upload to your hosting provider
4. Follow the hosting-specific guide in `DEPLOYMENT.md`
5. Configure SSL certificate
6. Test your live application

For platform-specific deployment instructions, see **DEPLOYMENT.md**.

---

**Need Help?**
- Check DEPLOYMENT.md for hosting-specific guides
- Review error logs: `tail -f /var/log/nginx/error.log`
- Verify document root points to `src/`
- Ensure all dependencies are installed
