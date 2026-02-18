# Docker Compose 配置说明

## 核心结论

✅ **根目录的 `docker-compose.yml` 仍然需要**,但用途与自动生成的配置文件不同:

- **项目配置** (`docker-compose.yml`): 用于生产环境部署或独立运行
- **临时配置** (`.https-toolkit/output/docker-compose-local.yml`): https-toolkit 自动生成,用于本地 HTTPS 开发

## 配置文件对比

### 1. `/Users/yeanhua/workspace/playground/claude/top-ai-news/docker-compose.yml`

**用途**: 生产环境部署,或不使用 https-toolkit 时的独立运行

**特点**:
- ✅ 支持通过 `DOCKER_IMAGE` 环境变量指定镜像版本
- ✅ 包含 `app-data` 卷,持久化应用数据
- ✅ 统一命名: `news` 服务/容器/镜像
- ✅ 使用 `expose` 而非 `ports`,更安全(只在内部网络暴露)
- ✅ 配置健康检查,支持容器监控
- ✅ 时区设置 `TZ=Asia/Shanghai`

**配置示例**:
```yaml
services:
  news:
    image: ${DOCKER_IMAGE:-news:latest}
    container_name: news
    restart: unless-stopped
    expose:
      - "8080"
    volumes:
      - app-data:/app/data
    environment:
      - TZ=Asia/Shanghai
    networks:
      - https-toolkit-network
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  https-toolkit-network:
    external: true

volumes:
  app-data:
```

### 2. `.https-toolkit/output/docker-compose-local.yml`

**用途**: https-toolkit 自动生成,用于本地 HTTPS 开发

**特点**:
- ✅ 包含 build context,支持本地构建
- ✅ 自动配置 HTTPS 网络
- ⚠️  **临时文件**,每次 `https-deploy --dev` 都会重新生成
- ⚠️  不包含数据持久化卷(自动生成时未考虑)

**配置示例**:
```yaml
services:
  news:
    image: news:latest
    container_name: news
    build:
      context: /Users/yeanhua/workspace/playground/claude/top-ai-news
      dockerfile: Dockerfile
    networks:
      - https-toolkit-network
    environment:
      - TZ=Asia/Shanghai
      - PORT=8080
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-qO", "/dev/null", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  https-toolkit-network:
    external: true
```

## 使用方式

### 方式 1: 独立运行(生产/测试)

```bash
cd /Users/yeanhua/workspace/playground/claude/top-ai-news

# 构建镜像
docker build -t news:latest .

# 启动服务(使用项目配置)
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

**访问地址**: `http://localhost:8080` (仅 HTTP,无 HTTPS)

### 方式 2: 使用 https-toolkit(本地 HTTPS 开发)

```bash
cd /Users/yeanhua/workspace/playground/claude/top-ai-news

# 方式 A: 使用 https-deploy 命令(推荐)
https-deploy --dev

# 方式 B: 使用自动生成的配置
cd .https-toolkit/output
docker-compose -f docker-compose-local.yml up -d
```

**访问地址**: `https://local.yeanhua.asia/news` (带 HTTPS + 路径前缀)

## 关键配置说明

### 网络配置

```yaml
networks:
  https-toolkit-network:
    external: true
```

**说明**:
- `external: true` 表示网络由外部管理(https-toolkit 创建)
- 确保服务能与 HTTPS 网关通信
- 如果独立运行且没有 https-toolkit,需要手动创建网络:
  ```bash
  docker network create https-toolkit-network
  ```

### 数据持久化

```yaml
volumes:
  - app-data:/app/data

volumes:
  app-data:
```

**说明**:
- `app-data` 卷用于持久化应用数据(数据库、日志等)
- 容器删除后数据仍然保留
- 查看卷: `docker volume ls`
- 备份数据: `docker run --rm -v app-data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data`

### 端口暴露方式

**expose vs ports**:

```yaml
# 方式 1: expose (推荐,更安全)
expose:
  - "8080"

# 方式 2: ports (不推荐,暴露到宿主机)
ports:
  - "8080:8080"
```

**区别**:
- `expose`: 只在 Docker 网络内可见,外部无法直接访问
- `ports`: 映射到宿主机,外部可直接访问

**为什么使用 expose**:
- ✅ 更安全,减少攻击面
- ✅ 由 HTTPS 网关统一管理入口
- ✅ 支持多服务部署而不冲突

### 健康检查

```yaml
healthcheck:
  test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
  interval: 30s
  timeout: 5s
  retries: 3
```

**说明**:
- 每 30 秒检查一次 `/health` 端点
- 超时 5 秒视为失败
- 连续失败 3 次后标记为 unhealthy
- 查看健康状态: `docker ps` (STATUS 列显示健康状态)

## 环境变量

### DOCKER_IMAGE

```bash
# 使用默认镜像
docker-compose up -d

# 使用指定镜像
DOCKER_IMAGE=news:v1.0.0 docker-compose up -d

# 使用 Harbor 镜像
DOCKER_IMAGE=harbor.example.com/project/news:latest docker-compose up -d
```

### TZ (时区)

```yaml
environment:
  - TZ=Asia/Shanghai
```

**说明**:
- 设置容器时区为上海(UTC+8)
- 影响日志时间戳、定时任务等
- 其他常用时区: `UTC`, `America/New_York`, `Europe/London`

## 常见问题

### Q1: 为什么需要两个 docker-compose 配置?

**A**: 因为使用场景不同:

| 场景 | 使用配置 | 特点 |
|-----|---------|-----|
| 生产部署 | `docker-compose.yml` | 数据持久化、灵活镜像版本 |
| 独立测试 | `docker-compose.yml` | HTTP 访问、无需 HTTPS |
| 本地 HTTPS 开发 | `.https-toolkit/output/docker-compose-local.yml` | 自动 HTTPS、路径前缀 |

### Q2: 为什么自动生成的配置没有数据持久化?

**A**: https-toolkit 自动生成配置时只处理基本的网络和运行配置,不了解每个应用的数据存储需求。因此:

- ✅ **生产环境**: 使用 `docker-compose.yml`,包含数据持久化
- ⚠️ **开发环境**: 使用自动生成配置,数据可能丢失(容器删除后)

### Q3: 如何在自动生成的配置中添加数据持久化?

**A**: 不推荐修改自动生成的文件(会被覆盖)。推荐方式:

```bash
# 方式 1: 修改项目配置后使用 https-deploy
# 编辑 docker-compose.yml 添加卷配置
https-deploy --dev --compose docker-compose.yml

# 方式 2: 独立运行,手动配置 HTTPS
docker-compose up -d
# 然后配置 nginx 反向代理
```

### Q4: 网络 https-toolkit-network 不存在怎么办?

**A**: 手动创建网络:

```bash
docker network create https-toolkit-network
```

或使用 https-toolkit 初始化:

```bash
https-deploy --init
```

### Q5: 如何切换镜像版本?

**A**: 使用环境变量:

```bash
# 构建新版本
docker build -t news:v2.0.0 .

# 使用新版本启动
DOCKER_IMAGE=news:v2.0.0 docker-compose up -d

# 或永久设置(.env 文件)
echo "DOCKER_IMAGE=news:v2.0.0" > .env
docker-compose up -d
```

## 架构演进

### 之前(集成 HTTPS)

```yaml
services:
  app:           # 应用服务
  nginx:         # HTTPS 反向代理
  certbot:       # 证书管理
```

**问题**:
- 每个项目都要配置 nginx/certbot
- 证书管理重复
- 配置复杂

### 现在(独立工具)

```yaml
# 应用项目
services:
  news:          # 只关注业务逻辑

# https-toolkit (独立工具)
services:
  gateway:       # 统一 HTTPS 网关
  certbot:       # 统一证书管理
```

**优势**:
- ✅ 关注点分离
- ✅ 配置简化
- ✅ 统一 HTTPS 管理
- ✅ 支持多项目

## 相关文档

- [HTTPS Toolkit 使用指南](../../https-toolkit/README.md)
- [HTTPS 文件清理记录](cleanup-https-files-2026-02-18.md)
- [本地开发指南](local-dev-guide-2026-02-16.md)
- [部署指南](deployment-guide-2026-02-16.md)
