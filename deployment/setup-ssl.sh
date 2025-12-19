#!/bin/bash

# RedInk SSL 证书配置脚本
# 用于在服务器上配置 Nginx 和 Let's Encrypt SSL 证书

set -e

DOMAIN="redink.mengqilong.com"
EMAIL="bausi0103@gmail.com"

echo "🔐 RedInk SSL 证书配置脚本"
echo "域名: $DOMAIN"
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

# 1. 安装 Nginx 和 Certbot
echo "📦 安装必要软件..."
if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    apt-get update
    apt-get install -y nginx certbot python3-certbot-nginx
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    yum install -y epel-release
    yum install -y nginx certbot python3-certbot-nginx
else
    echo "❌ 不支持的系统"
    exit 1
fi

# 2. 停止 Nginx（如果正在运行）
echo "🛑 停止 Nginx..."
systemctl stop nginx || true

# 3. 复制 Nginx 配置
echo "📝 配置 Nginx..."
NGINX_CONF="/etc/nginx/sites-available/redink.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/redink.conf"

# 创建临时配置（用于获取证书）
cat > $NGINX_CONF << 'EOF'
server {
    listen 80;
    server_name redink.mengqilong.com;
    
    location / {
        proxy_pass http://localhost:12398;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 启用配置
ln -sf $NGINX_CONF $NGINX_ENABLED

# 测试配置
nginx -t

# 4. 启动 Nginx
echo "🚀 启动 Nginx..."
systemctl start nginx
systemctl enable nginx

# 5. 获取 SSL 证书
echo "🔒 获取 SSL 证书..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect

# 6. 更新 Nginx 配置（完整版）
echo "📝 更新 Nginx 配置..."
cat > $NGINX_CONF << 'EOF'
server {
    listen 80;
    server_name redink.mengqilong.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name redink.mengqilong.com;
    
    ssl_certificate /etc/letsencrypt/live/redink.mengqilong.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/redink.mengqilong.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    access_log /var/log/nginx/redink.access.log;
    error_log /var/log/nginx/redink.error.log;
    
    location / {
        proxy_pass http://localhost:12398;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        proxy_buffering off;
    }
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:12398;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# 7. 重新加载 Nginx
echo "🔄 重新加载 Nginx..."
nginx -t
systemctl reload nginx

# 8. 配置防火墙
echo "🔥 配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

# 9. 设置证书自动续期
echo "⏰ 配置证书自动续期..."
systemctl enable certbot.timer
systemctl start certbot.timer

echo ""
echo "✅ SSL 证书配置完成！"
echo ""
echo "📋 配置信息："
echo "  域名: https://$DOMAIN"
echo "  证书路径: /etc/letsencrypt/live/$DOMAIN/"
echo "  Nginx 配置: $NGINX_CONF"
echo ""
echo "🔍 测试连接："
echo "  curl https://$DOMAIN"
echo ""
echo "📅 证书到期时间："
certbot certificates
echo ""
echo "💡 证书会自动续期，无需手动操作"
