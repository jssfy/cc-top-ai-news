# 本地开发指南

## 核心结论

- ⭐ **一键启动**：`make docker-dev`
- ✅ 自动配置 HTTPS（mkcert）
- ✅ 使用域名 `local.yeanhua.asia`
- ✅ 自动显示实时日志
- 🔒 完整的本地 HTTPS 开发环境

---

## 🚀 快速开始

### 一键启动开发环境

```bash
# 一条命令完成所有配置
make docker-dev
```

**自动完成的步骤**：
1. ✅ 检查 `local.yeanhua.asia` 域名配置
2. ✅ 检查/生成 mkcert 本地证书
3. ✅ 构建 Docker 镜像
4. ✅ 启动 HTTPS 服务
5. ✅ 显示实时日志

**访问地址**：
- https://local.yeanhua.asia 🔒
- https://localhost 🔒

---

## 📋 前置条件

### 1. 安装 mkcert

```bash
# Mac
brew install mkcert

# Linux (Ubuntu/Debian)
sudo apt install libnss3-tools
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-v*-linux-amd64
sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert

# Arch Linux
sudo pacman -S mkcert

# 验证安装
mkcert -version
```

### 2. 配置本地域名（可选，推荐）

```bash
# 查看配置说明
make setup-local-domain

# 或直接编辑 hosts 文件
sudo vim /etc/hosts

# 添加以下行
127.0.0.1 local.yeanhua.asia
```

**验证域名**：
```bash
# 检查配置
make check-local-domain

# 或手动测试
ping local.yeanhua.asia
# 应该返回 127.0.0.1
```

---

## 🛠️ 使用方式

### 启动开发环境

```bash
# 一键启动（推荐）
make docker-dev
```

**输出示例**：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠️ 开发模式启动（HTTPS + local.yeanhua.asia）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/4] 检查本地域名配置...
✓ local.yeanhua.asia 已配置

[2/4] 检查/生成 mkcert 证书...
✓ 证书已存在

[3/4] 构建并启动服务（HTTPS）...
==> 构建 Docker 镜像...
✓ 构建完成: top-ai-news:latest
✓ 服务已启动

[4/4] 服务信息...
NAME         IMAGE                  STATUS         PORTS
nginx        nginx:alpine           Up 2 seconds   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
app          top-ai-news:latest     Up 2 seconds   8080/tcp

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 开发环境就绪！
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

访问地址:
  • https://local.yeanhua.asia 🔒
  • https://localhost 🔒

查看日志: make docker-logs

==> 查看实时日志 (Ctrl+C 退出)...
```

### 停止开发环境

```bash
# 停止服务
make docker-down

# 或按 Ctrl+C 退出日志查看（服务继续运行）
```

### 重启服务

```bash
# 重启所有容器
make docker-restart

# 代码修改后重新构建
make docker-rebuild
```

---

## 🔧 开发流程

### 标准开发流程

```bash
# 1. 启动开发环境
make docker-dev

# 2. 在另一个终端修改代码
vim main.go

# 3. 重新构建并查看效果
make docker-rebuild

# 4. 在浏览器中测试
open https://local.yeanhua.asia
```

### 快速迭代流程

```bash
# 终端 1：保持日志监控
make docker-logs

# 终端 2：修改代码后快速重新部署
vim main.go
make docker-rebuild

# 浏览器：刷新页面查看效果
```

---

## 🎯 常见场景

### 场景 1：首次使用

```bash
# 1. 安装 mkcert
brew install mkcert

# 2. 配置本地域名（可选）
make setup-local-domain
sudo vim /etc/hosts  # 添加 127.0.0.1 local.yeanhua.asia

# 3. 启动开发环境
make docker-dev

# 4. 访问
open https://local.yeanhua.asia
```

### 场景 2：证书过期或失效

```bash
# 删除旧证书
make cert-clean

# 重新生成
make cert-generate-mkcert

# 重启服务
make docker-restart
```

### 场景 3：端口被占用

```bash
# 检查端口占用
lsof -i :80
lsof -i :443

# 停止占用进程
kill -9 <PID>

# 或使用不同端口（修改 docker-compose.yml）
```

### 场景 4：切换到 HTTP 模式

```bash
# 使用 HTTP 模式启动
make docker-up

# 访问
open http://localhost
```

---

## 🔍 故障排查

### 问题 1：域名无法访问

**症状**：访问 https://local.yeanhua.asia 失败

**检查**：
```bash
# 1. 检查域名配置
make check-local-domain

# 2. 测试域名解析
ping local.yeanhua.asia

# 3. 检查服务状态
make docker-ps
```

**解决**：
```bash
# 配置域名
sudo vim /etc/hosts
# 添加：127.0.0.1 local.yeanhua.asia

# 或直接使用 localhost
open https://localhost
```

---

### 问题 2：证书不受信任

**症状**：浏览器显示"不安全连接"

**原因**：mkcert CA 未安装

**解决**：
```bash
# 安装 mkcert CA
mkcert -install

# 重新生成证书
make cert-clean
make cert-generate-mkcert

# 重启浏览器
```

---

### 问题 3：服务无法启动

**症状**：`make docker-dev` 失败

**检查**：
```bash
# 1. 查看详细日志
make docker-logs

# 2. 检查 Docker 状态
docker info

# 3. 检查端口占用
lsof -i :80
lsof -i :443
```

**解决**：
```bash
# 停止现有服务
make docker-down

# 清理资源
make docker-prune

# 重新启动
make docker-dev
```

---

### 问题 4：代码修改不生效

**症状**：修改代码后刷新页面无变化

**原因**：Docker 镜像未重新构建

**解决**：
```bash
# 重新构建镜像
make docker-rebuild

# 或强制重新构建（清除缓存）
docker compose build --no-cache
make docker-up-https
```

---

## 📊 开发环境配置

### 推荐的编辑器配置

**VS Code**：
```json
{
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.git/objects/**": true,
    "**/tmp/**": true
  },
  "go.useLanguageServer": true,
  "go.autocompleteUnimportedPackages": true
}
```

**GoLand/IDEA**：
- 启用 File Watchers
- 配置 Go Module 支持
- 启用自动导入

---

## 🚀 性能优化

### 使用 Volume 挂载（可选）

如需代码热更新，创建 `docker-compose.dev.yml`：

```yaml
services:
  app:
    volumes:
      - .:/app
      - /app/tmp
    environment:
      - GO_ENV=development
```

使用：
```bash
# 启动开发模式（热更新）
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# 代码修改自动生效
```

---

## 🔗 相关命令

```bash
# 查看帮助
make help

# 查看日志
make docker-logs

# 查看服务状态
make docker-ps

# 进入容器
make docker-shell

# 健康检查
make docker-health

# 查看证书信息
make cert-info

# 备份数据
make docker-backup
```

---

## 📚 相关文档

- [README.md](../README.md) - 项目主文档
- [快速参考](quick-reference-2026-02-16.md) - 常用命令
- [本地 HTTPS 配置](local-https-setup-2026-02-16.md) - HTTPS 详细配置
- [代码更新指南](code-update-guide-2026-02-16.md) - 生产环境部署

---

## 💡 最佳实践

### 开发流程

1. ✅ 使用 `make docker-dev` 启动开发环境
2. ✅ 保持终端显示日志（Ctrl+C 不会停止服务）
3. ✅ 修改代码后运行 `make docker-rebuild`
4. ✅ 使用 Git 分支管理功能开发
5. ✅ 定期运行 `make docker-prune` 清理资源

### 调试技巧

```bash
# 1. 实时日志
make docker-logs

# 2. 进入容器调试
make docker-shell

# 3. 查看环境变量
docker compose exec app env

# 4. 测试 API
curl https://localhost/api/news

# 5. 检查数据库
make docker-shell
ls -la /app/data/
```

### 团队协作

```bash
# 1. 使用统一的开发环境
make docker-dev

# 2. 提交前本地测试
make docker-rebuild
curl https://localhost

# 3. 使用 Git Hooks（可选）
# 在 .git/hooks/pre-commit 添加
#!/bin/bash
make docker-rebuild
```

---

## 总结

### 核心命令

```bash
make docker-dev      # 启动开发环境（一键）
make docker-down     # 停止服务
make docker-rebuild  # 代码更新后重新构建
make docker-logs     # 查看日志
```

### 访问地址

- **HTTPS**：https://local.yeanhua.asia 🔒
- **备用**：https://localhost 🔒

### 优势

- ⚡ 一键启动，无需手动配置
- 🔒 完整的 HTTPS 本地开发环境
- 📊 自动显示实时日志
- 🛠️ 与生产环境一致的配置
- 🎯 简单易用，降低学习成本
