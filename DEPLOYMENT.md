# TicketFlow - Deployment Guide

This guide covers deploying your TicketFlow Twig application to production.

## Prerequisites

Before deploying, ensure:
- ✅ PHP 8.0+ installed
- ✅ Composer installed
- ✅ All dependencies installed (`composer install`)
- ✅ Application tested locally

## Pre-Deployment Checklist

1. **Optimize Composer autoloader**:
```powershell
cd C:\Users\HomePC\Development\Twig_t2
composer install --no-dev --optimize-autoloader
```

2. **Verify PHP files have no syntax errors**:
```powershell
php -l src/index.php
php -l src/bootstrap.php
```

3. **Test locally one final time**:
```powershell
php -S localhost:9000 -t src
```

---

## Option 1: Shared Hosting (cPanel) - EASIEST

**Best for beginners. Cost: $3-10/month**

### Step 1: Choose a Host
Popular options:
- Namecheap (recommended for beginners)
- Hostinger
- Bluehost
- SiteGround

Look for plans with:
- PHP 8.0+
- SSH access (optional but helpful)
- Free SSL certificate

### Step 2: Upload Files

**Via File Manager (easiest)**:
1. Log into cPanel
2. Open "File Manager"
3. Navigate to `public_html` (or your domain's folder)
4. Upload ALL project files
5. Important: Set document root to `/path/to/your/project/src`
   - In cPanel → "Domains" → "Manage" → "Document Root"
   - Change to: `/home/yourusername/public_html/src`

**Via FTP**:
1. Use FileZilla or WinSCP
2. Connect with credentials from your host
3. Upload entire `Twig_t2` folder to `/public_html/`

### Step 3: Install Composer Dependencies

**If SSH is available**:
```bash
cd /home/yourusername/public_html/Twig_t2
composer install --no-dev --optimize-autoloader
```

**If NO SSH**:
- Run `composer install --no-dev` locally (Windows)
- Upload the entire `vendor/` folder via FTP

### Step 4: Configure Document Root

In cPanel:
1. Go to "Domains" → Select your domain
2. Set "Document Root" to: `/home/yourusername/public_html/Twig_t2/src`
3. Save

### Step 5: Set File Permissions
- Folders: `755`
- Files: `644`
- `src/index.php`: `644`

### Step 6: Enable HTTPS
1. In cPanel → "SSL/TLS Status"
2. Enable "AutoSSL" (Let's Encrypt)
3. Wait 5-10 minutes for certificate

### Step 7: Test
Visit: `https://yourdomain.com`

**Expected**:
- Landing page loads
- Login at `/auth/login`
- Dashboard protected (redirects if not logged in)

---

## Option 2: VPS with Nginx + PHP-FPM - ADVANCED

**Best for control and performance. Cost: $5-20/month**

### Step 1: Get a VPS
Providers:
- DigitalOcean (recommended)
- Linode
- Vultr
- AWS Lightsail

Choose: Ubuntu 22.04 LTS, 1GB RAM minimum

### Step 2: Initial Server Setup

```bash
# SSH into your server
ssh root@your-server-ip

# Update packages
apt update && apt upgrade -y

# Install required packages
apt install -y nginx php8.1-fpm php8.1-cli php8.1-mbstring php8.1-xml unzip git

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
```

### Step 3: Deploy Application

```bash
# Create directory
mkdir -p /var/www/ticketflow
cd /var/www/ticketflow

# Upload files (use Git or SCP)
# Option A: Git
git clone https://github.com/yourusername/ticketflow.git .

# Option B: SCP from local machine (run on Windows)
# scp -r C:\Users\HomePC\Development\Twig_t2\* root@your-server-ip:/var/www/ticketflow/

# Install dependencies
composer install --no-dev --optimize-autoloader

# Set permissions
chown -R www-data:www-data /var/www/ticketflow
chmod -R 755 /var/www/ticketflow
```

### Step 4: Configure Nginx

Create config file:
```bash
nano /etc/nginx/sites-available/ticketflow
```

Paste this configuration:
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    root /var/www/ticketflow/src;
    
    index index.php;
    
    # Logging
    access_log /var/log/nginx/ticketflow-access.log;
    error_log /var/log/nginx/ticketflow-error.log;
    
    # Main location
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    # PHP-FPM
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable site:
```bash
ln -s /etc/nginx/sites-available/ticketflow /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
systemctl restart php8.1-fpm
```

### Step 5: Setup SSL with Certbot

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Follow prompts. Certbot auto-renews certificates.

### Step 6: Test
Visit: `https://yourdomain.com`

---

## Option 3: Docker + Render/Fly.io - MODERN

**Best for scalability. Free tier available**

### Step 1: Create Dockerfile

I'll create this for you in the next step.

### Step 2: Deploy to Render

1. Push code to GitHub
2. Go to https://render.com
3. "New" → "Web Service"
4. Connect GitHub repo
5. Settings:
   - Environment: Docker
   - Build Command: (auto-detected)
   - Start Command: (auto-detected)
6. Deploy!

Render provides:
- Free HTTPS
- Auto-deployments on Git push
- Free tier (with limitations)

---

## Post-Deployment Security

### 1. Disable Error Display

Create `src/.user.ini`:
```ini
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /path/to/logs/php-error.log
```

### 2. Set Secure Cookie Flags

Update cookie setting in `src/public/js/main.js`:
```javascript
function setCookie(name,value,days){ 
  let s = name+'='+encodeURIComponent(value)+'; path=/; Secure; HttpOnly; SameSite=Strict;'; 
  if(days){ s += ' Max-Age='+(days*24*60*60)+';'; } 
  document.cookie = s; 
}
```

### 3. Add .htaccess (if using Apache)

See the `.htaccess` file I'll create.

### 4. Environment Variables

For production, consider:
- Database credentials (if you add DB later)
- API keys
- Secret keys

---

## DNS Configuration

### Point Domain to Server

**For VPS**:
Add A records at your domain registrar:
```
Type  Name  Value            TTL
A     @     your-server-ip   3600
A     www   your-server-ip   3600
```

**For Render/Fly**:
Add CNAME records:
```
Type   Name  Value                      TTL
CNAME  www   yourapp.onrender.com       3600
```

DNS propagation takes 5 minutes to 48 hours.

---

## Monitoring & Maintenance

### 1. Check Logs

**cPanel**: Error logs in File Manager
**VPS**: 
```bash
tail -f /var/log/nginx/ticketflow-error.log
```

### 2. Backups

**cPanel**: Use built-in backup tool
**VPS**: 
```bash
# Backup files
tar -czf ticketflow-backup-$(date +%Y%m%d).tar.gz /var/www/ticketflow

# Backup localStorage data (if needed)
# Users should export their data manually
```

### 3. Updates

```bash
cd /var/www/ticketflow
git pull
composer install --no-dev --optimize-autoloader
```

---

## Troubleshooting

### Issue: "500 Internal Server Error"
- Check PHP error logs
- Verify file permissions (644 files, 755 folders)
- Ensure `vendor/` exists
- Check PHP version (must be 8.0+)

### Issue: Assets not loading (CSS/JS)
- Verify document root points to `src/`
- Check paths in `base.html.twig`: `/public/css/main.css`
- Clear browser cache

### Issue: Routes not working (404s)
**Apache**: Ensure `.htaccess` is present and `AllowOverride All` is set
**Nginx**: Verify `try_files` directive in config

### Issue: Session/cookies not working
- Ensure HTTPS is enabled
- Check cookie flags (Secure requires HTTPS)
- Verify browser isn't blocking cookies

---

## Performance Optimization

1. **Enable Gzip compression** (Nginx/Apache)
2. **Cache static assets** (already configured in Nginx example)
3. **Use CDN** for static files (optional)
4. **Enable PHP OPcache**:
```ini
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=10000
```

---

## Next Steps After Deployment

1. ✅ Test all features (login, dashboard, CRUD)
2. ✅ Verify HTTPS certificate
3. ✅ Monitor error logs for 24-48 hours
4. ✅ Set up automated backups
5. ✅ Consider adding:
   - Database backend (MySQL/PostgreSQL)
   - Server-side authentication
   - Email notifications
   - User registration with email verification

---

## Cost Estimates

| Option         | Monthly Cost | Setup Time | Skill Level |
|----------------|--------------|------------|-------------|
| Shared cPanel  | $3-10        | 30 min     | Beginner    |
| VPS Nginx      | $5-20        | 1-2 hours  | Advanced    |
| Render Free    | $0           | 15 min     | Beginner    |
| Render Paid    | $7+          | 15 min     | Beginner    |

---

## Support & Resources

- **Namecheap cPanel guide**: https://www.namecheap.com/support/knowledgebase/category/1/
- **DigitalOcean tutorials**: https://www.digitalocean.com/community/tutorials
- **Render docs**: https://render.com/docs
- **Let's Encrypt**: https://letsencrypt.org/getting-started/

---

**Ready to deploy?** Follow the option that best fits your needs. I recommend starting with **Option 1 (cPanel)** if you're a beginner, or **Option 3 (Render)** if you want modern containerized deployment.
