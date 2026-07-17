# BioSecure Data Vault - Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Docker Deployment](#docker-deployment)
4. [Manual Deployment](#manual-deployment)
5. [SSL/TLS Configuration](#ssltls-configuration)
6. [Database Setup](#database-setup)
7. [Biometric Hardware Setup](#biometric-hardware-setup)
8. [Post-Deployment Verification](#post-deployment-verification)
9. [Backup & Recovery](#backup--recovery)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware Requirements
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 4 cores | 8+ cores |
| RAM | 8 GB | 16+ GB |
| Storage | 100 GB SSD | 500 GB NVMe |
| Network | 100 Mbps | 1 Gbps |

### Software Requirements
- Docker Engine 24.0+
- Docker Compose 2.20+
- Git 2.40+
- OpenSSL 3.0+

### Biometric Hardware (Optional)
- Iris Scanner: IriTech IriShield MK 2120U
- Fingerprint Scanner: Digital Persona U.are.U 4500
- WebAuthn: Compatible FIDO2 security keys

---

## Environment Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-org/biosecure-vault.git
cd biosecure-vault
cp .env.example .env
```

### 2. Environment Variables
Edit `.env` file:
```env
# Application
APP_NAME="BioSecure Data Vault"
APP_ENV=production
APP_KEY=base64:your-key-here
APP_DEBUG=false
APP_URL=https://vault.yourdomain.com

# Database
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=biosecure_vault
DB_USERNAME=biosecure
DB_PASSWORD=your-secure-password

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=your-redis-password
REDIS_PORT=6379

# Mail
MAIL_MAILER=smtp
MAIL_HOST=smtp.sendgrid.net
MAIL_PORT=587
MAIL_USERNAME=apikey
MAIL_PASSWORD=your-sendgrid-api-key

# Storage
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=biosecure-vault-data

# Security
ENCRYPTION_KEY_ID=your-hsm-key-id
SESSION_LIFETIME=600
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=30

# Biometric
BIOMETRIC_IRIS_ENABLED=true
BIOMETRIC_FINGERPRINT_ENABLED=true
WEBAUTHN_ENABLED=true
```

### 3. Generate Application Key
```bash
docker compose run --rm app php artisan key:generate
```

---

## Docker Deployment

### Quick Start
```bash
# Build and start all services
docker compose up -d --build

# Run database migrations
docker compose exec app php artisan migrate --force

# Seed initial data (roles, admin user)
docker compose exec app php artisan db:seed --class=InitialDataSeeder

# Optimize for production
docker compose exec app php artisan optimize
```

### Docker Compose Configuration
```yaml
version: '3.8'

services:
  # Application Server
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: biosecure-app
    restart: unless-stopped
    environment:
      - APP_ENV=production
      - APP_DEBUG=false
    volumes:
      - ./storage:/var/www/storage
      - ./bootstrap/cache:/var/www/bootstrap/cache
    networks:
      - biosecure-network
    depends_on:
      - mysql
      - redis
      - vault

  # Web Server
  nginx:
    image: nginx:1.24-alpine
    container_name: biosecure-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
      - ./public:/var/www/public
    networks:
      - biosecure-network
    depends_on:
      - app

  # Database
  mysql:
    image: mysql:8.0
    container_name: biosecure-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MYSQL_DATABASE: biosecure_vault
      MYSQL_USER: biosecure
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql.cnf:/etc/mysql/conf.d/custom.cnf
    networks:
      - biosecure-network
    secrets:
      - db_root_password
      - db_password

  # Cache & Session Store
  redis:
    image: redis:7-alpine
    container_name: biosecure-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - biosecure-network

  # Object Storage
  minio:
    image: minio/minio:latest
    container_name: biosecure-minio
    restart: unless-stopped
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD_FILE: /run/secrets/minio_password
    volumes:
      - minio_data:/data
    ports:
      - "9000:9000"
      - "9001:9001"
    networks:
      - biosecure-network
    secrets:
      - minio_password

  # Secrets Management
  vault:
    image: hashicorp/vault:latest
    container_name: biosecure-vault
    restart: unless-stopped
    cap_add:
      - IPC_LOCK
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: ${VAULT_TOKEN}
      VAULT_DEV_LISTEN_ADDRESS: 0.0.0.0:8200
    volumes:
      - vault_data:/vault/file
    ports:
      - "8200:8200"
    networks:
      - biosecure-network

  # Queue Worker
  queue:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: biosecure-queue
    restart: unless-stopped
    command: php artisan queue:work --sleep=3 --tries=3 --max-time=3600
    environment:
      - APP_ENV=production
    volumes:
      - ./storage:/var/www/storage
    networks:
      - biosecure-network
    depends_on:
      - mysql
      - redis

  # Scheduler
  scheduler:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: biosecure-scheduler
    restart: unless-stopped
    command: /bin/sh -c "while true; do php artisan schedule:run; sleep 60; done"
    environment:
      - APP_ENV=production
    volumes:
      - ./storage:/var/www/storage
    networks:
      - biosecure-network
    depends_on:
      - mysql
      - redis

networks:
  biosecure-network:
    driver: bridge

volumes:
  mysql_data:
  redis_data:
  minio_data:
  vault_data:

secrets:
  db_root_password:
    file: ./secrets/db_root_password.txt
  db_password:
    file: ./secrets/db_password.txt
  minio_password:
    file: ./secrets/minio_password.txt
```

---

## Manual Deployment

### Ubuntu Server 22.04 LTS

#### 1. System Update
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx mysql-server redis-server php8.2-fpm php8.2-mysql php8.2-redis php8.2-mbstring php8.2-xml php8.2-bcmath php8.2-curl php8.2-zip php8.2-gd openssl
```

#### 2. MySQL Configuration
```bash
sudo mysql_secure_installation

# Create database and user
sudo mysql -e "CREATE DATABASE biosecure_vault;"
sudo mysql -e "CREATE USER 'biosecure'@'localhost' IDENTIFIED BY 'your-secure-password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON biosecure_vault.* TO 'biosecure'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```

#### 3. Nginx Configuration
```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name vault.yourdomain.com;
    root /var/www/biosecure-vault/public;
    index index.php;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' cdn.jsdelivr.net cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' cdn.jsdelivr.net cdnjs.cloudflare.com fonts.googleapis.com; font-src 'self' fonts.gstatic.com; img-src 'self' data: blob:; connect-src 'self';" always;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

#### 4. Application Setup
```bash
cd /var/www
git clone https://github.com/your-org/biosecure-vault.git
cd biosecure-vault
composer install --no-dev --optimize-autoloader
npm install && npm run build

# Set permissions
sudo chown -R www-data:www-data /var/www/biosecure-vault
sudo chmod -R 755 /var/www/biosecure-vault/storage
sudo chmod -R 755 /var/www/biosecure-vault/bootstrap/cache

# Run migrations
php artisan migrate --force
php artisan optimize
```

---

## SSL/TLS Configuration

### Let's Encrypt (Free)
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d vault.yourdomain.com
sudo certbot renew --dry-run
```

### Self-Signed (Development)
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:4096     -keyout /etc/nginx/ssl/key.pem     -out /etc/nginx/ssl/cert.pem     -subj "/C=US/ST=State/L=City/O=Organization/CN=vault.yourdomain.com"
```

---

## Database Setup

### Initial Migration
```bash
docker compose exec app php artisan migrate --force
```

### Seeding Initial Data
```bash
docker compose exec app php artisan db:seed --class=RoleSeeder
docker compose exec app php artisan db:seed --class=AdminUserSeeder
```

### Database Optimization
```sql
-- After deployment, run these optimizations
ANALYZE TABLE users, biometrics, login_logs, user_data;
OPTIMIZE TABLE users, biometrics, login_logs, user_data;
```

---

## Biometric Hardware Setup

### Iris Scanner (IriTech)
```bash
# Install drivers
sudo apt install libusb-1.0-0-dev

# Add udev rules
sudo tee /etc/udev/rules.d/50-iris.rules << EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="1d6b", ATTR{idProduct}=="0104", MODE="0666", GROUP="plugdev"
EOF
sudo udevadm control --reload-rules

# Verify connection
lsusb | grep IriTech
```

### Fingerprint Scanner (Digital Persona)
```bash
# Install SDK
sudo dpkg -i libdpfj-1.0.0-amd64.deb

# Add udev rules
sudo tee /etc/udev/rules.d/50-fingerprint.rules << EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="05ba", ATTR{idProduct}=="000a", MODE="0666", GROUP="plugdev"
EOF
sudo udevadm control --reload-rules
```

### WebAuthn/FIDO2
No additional hardware needed for platform authenticators (Touch ID, Windows Hello).
For roaming authenticators, simply plug in YubiKey or compatible device.

---

## Post-Deployment Verification

### Health Checks
```bash
# Application health
curl -f https://vault.yourdomain.com/health || echo "App unhealthy"

# Database connectivity
docker compose exec app php artisan tinker --execute="DB::connection()->getPdo(); echo 'DB OK';"

# Redis connectivity
docker compose exec app php artisan tinker --execute="Redis::ping(); echo 'Redis OK';"

# Storage accessibility
docker compose exec app php artisan storage:link
```

### Security Verification
```bash
# SSL certificate check
openssl s_client -connect vault.yourdomain.com:443 -servername vault.yourdomain.com </dev/null | openssl x509 -noout -dates

# Header verification
curl -I https://vault.yourdomain.com | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options)"

# Rate limiting test
for i in {1..10}; do curl -s -o /dev/null -w "%{http_code}
" https://vault.yourdomain.com/api/v1/auth/login; done
```

---

## Backup & Recovery

### Automated Backups
```bash
# Add to crontab
0 2 * * * /var/www/biosecure-vault/scripts/backup.sh full
0 */6 * * * /var/www/biosecure-vault/scripts/backup.sh incremental
```

### Backup Script
```bash
#!/bin/bash
# scripts/backup.sh

TYPE=${1:-full}
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/$TYPE/$DATE"

mkdir -p $BACKUP_DIR

# Database backup
mysqldump -u biosecure -p biosecure_vault | gzip > $BACKUP_DIR/database.sql.gz

# File storage backup
aws s3 sync s3://biosecure-vault-data $BACKUP_DIR/files/

# Application files
tar -czf $BACKUP_DIR/application.tar.gz /var/www/biosecure-vault

# Encrypt backup
openssl enc -aes-256-cbc -salt -in $BACKUP_DIR.tar.gz -out $BACKUP_DIR.tar.gz.enc -pass pass:$(cat /run/secrets/backup_key)

# Upload to offsite storage
aws s3 cp $BACKUP_DIR.tar.gz.enc s3://biosecure-backups/

# Cleanup old backups (keep 30 days)
find /backups -type d -mtime +30 -exec rm -rf {} +
```

### Recovery Procedure
```bash
# 1. Stop application
docker compose down

# 2. Restore database
zcat backup_database.sql.gz | mysql -u biosecure -p biosecure_vault

# 3. Restore files
aws s3 sync s3://biosecure-backups/files/ s3://biosecure-vault-data/

# 4. Restart application
docker compose up -d

# 5. Verify
php artisan migrate:status
```

---

## Troubleshooting

### Common Issues

#### 1. Permission Denied on Storage
```bash
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

#### 2. Database Connection Failed
```bash
# Check MySQL status
docker compose exec mysql mysqladmin -u root -p status

# Verify credentials
docker compose exec app php artisan tinker --execute="dd(DB::connection()->getPdo());"
```

#### 3. Redis Connection Failed
```bash
docker compose exec redis redis-cli ping
# Should return PONG
```

#### 4. SSL Certificate Errors
```bash
# Check certificate expiry
openssl x509 -in /etc/nginx/ssl/cert.pem -noout -dates

# Renew Let's Encrypt
sudo certbot renew
```

#### 5. Biometric Device Not Detected
```bash
# Check USB devices
lsusb

# Check device permissions
ls -la /dev/bus/usb/*/

# Restart udev
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Log Locations
```
Application: /var/www/biosecure-vault/storage/logs/laravel.log
Nginx:       /var/log/nginx/error.log
MySQL:       /var/log/mysql/error.log
Redis:       /var/log/redis/redis-server.log
System:      journalctl -u biosecure-app
```

### Performance Tuning
```bash
# PHP-FPM optimization
sudo nano /etc/php/8.2/fpm/pool.d/www.conf
# pm.max_children = 50
# pm.start_servers = 10
# pm.min_spare_servers = 5
# pm.max_spare_servers = 15

# MySQL optimization
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# innodb_buffer_pool_size = 4G
# max_connections = 200
# query_cache_size = 256M

# Restart services
sudo systemctl restart php8.2-fpm mysql nginx
```

---

**Document Version:** 1.0.0
**Last Updated:** 2026-07-13
