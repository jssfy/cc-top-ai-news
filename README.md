# Top AI News

RSS-based AI news aggregator with real-time feeds.

---

## 🚀 快速开始

### 本地开发

```bash
# 查看所有可用命令
make help

# 一键启动
make docker-dev

# 访问服务
open http://local.yeanhua.asia
```

### 生产环境一键部署 ⭐

**首次部署（HTTPS）**：
```bash
# SSH 到服务器
ssh user@服务器IP
cd ~/top-ai-news

# 一键部署（自动生成证书+构建+启动）
make deploy-https

# 访问服务
# https://data.yeanhua.asia
```

**代码更新（重新加载）**：
```bash
# SSH 到服务器
cd ~/top-ai-news

# 一键更新（拉取代码+重新构建+重启）
make update-https

# 完成！
```

### 本地 HTTPS 开发

**推荐使用 mkcert**：
```bash
# 生成本地证书（无需配置）
make cert-generate-mkcert

# 启动 HTTPS 服务
make docker-up-https

# 访问服务
open https://local.yeanhua.asia
```

### 手动部署（了解细节）

**HTTP-01 验证（单域名）**：
```bash
# ⚠️ 在生产服务器上运行
ssh user@服务器IP
cd ~/top-ai-news

# 前置条件：域名解析到服务器，80 端口开放
# 停止占用 80 端口的服务
docker compose down

# 生成证书
make cert-generate

# 启动服务
make docker-up-https
```

**DNS-01 验证（泛域名）**：
```bash
# ✅ 可以在本地运行
make cert-setup-dns
vim ~/.secrets/dns-credentials.ini
pip3 install certbot-dns-aliyun
make cert-generate-dns

# 上传到服务器
scp ~/.local-certs/yeanhua.asia/* user@服务器IP:~/certs/

# 在服务器上部署
ssh user@服务器IP
cd ~/top-ai-news
make docker-up-https
```

---

## 📚 文档

完整文档请查看 [docs/](docs/) 目录。

### 快速导航

**入门指南**：
- [快速参考](docs/quick-reference-2026-02-16.md) - ⭐ **常用命令速查**
- [新手入门](docs/deploy-quickstart-2026-02-16.md) - 5 分钟快速上手
- [代码更新指南](docs/code-update-guide-2026-02-16.md) - ⭐ **如何更新代码**
- [Makefile 命令](docs/makefile-usage-2026-02-16.md) - 完整命令参考
- [完整部署指南](docs/deployment-guide-2026-02-16.md) - 深入了解架构

**HTTPS 证书**：
- [Let's Encrypt 配置](docs/letsencrypt-setup-2026-02-16.md) - 生产环境证书
- [证书生成运行位置](docs/cert-generation-location-2026-02-16.md) - ⭐ **在哪运行命令**
- [单域名部署指南](docs/single-domain-deployment-2026-02-16.md) - HTTP-01 完整流程
- [本地 HTTPS 配置](docs/local-https-setup-2026-02-16.md) - 开发环境配置
- [证书方案对比](docs/certificate-comparison-2026-02-16.md) - mkcert vs Let's Encrypt
- [默认改用 Let's Encrypt](docs/cert-default-letsencrypt-2026-02-16.md) - ⚠️ 重要变更

**索引**：
- [文档总索引](docs/README.md) - 查看所有文档

---

## 🛠️ 常用命令

```bash
# 🚀 快速部署（推荐）
make deploy             # 一键部署（HTTP，首次）
make deploy-https       # 一键部署（HTTPS，首次）⭐
make update             # 代码更新（HTTP）
make update-https       # 代码更新（HTTPS）⭐

# 📦 Docker 服务管理
make docker-up          # 启动服务（HTTP）
make docker-up-https    # 启动服务（HTTPS）🔒
make docker-down        # 停止服务
make docker-restart     # 重启服务
make docker-rebuild     # 重新构建并部署

# 📊 监控和调试
make docker-logs        # 查看日志
make docker-ps          # 查看状态
make docker-health      # 健康检查

# HTTPS 证书管理
make cert-check              # 检查证书状态和有效期
make cert-generate           # 生成证书（Let's Encrypt HTTP-01，单域名）
make cert-generate-mkcert    # 生成本地证书（mkcert，推荐本地开发）
make cert-generate-dns       # 生成泛域名证书（DNS-01，需 DNS API）
make cert-setup-dns          # 配置 DNS API（DNS-01 使用）
make cert-renew              # 续期证书（Let's Encrypt 90天）
make cert-info               # 查看证书详细信息
make cert-clean              # 删除证书
```

---

## 🔒 HTTPS 证书配置

### 方案选择

| 使用场景 | 推荐方案 | 配置命令 |
|---------|---------|---------|
| **本地开发** | mkcert | `make cert-generate-mkcert` |
| **生产环境（单域名）** | Let's Encrypt HTTP-01 | `make cert-generate` |
| **生产环境（多子域名）** | Let's Encrypt DNS-01 | `make cert-setup-dns` + `make cert-generate-dns` |
| **团队共享** | Let's Encrypt | `make cert-generate` |

### mkcert（本地开发推荐）

**优势**：
- ✅ 配置简单，一分钟完成
- ✅ 无需域名和 DNS API
- ✅ 支持 localhost 和内网 IP
- ✅ 证书长期有效，无需续期

**使用**：
```bash
make cert-generate-mkcert
make docker-up-https
```

### Let's Encrypt（生产环境）

**优势**：
- ✅ 全球浏览器信任
- ✅ 免费且自动化
- ✅ 支持单域名和泛域名

#### 方式 1：HTTP-01 验证（单域名，推荐）⭐

**特点**：
- ✅ 无需 DNS API
- ✅ 配置简单
- ❌ 只支持 `data.yeanhua.asia`
- ⚠️ **必须在生产服务器上运行**
- ⚠️ 需要 80 端口公网可访问

**配置步骤**：
```bash
# ⚠️ 在生产服务器上运行
ssh user@服务器IP
cd ~/top-ai-news

# 前置条件：域名解析到服务器，80 端口开放
# 停止占用 80 端口的服务
docker compose down

# 生成证书
make cert-generate

# 启动服务
make docker-up-https
```

#### 方式 2：DNS-01 验证（泛域名）

**特点**：
- ✅ 支持 `*.yeanhua.asia`
- ✅ 无需 80 端口
- ✅ **可以在本地或服务器运行**
- ❌ 需要 DNS API 配置

**配置步骤（本地生成）**：
```bash
# 1. 配置 DNS API（本地）
make cert-setup-dns
vim ~/.secrets/dns-credentials.ini

# 2. 安装插件
pip3 install certbot-dns-aliyun      # 阿里云
pip3 install certbot-dns-cloudflare  # Cloudflare
pip3 install certbot-dns-dnspod      # DNSPod

# 3. 生成泛域名证书
make cert-generate-dns

# 4. 上传到服务器
scp ~/.local-certs/yeanhua.asia/* user@服务器IP:~/certs/

# 5. 在服务器上启动服务
ssh user@服务器IP
cd ~/top-ai-news
make docker-up-https
```

**详细文档**：
- [Let's Encrypt 配置指南](docs/letsencrypt-setup-2026-02-16.md)
- [证书方案对比](docs/certificate-comparison-2026-02-16.md)
- [为何本地用 mkcert](docs/why-mkcert-for-local-2026-02-16.md)

---

## 🌐 访问地址

### 本地开发

- **HTTP**：http://local.yeanhua.asia 或 http://localhost
- **HTTPS**：https://local.yeanhua.asia 🔒 或 https://localhost 🔒

### 生产环境

- **正式服务**：https://data.yeanhua.asia

---

## 📖 项目结构

```
top-ai-news/
├── main.go                 # 主程序
├── Makefile               # 开发命令
├── Dockerfile             # 容器镜像
├── docker-compose.yml     # 服务编排（HTTP）
├── docker-compose.https.yml  # HTTPS 覆盖配置
├── .env.example           # 环境变量模板
├── docs/                  # 📚 完整文档
│   ├── README.md          # 文档索引
│   ├── letsencrypt-setup-2026-02-16.md  # Let's Encrypt 指南
│   └── ...
├── scripts/               # 工具脚本
│   └── cert-manager.sh    # 证书管理脚本
└── deploy/                # 部署配置
    ├── nginx/
    │   └── conf.d/
    │       ├── default.conf        # HTTP 配置
    │       └── default-https.conf  # HTTPS 配置
    └── init-ssl.sh        # SSL 初始化
```

---

## ❓ 常见问题

### Q1: 如何快速部署到生产服务器？

**使用一键部署命令**：

```bash
# 首次部署
ssh user@服务器IP
cd ~/top-ai-news
make deploy-https       # 自动生成证书+构建+启动

# 后续更新
make update-https       # 拉取代码+重新构建+重启
```

**详细说明**：[代码更新部署指南](docs/code-update-guide-2026-02-16.md)

### Q2: 证书生成命令在哪里运行？

**HTTP-01 必须在服务器运行，DNS-01 可以在本地或服务器**

| 验证方式 | 运行位置 | 原因 |
|---------|---------|------|
| **HTTP-01** | ⚠️ **必须在服务器** | Let's Encrypt 需访问服务器 80 端口 |
| **DNS-01** | ✅ **本地或服务器** | 只需 DNS API，无需服务器 |
| **mkcert** | ✅ **任何地方** | 本地 CA，无外部依赖 |

**详细说明**：[证书生成运行位置指南](docs/cert-generation-location-2026-02-16.md)

### Q3: 每次更新代码都需要重新构建吗？

**生产环境（镜像部署）**：是的，需要重新构建

```bash
# 使用一键更新命令
make update-https       # 自动：git pull + build + restart
```

**开发环境（可选 Volume 挂载）**：不需要

详见：[代码更新部署指南](docs/code-update-guide-2026-02-16.md)

### Q4: 本地开发应该用哪种证书？

**推荐 mkcert**，配置简单且无需续期：

```bash
make cert-generate-mkcert
make docker-up-https
```

### Q5: Let's Encrypt 提示缺少 DNS API 配置怎么办？

**使用 HTTP-01 验证（推荐）**：

```bash
# 无需 DNS API，在服务器上运行
make deploy-https
```

**或配置 DNS-01 验证**：

```bash
make cert-setup-dns
vim ~/.secrets/dns-credentials.ini
pip3 install certbot-dns-aliyun
make cert-generate-dns
```

### Q6: 如何切换回 mkcert？

```bash
# 删除现有证书
make cert-clean

# 使用 mkcert 生成
make cert-generate-mkcert

# 重启服务
make docker-restart
```

### Q7: 证书有效期是多久？

- **mkcert**：1-10 年（无需续期）
- **Let's Encrypt**：90 天（需定期续期：`make cert-renew`）

### Q8: HTTPS 访问显示证书错误？

**mkcert 用户**：确保已安装本地 CA

```bash
# 重新安装 CA
mkcert -install

# 重新生成证书
make cert-generate-mkcert
```

**Let's Encrypt 用户**：检查证书是否过期

```bash
make cert-check  # 查看状态
make cert-renew  # 续期证书
```

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📝 License

MIT
