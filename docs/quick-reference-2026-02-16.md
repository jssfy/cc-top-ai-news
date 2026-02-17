# 快速参考 - 常用命令

## 核心结论

- ⭐ **首次部署**：`make deploy-https`
- ⭐ **代码更新**：`make update-https`
- 📖 **查看帮助**：`make help`
- 📊 **查看日志**：`make docker-logs`

---

## 🚀 一键部署

### 首次部署

```bash
# SSH 到服务器
ssh user@服务器IP
cd ~/top-ai-news

# 一键部署（HTTP）
make deploy

# 一键部署（HTTPS）⭐
make deploy-https
```

### 代码更新

```bash
# HTTP 模式
make update

# HTTPS 模式 ⭐
make update-https
```

---

## 📦 Docker 服务管理

### 启动服务

```bash
# HTTP 模式
make docker-up

# HTTPS 模式
make docker-up-https

# 开发模式（构建+启动+日志）
make docker-dev
```

### 停止和重启

```bash
# 停止服务
make docker-down

# 重启服务
make docker-restart

# 重新构建并部署
make docker-rebuild
```

### 监控和调试

```bash
# 查看服务状态
make docker-ps

# 查看实时日志
make docker-logs

# 进入容器 shell
make docker-shell

# 健康检查
make docker-health
```

---

## 🔒 HTTPS 证书管理

### 生成证书

```bash
# Let's Encrypt HTTP-01（推荐生产环境）
make cert-generate

# Let's Encrypt DNS-01（泛域名）
make cert-generate-dns

# mkcert（推荐本地开发）
make cert-generate-mkcert
```

### 证书维护

```bash
# 检查证书状态
make cert-check

# 查看证书详情
make cert-info

# 续期证书
make cert-renew

# 删除证书
make cert-clean
```

### DNS API 配置

```bash
# 配置 DNS API（DNS-01 使用）
make cert-setup-dns

# 编辑配置文件
vim ~/.secrets/dns-credentials.ini

# 安装 DNS 插件
pip3 install certbot-dns-aliyun      # 阿里云
pip3 install certbot-dns-cloudflare  # Cloudflare
pip3 install certbot-dns-dnspod      # DNSPod
```

---

## 🛠️ 开发命令

### Go 原生开发

```bash
# 运行开发服务器
make run

# 编译二进制文件
make build

# 运行编译后的二进制
make start

# 安装/更新依赖
make deps

# 清理编译产物
make clean
```

---

## 📊 数据管理

### 备份和恢复

```bash
# 备份数据库
make docker-backup

# 恢复数据库
make docker-restore

# 备份文件位置
ls backups/
```

---

## 🌐 域名配置

### 本地域名

```bash
# 配置 local.yeanhua.asia
make setup-local-domain

# 检查域名配置
make check-local-domain
```

---

## 🔧 高级操作

### Nginx 管理

```bash
# 重载 Nginx 配置（不中断服务）
make docker-nginx-reload

# 测试 Nginx 配置语法
make docker-nginx-test
```

### Docker 清理

```bash
# 清理未使用的资源
make docker-prune

# 清理所有资源（包括数据）
make docker-clean
```

---

## 📖 完整工作流程

### 本地开发流程

```bash
# 1. 启动开发环境
make docker-dev

# 2. 修改代码
vim main.go

# 3. 查看日志（代码自动重载）
make docker-logs

# 4. 测试
curl http://localhost
```

### 生产部署流程

```bash
# 1. SSH 到服务器
ssh user@服务器IP
cd ~/top-ai-news

# 2. 首次部署
make deploy-https

# 3. 验证部署
make docker-ps
make docker-logs
curl https://data.yeanhua.asia

# 4. 后续更新
git pull                # 或在服务器上直接
make update-https       # 一键更新

# 5. 监控
make docker-logs
make docker-health
```

### 紧急回滚流程

```bash
# 1. 查看历史版本
git log --oneline

# 2. 回滚到指定版本
git checkout <commit-hash>

# 3. 重新部署
make update-https

# 4. 验证
curl https://data.yeanhua.asia
```

---

## 🎯 常见场景

### 场景 1：首次在服务器部署

```bash
ssh user@服务器IP
git clone <your-repo> ~/top-ai-news
cd ~/top-ai-news
make deploy-https
```

### 场景 2：本地修改后推送到生产

```bash
# 本地
git add .
git commit -m "feat: new feature"
git push

# 服务器
ssh user@服务器IP
cd ~/top-ai-news
make update-https
```

### 场景 3：证书即将过期

```bash
# 检查证书
make cert-check

# 续期证书
make cert-renew

# 重启服务
make docker-restart
```

### 场景 4：服务无响应

```bash
# 查看状态
make docker-ps

# 查看日志
make docker-logs

# 重启服务
make docker-restart

# 健康检查
make docker-health
```

### 场景 5：需要清理 Docker 资源

```bash
# 清理未使用的资源
make docker-prune

# 完全重新部署
make docker-clean
make deploy-https
```

---

## 🔍 故障排查

### 服务启动失败

```bash
# 1. 查看日志
make docker-logs

# 2. 检查容器状态
make docker-ps

# 3. 检查端口占用
lsof -i :80
lsof -i :443

# 4. 重新构建
make docker-rebuild
```

### 证书问题

```bash
# 1. 检查证书状态
make cert-check

# 2. 查看证书详情
make cert-info

# 3. 重新生成证书
make cert-clean
make cert-generate

# 4. 重启服务
make docker-restart
```

### 代码更新未生效

```bash
# 1. 确认代码已更新
git log -1
git status

# 2. 强制重新构建
make docker-build --no-cache

# 3. 重启服务
make docker-restart

# 4. 清理缓存并重新部署
make docker-clean
make deploy-https
```

---

## 📚 相关文档

- [README.md](../README.md) - 项目主文档
- [代码更新指南](code-update-guide-2026-02-16.md) - 详细更新流程
- [Makefile 使用指南](makefile-usage-2026-02-16.md) - 完整命令说明
- [证书生成位置](cert-generation-location-2026-02-16.md) - 证书生成说明
- [单域名部署](single-domain-deployment-2026-02-16.md) - HTTP-01 部署指南

---

## 💡 最佳实践

### 生产环境

1. ✅ 使用 `make deploy-https` 首次部署
2. ✅ 使用 `make update-https` 代码更新
3. ✅ 定期运行 `make cert-check` 检查证书
4. ✅ 设置自动续期任务（crontab）
5. ✅ 定期备份数据库 `make docker-backup`

### 开发环境

1. ✅ 使用 `make cert-generate-mkcert` 生成本地证书
2. ✅ 使用 `make docker-dev` 启动开发模式
3. ✅ 使用 Volume 挂载实现热更新
4. ✅ 定期运行 `make docker-prune` 清理资源

### 版本管理

1. ✅ 使用 Git 标签标记版本 `git tag v1.0.0`
2. ✅ 提交前本地测试 `make docker-dev`
3. ✅ 重要更新前备份 `make docker-backup`
4. ✅ 保留最近 3 个版本的备份

---

## ⚡ 快捷键盘

```bash
# 创建别名（添加到 ~/.bashrc 或 ~/.zshrc）
alias d-up='make docker-up-https'
alias d-down='make docker-down'
alias d-logs='make docker-logs'
alias d-ps='make docker-ps'
alias d-update='make update-https'

# 使用
d-up        # 启动服务
d-logs      # 查看日志
d-update    # 更新代码
```

---

## 📞 获取帮助

```bash
# 查看所有可用命令
make help

# 查看 Git 帮助
git --help

# 查看 Docker 帮助
docker --help
docker compose --help
```

---

## 总结

### 最常用的 5 个命令

1. `make deploy-https` - 首次部署
2. `make update-https` - 代码更新
3. `make docker-logs` - 查看日志
4. `make cert-check` - 检查证书
5. `make help` - 查看帮助

### 牢记原则

- 🚀 **首次部署**：用 `deploy-https`
- 🔄 **代码更新**：用 `update-https`
- 📊 **出问题了**：先看 `docker-logs`
- 🔒 **证书相关**：都有 `cert-` 前缀
- 📖 **不确定**：运行 `make help`
