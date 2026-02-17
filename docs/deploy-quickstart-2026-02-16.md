# 部署快速上手 - 5 分钟速查

## 本地部署（开发测试）

### 使用 Makefile（推荐）

```bash
# 查看所有可用命令
make help

# 一键启动（构建 + 启动 + 查看日志）
make docker-dev

# 或分步执行
make docker-build    # 构建镜像
make docker-up       # 启动服务（HTTP 模式）
make docker-logs     # 查看日志

# 使用 HTTPS 模式（可选）
make docker-up-https  # 启动 HTTPS 服务 🔒
# 首次使用会自动安装 mkcert 并生成证书

# 日常更新（代码修改后）
make docker-rebuild

# 停止服务
make docker-down
```

### HTTP vs HTTPS 模式

| 模式 | 命令 | 访问地址 | 适用场景 |
|------|------|----------|----------|
| **HTTP** | `make docker-up-http` | http://local.yeanhua.asia | 日常开发、快速迭代 |
| **HTTPS** | `make docker-up-https` | https://local.yeanhua.asia 🔒 | 测试 HTTPS 功能、模拟生产 |

**HTTPS 模式特性**：
- ✅ 自动生成本地可信证书（浏览器无警告）
- ✅ 支持泛域名：`*.yeanhua.asia`
- ✅ 证书统一存储：`~/.local-certs/yeanhua.asia/`

详见：[本地 HTTPS 配置文档](local-https-setup-2026-02-16.md)

### 使用原始 Docker 命令

```bash
# 1. 构建镜像
docker build -t top-ai-news:latest .

# 2. 启动服务
export DOCKER_IMAGE=top-ai-news:latest
docker compose up -d

# 3. 访问服务
open http://localhost

# 日常更新
docker build -t top-ai-news:latest . && docker compose restart app
```

---

## ECS 生产部署（首次配置）

### 第一步：初始化 ECS（执行一次）

```bash
# 1. 在本地执行，远程初始化 ECS
ssh root@<ECS_IP> 'bash -s' < deploy/setup-ecs.sh

# 2. 上传配置文件
scp docker-compose.yml root@<ECS_IP>:/opt/top-ai-news/
scp -r deploy root@<ECS_IP>:/opt/top-ai-news/

# 3. 配置域名 DNS A 记录指向 ECS_IP

# 4. SSH 登录 ECS 申请 SSL 证书
ssh root@<ECS_IP>
cd /opt/top-ai-news
./deploy/init-ssl.sh data.yeanhua.asia your@email.com
```

### 第二步：配置 GitHub Secrets（执行一次）

```bash
# 1. 生成 SSH 密钥
ssh-keygen -t ed25519 -f ~/.ssh/ecs_deploy_key

# 2. 添加公钥到 ECS
ssh-copy-id -i ~/.ssh/ecs_deploy_key.pub root@<ECS_IP>

# 3. 在 GitHub 仓库 Settings → Secrets 添加：
```

| Secret 名称 | 值 |
|------------|---|
| `ECS_HOST` | `<ECS公网IP>` |
| `ECS_USER` | `root` |
| `ECS_SSH_KEY` | 私钥内容 `cat ~/.ssh/ecs_deploy_key` |
| `DEPLOY_GHCR_TOKEN` | GitHub Personal Access Token (需要 `read:packages`, `write:packages`) |

```bash
# 4. 测试首次部署
git push origin main
# 在 GitHub Actions 中查看部署进度
```

---

## 日常开发流程

```bash
# 1. 本地开发测试
git checkout -b feature/xxx
# 修改代码...
docker build -t top-ai-news:latest . && docker compose restart app

# 2. 提交代码
git add .
git commit -m "feat: new feature"
git push origin feature/xxx

# 3. 合并到 main 触发自动部署
git checkout main
git merge feature/xxx
git push origin main
# GitHub Actions 自动部署到 ECS（3-5 分钟）

# 4. 验证线上服务
curl https://data.yeanhua.asia
```

---

## 常用命令

### 本地（Makefile）

```bash
# 查看帮助
make help

# 启动/停止
make docker-up         # 启动服务（HTTP）
make docker-up-http    # 启动 HTTP 服务
make docker-up-https   # 启动 HTTPS 服务 🔒
make docker-down       # 停止服务
make docker-restart    # 重启服务

# 日志/状态
make docker-logs       # 查看 app 日志
make docker-ps         # 查看服务状态
make docker-health     # 检查健康状态

# 开发调试
make docker-shell      # 进入容器
make docker-rebuild    # 代码更新后重新部署

# 数据管理
make docker-backup     # 备份数据库
make docker-clean      # 清理所有数据（危险）

# HTTPS 证书管理
make cert-check        # 检查证书状态
make cert-generate     # 生成本地证书
make cert-info         # 查看证书信息
make cert-renew        # 续期证书
```

### 本地（原始 Docker 命令）

```bash
# 查看日志
docker compose logs -f app

# 重启服务
docker compose restart app

# 停止服务
docker compose down
```

### ECS

```bash
# SSH 登录
ssh root@<ECS_IP>

# 查看服务状态
cd /opt/top-ai-news && docker compose ps

# 查看日志
docker compose logs -f app

# 手动拉取最新镜像（CI/CD 失败时）
export DOCKER_IMAGE=ghcr.io/<owner>/top-ai-news:latest
docker login ghcr.io -u <username> -p <DEPLOY_GHCR_TOKEN>
docker compose pull app
docker compose up -d app
```

---

## 故障排查

```bash
# 容器未运行
docker compose ps
docker compose logs app

# 服务 502 错误
docker compose restart nginx app

# 磁盘空间不足
docker system prune -af

# SSL 证书过期
docker compose run --rm certbot renew
docker compose restart nginx
```

---

完整文档：[deployment-guide-2026-02-16.md](deployment-guide-2026-02-16.md)
