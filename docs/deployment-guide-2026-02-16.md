# 部署指南 - 本地部署 vs 阿里云 ECS CD 部署

## 核心结论

| 部署方式 | 适用场景 | 操作复杂度 | 更新方式 |
|---------|---------|-----------|---------|
| **本地部署** | 开发测试、快速验证 | 简单（3 步完成） | 手动重新构建 |
| **ECS CD 部署** | 生产环境 | 中等（一次配置，后续自动） | `git push` 自动部署 |

**推荐策略**：
- 开发阶段：本地部署快速迭代
- 生产环境：ECS CD 部署，`git push` 自动更新

---

## 方案一：本地部署

### 适用场景
- 开发测试环境
- 快速功能验证
- 无需公网访问
- 单机运行

### 前置条件

```bash
# 1. 安装 Docker Desktop (Mac/Windows) 或 Docker Engine (Linux)
docker --version  # 需要 ≥ 20.10

# 2. 安装 Docker Compose
docker compose version  # 需要 ≥ 2.0

# 3. 克隆项目（如果还没有）
git clone <your-repo-url>
cd top-ai-news
```

### 快速启动（3 步）

#### 步骤 1: 构建镜像

```bash
# 本地构建 Docker 镜像
docker build -t top-ai-news:latest .

# 验证镜像创建成功
docker images | grep top-ai-news
```

#### 步骤 2: 配置 HTTP-only nginx（跳过 SSL）

本地部署通常不需要 HTTPS，确认 `deploy/nginx/conf.d/default.conf` 为 HTTP 配置：

```nginx
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://app:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### 步骤 3: 启动服务

```bash
# 使用本地构建的镜像启动服务
export DOCKER_IMAGE=top-ai-news:latest
docker compose up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f app
```

### 访问服务

```bash
# 浏览器访问
open http://localhost

# 或命令行测试
curl http://localhost
```

### 本地开发工作流

```bash
# 1. 修改代码后重新构建
docker build -t top-ai-news:latest .

# 2. 重启 app 容器
docker compose up -d app

# 3. 查看日志调试
docker compose logs -f app

# 4. 停止所有服务
docker compose down

# 5. 清理数据（谨慎！会删除数据库）
docker compose down -v
```

### 常用命令

```bash
# 进入 app 容器排查问题
docker compose exec app sh

# 查看 SQLite 数据库
docker compose exec app ls -lh /app/data/

# 重启单个服务
docker compose restart app

# 查看资源占用
docker stats top-ai-news

# 清理未使用的镜像
docker image prune -f
```

---

## 方案二：阿里云 ECS CD 自动部署

### 适用场景
- 生产环境
- 需要公网 HTTPS 访问
- 代码推送自动部署
- 多人协作开发

### 部署架构

```
┌─────────────┐       ┌──────────────────┐       ┌─────────────┐
│   GitHub    │──push─▶│ GitHub Actions  │──SSH──▶│  Ali ECS    │
│   (代码)    │       │  (CI/CD 流水线)  │       │  (生产服务器)│
└─────────────┘       └──────────────────┘       └─────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ GitHub Container │
                    │    Registry      │
                    │   (镜像仓库)     │
                    └──────────────────┘
```

**工作流程**：
1. 开发者 `git push` 到 `main` 分支
2. GitHub Actions 自动构建 Docker 镜像
3. 推送镜像到 GitHub Container Registry (ghcr.io)
4. SSH 连接到 ECS 服务器
5. 拉取最新镜像并重启服务（零停机部署）

---

## ECS 初始化（首次配置）

### 步骤 1: 购买并配置阿里云 ECS

```bash
# ECS 配置建议
CPU:    2 核
内存:   2 GB
带宽:   1-5 Mbps
系统:   Ubuntu 22.04 LTS
磁盘:   40 GB
安全组: 开放 22 (SSH), 80 (HTTP), 443 (HTTPS)
```

### 步骤 2: 执行自动化初始化脚本

**方法 1: 远程执行（推荐）**

```bash
# 在本地执行，自动通过 SSH 在 ECS 上运行初始化
ssh root@<ECS公网IP> 'bash -s' < deploy/setup-ecs.sh
```

**方法 2: 手动登录执行**

```bash
# 1. SSH 登录 ECS
ssh root@<ECS公网IP>

# 2. 下载并执行初始化脚本
curl -fsSL https://raw.githubusercontent.com/<your-repo>/main/deploy/setup-ecs.sh | bash
```

**脚本执行内容**：
- 更新系统包
- 安装 Docker + Docker Compose
- 创建项目目录 `/opt/top-ai-news`
- 配置防火墙开放 80/443 端口

### 步骤 3: 上传配置文件到 ECS

```bash
# 在本地项目目录执行
scp docker-compose.yml root@<ECS公网IP>:/opt/top-ai-news/
scp -r deploy root@<ECS公网IP>:/opt/top-ai-news/

# 验证文件上传成功
ssh root@<ECS公网IP> 'ls -R /opt/top-ai-news'
```

### 步骤 4: 配置域名 DNS 解析

在域名服务商（如阿里云、Cloudflare）添加 A 记录：

```
类型: A
主机记录: data (或 @)
记录值: <ECS公网IP>
TTL: 600
```

验证 DNS 解析：

```bash
# 等待 DNS 生效（可能需要 5-10 分钟）
dig +short data.yeanhua.asia
nslookup data.yeanhua.asia
```

### 步骤 5: 申请 SSL 证书

```bash
# SSH 登录 ECS
ssh root@<ECS公网IP>

# 执行 SSL 初始化脚本
cd /opt/top-ai-news
./deploy/init-ssl.sh data.yeanhua.asia your-email@example.com

# 验证 HTTPS 访问
curl -I https://data.yeanhua.asia
```

---

## 配置 GitHub Actions CD 流水线

### 步骤 1: 生成 ECS SSH 密钥

```bash
# 在本地生成 SSH 密钥对
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/ecs_deploy_key

# 查看公钥内容
cat ~/.ssh/ecs_deploy_key.pub

# 查看私钥内容（稍后配置到 GitHub Secrets）
cat ~/.ssh/ecs_deploy_key
```

### 步骤 2: 将公钥添加到 ECS

```bash
# 方法 1: 复制公钥到 ECS（推荐）
ssh-copy-id -i ~/.ssh/ecs_deploy_key.pub root@<ECS公网IP>

# 方法 2: 手动添加
ssh root@<ECS公网IP>
mkdir -p ~/.ssh
echo "ssh-ed25519 AAAA...公钥内容..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 步骤 3: 生成 GitHub Personal Access Token

**用途**：允许 ECS 服务器从 GitHub Container Registry 拉取私有镜像

**操作步骤**：

1. 访问 https://github.com/settings/tokens
2. 点击 `Generate new token` → `Generate new token (classic)`
3. 配置权限：
   - `repo`: Full control of private repositories
   - `read:packages`: Download packages from GitHub Package Registry
   - `write:packages`: Upload packages to GitHub Package Registry
4. 生成并复制 token（格式：`ghp_xxxxxxxxxxxx`）

### 步骤 4: 配置 GitHub Secrets

在 GitHub 仓库页面：

1. 进入 `Settings` → `Secrets and variables` → `Actions`
2. 点击 `New repository secret` 添加以下 secrets：

| Secret 名称 | 值 | 说明 |
|------------|---|------|
| `ECS_HOST` | `<ECS公网IP>` | 阿里云 ECS 服务器 IP 地址 |
| `ECS_USER` | `root` | SSH 登录用户名 |
| `ECS_SSH_KEY` | `cat ~/.ssh/ecs_deploy_key` | SSH 私钥完整内容（包含 BEGIN/END） |
| `DEPLOY_GHCR_TOKEN` | `ghp_xxxxxxxxxxxx` | 上一步生成的 GitHub Personal Access Token |

**验证配置**：

```bash
# 测试 SSH 连接
ssh -i ~/.ssh/ecs_deploy_key root@<ECS公网IP> 'echo "SSH connection successful"'
```

### 步骤 5: 测试 CD 流水线

```bash
# 方法 1: 推送代码触发（推荐）
git add .
git commit -m "test: trigger CD deployment"
git push origin main

# 方法 2: 手动触发
# 在 GitHub 仓库页面: Actions → Build & Deploy → Run workflow
```

**查看部署进度**：

1. GitHub 仓库页面 → `Actions` 标签
2. 查看最新的 workflow run
3. 点击查看详细日志

**在 ECS 上验证部署**：

```bash
# SSH 登录 ECS
ssh root@<ECS公网IP>

# 查看运行的容器
docker ps

# 查看最新日志
cd /opt/top-ai-news
docker compose logs -f app

# 验证服务响应
curl https://data.yeanhua.asia
```

---

## CD 工作流详解

### 流水线阶段

#### 阶段 1: 构建并推送镜像 (build-and-push)

```yaml
- name: Checkout                              # 拉取代码
  uses: actions/checkout@v4

- name: Login to GitHub Container Registry    # 登录镜像仓库
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}             # 自动使用 GitHub 用户名
    password: ${{ secrets.GITHUB_TOKEN }}     # 自动注入的 token

- name: Build and push Docker image           # 构建并推送镜像
  uses: docker/build-push-action@v6
  with:
    context: .
    push: true
    tags: |
      ghcr.io/<owner>/top-ai-news:latest    # latest 标签
      ghcr.io/<owner>/top-ai-news:<commit>  # commit SHA 标签
```

**镜像标签策略**：
- `latest`：始终指向最新版本（生产环境使用）
- `<commit-sha>`：精确版本控制（回滚时使用）

#### 阶段 2: 部署到 ECS (deploy)

```yaml
- name: Deploy to ECS via SSH
  uses: appleboy/ssh-action@v1
  with:
    host: ${{ secrets.ECS_HOST }}
    username: ${{ secrets.ECS_USER }}
    key: ${{ secrets.ECS_SSH_KEY }}
    script: |
      cd /opt/top-ai-news

      # 登录 GHCR（使用 DEPLOY_GHCR_TOKEN）
      docker login ghcr.io -u <user> -p ${{ secrets.DEPLOY_GHCR_TOKEN }}

      # 拉取最新镜像
      export DOCKER_IMAGE=ghcr.io/<owner>/top-ai-news:latest
      docker compose pull app

      # 零停机重启（先启动新容器，再停止旧容器）
      docker compose up -d app

      # 清理旧镜像
      docker image prune -f
```

### 零停机部署原理

```bash
# docker compose up -d 的行为：
# 1. 拉取新镜像
# 2. 创建新容器（新端口或与旧容器共存）
# 3. 新容器启动成功后，停止旧容器
# 4. 删除旧容器
# 整个过程中，nginx 始终有可用的 app 后端
```

### 触发条件

```yaml
on:
  push:
    branches: [main]      # 推送到 main 分支自动触发
  workflow_dispatch:       # 支持手动触发
```

---

## 日常更新流程

### 本地开发流程

```bash
# 1. 创建功能分支
git checkout -b feature/new-feature

# 2. 本地开发测试
docker build -t top-ai-news:latest .
docker compose up -d app
# 测试功能...

# 3. 提交代码
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# 4. 创建 Pull Request（可选，团队协作时使用）
# 在 GitHub 上创建 PR，代码审查后合并到 main

# 5. 合并到 main 分支（触发自动部署）
git checkout main
git merge feature/new-feature
git push origin main
# GitHub Actions 自动构建并部署到 ECS
```

### 生产环境热修复

```bash
# 1. 创建 hotfix 分支
git checkout -b hotfix/critical-bug main

# 2. 快速修复
# 修改代码...

# 3. 直接合并到 main（跳过 PR 流程）
git checkout main
git merge hotfix/critical-bug
git push origin main
# 等待自动部署完成（约 3-5 分钟）

# 4. 验证修复
curl https://data.yeanhua.asia
```

---

## 回滚操作

### 方法 1: 使用 Git 回滚（推荐）

```bash
# 1. 查看最近的提交
git log --oneline -10

# 2. 回滚到指定 commit
git revert <commit-sha>
# 或强制回滚
git reset --hard <commit-sha>

# 3. 推送触发重新部署
git push origin main --force
```

### 方法 2: 手动切换镜像版本

```bash
# 1. SSH 登录 ECS
ssh root@<ECS公网IP>

# 2. 查看可用的镜像版本
docker images | grep top-ai-news

# 3. 指定旧版本镜像
cd /opt/top-ai-news
export DOCKER_IMAGE=ghcr.io/<owner>/top-ai-news:<old-commit-sha>
docker compose pull app
docker compose up -d app

# 4. 验证回滚成功
docker compose logs -f app
```

### 方法 3: 从备份恢复数据

```bash
# 1. 停止服务
docker compose stop app

# 2. 恢复数据库备份
docker run --rm -v top-ai-news_app-data:/data \
  -v $(pwd)/backups:/backup alpine \
  cp /backup/data.db.backup /data/data.db

# 3. 重启服务
docker compose up -d app
```

---

## 监控与维护

### 服务健康检查

```bash
# 1. 检查容器状态
ssh root@<ECS公网IP> 'docker compose -f /opt/top-ai-news/docker-compose.yml ps'

# 2. 检查服务响应
curl -f https://data.yeanhua.asia || echo "Service down!"

# 3. 查看最近日志
ssh root@<ECS公网IP> 'docker compose -f /opt/top-ai-news/docker-compose.yml logs --tail=100 app'
```

### 日志管理

```bash
# 实时日志
docker compose logs -f app

# 查看最近 100 行
docker compose logs --tail=100 app

# 导出日志到文件
docker compose logs app > /tmp/app-$(date +%Y%m%d).log

# 清理日志（释放磁盘空间）
docker compose down
docker system prune -af --volumes
docker compose up -d
```

### 数据备份

```bash
# 自动备份脚本（可添加到 crontab）
#!/bin/bash
BACKUP_DIR="/opt/backups/top-ai-news"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份 SQLite 数据库
docker run --rm \
  -v top-ai-news_app-data:/data \
  -v $BACKUP_DIR:/backup \
  alpine cp /data/data.db /backup/data.db.$DATE

# 保留最近 7 天的备份
find $BACKUP_DIR -name "data.db.*" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/data.db.$DATE"
```

**配置定时备份**：

```bash
# 编辑 crontab
crontab -e

# 每天凌晨 2 点备份
0 2 * * * /opt/scripts/backup-top-ai-news.sh
```

### 证书续期监控

```bash
# 查看证书有效期
ssh root@<ECS公网IP> 'docker compose -f /opt/top-ai-news/docker-compose.yml run --rm certbot certificates'

# 测试自动续期
ssh root@<ECS公网IP> 'docker compose -f /opt/top-ai-news/docker-compose.yml run --rm certbot renew --dry-run'

# 手动强制续期（如果自动续期失败）
ssh root@<ECS公网IP> 'docker compose -f /opt/top-ai-news/docker-compose.yml run --rm certbot renew --force-renewal'
ssh root@<ECS公网IP> 'docker compose -f /opt/top-ai-news/docker-compose.yml restart nginx'
```

---

## 常见问题排查

### 问题 1: GitHub Actions 构建失败

**错误信息**：`Error: buildx failed with: ERROR: failed to solve: process "/bin/sh -c go build" did not complete successfully`

**原因**：Go 依赖下载失败或编译错误

**解决**：

```bash
# 1. 本地构建测试
docker build -t top-ai-news:latest .

# 2. 检查 go.mod 依赖
go mod tidy

# 3. 查看 GitHub Actions 日志
# 在 GitHub 仓库页面: Actions → 失败的 workflow → 点击查看详细日志
```

### 问题 2: ECS 拉取镜像失败

**错误信息**：`Error response from daemon: pull access denied for ghcr.io/xxx/top-ai-news`

**原因**：GHCR 认证失败

**解决**：

```bash
# 1. 验证 DEPLOY_GHCR_TOKEN 是否配置正确
# GitHub: Settings → Secrets → 检查 DEPLOY_GHCR_TOKEN

# 2. 测试 token 是否有效
echo $DEPLOY_GHCR_TOKEN | docker login ghcr.io -u <username> --password-stdin

# 3. 确认镜像权限设置为 public（如果是私有项目）
# GitHub: 仓库页面 → Packages → top-ai-news → Package settings → Change visibility
```

### 问题 3: 部署后服务无响应

**错误信息**：`502 Bad Gateway` 或 `Connection refused`

**排查步骤**：

```bash
# 1. 检查 app 容器是否运行
ssh root@<ECS公网IP> 'docker ps | grep top-ai-news'

# 2. 查看 app 容器日志
ssh root@<ECS公网IP> 'docker compose -f /opt/top-ai-news/docker-compose.yml logs --tail=50 app'

# 3. 检查端口监听
ssh root@<ECS公网IP> 'netstat -tuln | grep 8080'

# 4. 手动测试 app 后端
ssh root@<ECS公网IP> 'curl http://127.0.0.1:8080'

# 5. 检查 nginx 配置
ssh root@<ECS公网IP> 'docker compose -f /opt/top-ai-news/docker-compose.yml exec nginx nginx -t'
```

### 问题 4: SSH 连接超时

**错误信息**：`timeout waiting for connection`

**原因**：阿里云安全组未开放 22 端口

**解决**：

1. 登录阿里云控制台
2. ECS 实例 → 安全组 → 配置规则
3. 添加入方向规则：
   - 协议类型：TCP
   - 端口范围：22/22
   - 授权对象：0.0.0.0/0（或指定 IP）

### 问题 5: 磁盘空间不足

**错误信息**：`no space left on device`

**解决**：

```bash
# 1. 查看磁盘使用情况
ssh root@<ECS公网IP> 'df -h'

# 2. 清理 Docker 缓存
ssh root@<ECS公网IP> 'docker system prune -af --volumes'

# 3. 清理旧镜像
ssh root@<ECS公网IP> 'docker images | grep top-ai-news'
ssh root@<ECS公网IP> 'docker rmi <old-image-id>'

# 4. 清理日志文件
ssh root@<ECS公网IP> 'journalctl --vacuum-time=7d'
```

---

## 性能优化建议

### 构建优化

**多阶段构建缓存**：

```dockerfile
# 利用 Docker 层缓存，依赖变化时才重新下载
COPY go.mod go.sum ./
RUN go mod download        # 这一层会被缓存

COPY . .
RUN go build               # 只有代码变化才执行
```

**使用 BuildKit**：

```bash
# 启用 BuildKit 加速构建
export DOCKER_BUILDKIT=1
docker build -t top-ai-news:latest .
```

### 镜像优化

```bash
# 查看镜像大小
docker images top-ai-news

# 当前镜像大小（多阶段构建后）
# REPOSITORY      TAG       SIZE
# top-ai-news     latest    ~20 MB (alpine base)

# 优化技巧：
# 1. 使用 alpine 基础镜像（已应用）
# 2. 多阶段构建，只保留运行时文件（已应用）
# 3. 使用 .dockerignore 排除不必要的文件（已应用）
```

### 部署优化

**并行部署多个服务**：

```bash
# 如果有多个独立服务，可以并行重启
docker compose up -d app nginx certbot --no-deps
```

**健康检查**：

```yaml
# 在 docker-compose.yml 中添加
services:
  app:
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

## 安全加固建议

### ECS 安全

```bash
# 1. 禁用 root 密码登录，只允许密钥认证
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 2. 配置 fail2ban 防止暴力破解
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban

# 3. 定期更新系统
sudo apt-get update && sudo apt-get upgrade -y

# 4. 使用非 root 用户运行服务（可选）
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
```

### Secrets 管理

```bash
# 不要在代码中硬编码敏感信息
# ❌ 错误示例
export DB_PASSWORD="my_password"

# ✅ 正确示例：使用环境变量
# 在 GitHub Secrets 中配置 DB_PASSWORD
# 在 docker-compose.yml 中引用
environment:
  - DB_PASSWORD=${DB_PASSWORD}
```

### 镜像安全

```bash
# 定期扫描镜像漏洞
docker scan top-ai-news:latest

# 使用官方基础镜像
FROM golang:1.25-alpine  # 官方维护，及时修复漏洞
```

---

## 快速参考命令

### 本地部署

```bash
# 构建并启动
docker build -t top-ai-news:latest . && docker compose up -d

# 查看日志
docker compose logs -f app

# 重启服务
docker compose restart app

# 停止并清理
docker compose down -v
```

### ECS 部署

```bash
# 触发部署
git push origin main

# 查看部署状态
# 在 GitHub: Actions → 最新的 workflow run

# SSH 登录 ECS
ssh root@<ECS公网IP>

# 查看服务状态
cd /opt/top-ai-news && docker compose ps

# 查看日志
cd /opt/top-ai-news && docker compose logs -f app
```

### 故障排查

```bash
# 容器状态
docker ps -a

# 详细日志
docker compose logs --tail=100 app

# 进入容器调试
docker compose exec app sh

# 重启所有服务
docker compose restart

# 完全重建（清理缓存）
docker compose down && docker compose up -d --build
```

---

## 相关文件

- `Dockerfile` - Docker 镜像构建配置
- `docker-compose.yml` - 服务编排配置
- `.github/workflows/deploy.yml` - CI/CD 流水线配置
- `deploy/setup-ecs.sh` - ECS 初始化脚本
- `deploy/init-ssl.sh` - SSL 证书申请脚本
- `.dockerignore` - Docker 构建排除文件

## 参考资料

- [Docker 官方文档](https://docs.docker.com/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [阿里云 ECS 文档](https://help.aliyun.com/product/25365.html)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
