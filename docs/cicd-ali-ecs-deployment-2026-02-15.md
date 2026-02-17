# CI/CD 部署方案：Ali ECS + HTTPS + 域名访问

## 核心结论

- **CI/CD 方案**：GitHub Actions + GHCR（GitHub Container Registry）+ SSH 部署，零成本、与代码仓库无缝集成
- **HTTPS 方案**：Nginx 反向代理 + Let's Encrypt 免费证书，certbot 自动续期
- **部署架构**：Docker Compose 编排 3 个容器（App + Nginx + Certbot），单机即可运行
- **首次部署约 30 分钟**，后续每次 push 到 main 自动完成构建 + 部署

---

## 1. 整体架构

```
                    ┌─────────────┐
  用户浏览器 ──────→│  Ali ECS     │
  https://domain    │             │
                    │  ┌────────┐ │
              :443 →│  │ Nginx  │ │  反向代理 + SSL 终止
                    │  └───┬────┘ │
                    │      │:8080 │
                    │  ┌───▼────┐ │
                    │  │ Go App │ │  top-ai-news 服务
                    │  └───┬────┘ │
                    │      │      │
                    │  ┌───▼────┐ │
                    │  │ SQLite │ │  数据持久化 (Docker Volume)
                    │  └────────┘ │
                    └─────────────┘
```

**CI/CD 流程：**

```
git push main → GitHub Actions → Build Docker Image → Push to GHCR → SSH to ECS → docker compose pull & up
```

## 2. 创建的文件清单

| 文件 | 用途 |
|------|------|
| `Dockerfile` | 多阶段构建，生成精简的 Alpine 运行镜像 |
| `docker-compose.yml` | 编排 App + Nginx + Certbot 三个服务 |
| `.dockerignore` | 排除不需要的文件加速构建 |
| `.github/workflows/deploy.yml` | GitHub Actions CI/CD 工作流 |
| `deploy/nginx/conf.d/default.conf` | Nginx 配置（HTTPS + 反向代理） |
| `deploy/init-ssl.sh` | 首次 SSL 证书申请脚本 |
| `deploy/setup-ecs.sh` | ECS 服务器初始化脚本 |

## 3. 部署步骤（按顺序执行）

### Step 1: 准备工作

**前置条件：**
- 一台 Ali ECS 实例（推荐 Ubuntu 22.04，2C4G 足够）
- 一个域名（已完成备案，如果是 .cn 域名）
- GitHub 仓库（代码已推送）

**域名 DNS 配置：**
在域名控制台添加 A 记录，指向 ECS 公网 IP：
```
类型: A
主机记录: @（或 www、news 等子域名）
记录值: <ECS 公网 IP>
```

### Step 2: 初始化 ECS

```bash
# 本地执行，远程运行初始化脚本
ssh root@<ECS_IP> 'bash -s' < deploy/setup-ecs.sh
```

### Step 3: 上传配置文件到 ECS

```bash
# 上传 docker-compose 和 deploy 目录
scp docker-compose.yml root@<ECS_IP>:/opt/top-ai-news/
scp -r deploy/ root@<ECS_IP>:/opt/top-ai-news/
```

### Step 4: 申请 SSL 证书

```bash
ssh root@<ECS_IP>
cd /opt/top-ai-news

# 首次需要先手动拉取镜像并启动
export DOCKER_IMAGE=ghcr.io/<your-github-username>/top-ai-news:latest
docker login ghcr.io -u <your-github-username>
docker compose pull app

# 申请证书（自动完成 HTTP 验证 → 获取证书 → 启用 HTTPS）
./deploy/init-ssl.sh your-domain.com your-email@example.com
```

### Step 5: 配置 GitHub Actions Secrets

在 GitHub 仓库 → Settings → Secrets and variables → Actions 中添加：

| Secret Name | 值 |
|-------------|---|
| `ECS_HOST` | ECS 公网 IP |
| `ECS_USER` | `root`（或其他用户） |
| `ECS_SSH_KEY` | ECS 的 SSH 私钥内容 |
| `DEPLOY_GHCR_TOKEN` | GitHub PAT（需 `read:packages` 权限） |

### Step 6: 触发首次部署

```bash
git add .
git commit -m "feat: add CI/CD pipeline for Ali ECS deployment"
git push origin main
```

push 后 GitHub Actions 自动执行：构建镜像 → 推送到 GHCR → SSH 到 ECS 拉取并重启。

## 4. 方案对比与选型理由

### CI/CD 工具选型

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **GitHub Actions + GHCR** ✅ | 免费、与 GitHub 原生集成、无需额外服务 | 国内拉取 GHCR 偶尔较慢 | 个人/小团队项目 |
| GitHub Actions + 阿里 ACR | 国内拉取快 | 需额外开通 ACR 服务、配置 AccessKey | 对国内速度敏感 |
| Jenkins on ECS | 灵活、可控 | 需额外服务器资源、运维成本高 | 企业内部 |

**选 GitHub Actions + GHCR 的理由：** 零成本、配置简单、对个人项目完全够用。如果 GHCR 拉取慢，可加一层阿里云镜像加速。

### HTTPS 方案

| 方案 | 成本 | 自动续期 | 复杂度 |
|------|------|----------|--------|
| **Let's Encrypt + Certbot** ✅ | 免费 | 支持 | 低 |
| 阿里云免费 SSL 证书 | 免费（每年限 20 个） | 需手动 | 中 |
| 付费 SSL 证书 | ¥1000+/年 | 视厂商 | 低 |

**选 Let's Encrypt 的理由：** 完全免费、自动续期、行业标准，docker-compose 中 certbot 容器每 12 小时检查并续期。

## 5. 关键配置说明

### Dockerfile 多阶段构建

```
golang:1.23-alpine (构建层)  →  alpine:3.19 (运行层)
~1GB                            ~17MB + binary
```
最终镜像约 **30MB**，相比直接使用 golang 镜像减少 97% 体积。

### Nginx SSL 安全配置

- 仅启用 TLS 1.2/1.3
- HSTS 头强制 HTTPS（max-age=1年）
- 防 XSS、点击劫持等安全头
- Gzip 压缩静态资源

### 数据持久化

SQLite 数据库通过 Docker Named Volume (`app-data`) 持久化，不会因容器重启丢失数据。

## 6. 后续运维

```bash
# 查看日志
docker compose logs -f app

# 手动重启
docker compose restart app

# 手动更新部署（不通过 CI/CD）
docker compose pull app && docker compose up -d app

# 备份数据库
docker cp top-ai-news:/app/data/data.db ./backup-$(date +%Y%m%d).db

# SSL 证书状态检查
docker compose run --rm certbot certificates
```

## 7. 可选优化

- **GHCR 拉取慢**：可改用阿里云 ACR，workflow 中替换 registry 即可
- **多实例扩展**：如果流量增长，可将 SQLite 替换为 MySQL/PostgreSQL，Nginx 做负载均衡
- **监控告警**：接入阿里云云监控或 Prometheus + Grafana
- **数据库自动备份**：添加 cron job 定期将 data.db 备份到 OSS
