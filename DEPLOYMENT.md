# Deployment Guide for Digital Ocean

This guide covers deploying the Dukaan360 Rails application to a Digital Ocean droplet.

## Prerequisites

- Digital Ocean droplet with Ubuntu 20.04/22.04
- Domain name pointing to your droplet
- SSH access to your droplet

## Server Setup

### 1. Initial Server Setup

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Ruby (using rbenv)
sudo apt install -y git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev

git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

rbenv install 3.3.0
rbenv global 3.3.0
ruby -v
```

### 2. Install PostgreSQL

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib libpq-dev

# Create database user
sudo -u postgres createuser --interactive --pwprompt dukaan360
sudo -u postgres createdb -O dukaan360 dukaan360_production
```

### 3. Install Nginx

```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Application Deployment

### 1. Clone Repository

```bash
sudo mkdir -p /var/www/dukaan360
sudo chown $USER:$USER /var/www/dukaan360
cd /var/www
git clone https://github.com/shafin2/dukaan360.git
cd dukaan360
```

### 2. Install Dependencies

```bash
# Install Ruby gems
bundle install --deployment --without development test

# Install Node.js packages
npm ci --production
```

### 3. Environment Configuration

```bash
# Create environment file
cp .env.example .env

# Edit environment file
nano .env
```

Add the following to your `.env` file:

```
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_base_here
DATABASE_URL=postgresql://dukaan360:password@localhost/dukaan360_production
RAILS_SERVE_STATIC_FILES=true
```

Generate secret key base:
```bash
bundle exec rails secret
```

### 4. Database Setup

```bash
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails db:seed
```

### 5. Precompile Assets

```bash
RAILS_ENV=production bundle exec rails assets:precompile
```

## System Service Setup

### 1. Create Systemd Service

Create `/etc/systemd/system/dukaan360.service`:

```ini
[Unit]
Description=Dukaan360 Rails Application
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/dukaan360
ExecStart=/home/ubuntu/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=5
Environment=RAILS_ENV=production
EnvironmentFile=/var/www/dukaan360/.env

[Install]
WantedBy=multi-user.target
```

### 2. Configure Nginx

Create `/etc/nginx/sites-available/dukaan360`:

```nginx
upstream app {
    server 127.0.0.1:3000 fail_timeout=0;
}

server {
    listen 80;
    server_name your_domain.com www.your_domain.com;
    root /var/www/dukaan360/public;

    location / {
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Connection '';
        proxy_pass http://app;
    }

    location ~ ^/(assets|packs)/ {
        expires 1y;
        add_header Cache-Control public;
        add_header ETag "";
        break;
    }

    error_page 500 502 503 504 /500.html;
    client_max_body_size 4G;
    keepalive_timeout 10;
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/dukaan360 /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 3. Start Services

```bash
sudo systemctl daemon-reload
sudo systemctl start dukaan360
sudo systemctl enable dukaan360
sudo systemctl status dukaan360
```

## SSL Setup with Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your_domain.com -d www.your_domain.com
```

## GitHub Secrets Setup

Add these secrets to your GitHub repository:

- `DO_HOST`: Your Digital Ocean droplet IP address
- `DO_USER`: SSH username (usually ubuntu or root)
- `DO_SSH_KEY`: Your private SSH key for accessing the droplet

## Monitoring and Maintenance

### Check Application Status

```bash
sudo systemctl status dukaan360
sudo systemctl status nginx
sudo systemctl status postgresql
```

### View Logs

```bash
sudo journalctl -u dukaan360 -f
tail -f /var/www/dukaan360/log/production.log
```

### Update Application

The GitHub Actions workflow will automatically deploy when you push to the main branch. For manual deployment:

```bash
cd /var/www/dukaan360
git pull origin main
bundle install --deployment --without development test
RAILS_ENV=production bundle exec rails assets:precompile
RAILS_ENV=production bundle exec rails db:migrate
sudo systemctl restart dukaan360
```
