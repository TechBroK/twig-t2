# GitHub Deployment Guide for TicketFlow

This guide covers deploying TicketFlow using GitHub as your code repository with automated CI/CD.

## 🎯 Overview

Your project is now configured with:
- ✅ GitHub repository hosting
- ✅ Automated CI/CD with GitHub Actions
- ✅ Docker image builds on push
- ✅ Multiple deployment options
- ✅ Automated releases

## 📋 Current Setup

**Repository**: `TechBroK/twig-t2`  
**Branch**: `main`  
**GitHub Actions**: Enabled

## 🚀 Deployment Options with GitHub

### Option 1: Render.com (Recommended - Free Tier)

**Automatic deployment on every push to main!**

#### Setup Steps:

1. **Create Render Account**
   - Go to https://render.com
   - Sign up with your GitHub account

2. **Connect Repository**
   - Click "New +" → "Web Service"
   - Select "TechBroK/twig-t2" repository
   - Click "Connect"

3. **Configure Service**
   ```
   Name: ticketflow
   Environment: Docker
   Branch: main
   Plan: Free
   ```

4. **Get Deploy Hook (Optional for manual triggers)**
   - In Render dashboard → Settings
   - Copy "Deploy Hook URL"
   - Add to GitHub Secrets as `RENDER_DEPLOY_HOOK`

5. **Deploy!**
   ```powershell
   git add .
   git commit -m "Deploy to Render"
   git push origin main
   ```

Render will automatically:
- Detect your Dockerfile
- Build the image
- Deploy the container
- Provide HTTPS URL (e.g., `https://ticketflow.onrender.com`)

**Cost**: FREE (with automatic sleep after 15 min inactivity)  
**Upgrade**: $7/mo for always-on service

---

### Option 2: GitHub Pages + Static Server (Free)

For static hosting with client-side routing:

1. **Enable GitHub Pages**
   - Go to: `https://github.com/TechBroK/twig-t2/settings/pages`
   - Source: "GitHub Actions"
   - Save

2. **Access Documentation**
   - Your docs will be at: `https://techbrok.github.io/twig-t2/`

**Note**: GitHub Pages doesn't support PHP server-side rendering. Use this for documentation only, deploy the app elsewhere.

---

### Option 3: Railway.app (Easy + Free Tier)

1. **Sign up at https://railway.app**
2. Click "New Project" → "Deploy from GitHub repo"
3. Select `TechBroK/twig-t2`
4. Railway auto-detects Dockerfile
5. Deploy automatically

**Cost**: FREE $5 credit/month (then pay-as-you-go)

---

### Option 4: Fly.io (Global Edge Deployment)

1. **Install Fly CLI**
   ```powershell
   iwr https://fly.io/install.ps1 -useb | iex
   ```

2. **Login and Initialize**
   ```powershell
   fly auth login
   fly launch --name ticketflow --region ord
   ```

3. **Deploy**
   ```powershell
   fly deploy
   ```

4. **Auto-deploy on push** (optional)
   ```powershell
   fly secrets set GITHUB_TOKEN=your_token
   ```

**Cost**: FREE tier includes 3GB storage + 160GB transfer

---

### Option 5: Your Own VPS (Advanced)

Deploy from GitHub to your VPS:

1. **SSH into VPS**
   ```bash
   ssh user@your-server.com
   ```

2. **Clone Repository**
   ```bash
   cd /var/www
   git clone https://github.com/TechBroK/twig-t2.git ticketflow
   cd ticketflow
   ```

3. **Install and Setup**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```

4. **Configure Nginx** (see DEPLOYMENT.md)

5. **Auto-deploy with Webhooks** (optional)
   ```bash
   # Create webhook script
   cat > /var/www/deploy.sh << 'EOF'
   #!/bin/bash
   cd /var/www/ticketflow
   git pull origin main
   composer install --no-dev --optimize-autoloader
   sudo systemctl reload nginx
   EOF
   
   chmod +x /var/www/deploy.sh
   ```

---

## 🔄 GitHub Actions CI/CD

Your repository includes automated workflows:

### Workflow: Deploy to Production (`.github/workflows/deploy.yml`)

**Triggers on**:
- Push to `main` branch
- Pull requests to `main`
- Manual dispatch

**What it does**:
1. ✅ Runs PHP syntax checks
2. ✅ Validates all required files exist
3. ✅ Starts test server and verifies it works
4. ✅ Builds Docker image
5. ✅ Tests Docker container
6. ✅ Triggers Render deployment (if configured)
7. ✅ Creates GitHub releases (on tags)

### Workflow: Deploy Docs (`.github/workflows/pages.yml`)

**Triggers on**:
- Changes to README.md or DEPLOYMENT.md
- Manual dispatch

**What it does**:
- Publishes documentation to GitHub Pages

---

## 📦 Creating Releases

Create versioned releases automatically:

```powershell
# Tag your release
git tag -a v1.0.0 -m "Release v1.0.0 - Initial production release"
git push origin v1.0.0
```

GitHub Actions will:
1. Run all tests
2. Build production package
3. Create downloadable ZIP
4. Publish to GitHub Releases

**Download releases**: `https://github.com/TechBroK/twig-t2/releases`

---

## 🔐 GitHub Secrets Setup

Add secrets for automated deployments:

1. Go to: `https://github.com/TechBroK/twig-t2/settings/secrets/actions`

2. **Add these secrets**:

   | Secret Name | Description | Required For |
   |------------|-------------|--------------|
   | `RENDER_DEPLOY_HOOK` | Render deploy webhook URL | Render auto-deploy |
   | `DOCKERHUB_USERNAME` | Docker Hub username | Docker image push |
   | `DOCKERHUB_TOKEN` | Docker Hub access token | Docker image push |
   | `VPS_SSH_KEY` | SSH private key | VPS auto-deploy |
   | `VPS_HOST` | VPS hostname | VPS auto-deploy |
   | `VPS_USER` | VPS username | VPS auto-deploy |

---

## 🎬 Quick Start: Deploy to Render Now

```powershell
# 1. Ensure all changes are committed
git add .
git commit -m "Ready for production deployment"

# 2. Push to GitHub
git push origin main

# 3. Go to Render.com
#    - Sign in with GitHub
#    - New Web Service
#    - Connect TechBroK/twig-t2
#    - Click "Create Web Service"

# 4. Wait for deployment (2-3 minutes)
#    Your app will be live at: https://ticketflow-xxxx.onrender.com
```

---

## 📊 Monitoring Your Deployment

### Check GitHub Actions Status
```
https://github.com/TechBroK/twig-t2/actions
```

### View Deployment Logs
- **Render**: Dashboard → Logs tab
- **Railway**: Project → Deployments → Logs
- **Fly.io**: `fly logs`

### Health Check
After deployment, verify:
```powershell
# Run post-deploy checks
.\scripts\post-deploy.ps1 -Environment production -URL "https://your-app-url.com"
```

---

## 🔄 Continuous Deployment Workflow

```powershell
# 1. Make changes locally
code .

# 2. Test locally
composer serve

# 3. Commit and push
git add .
git commit -m "Feature: Add new functionality"
git push origin main

# 4. GitHub Actions automatically:
#    - Runs tests
#    - Builds Docker image
#    - Deploys to Render/Railway/etc
#    - Notifies you of success/failure

# 5. Verify deployment
# Check GitHub Actions status
# Visit your live URL
```

---

## 🐛 Troubleshooting GitHub Deployments

### Issue: GitHub Actions Failing

**Check the logs**:
```
https://github.com/TechBroK/twig-t2/actions
```

**Common fixes**:
- Ensure `composer.json` is valid
- Check PHP syntax: `composer check`
- Verify all required files exist
- Review error messages in Actions logs

### Issue: Render Deployment Not Triggering

1. Check webhook is configured in GitHub Secrets
2. Manually trigger: Render Dashboard → Manual Deploy
3. Check Render logs for errors

### Issue: Docker Build Fails

```powershell
# Test locally first
docker build -t ticketflow:test .
docker run -d -p 8080:80 ticketflow:test
curl http://localhost:8080
```

### Issue: Permission Errors on VPS

```bash
# Fix permissions
sudo chown -R www-data:www-data /var/www/ticketflow
sudo chmod -R 755 /var/www/ticketflow
```

---

## 📚 Additional Resources

- **GitHub Actions Docs**: https://docs.github.com/actions
- **Render Docs**: https://render.com/docs
- **Railway Docs**: https://docs.railway.app
- **Fly.io Docs**: https://fly.io/docs
- **Docker Hub**: https://hub.docker.com

---

## 🎯 Recommended Setup for Beginners

**For your situation (using GitHub), I recommend Render.com**:

1. ✅ **Free tier** available
2. ✅ **Auto-deploys** from GitHub on every push
3. ✅ **Free HTTPS** included
4. ✅ **Zero server management** required
5. ✅ **Docker support** (uses your Dockerfile)
6. ✅ **Easy rollbacks** if something breaks

**Setup time**: 5 minutes  
**Cost**: FREE (with limitations) or $7/mo for production

---

## 🚀 Next Steps

1. **Push your code** to GitHub (already done ✓)
2. **Choose a platform** (Render recommended)
3. **Connect your repo** to the platform
4. **Deploy automatically** on push
5. **Monitor** with GitHub Actions

**Ready to deploy?** Follow the Render.com setup above! 🎉
