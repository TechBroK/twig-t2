#!/bin/bash
# TicketFlow Production Deployment Script (Bash)
# Run this script to deploy to production on Linux/Mac
# Usage: bash deploy.sh or ./deploy.sh

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================"
echo -e "  TicketFlow Production Deployment   "
echo -e "======================================${NC}"
echo ""

# Check if Composer is installed
echo -e "${YELLOW}[1/5] Checking dependencies...${NC}"
if ! command -v composer &> /dev/null; then
    echo -e "${RED}ERROR: Composer is not installed!${NC}"
    echo -e "${RED}Please install Composer from https://getcomposer.org${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Composer found${NC}"

# Check if PHP is installed
if ! command -v php &> /dev/null; then
    echo -e "${RED}ERROR: PHP is not installed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ PHP found ($(php -v | head -n 1))${NC}"
echo ""

# Pre-deployment checks
echo -e "${YELLOW}[2/5] Running pre-deployment checks...${NC}"
if ! composer run-script pre-deploy; then
    echo -e "${RED}ERROR: Pre-deployment checks failed!${NC}"
    exit 1
fi
echo ""

# Backup existing vendor directory
if [ -d "vendor" ]; then
    echo -e "${YELLOW}[3/5] Backing up existing vendor directory...${NC}"
    timestamp=$(date +%Y%m%d_%H%M%S)
    mv vendor "vendor_backup_$timestamp"
    echo -e "${GREEN}✓ Backup created: vendor_backup_$timestamp${NC}"
else
    echo -e "${YELLOW}[3/5] No existing vendor directory to backup${NC}"
fi
echo ""

# Run deployment
echo -e "${YELLOW}[4/5] Installing production dependencies...${NC}"
if ! composer run-script deploy; then
    echo -e "${RED}ERROR: Deployment failed!${NC}"
    
    # Restore backup if exists
    latest_backup=$(ls -dt vendor_backup_* 2>/dev/null | head -n 1)
    if [ -n "$latest_backup" ]; then
        echo -e "${YELLOW}Restoring backup...${NC}"
        rm -rf vendor
        mv "$latest_backup" vendor
        echo -e "${GREEN}✓ Backup restored${NC}"
    fi
    exit 1
fi
echo ""

# Post-deployment verification
echo -e "${YELLOW}[5/5] Running post-deployment verification...${NC}"
if ! composer run-script post-deploy; then
    echo -e "${YELLOW}WARNING: Post-deployment checks failed!${NC}"
    echo -e "${YELLOW}Deployment completed but verification failed. Please review.${NC}"
else
    echo ""
    echo -e "${GREEN}======================================"
    echo -e "  Deployment Successful! ✓           "
    echo -e "======================================${NC}"
fi
echo ""

# Clean up old backups (keep last 3)
echo -e "${YELLOW}Cleaning up old backups...${NC}"
ls -dt vendor_backup_* 2>/dev/null | tail -n +4 | xargs rm -rf
echo ""

# Display next steps
echo -e "${CYAN}Next Steps:${NC}"
echo "1. Upload all files to your hosting server"
echo "2. Set document root to: /path/to/your/project/src"
echo "3. Ensure .htaccess is present in src/ directory"
echo "4. Configure SSL certificate (Let's Encrypt recommended)"
echo "5. Test your deployment at your domain URL"
echo ""
echo -e "${CYAN}For detailed instructions, see DEPLOYMENT.md${NC}"
echo ""

# Offer to create tar.gz for upload
read -p "Create deployment archive for upload? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    archive_name="ticketflow_deploy_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo -e "${YELLOW}Creating deployment package...${NC}"
    
    # Create archive excluding unnecessary files
    tar -czf "$archive_name" \
        --exclude='vendor_backup_*' \
        --exclude='*.tar.gz' \
        --exclude='*.zip' \
        --exclude='.git' \
        --exclude='.vscode' \
        --exclude='.idea' \
        --exclude='node_modules' \
        --exclude='*.log' \
        .
    
    echo -e "${GREEN}✓ Deployment package created: $archive_name${NC}"
    echo "Upload this file to your server and extract it."
fi

echo ""
echo -e "${GREEN}Deployment script completed!${NC}"
