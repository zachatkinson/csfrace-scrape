#!/bin/bash
# CSFrace Scrape - Security Audit Script
# Checks for common security issues before deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ISSUES_FOUND=0

echo "========================================"
echo "  CSFrace Scrape - Security Audit"
echo "========================================"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}[FAIL]${NC} .env file not found"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} .env file exists"
fi

# Check for default passwords
echo ""
echo "Checking for default passwords..."

if grep -q "secure_password_change_in_production" .env 2>/dev/null; then
    echo -e "${RED}[FAIL]${NC} Default POSTGRES_PASSWORD detected"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} POSTGRES_PASSWORD changed"
fi

if grep -q "admin_change_in_production" .env 2>/dev/null; then
    echo -e "${RED}[FAIL]${NC} Default GRAFANA_ADMIN_PASSWORD detected"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} GRAFANA_ADMIN_PASSWORD changed"
fi

if grep -q "your-super-secret-jwt-key" .env 2>/dev/null; then
    echo -e "${RED}[FAIL]${NC} Default JWT_SECRET_KEY detected"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} JWT_SECRET_KEY changed"
fi

if grep -q "CHANGE-ME" .env 2>/dev/null; then
    echo -e "${RED}[FAIL]${NC} Placeholder SECRET_KEY detected"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} SECRET_KEY changed"
fi

# Check SECRET_KEY length
echo ""
echo "Checking SECRET_KEY strength..."
SECRET_KEY=$(grep "^SECRET_KEY=" .env 2>/dev/null | cut -d'=' -f2)
if [ ${#SECRET_KEY} -lt 32 ]; then
    echo -e "${YELLOW}[WARN]${NC} SECRET_KEY is short (${#SECRET_KEY} chars). Recommended: 64+ chars"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} SECRET_KEY length adequate (${#SECRET_KEY} chars)"
fi

# Check ENVIRONMENT setting
echo ""
echo "Checking environment configuration..."
if grep -q "^ENVIRONMENT=development" .env 2>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} ENVIRONMENT=development (consider production for clients)"
else
    echo -e "${GREEN}[PASS]${NC} ENVIRONMENT not set to development"
fi

# Check DEBUG settings
if grep -q "^DEBUG=true" .env 2>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} DEBUG=true (should be false for production)"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} DEBUG=false or not set"
fi

# Check SSL certificates
echo ""
echo "Checking SSL certificates..."
if [ ! -f "nginx/ssl/certificate.crt" ] || [ ! -f "nginx/ssl/private.key" ]; then
    echo -e "${RED}[FAIL]${NC} SSL certificates not found"
    echo "  Run: openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\"
    echo "       -keyout nginx/ssl/private.key \\"
    echo "       -out nginx/ssl/certificate.crt \\"
    echo "       -subj \"/C=US/ST=State/L=City/O=CSFrace/CN=localhost\""
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} SSL certificates exist"

    # Check certificate expiration
    EXPIRY=$(openssl x509 -enddate -noout -in nginx/ssl/certificate.crt 2>/dev/null | cut -d= -f2)
    EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$EXPIRY" "+%s" 2>/dev/null || date -d "$EXPIRY" "+%s" 2>/dev/null)
    NOW_EPOCH=$(date "+%s")
    DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

    if [ $DAYS_LEFT -lt 30 ]; then
        echo -e "${YELLOW}[WARN]${NC} SSL certificate expires in $DAYS_LEFT days"
    else
        echo -e "${GREEN}[INFO]${NC} SSL certificate valid for $DAYS_LEFT days"
    fi
fi

# Check .gitignore
echo ""
echo "Checking .gitignore..."
if grep -q "^\.env$" .gitignore 2>/dev/null; then
    echo -e "${GREEN}[PASS]${NC} .env is in .gitignore"
else
    echo -e "${RED}[FAIL]${NC} .env not in .gitignore (SECURITY RISK!)"
    echo "  Run: echo '.env' >> .gitignore"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check for exposed OAuth credentials
echo ""
echo "Checking for OAuth credentials..."
if grep -E "^OAUTH_.*CLIENT_ID=[a-zA-Z0-9-]+" .env 2>/dev/null | grep -qv "your-.*-client-id"; then
    echo -e "${YELLOW}[INFO]${NC} OAuth credentials configured"
    echo "  Ensure these are production credentials (not development)"
else
    echo -e "${GREEN}[PASS]${NC} No OAuth credentials or placeholders only"
fi

# Check Docker
echo ""
echo "Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[FAIL]${NC} Docker not installed"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} Docker installed"
    docker --version
fi

# Check Docker Compose
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}[FAIL]${NC} Docker Compose not installed"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}[PASS]${NC} Docker Compose installed"
    docker compose version
fi

# Check disk space
echo ""
echo "Checking disk space..."
AVAILABLE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ $(echo "$AVAILABLE < 10" | bc 2>/dev/null || echo "0") -eq 1 ]; then
    echo -e "${YELLOW}[WARN]${NC} Low disk space: ${AVAILABLE}GB available"
    echo "  Recommended: 20GB+ free"
else
    echo -e "${GREEN}[PASS]${NC} Sufficient disk space: ${AVAILABLE}GB available"
fi

# Summary
echo ""
echo "========================================"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ Security audit passed!${NC}"
    echo "  No critical issues found"
    exit 0
else
    echo -e "${RED}✗ Security audit failed!${NC}"
    echo "  $ISSUES_FOUND issue(s) found"
    echo ""
    echo "Please fix the issues above before deployment."
    echo "See PRODUCTION_READINESS_CHECKLIST.md for details."
    exit 1
fi
