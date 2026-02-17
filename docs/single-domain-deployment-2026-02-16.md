# 单域名部署指南 - data.yeanhua.asia

## 核心结论

- ✅ 使用 Let's Encrypt HTTP-01 验证（无需 DNS API）
- ✅ 支持单域名 `data.yeanhua.asia`
- ✅ 配置简单，5 分钟完成
- ⚠️ **必须在生产服务器上运行 `make cert-generate`**
- ⚠️ 需要 80 端口公网可访问
- ⚠️ 域名必须解析到服务器公网 IP

---

## ⚠️ 重要说明：运行位置

### HTTP-01 验证的要求

**HTTP-01 验证必须在生产服务器上运行**，原因：

```
Let's Encrypt 服务器
    ↓
通过公网访问: http://data.yeanhua.asia/.well-known/acme-challenge/xxx
    ↓
域名解析到: 121.41.107.93（你的生产服务器）
    ↓
验证文件必须在该服务器上
```

**不能在本地生成的原因**：
- 即使在本地运行 `make cert-generate`，Let's Encrypt 会访问 `data.yeanhua.asia` 的公网 IP
- 域名解析到生产服务器，Let's Encrypt 访问不到本地的验证文件
- 验证会失败：`Connection refused`

### 替代方案：DNS-01（可本地生成）

如果需要在本地生成证书，使用 DNS-01：

```bash
# 本地生成
make cert-generate-dns

# 上传到服务器
scp ~/.local-certs/yeanhua.asia/* user@121.41.107.93:~/certs/
```

**对比总结**：

| 验证方式 | 运行位置 | 原因 |
|---------|---------|------|
| **HTTP-01** | ⚠️ **必须在服务器** | Let's Encrypt 需访问服务器的 80 端口 |
| **DNS-01** | ✅ **可以本地** | 只需 DNS API 权限，无需服务器 |
| **mkcert** | ✅ **可以本地** | 本地 CA，无需外部验证 |

---

## 🚀 快速部署

### 步骤 0：连接到生产服务器

**⚠️ 关键步骤：所有操作都在服务器上执行**

```bash
# SSH 到生产服务器
ssh user@121.41.107.93
# 或使用域名
ssh user@data.yeanhua.asia

# 进入项目目录
cd ~/top-ai-news

# 如果是首次部署，先克隆代码
git clone <your-repo-url> ~/top-ai-news
cd ~/top-ai-news
```

### 前置条件检查

```bash
# 1. 域名解析检查（在服务器上运行）
ping data.yeanhua.asia
# 应该解析到本机公网 IP

# 2. 80 端口检查
# 确保 80 端口未被占用，或先停止服务
docker compose down
```

### 一键部署

```bash
# ⚠️ 以下命令在服务器上运行

# 1. 生成证书（HTTP-01 验证）
make cert-generate

# 2. 启动服务
make docker-up-https

# 3. 访问（在本地浏览器）
# 浏览器打开: https://data.yeanhua.asia
```

**就这么简单！无需 DNS API 配置** 🎉

---

## 📋 详细步骤

### 步骤 0：连接到生产服务器

**⚠️ 所有后续操作都在服务器上执行**

```bash
# 1. SSH 连接
ssh user@121.41.107.93

# 2. 克隆或更新代码
# 首次部署
git clone <your-repo-url> ~/top-ai-news
cd ~/top-ai-news

# 已有项目
cd ~/top-ai-news
git pull
```

### 步骤 1：准备环境（在服务器上）

**检查 certbot 安装**：
```bash
# Mac
brew install certbot

# Ubuntu/Debian
sudo apt install certbot

# CentOS/RHEL
sudo yum install certbot
```

**检查域名解析**：
```bash
# 确认域名解析到服务器
dig data.yeanhua.asia +short
# 应该返回服务器的公网 IP

# 或使用 ping
ping -c 1 data.yeanhua.asia
```

### 步骤 2：停止占用 80 端口的服务

Let's Encrypt HTTP-01 验证需要临时占用 80 端口。

```bash
# 如果运行了 Docker 服务
docker compose down

# 如果运行了 Nginx
sudo nginx -s stop

# 检查 80 端口是否空闲
lsof -i :80
# 应该没有输出，表示端口空闲
```

### 步骤 3：生成证书

```bash
# 执行证书生成
make cert-generate
```

**交互过程**：
```
[INFO] 使用 Let's Encrypt 生成证书（HTTP-01 验证）...

⚠️  HTTP-01 验证要求：
  1. 域名 data.yeanhua.asia 必须解析到本机公网 IP
  2. 80 端口必须可从公网访问
  3. 申请期间会临时占用 80 端口

确认满足以上条件？[y/N] y

[INFO] 检查 80 端口占用...
[INFO] 申请证书（standalone 模式）...

Saving debug log to /var/log/letsencrypt/letsencrypt.log
Account registered.
Requesting a certificate for data.yeanhua.asia

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/data.yeanhua.asia/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/data.yeanhua.asia/privkey.pem

[INFO] 复制证书到: /Users/yeanhua/.local-certs/yeanhua.asia
[INFO] ✓ Let's Encrypt 证书生成成功

证书位置: /Users/yeanhua/.local-certs/yeanhua.asia
  - fullchain.pem (证书)
  - privkey.pem (私钥)

证书有效期: 90 天
续期命令: make cert-renew 或 certbot renew

支持的域名:
  - data.yeanhua.asia
```

### 步骤 4：启动 HTTPS 服务

```bash
# 启动所有服务（HTTPS 模式）
make docker-up-https

# 查看服务状态
make docker-ps

# 查看日志
make docker-logs
```

### 步骤 5：验证部署

```bash
# 1. 浏览器访问
open https://data.yeanhua.asia

# 2. 检查证书
make cert-info

# 3. 测试 API
curl https://data.yeanhua.asia/
```

---

## 🔄 证书续期

Let's Encrypt 证书有效期 90 天，需要定期续期。

### 自动续期（推荐）

**方式 1：crontab**

```bash
# 编辑 crontab
crontab -e

# 添加自动续期任务（每周一凌晨 2 点）
0 2 * * 1 cd /path/to/top-ai-news && make cert-renew && make docker-restart
```

**方式 2：systemd timer**

```bash
# 查看 certbot 自动续期状态
sudo systemctl status certbot-renew.timer

# 启用自动续期
sudo systemctl enable certbot-renew.timer
```

### 手动续期

```bash
# 检查证书是否需要续期
make cert-check

# 手动续期
make cert-renew

# 重启服务应用新证书
make docker-restart
```

---

## ⚠️ 常见问题

### Q1: 80 端口被占用怎么办？

**错误信息**：
```
[WARN] 80 端口被占用，使用 Webroot 模式
```

**解决方案 1：使用 Webroot 模式（推荐，无需停止服务）**

如果 80 端口有 Nginx 等 Web 服务正在运行，配置 Nginx 支持 ACME 验证：

```nginx
# 编辑 Nginx 配置
sudo vim /etc/nginx/sites-available/data.yeanhua.asia

server {
    listen 80;
    server_name data.yeanhua.asia;

    # ACME HTTP-01 验证路径
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # 现有服务配置保持不变
    location / {
        # ...
    }
}
```

```bash
# 重载 Nginx
sudo nginx -s reload

# 生成证书（自动使用 webroot 模式）
make cert-generate
```

**解决方案 2：临时停止服务（standalone 模式）**

```bash
# 查看占用进程
lsof -i :80

# 停止 Docker 服务
docker compose down

# 或停止 Nginx
sudo nginx -s stop

# 生成证书
make cert-generate

# 重启服务
make docker-up-https
```

**解决方案 3：使用 DNS-01（无需 80 端口）**

```bash
make cert-setup-dns
vim ~/.secrets/dns-credentials.ini
pip3 install certbot-dns-aliyun
make cert-generate-dns
```

---

### Q2: 域名解析失败

**错误信息**：
```
Failed to validate domain ownership
Connection refused
```

**解决方案**：

1. **检查域名解析**：
   ```bash
   dig data.yeanhua.asia +short
   # 应该返回服务器的公网 IP
   ```

2. **等待 DNS 传播**：
   - DNS 更新可能需要几分钟到几小时
   - 使用 `https://dnschecker.org` 检查全球解析情况

3. **检查防火墙**：
   ```bash
   # 确保 80 端口对外开放
   sudo ufw allow 80
   sudo ufw status
   ```

---

### Q3: 证书申请失败

**错误信息**：
```
Challenge failed for domain data.yeanhua.asia
```

**常见原因**：
1. 域名未解析或解析错误
2. 80 端口被占用或防火墙阻止
3. Let's Encrypt 服务器无法访问你的服务器

**排查步骤**：
```bash
# 1. 测试域名解析
curl -I http://data.yeanhua.asia

# 2. 测试从外网访问
# 使用手机 4G 网络或其他外网环境
curl -I http://<你的公网IP>

# 3. 查看详细日志
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

---

### Q4: 如何查看证书信息？

```bash
# 使用 make 命令
make cert-info

# 或直接查看
openssl x509 -in ~/.local-certs/yeanhua.asia/fullchain.pem -noout -text

# 查看过期时间
openssl x509 -in ~/.local-certs/yeanhua.asia/fullchain.pem -noout -dates
```

---

### Q5: 如何切换回 mkcert？

```bash
# 删除现有证书
make cert-clean

# 使用 mkcert 生成
make cert-generate-mkcert

# 重启服务
make docker-restart
```

---

## 🔒 HTTP-01 vs DNS-01 对比

| 维度 | HTTP-01（当前使用）| DNS-01 |
|------|------------------|---------|
| **配置复杂度** | ⭐ 简单 | ⭐⭐⭐ 复杂 |
| **前置条件** | 80 端口开放 | DNS API 凭证 |
| **域名支持** | 单域名 | 泛域名 |
| **网络要求** | 公网可访问 | 无特殊要求 |
| **适用场景** | **单域名部署** | 多子域名 |

---

## 📊 部署架构

### HTTP-01 验证流程

```
你的服务器 (data.yeanhua.asia)
    ↓
make cert-generate
    ↓
certbot 启动临时 HTTP 服务器（端口 80）
    ↓
Let's Encrypt 服务器访问：
http://data.yeanhua.asia/.well-known/acme-challenge/xxx
    ↓
验证成功 ✅
    ↓
签发证书保存到：
/etc/letsencrypt/live/data.yeanhua.asia/
    ↓
复制到项目目录：
~/.local-certs/yeanhua.asia/
```

### 生产环境架构

```
Internet
    ↓
域名解析: data.yeanhua.asia → 服务器公网 IP
    ↓
防火墙/安全组（开放 80, 443 端口）
    ↓
Nginx（HTTPS）
    ├─ 443 端口 → SSL 终止
    └─ 80 端口 → 重定向到 HTTPS
    ↓
App 容器（端口 8080）
```

---

## 🎯 生产环境检查清单

### 部署前

- [ ] 域名已解析到服务器公网 IP
- [ ] 80 端口从公网可访问
- [ ] 443 端口从公网可访问
- [ ] certbot 已安装
- [ ] Docker 和 docker compose 已安装

### 部署中

- [ ] 停止占用 80 端口的服务
- [ ] 成功生成证书
- [ ] 证书文件存在且权限正确
- [ ] 服务成功启动

### 部署后

- [ ] HTTPS 可正常访问
- [ ] 证书信任链正确
- [ ] HTTP 自动重定向到 HTTPS
- [ ] 配置自动续期任务

---

## 📝 生产环境配置示例

### Nginx 配置（自动重定向）

```nginx
# HTTP → HTTPS 重定向
server {
    listen 80;
    server_name data.yeanhua.asia;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name data.yeanhua.asia;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000" always;

    location / {
        proxy_pass http://app:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 🔗 相关文档

- [letsencrypt-setup-2026-02-16.md](letsencrypt-setup-2026-02-16.md) - Let's Encrypt 完整指南
- [certificate-comparison-2026-02-16.md](certificate-comparison-2026-02-16.md) - 证书方案对比
- [deployment-guide-2026-02-16.md](deployment-guide-2026-02-16.md) - 完整部署指南

---

## 📞 获取帮助

### 查看帮助

```bash
# Makefile 帮助
make help

# cert-manager 帮助
./scripts/cert-manager.sh help
```

### 常用诊断命令

```bash
# 检查证书状态
make cert-check
make cert-info

# 查看服务状态
make docker-ps
make docker-logs

# 测试 HTTPS
curl -I https://data.yeanhua.asia
```

---

## 总结

单域名部署使用 HTTP-01 验证是最简单的方式：

✅ **优势**：
- 无需 DNS API 配置
- 配置步骤简单
- 续期自动化

⚠️ **注意**：
- 需要 80 端口公网可访问
- 只支持单个域名
- 域名必须正确解析

如果未来需要支持多个子域名（如 `api.yeanhua.asia`、`www.yeanhua.asia`），可以使用 `make cert-generate-dns` 申请泛域名证书。
