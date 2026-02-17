# Makefile 使用指南

## 核心命令速查

```bash
# 显示所有可用命令
make help

# 一键启动开发环境
make docker-dev        # 构建 + 启动 + 实时日志

# 日常开发流程
make docker-rebuild    # 代码修改后重新部署
make docker-logs       # 查看运行日志
make docker-down       # 停止服务
```

---

## 完整命令列表

### Go 原生开发（不使用 Docker）

```bash
make run          # 运行开发服务器 (go run)
make build        # 编译二进制文件
make start        # 运行编译后的二进制
make deps         # 安装/更新 Go 依赖
make clean        # 清理编译产物
```

### Docker 容器开发

#### 基础操作

```bash
make docker-build       # 构建 Docker 镜像
make docker-up          # 启动所有服务（HTTP 模式）
make docker-up-http     # 启动服务（HTTP 模式）
make docker-up-https    # 启动服务（HTTPS 模式）🔒
make docker-down        # 停止所有服务
make docker-restart     # 重启服务
```

#### 日志与调试

```bash
make docker-logs       # 查看 app 实时日志
make docker-logs-all   # 查看所有服务日志
make docker-ps         # 查看服务运行状态
make docker-shell      # 进入 app 容器的 shell
make docker-health     # 检查服务健康状态
```

#### 开发与部署

```bash
make docker-dev       # 开发模式：构建 + 启动 + 日志
make docker-rebuild   # 重新构建并部署（代码更新后使用）
```

#### 数据管理

```bash
make docker-backup    # 备份 SQLite 数据库
make docker-restore   # 从备份恢复数据库（交互式）
make docker-clean     # 清理所有资源（包括数据，需确认）
```

#### 系统维护

```bash
make docker-prune          # 清理未使用的 Docker 资源
make docker-nginx-reload   # 重载 nginx 配置（不中断服务）
make docker-nginx-test     # 测试 nginx 配置语法
```

#### HTTPS 证书管理

```bash
make cert-check        # 检查证书状态和有效期
make cert-generate     # 生成本地开发证书（mkcert）
make cert-info         # 查看证书详细信息
make cert-renew        # 续期证书
make cert-clean        # 删除证书（需确认）
```

**说明**：
- 使用 mkcert 生成本地可信证书
- 证书存储在 `~/.local-certs/yeanhua.asia/`
- 支持泛域名：`*.yeanhua.asia`
- 详见：[本地 HTTPS 配置文档](local-https-setup-2026-02-16.md)

---

## 常见使用场景

### 场景 1: 首次启动项目

```bash
# 1. 克隆项目
git clone <repo-url>
cd top-ai-news

# 2. 一键启动
make docker-dev

# 3. 访问服务
open http://localhost
```

### 场景 2: 日常开发流程

```bash
# 1. 修改代码
vim main.go

# 2. 重新构建并部署
make docker-rebuild

# 3. 查看日志确认
# 日志会自动显示（Ctrl+C 退出日志查看）
```

### 场景 3: 调试问题

```bash
# 1. 查看服务状态
make docker-ps

# 2. 查看日志
make docker-logs

# 3. 进入容器排查
make docker-shell
# 在容器内执行命令...
ls -la /app/data/
exit

# 4. 检查服务响应
make docker-health
```

### 场景 4: 代码提交前清理

```bash
# 1. 停止服务
make docker-down

# 2. 清理 Docker 资源
make docker-prune

# 3. 提交代码
git add .
git commit -m "feat: new feature"
git push
```

### 场景 5: 数据备份与恢复

```bash
# 备份数据库
make docker-backup
# 输出: ✓ 备份完成: backups/data.db.20260216_143000

# 恢复数据库（交互式）
make docker-restore
# 根据提示输入备份文件名
```

### 场景 6: 紧急故障恢复

```bash
# 1. 快速重启所有服务
make docker-restart

# 2. 如果仍有问题，完全重建
make docker-down
make docker-build
make docker-up

# 3. 检查健康状态
make docker-health
```

### 场景 7: HTTPS 开发环境

```bash
# 首次启动 HTTPS（自动生成证书）
make docker-up-https
# 输出:
# [INFO] 检查 HTTPS 证书...
# 证书不存在，正在生成...
# [INFO] 使用 mkcert 生成本地开发证书...
# ✓ 服务已启动（HTTPS）
# 访问地址:
#   • https://local.yeanhua.asia 🔒

# 后续启动（证书已存在）
make docker-up-https

# 查看证书信息
make cert-info

# 测试 HTTPS 功能
open https://local.yeanhua.asia

# 切换回 HTTP
make docker-down
make docker-up-http
```

**适用场景**：
- 测试 HTTPS 重定向
- 测试 Cookie secure 属性
- 测试 CORS 跨域策略
- 开发 Service Worker
- 开发 PWA 应用

---

## 命令对比：Makefile vs 原始 Docker

| 操作 | Makefile 命令 | 原始 Docker 命令 |
|------|--------------|-----------------|
| 构建镜像 | `make docker-build` | `docker build -t top-ai-news:latest .` |
| 启动服务 | `make docker-up` | `export DOCKER_IMAGE=top-ai-news:latest && docker compose up -d` |
| 停止服务 | `make docker-down` | `docker compose down` |
| 查看日志 | `make docker-logs` | `docker compose logs -f app` |
| 重启服务 | `make docker-restart` | `docker compose restart` |
| 进入容器 | `make docker-shell` | `docker compose exec app sh` |
| 重新部署 | `make docker-rebuild` | `docker build -t top-ai-news:latest . && docker compose up -d app` |
| 清理资源 | `make docker-prune` | `docker system prune -f` |
| 备份数据 | `make docker-backup` | 复杂的 docker run 命令... |

---

## 高级技巧

### 自定义镜像名称

```bash
# 临时修改镜像名称
IMAGE_NAME=my-custom-name make docker-build

# 或修改 Makefile 中的变量：
# IMAGE_NAME := my-custom-name
# IMAGE_TAG := v1.0.0
```

### 并行查看多个服务日志

```bash
# 使用原始命令可以自定义日志输出
docker compose logs -f app nginx certbot
```

### 在后台运行日志查看

```bash
# 启动服务后不自动显示日志
make docker-up

# 需要时再查看
make docker-logs
```

---

## 故障排查

### Makefile 命令不工作

```bash
# 检查 Make 是否安装
make --version

# Mac 安装 Make（通常已预装）
brew install make

# Linux 安装 Make
sudo apt-get install -y make
```

### 权限错误

```bash
# 确保 Makefile 有执行权限
chmod +x Makefile

# 或使用 sudo（不推荐）
sudo make docker-up
```

### Docker 未运行

```bash
# 启动 Docker Desktop (Mac/Windows)
# 或启动 Docker 服务 (Linux)
sudo systemctl start docker
```

---

## 最佳实践

1. **日常开发**：使用 `make docker-rebuild` 快速更新
2. **首次启动**：使用 `make docker-dev` 一键启动并查看日志
3. **调试问题**：先 `make docker-ps` 查看状态，再 `make docker-logs` 看日志
4. **定期备份**：使用 `make docker-backup` 备份数据（建议加入定时任务）
5. **清理资源**：定期 `make docker-prune` 释放磁盘空间
6. **配置更新**：nginx 配置更新后使用 `make docker-nginx-reload` 避免服务中断

---

## 参考资料

- 完整部署指南：[deployment-guide-2026-02-16.md](./deployment-guide-2026-02-16.md)
- 快速上手：[DEPLOY-QUICKSTART.md](./DEPLOY-QUICKSTART.md)
- SSL 配置：[ssl-certificate-setup-2026-02-16.md](./ssl-certificate-setup-2026-02-16.md)
