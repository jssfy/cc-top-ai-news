# top-ai-news 项目 HTTPS 文件清理记录

**清理日期**: 2026-02-18
**原因**: 统一由外置 `https-toolkit` 工具处理 HTTPS 和证书相关功能

## 核心结论

✅ **清理完成**

- 移除所有 HTTPS、证书和网关相关的配置文件
- 项目回归为纯应用代码
- HTTPS 功能统一由 `https-toolkit` 提供

---

## 已删除的文件

### 1. 部署配置 ✓

```
deploy/
├── init-ssl.sh              # SSL 证书申请脚本
├── setup-ecs.sh             # ECS 服务器初始化
└── nginx/
    └── conf.d/
        └── default-https.conf  # Nginx HTTPS 配置
```

**说明**:
- `init-ssl.sh`: Let's Encrypt 证书自动申请脚本
- `setup-ecs.sh`: 阿里云 ECS 服务器环境初始化
- `nginx/`: Nginx HTTPS 配置模板

### 2. Docker Compose 配置 ✓

```
- docker-compose.https.yml      # HTTPS 部署配置
- docker-compose.gateway.yml    # 网关测试配置
```

**保留**:
```
docker-compose.yml              # 基础应用部署配置
```

### 3. 网关配置 ✓

```
- config.yaml                   # https-toolkit 项目配置
```

### 4. 证书管理脚本 ✓

```
scripts/
└── cert-manager.sh             # 证书管理和续期脚本
```

**说明**: scripts 目录已清空并删除

### 5. 临时文件 ✓

```
.https-toolkit/                 # 临时生成目录
└── output/
    └── docker-compose-local.yml
```

---

## 文档处理

### HTTPS 相关文档 (待处理)

以下文档记录了 HTTPS 功能的设计和实现过程,可选择:
- **保留**: 作为项目历史记录
- **移动**: 迁移到 `https-toolkit` 项目
- **删除**: 不再需要

```
docs/
├── https-deploy-internals-2026-02-17.md
├── https-deploy-execution-flow-2026-02-17.md
├── https-toolkit-usage-guide-2026-02-16.md
├── https-path-based-gateway-design-2026-02-17.md
├── https-gateway-test-results-2026-02-17.md
├── https-feature-summary-2026-02-16.md
├── https-generalization-plan-2026-02-16.md
├── certificate-comparison-2026-02-16.md
├── local-https-setup-2026-02-16.md
├── why-mkcert-for-local-2026-02-16.md
├── cert-generation-location-2026-02-16.md
├── ssl-certificate-setup-2026-02-16.md
├── cert-default-letsencrypt-2026-02-16.md
└── docs-update-https-2026-02-16.md
```

**建议**: 这些文档主要记录 `https-toolkit` 的设计过程,建议移动到 https-toolkit 项目的 `docs/archive/` 目录作为历史记录。

---

## 现在的项目结构

### top-ai-news (纯应用)

```
top-ai-news/
├── cmd/
│   └── server/
│       └── main.go           # 应用主程序
├── internal/                 # 应用业务逻辑
├── static/                   # 静态文件
├── data/                     # 数据存储
├── docker-compose.yml        # 基础部署配置
├── Dockerfile               # 应用镜像构建
└── docs/                    # 文档
    └── (保留应用相关文档)
```

### https-toolkit (独立工具)

```
https-toolkit/
├── bin/
│   └── https-deploy         # CLI 工具
├── lib/                     # 功能库
├── Makefile                 # 管理命令
└── docs/                    # 工具文档
```

---

## 使用方式变化

### 之前 (项目内置 HTTPS)

```bash
cd top-ai-news

# 初始化 SSL
./deploy/init-ssl.sh domain.com email@example.com

# 部署
docker compose -f docker-compose.https.yml up -d
```

### 现在 (使用 https-toolkit)

```bash
# 1. 启动应用 (HTTP only)
cd top-ai-news
docker compose up -d

# 2. 使用 https-toolkit 提供 HTTPS
cd /path/to/https-toolkit
~/.https-toolkit/bin/https-deploy init
~/.https-toolkit/bin/https-deploy up

# 访问
open https://localhost/news/
```

---

## 优势

### 1. 职责清晰 ✅

- **top-ai-news**: 专注于 AI 新闻聚合业务逻辑
- **https-toolkit**: 专注于 HTTPS 网关和证书管理

### 2. 代码复用 ✅

- https-toolkit 可被多个项目共享
- 减少重复代码和配置

### 3. 独立演进 ✅

- 两个项目可以独立更新和发布
- 互不影响

### 4. 简化部署 ✅

- 应用部署更简单 (只需关注业务)
- HTTPS 配置统一管理

---

## 迁移建议

### 对于新项目

```bash
# 1. 开发应用 (只关注业务逻辑)
cd my-new-app
# 编写代码...

# 2. 使用 https-toolkit 提供 HTTPS
~/.https-toolkit/bin/https-deploy init
~/.https-toolkit/bin/https-deploy up
```

### 对于现有项目

如果项目还在使用旧的 HTTPS 配置:

```bash
# 1. 备份现有证书 (如果有)
cp -r /etc/letsencrypt ~/letsencrypt-backup

# 2. 清理旧配置
rm -rf deploy/ docker-compose.https.yml

# 3. 使用 https-toolkit
~/.https-toolkit/bin/https-deploy init
~/.https-toolkit/bin/https-deploy up
```

---

## .gitignore 更新

已添加忽略规则:

```gitignore
# HTTPS Toolkit temporary files
.https-toolkit/
```

---

## 相关文档

- [https-toolkit 迁移记录](../../https-toolkit/MIGRATION-2026-02-18.md)
- [https-toolkit README](../../https-toolkit/README.md)
- [https-toolkit 快速开始](../../https-toolkit/QUICK_START.md)

---

## 总结

✅ **清理完成,项目结构更清晰**

**删除文件统计**:
- 部署脚本: 2 个 (`init-ssl.sh`, `setup-ecs.sh`)
- Docker Compose: 2 个 (`docker-compose.https.yml`, `docker-compose.gateway.yml`)
- 配置文件: 1 个 (`config.yaml`)
- 证书脚本: 1 个 (`cert-manager.sh`)
- 目录: 2 个 (`deploy/`, `scripts/`)

**保留**:
- `docker-compose.yml` - 基础应用部署配置
- `Dockerfile` - 应用镜像构建
- 应用核心代码

**现在 top-ai-news 是一个纯粹的应用项目,所有 HTTPS 功能由 `https-toolkit` 统一提供!** 🎉
