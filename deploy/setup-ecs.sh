#!/bin/bash
# Ali ECS 服务器初始化脚本
# 在 ECS 上执行一次即可
# 用法: ssh root@your-ecs-ip 'bash -s' < deploy/setup-ecs.sh

set -e

echo "==> 更新系统包..."
apt-get update && apt-get upgrade -y

echo "==> 安装 Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

echo "==> 安装 Docker Compose 插件..."
if ! docker compose version &> /dev/null; then
    apt-get install -y docker-compose-plugin
fi

echo "==> 创建项目目录..."
mkdir -p /opt/top-ai-news/deploy/nginx/conf.d

echo "==> 配置防火墙（开放 80/443）..."
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
fi

echo "==> ECS 初始化完成！"
echo ""
echo "后续步骤:"
echo "  1. 将 docker-compose.yml 和 deploy/ 目录上传到 /opt/top-ai-news/"
echo "  2. 配置域名 DNS A 记录指向此服务器 IP"
echo "  3. 执行: cd /opt/top-ai-news && ./deploy/init-ssl.sh your-domain.com your-email@example.com"
