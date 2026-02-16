.PHONY: help run build start deps clean \
	docker-build docker-up docker-up-http docker-up-https docker-down docker-restart docker-logs docker-ps docker-shell \
	docker-clean docker-rebuild docker-dev docker-prune docker-backup docker-health \
	deploy deploy-https update update-https \
	setup-local-domain check-local-domain cert-check cert-generate cert-generate-mkcert cert-generate-dns cert-info cert-renew cert-clean cert-setup-dns

# ====================================
# Go Native Development (本地 Go 开发)
# ====================================

# Default port
PORT ?= 8080

# Run in development mode
run: deps
	go run . -port $(PORT)

# Build binary
build: deps
	go build -o bin/top-ai-news .

# Run built binary
start: build
	./bin/top-ai-news -port $(PORT)

# Install dependencies
deps:
	go mod tidy

# Clean build artifacts and database
clean:
	rm -rf bin/ data.db

# ====================================
# Docker Development (Docker 容器开发)
# ====================================

# Docker image settings
IMAGE_NAME := top-ai-news
IMAGE_TAG := latest
DOCKER_IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

# Default target
.DEFAULT_GOAL := help

## help: 显示帮助信息
help:
	@echo "Top AI News - 开发命令"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Go 原生开发（本地直接运行）:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  make run          - 运行开发服务器 (go run)"
	@echo "  make build        - 编译二进制文件"
	@echo "  make start        - 运行编译后的二进制"
	@echo "  make deps         - 安装/更新依赖"
	@echo "  make clean        - 清理编译产物"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🚀 快速部署（推荐）:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  make deploy             - 一键部署（HTTP，首次部署）"
	@echo "  make deploy-https       - 一键部署（HTTPS，首次部署）⭐"
	@echo "  make update             - 代码更新（HTTP，重新加载）"
	@echo "  make update-https       - 代码更新（HTTPS，重新加载）⭐"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Docker 开发（容器化部署）:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  make docker-build       - 构建 Docker 镜像"
	@echo "  make docker-up          - 启动所有服务（HTTP 模式）"
	@echo "  make docker-up-http     - 启动服务（HTTP 模式）"
	@echo "  make docker-up-https    - 启动服务（HTTPS 模式）🔒"
	@echo "  make docker-down        - 停止所有服务"
	@echo "  make docker-restart     - 重启服务"
	@echo "  make docker-logs        - 查看实时日志"
	@echo "  make docker-ps          - 查看服务状态"
	@echo "  make docker-shell       - 进入容器 shell"
	@echo "  make docker-clean       - 清理所有资源（包括数据）"
	@echo "  make docker-rebuild     - 重新构建并部署"
	@echo "  make docker-dev         - 开发模式（HTTPS + local.yeanhua.asia）⭐"
	@echo "  make docker-prune       - 清理未使用的 Docker 资源"
	@echo "  make docker-backup      - 备份数据库"
	@echo "  make docker-health      - 检查服务健康状态"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "HTTPS 证书管理:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  make cert-check            - 检查证书状态"
	@echo "  make cert-generate         - 生成证书（默认 Let's Encrypt HTTP-01）"
	@echo "  make cert-generate-mkcert  - 生成本地证书（mkcert，推荐开发）"
	@echo "  make cert-generate-dns     - 生成泛域名证书（DNS-01，需 DNS API）"
	@echo "  make cert-info             - 查看证书详细信息"
	@echo "  make cert-renew            - 续期证书"
	@echo "  make cert-clean            - 删除证书"
	@echo "  make cert-setup-dns        - 配置 DNS API 凭证（DNS-01 使用）"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "本地域名配置:"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  make setup-local-domain  - 配置 local.yeanhua.asia"
	@echo "  make check-local-domain  - 检查域名配置状态"
	@echo ""

## docker-build: 构建 Docker 镜像
docker-build:
	@echo "==> 构建 Docker 镜像..."
	docker build -t $(DOCKER_IMAGE) .
	@echo "✓ 构建完成: $(DOCKER_IMAGE)"

## docker-up: 启动所有服务（后台运行，HTTP 模式）
docker-up: docker-up-http

## docker-up-http: 启动服务（HTTP 模式）
docker-up-http:
	@echo "==> 启动服务（HTTP 模式）..."
	export DOCKER_IMAGE=$(DOCKER_IMAGE) && docker compose up -d
	@echo "✓ 服务已启动（HTTP）"
	@echo ""
	@echo "访问地址:"
	@echo "  • http://local.yeanhua.asia"
	@echo "  • http://localhost"
	@echo ""
	@make docker-ps

## docker-up-https: 启动服务（HTTPS 模式，需要先生成证书）
docker-up-https:
	@echo "==> 检查 HTTPS 证书..."
	@if ./scripts/cert-manager.sh check >/dev/null 2>&1; then \
		echo "✓ 证书有效"; \
	else \
		echo ""; \
		echo "证书不存在或已过期，正在生成..."; \
		./scripts/cert-manager.sh generate || exit 1; \
	fi
	@echo ""
	@echo "==> 启动服务（HTTPS 模式）..."
	export DOCKER_IMAGE=$(DOCKER_IMAGE) && docker compose -f docker-compose.yml -f docker-compose.https.yml up -d
	@echo "✓ 服务已启动（HTTPS）"
	@echo ""
	@echo "访问地址:"
	@echo "  • https://local.yeanhua.asia  🔒"
	@echo "  • https://localhost  🔒"
	@echo "  • http://local.yeanhua.asia  (重定向到 HTTPS)"
	@echo ""
	@make docker-ps

## docker-down: 停止并删除所有容器
docker-down:
	@echo "==> 停止服务..."
	docker compose down
	@echo "✓ 服务已停止"

## docker-restart: 重启服务
docker-restart:
	@echo "==> 重启服务..."
	docker compose restart
	@echo "✓ 服务已重启"
	@make docker-ps

## docker-logs: 查看 app 服务日志（实时）
docker-logs:
	docker compose logs -f app

## docker-logs-all: 查看所有服务日志
docker-logs-all:
	docker compose logs -f

## docker-ps: 查看服务状态
docker-ps:
	@echo "==> 服务状态:"
	@docker compose ps

## docker-shell: 进入 app 容器的 shell
docker-shell:
	docker compose exec app sh

## docker-clean: 停止服务并清理所有数据（包括 volumes）
docker-clean:
	@echo "⚠️  警告: 此操作将删除所有数据（包括数据库）"
	@read -p "确认要删除所有数据吗？[y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "✓ 清理完成"; \
	else \
		echo "✗ 取消清理"; \
	fi

## docker-rebuild: 重新构建并启动（用于代码更新后）
docker-rebuild: docker-build
	@echo "==> 重启 app 容器..."
	export DOCKER_IMAGE=$(DOCKER_IMAGE) && docker compose up -d app
	@echo "✓ 重新部署完成"
	@echo ""
	@echo "访问地址:"
	@echo "  • http://local.yeanhua.asia"
	@echo "  • http://localhost"
	@echo ""
	@echo "==> 查看日志 (Ctrl+C 退出)..."
	@make docker-logs

## docker-dev: 开发模式（构建 + HTTPS 启动 + 查看日志）
docker-dev:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🛠️ 开发模式启动（HTTPS + local.yeanhua.asia）"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "[1/4] 检查本地域名配置..."
	@if grep -q "local.yeanhua.asia" /etc/hosts 2>/dev/null; then \
		echo "✓ local.yeanhua.asia 已配置"; \
	else \
		echo "⚠️  local.yeanhua.asia 未配置"; \
		echo ""; \
		echo "请运行: make setup-local-domain"; \
		echo "或手动添加到 /etc/hosts:"; \
		echo "  127.0.0.1 local.yeanhua.asia"; \
		echo ""; \
	fi
	@echo ""
	@echo "[2/4] 检查/生成 mkcert 证书..."
	@if ./scripts/cert-manager.sh check >/dev/null 2>&1; then \
		echo "✓ 证书已存在"; \
	else \
		echo "生成 mkcert 本地证书..."; \
		./scripts/cert-manager.sh generate mkcert || exit 1; \
	fi
	@echo ""
	@echo "[3/4] 构建并启动服务（HTTPS）..."
	@$(MAKE) docker-build
	@export DOCKER_IMAGE=$(DOCKER_IMAGE) && docker compose -f docker-compose.yml -f docker-compose.https.yml up -d
	@echo "✓ 服务已启动"
	@echo ""
	@echo "[4/4] 服务信息..."
	@sleep 2
	@$(MAKE) docker-ps
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🎉 开发环境就绪！"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "访问地址:"
	@echo "  • https://local.yeanhua.asia 🔒"
	@echo "  • https://localhost 🔒"
	@echo ""
	@echo "查看日志: make docker-logs"
	@echo ""
	@echo "==> 查看实时日志 (Ctrl+C 退出)..."
	@$(MAKE) docker-logs

# ====================================
# One-Click Deployment (一键部署)
# ====================================

## deploy: 一键部署（HTTP 模式）
deploy:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🚀 一键部署开始（HTTP 模式）"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "[1/4] 拉取最新代码..."
	@git pull || (echo "✗ Git pull 失败" && exit 1)
	@echo "✓ 代码已更新"
	@echo ""
	@echo "[2/4] 构建 Docker 镜像..."
	@$(MAKE) docker-build
	@echo ""
	@echo "[3/4] 启动服务..."
	@$(MAKE) docker-up-http
	@echo ""
	@echo "[4/4] 检查服务状态..."
	@sleep 2
	@$(MAKE) docker-health
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🎉 部署完成！"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "访问地址:"
	@echo "  • http://data.yeanhua.asia"
	@echo "  • http://localhost"
	@echo ""
	@echo "查看日志: make docker-logs"
	@echo "查看状态: make docker-ps"
	@echo ""

## deploy-https: 一键部署（HTTPS 模式）
deploy-https:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🚀 一键部署开始（HTTPS 模式）"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "[1/5] 拉取最新代码..."
	@git pull || (echo "✗ Git pull 失败" && exit 1)
	@echo "✓ 代码已更新"
	@echo ""
	@echo "[2/5] 检查/生成 HTTPS 证书..."
	@if ./scripts/cert-manager.sh check >/dev/null 2>&1; then \
		echo "✓ 证书已存在且有效"; \
	else \
		echo "证书不存在，正在生成..."; \
		./scripts/cert-manager.sh generate || exit 1; \
	fi
	@echo ""
	@echo "[3/5] 构建 Docker 镜像..."
	@$(MAKE) docker-build
	@echo ""
	@echo "[4/5] 启动服务（HTTPS）..."
	@$(MAKE) docker-up-https
	@echo ""
	@echo "[5/5] 检查服务状态..."
	@sleep 2
	@curl -k -f https://localhost/ >/dev/null 2>&1 && echo "✓ HTTPS 服务正常运行" || echo "✗ HTTPS 服务未响应"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🎉 部署完成！"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "访问地址:"
	@echo "  • https://data.yeanhua.asia 🔒"
	@echo "  • https://localhost 🔒"
	@echo ""
	@echo "查看日志: make docker-logs"
	@echo "查看状态: make docker-ps"
	@echo "查看证书: make cert-info"
	@echo ""

## update: 代码更新并重新加载（HTTP 模式）
update:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔄 代码更新开始（HTTP 模式）"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "[1/3] 拉取最新代码..."
	@git pull || (echo "✗ Git pull 失败" && exit 1)
	@echo "✓ 代码已更新"
	@echo ""
	@echo "[2/3] 重新构建并部署..."
	@$(MAKE) docker-rebuild
	@echo ""
	@echo "[3/3] 验证服务..."
	@sleep 2
	@$(MAKE) docker-health
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "✓ 更新完成！"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""

## update-https: 代码更新并重新加载（HTTPS 模式）
update-https:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🔄 代码更新开始（HTTPS 模式）"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "[1/4] 拉取最新代码..."
	@git pull || (echo "✗ Git pull 失败" && exit 1)
	@echo "✓ 代码已更新"
	@echo ""
	@echo "[2/4] 检查证书有效期..."
	@./scripts/cert-manager.sh check || echo "⚠️  证书将过期，建议运行: make cert-renew"
	@echo ""
	@echo "[3/4] 重新构建镜像..."
	@$(MAKE) docker-build
	@echo ""
	@echo "[4/4] 重启服务..."
	@export DOCKER_IMAGE=$(DOCKER_IMAGE) && docker compose -f docker-compose.yml -f docker-compose.https.yml up -d app
	@echo "✓ 服务已重启"
	@echo ""
	@sleep 2
	@curl -k -f https://localhost/ >/dev/null 2>&1 && echo "✓ HTTPS 服务正常运行" || echo "✗ HTTPS 服务未响应"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "✓ 更新完成！"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "访问地址:"
	@echo "  • https://data.yeanhua.asia 🔒"
	@echo ""

## docker-prune: 清理未使用的 Docker 资源
docker-prune:
	@echo "==> 清理未使用的 Docker 资源..."
	docker system prune -f
	@echo "✓ 清理完成"

## docker-backup: 备份数据库
docker-backup:
	@echo "==> 备份数据库..."
	@mkdir -p backups
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	docker run --rm \
		-v top-ai-news_app-data:/data \
		-v $(PWD)/backups:/backup \
		alpine cp /data/data.db /backup/data.db.$$TIMESTAMP && \
	echo "✓ 备份完成: backups/data.db.$$TIMESTAMP" || \
	echo "✗ 备份失败"

## docker-restore: 从备份恢复数据库
docker-restore:
	@echo "==> 可用的备份文件:"
	@ls -1 backups/data.db.* 2>/dev/null || echo "  无备份文件"
	@echo ""
	@read -p "请输入要恢复的备份文件名（例如: data.db.20260216_103000）: " BACKUP_FILE; \
	if [ -f "backups/$$BACKUP_FILE" ]; then \
		echo "==> 停止服务..."; \
		docker compose stop app; \
		echo "==> 恢复数据库..."; \
		docker run --rm \
			-v top-ai-news_app-data:/data \
			-v $(PWD)/backups:/backup \
			alpine cp /backup/$$BACKUP_FILE /data/data.db; \
		echo "==> 启动服务..."; \
		docker compose up -d app; \
		echo "✓ 恢复完成"; \
	else \
		echo "✗ 错误: 文件不存在"; \
	fi

## docker-health: 检查服务健康状态
docker-health:
	@echo "==> 检查服务健康状态..."
	@curl -f http://localhost/ >/dev/null 2>&1 && echo "✓ 服务正常运行" || echo "✗ 服务未响应"

## docker-nginx-reload: 重载 nginx 配置（不中断服务）
docker-nginx-reload:
	@echo "==> 重载 nginx 配置..."
	docker compose exec nginx nginx -s reload
	@echo "✓ nginx 配置已重载"

## docker-nginx-test: 测试 nginx 配置语法
docker-nginx-test:
	@echo "==> 测试 nginx 配置..."
	docker compose exec nginx nginx -t

## setup-local-domain: 显示本地域名配置说明
setup-local-domain:
	@echo "==> 配置本地域名 local.yeanhua.asia"
	@echo ""
	@echo "如果你想使用域名访问本地服务，请手动添加以下配置："
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Mac/Linux 用户："
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  sudo vim /etc/hosts"
	@echo ""
	@echo "添加以下行："
	@echo "  127.0.0.1 local.yeanhua.asia"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Windows 用户："
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  notepad C:\\Windows\\System32\\drivers\\etc\\hosts"
	@echo ""
	@echo "添加以下行："
	@echo "  127.0.0.1 local.yeanhua.asia"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "配置完成后，可以通过以下地址访问："
	@echo "  http://local.yeanhua.asia"
	@echo "  http://localhost  （无需配置也可用）"
	@echo ""
	@echo "运行 'make check-local-domain' 检查配置是否生效"

## check-local-domain: 检查本地域名配置
check-local-domain:
	@echo "==> 检查本地域名配置..."
	@echo ""
	@if grep -q "local.yeanhua.asia" /etc/hosts 2>/dev/null; then \
		echo "✓ /etc/hosts 已配置 local.yeanhua.asia"; \
		echo "  配置内容: $$(grep 'local.yeanhua.asia' /etc/hosts)"; \
	else \
		echo "✗ /etc/hosts 未配置 local.yeanhua.asia"; \
		echo ""; \
		echo "提示: 运行 'make setup-local-domain' 查看配置说明"; \
	fi
	@echo ""
	@echo "==> 测试域名解析..."
	@if ping -c 1 -W 1 local.yeanhua.asia >/dev/null 2>&1; then \
		echo "✓ local.yeanhua.asia 解析正常 → 127.0.0.1"; \
	else \
		echo "✗ local.yeanhua.asia 解析失败"; \
	fi
	@echo ""
	@echo "==> 当前可用的访问地址:"
	@if docker compose ps | grep -q "Up"; then \
		echo "  ✓ http://localhost"; \
		if ping -c 1 -W 1 local.yeanhua.asia >/dev/null 2>&1; then \
			echo "  ✓ http://local.yeanhua.asia"; \
		else \
			echo "  ✗ http://local.yeanhua.asia (需要先配置 hosts)"; \
		fi \
	else \
		echo "  ✗ 服务未启动，请先运行 'make docker-up'"; \
	fi

# ====================================
# HTTPS Certificate Management
# ====================================

## cert-check: 检查 HTTPS 证书状态
cert-check:
	@./scripts/cert-manager.sh check

## cert-generate: 生成 HTTPS 证书（Let's Encrypt HTTP-01，单域名）
cert-generate:
	@./scripts/cert-manager.sh generate letsencrypt

## cert-generate-mkcert: 生成本地开发证书（使用 mkcert）
cert-generate-mkcert:
	@./scripts/cert-manager.sh generate mkcert

## cert-generate-dns: 生成泛域名证书（Let's Encrypt DNS-01，需 DNS API）
cert-generate-dns:
	@./scripts/cert-manager.sh generate letsencrypt-dns

## cert-info: 显示证书详细信息
cert-info:
	@./scripts/cert-manager.sh info

## cert-renew: 续期证书
cert-renew:
	@./scripts/cert-manager.sh renew

## cert-clean: 删除证书
cert-clean:
	@./scripts/cert-manager.sh clean

## cert-setup-dns: 配置 DNS API 凭证
cert-setup-dns:
	@echo "==> 配置 DNS API 凭证"
	@echo ""
	@echo "创建 DNS API 配置文件用于 Let's Encrypt DNS-01 验证"
	@echo ""
	@mkdir -p ~/.secrets
	@if [ -f ~/.secrets/dns-credentials.ini ]; then \
		echo "⚠️  配置文件已存在: ~/.secrets/dns-credentials.ini"; \
		echo ""; \
		read -p "是否覆盖？[y/N] " -n 1 -r; \
		echo; \
		if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
			echo "已取消"; \
			exit 0; \
		fi; \
	fi
	@printf '%s\n' \
		'# Let's Encrypt DNS API 配置' \
		'# 用于 DNS-01 验证以获取泛域名证书（*.yeanhua.asia）' \
		'' \
		'# ==========================================' \
		'# 阿里云 DNS API（推荐）' \
		'# ==========================================' \
		'# 获取 Access Key: https://ram.console.aliyun.com/manage/ak' \
		'dns_aliyun_access_key = YOUR_ALIYUN_ACCESS_KEY_ID' \
		'dns_aliyun_access_key_secret = YOUR_ALIYUN_ACCESS_KEY_SECRET' \
		'' \
		'# ==========================================' \
		'# Cloudflare API Token（备选）' \
		'# ==========================================' \
		'# 获取 Token: https://dash.cloudflare.com/profile/api-tokens' \
		'# dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN' \
		'' \
		'# ==========================================' \
		'# DNSPod API（备选）' \
		'# ==========================================' \
		'# 获取 API: https://console.dnspod.cn/account/token' \
		'# dns_dnspod_api_id = YOUR_DNSPOD_API_ID' \
		'# dns_dnspod_api_token = YOUR_DNSPOD_API_TOKEN' \
		> ~/.secrets/dns-credentials.ini
	@chmod 600 ~/.secrets/dns-credentials.ini
	@echo "✓ 配置文件已创建: ~/.secrets/dns-credentials.ini"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "下一步操作："
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "1. 编辑配置文件，填入真实的 API 凭证："
	@echo "   vim ~/.secrets/dns-credentials.ini"
	@echo ""
	@echo "2. 安装对应的 DNS 插件："
	@echo "   阿里云: pip3 install certbot-dns-aliyun"
	@echo "   Cloudflare: pip3 install certbot-dns-cloudflare"
	@echo "   DNSPod: pip3 install certbot-dns-dnspod"
	@echo ""
	@echo "3. 生成证书："
	@echo "   make cert-generate"
	@echo ""
