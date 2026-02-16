#!/bin/bash
# 首次 SSL 证书申请脚本
# 用法: ./deploy/init-ssl.sh your-domain.com your-email@example.com

set -e

DOMAIN=${1:?"用法: $0 <域名> <邮箱>"}
EMAIL=${2:?"用法: $0 <域名> <邮箱>"}

echo "==> 为 ${DOMAIN} 申请 SSL 证书..."

# Step 1: 先用 HTTP-only 的 Nginx 配置启动
cat > deploy/nginx/conf.d/default.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://app:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Step 2: 启动 app + nginx（不带 HTTPS）
docker compose up -d app nginx

echo "==> 等待 Nginx 启动..."
sleep 5

# Step 3: 申请证书
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    -d "${DOMAIN}" \
    --email "${EMAIL}" \
    --agree-tos \
    --no-eff-email

# Step 4: 恢复完整的 HTTPS Nginx 配置
cat > deploy/nginx/conf.d/default.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;

    location / {
        proxy_pass http://app:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Step 5: 重载 Nginx 使 HTTPS 生效
docker compose restart nginx

echo "==> SSL 证书申请完成！"
echo "==> 站点已可通过 https://${DOMAIN} 访问"
