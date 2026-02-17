# 代码更新部署指南

## 核心结论

- ✅ **一键部署**：使用 `make deploy-https`（首次）和 `make update-https`（更新）
- ✅ **生产环境**：每次代码更新需要重新构建镜像
- ✅ **开发环境**：可以使用 Volume 挂载，无需 rebuild（热更新）
- ⚠️ 区分环境使用不同的更新策略
- 📝 推荐使用 Git 标签管理版本

---

## 🚀 一键部署和更新（推荐）

### 首次部署

```bash
# SSH 到服务器
ssh user@服务器IP
cd ~/top-ai-news

# 一键部署（自动完成所有步骤）
make deploy-https
```

**执行内容**：
1. ✅ `git pull` - 拉取最新代码
2. ✅ 检查/生成 HTTPS 证书
3. ✅ `docker build` - 构建镜像
4. ✅ `docker compose up -d` - 启动服务
5. ✅ 健康检查

### 代码更新

```bash
# SSH 到服务器
cd ~/top-ai-news

# 一键更新（自动完成所有步骤）
make update-https
```

**执行内容**：
1. ✅ `git pull` - 拉取最新代码
2. ✅ 检查证书有效期
3. ✅ `docker build` - 重新构建镜像
4. ✅ `docker compose up -d` - 重启服务
5. ✅ 健康检查

---

## 🔄 代码更新流程对比

### 方式 1：一键部署/更新（推荐）⭐

**特点**：
- ✅ 一条命令完成所有步骤
- ✅ 自动检查证书
- ✅ 自动健康检查
- ✅ 友好的进度提示

**首次部署**：
```bash
make deploy-https
```

**后续更新**：
```bash
make update-https
```

---

### 方式 2：镜像部署（手动多步骤）

**特点**：
- ✅ 镜像自包含，环境一致
- ✅ 版本可控，易回滚
- ✅ 更安全，代码不暴露在宿主机
- ❌ 每次更新需要重新构建镜像

**更新步骤**：

```bash
# 1. SSH 到服务器
ssh user@服务器IP

# 2. 进入项目目录
cd ~/top-ai-news

# 3. 拉取最新代码
git pull

# 4. 重新构建并部署（一条命令）
make docker-rebuild

# 5. 查看状态
make docker-ps
make docker-logs
```

**等价于**：
```bash
git pull
docker compose down
docker compose build --no-cache
docker compose up -d
```

---

### 方式 2：Volume 挂载（开发环境）

**特点**：
- ✅ 代码立即生效，无需 rebuild
- ✅ 开发调试快速
- ❌ 宿主机需要安装依赖
- ❌ 环境不一致风险

**配置方式**：

创建 `docker-compose.dev.yml`：

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      # 挂载代码目录
      - .:/app
      # 排除构建产物
      - /app/tmp
    environment:
      - GO_ENV=development
      - AIR_ENABLED=true  # 使用 air 热重载
```

**使用方式**：

```bash
# 开发环境启动
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# 代码更新后（无需 rebuild）
git pull
docker compose restart app

# 或使用 air 热重载（代码自动生效）
# 修改代码 → 自动检测 → 自动重启
```

---

## 🚀 生产环境完整更新流程

### 步骤 1：本地测试

```bash
# 在本地测试新代码
git checkout -b feature/new-feature
# 开发...
make test
make docker-build
make docker-up
# 测试验证...
```

### 步骤 2：提交代码

```bash
# 提交到远程仓库
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# 合并到 main 分支
git checkout main
git merge feature/new-feature
git push origin main

# 打标签（推荐）
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1
```

### 步骤 3：服务器部署

```bash
# 1. SSH 到服务器
ssh user@服务器IP

# 2. 进入项目目录
cd ~/top-ai-news

# 3. 备份当前版本（可选）
docker tag top-ai-news:latest top-ai-news:backup-$(date +%Y%m%d-%H%M%S)

# 4. 拉取最新代码
git fetch --all
git pull origin main
# 或拉取特定标签
# git checkout v1.0.1

# 5. 重新构建并部署
make docker-rebuild

# 6. 验证部署
make docker-ps
make docker-logs

# 7. 测试服务
curl https://data.yeanhua.asia/health
# 或
curl https://data.yeanhua.asia/
```

### 步骤 4：回滚（如果出问题）

```bash
# 方案 1：回到上一个 Git 版本
git log --oneline  # 查看历史
git checkout <commit-hash>
make docker-rebuild

# 方案 2：使用备份镜像
docker compose down
docker tag top-ai-news:backup-20260216-143000 top-ai-news:latest
docker compose up -d

# 方案 3：回到上一个 Git 标签
git checkout v1.0.0
make docker-rebuild
```

---

## 🛠️ 开发环境快速更新

### 使用 Volume 挂载 + Air 热重载

**1. 安装 Air**

`Dockerfile.dev`：
```dockerfile
FROM golang:1.21-alpine

WORKDIR /app

# 安装 Air
RUN go install github.com/cosmtrek/air@latest

# 复制依赖文件
COPY go.mod go.sum ./
RUN go mod download

# 使用 air 启动
CMD ["air", "-c", ".air.toml"]
```

**2. 配置 Air**

`.air.toml`：
```toml
root = "."
testdata_dir = "testdata"
tmp_dir = "tmp"

[build]
  args_bin = []
  bin = "./tmp/main"
  cmd = "go build -o ./tmp/main ."
  delay = 1000
  exclude_dir = ["assets", "tmp", "vendor", "testdata"]
  exclude_file = []
  exclude_regex = ["_test.go"]
  exclude_unchanged = false
  follow_symlink = false
  full_bin = ""
  include_dir = []
  include_ext = ["go", "tpl", "tmpl", "html"]
  include_file = []
  kill_delay = "0s"
  log = "build-errors.log"
  poll = false
  poll_interval = 0
  rerun = false
  rerun_delay = 500
  send_interrupt = false
  stop_on_error = false

[color]
  app = ""
  build = "yellow"
  main = "magenta"
  runner = "green"
  watcher = "cyan"

[log]
  main_only = false
  time = false

[misc]
  clean_on_exit = false

[screen]
  clear_on_rebuild = false
  keep_scroll = true
```

**3. 使用开发环境**

```bash
# 启动开发环境
make docker-dev

# 修改代码后自动重启
# 无需手动 rebuild
vim main.go
# → Air 自动检测变化
# → 自动重新编译
# → 自动重启服务
```

---

## 📊 更新策略对比

| 维度 | 镜像部署（生产） | Volume 挂载（开发） |
|------|----------------|-------------------|
| **更新速度** | ⭐⭐ 慢（需 rebuild） | ⭐⭐⭐ 快（立即生效） |
| **环境一致性** | ⭐⭐⭐ 高 | ⭐ 低（依赖宿主机） |
| **安全性** | ⭐⭐⭐ 高 | ⭐⭐ 中 |
| **版本管理** | ⭐⭐⭐ 易回滚 | ⭐ 难回滚 |
| **适用场景** | 生产环境 | 本地开发 |

---

## 🎯 推荐的更新策略

### 本地开发

```bash
# 使用 Volume 挂载 + Air 热重载
make docker-dev

# 代码修改自动生效，无需任何操作
```

### 测试环境

```bash
# 使用一键更新
make update

# 或手动步骤
git pull
make docker-rebuild
make test
```

### 生产环境（推荐）⭐

```bash
# 方式 1：一键更新（推荐）
make update-https

# 方式 2：部署指定版本
git checkout v1.0.1
make deploy-https

# 方式 3：使用 CI/CD 自动部署
```

---

## ⚙️ Makefile 命令总览

项目已内置以下便捷命令：

### 快速部署命令 ✅

```bash
make deploy             # 一键部署（HTTP）
make deploy-https       # 一键部署（HTTPS）⭐
make update             # 代码更新（HTTP）
make update-https       # 代码更新（HTTPS）⭐
```

### 基础 Docker 命令 ✅

```bash
make docker-build       # 构建镜像
make docker-up          # 启动服务
make docker-up-https    # 启动服务（HTTPS）
make docker-down        # 停止服务
make docker-restart     # 重启服务
make docker-rebuild     # 重新构建+部署
make docker-logs        # 查看日志
make docker-ps          # 查看状态
```

### 证书管理命令 ✅

```bash
make cert-generate      # 生成证书
make cert-check         # 检查证书
make cert-info          # 证书详情
make cert-renew         # 续期证书
```

### 可选的额外命令

如需更多功能，可添加到 `Makefile`：

```makefile
# 查看版本
.PHONY: version
version:
	@git describe --tags --always
	@docker images top-ai-news:latest --format "{{.ID}} {{.CreatedAt}}"

# 回滚到上一版本
.PHONY: rollback
rollback:
	@echo "==> 回滚到上一个 commit..."
	git checkout HEAD~1
	$(MAKE) update-https

# 部署指定版本
.PHONY: deploy-version
deploy-version:
	@read -p "输入版本号（如 v1.0.0）: " version; \
	git checkout $$version && \
	$(MAKE) deploy-https
```

---

## 🔄 CI/CD 自动部署（可选）

### GitHub Actions 自动部署

`.github/workflows/deploy.yml`：

```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd ~/top-ai-news
            git fetch --all
            git checkout ${{ github.ref_name }}
            make docker-rebuild
            make docker-ps
```

**使用**：

```bash
# 本地打标签并推送
git tag v1.0.1
git push origin v1.0.1

# GitHub Actions 自动部署到服务器
# 无需手动 SSH
```

---

## 📝 常见问题

### Q1: 为什么每次都要 rebuild？

**原因**：代码被打包进 Docker 镜像

```dockerfile
# Dockerfile 中
COPY . /app
```

代码变更后，镜像内容未更新，所以需要 rebuild。

**解决**：
- 生产环境：接受 rebuild（更安全）
- 开发环境：使用 Volume 挂载

---

### Q2: rebuild 太慢怎么办？

**优化构建速度**：

```dockerfile
# 1. 多阶段构建
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download  # 缓存依赖
COPY . .
RUN go build -o main .

FROM alpine:latest
COPY --from=builder /app/main /app/main
CMD ["/app/main"]

# 2. 使用构建缓存
docker compose build --no-cache=false

# 3. 只重启服务（如果只改了配置）
make docker-restart
```

---

### Q3: 如何验证部署成功？

```bash
# 1. 检查容器状态
make docker-ps

# 2. 查看日志
make docker-logs

# 3. 测试服务
curl https://data.yeanhua.asia/health

# 4. 查看版本
curl https://data.yeanhua.asia/version
# 返回: {"version": "v1.0.1", "commit": "abc123"}

# 5. 监控指标（如果有）
curl https://data.yeanhua.asia/metrics
```

---

### Q4: 如何实现零停机部署？

**方案 1：使用 Docker Compose 滚动更新**

```bash
# 启用多副本
docker-compose.yml:
services:
  app:
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s

# 滚动更新
docker compose up -d --scale app=2
```

**方案 2：使用 Nginx 蓝绿部署**

```bash
# 1. 构建新版本（蓝）
docker build -t top-ai-news:blue .

# 2. 启动新容器
docker run -d --name app-blue -p 8081:8080 top-ai-news:blue

# 3. 测试新容器
curl http://localhost:8081

# 4. 切换 Nginx 上游
vim /etc/nginx/conf.d/app.conf
# upstream app {
#   server localhost:8081;  # 切换到蓝
# }
nginx -s reload

# 5. 停止旧容器（绿）
docker stop app-green
```

---

## 📚 相关文档

- [deployment-guide-2026-02-16.md](deployment-guide-2026-02-16.md) - 完整部署指南
- [makefile-usage-2026-02-16.md](makefile-usage-2026-02-16.md) - Makefile 命令参考
- [cicd-ali-ecs-deployment-2026-02-15.md](cicd-ali-ecs-deployment-2026-02-15.md) - CI/CD 自动部署

---

## 总结

### 生产环境（推荐）⭐

```bash
# 首次部署
ssh user@服务器
cd ~/top-ai-news
make deploy-https    # 一键部署 ✅

# 后续更新
make update-https    # 一键更新 ✅
```

### 开发环境（推荐）

```bash
# 使用 Volume 挂载
make docker-dev
# 代码修改自动生效 ✅ 无需 rebuild
```

### 快速命令对比

| 场景 | 命令 | 说明 |
|------|------|------|
| **首次部署** | `make deploy-https` | 自动生成证书+构建+启动 |
| **代码更新** | `make update-https` | 拉取+构建+重启 |
| **手动构建** | `make docker-rebuild` | 仅重新构建+重启 |
| **查看日志** | `make docker-logs` | 实时日志 |
| **查看状态** | `make docker-ps` | 容器状态 |

**核心原则**：
- 🏭 **生产环境**：使用一键命令，稳定可靠
- 🛠️ **开发环境**：使用热更新，提升效率
- 📦 **版本管理**：使用 Git 标签，易于回滚
- ⚡ **自动化**：减少手动操作，降低出错率
