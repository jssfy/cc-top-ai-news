# Top AI News

RSS-based AI news aggregator with real-time feeds.

---

## 🚀 快速开始

### 本地开发

**HTTP 开发**:
```bash
# 构建并启动服务
docker build -t news:latest .
docker-compose up -d

# 访问服务
open http://localhost:8080
```

**HTTPS 开发(使用 https-toolkit)**:
```bash
# 安装 https-toolkit
git clone https://github.com/yourusername/https-toolkit.git
cd https-toolkit
make install

# 返回项目目录,启动 HTTPS 服务
cd /path/to/top-ai-news
https-deploy --dev

# 访问服务
open https://local.yeanhua.asia/news
```

详见: [https-toolkit 文档](https://github.com/yourusername/https-toolkit)

### 生产环境部署

```bash
# 构建镜像
docker build -t news:latest .

# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps
docker-compose logs -f
```

**HTTPS 配置**: 使用 [https-toolkit](https://github.com/yourusername/https-toolkit) 或自行配置 nginx/caddy 反向代理

---

## 📚 文档

完整文档请查看 [docs/](docs/) 目录。

### 快速导航

**部署指南**：
- [Docker Compose 配置说明](docs/docker-compose-configuration-2026-02-18.md) - ⭐ **配置文件详解**
- [部署指南](docs/deployment-guide-2026-02-16.md) - 深入了解架构

**HTTPS 配置**：
- ⭐ [https-toolkit](https://github.com/yourusername/https-toolkit) - 独立 HTTPS 工具(推荐)
- [HTTPS 文件清理记录](docs/cleanup-https-files-2026-02-18.md) - 架构演进

**索引**：
- [文档总索引](docs/README.md) - 查看所有文档

**注**: HTTPS 相关文档已迁移至 [https-toolkit/docs/archive](../https-toolkit/docs/archive/)

---

## 🛠️ 常用命令

```bash
# 🚀 Docker 服务管理
docker build -t news:latest .      # 构建镜像
docker-compose up -d                # 启动服务
docker-compose down                 # 停止服务
docker-compose restart              # 重启服务
docker-compose ps                   # 查看状态
docker-compose logs -f              # 查看日志

# 📊 健康检查
curl http://localhost:8080/health   # 检查服务状态
docker ps                           # 查看容器健康状态

# 🔒 HTTPS 配置
# 使用 https-toolkit (推荐)
https-deploy --dev                  # 本地 HTTPS 开发
# 详见: https://github.com/yourusername/https-toolkit
```

---

## 🌐 访问地址

### 本地开发

- **HTTP**: `http://localhost:8080`
- **HTTPS**: 使用 [https-toolkit](https://github.com/yourusername/https-toolkit) - `https://local.yeanhua.asia/news`

### 生产环境

- 根据部署配置自行设置域名和 HTTPS

---

## 📖 项目结构

```
top-ai-news/
├── main.go                 # 主程序 (Go Web 服务)
├── Dockerfile              # 容器镜像构建
├── docker-compose.yml      # Docker 服务编排
├── web/                    # 前端静态资源
│   ├── index.html
│   ├── app.js
│   └── style.css
├── internal/               # 内部包
│   ├── database/           # 数据库层
│   ├── fetcher/            # RSS 抓取
│   └── handler/            # HTTP 处理器
├── docs/                   # 📚 文档
│   ├── README.md
│   ├── docker-compose-configuration-2026-02-18.md
│   └── ...
└── .gitignore
```

---

## ❓ 常见问题

### Q1: 如何部署到生产服务器?

```bash
# 1. 构建镜像
docker build -t news:latest .

# 2. 启动服务
docker-compose up -d

# 3. 查看状态
docker-compose ps
docker-compose logs -f
```

**HTTPS 配置**: 使用 [https-toolkit](https://github.com/yourusername/https-toolkit) 或自行配置反向代理

### Q2: 如何更新代码?

```bash
# 1. 拉取最新代码
git pull

# 2. 重新构建镜像
docker build -t news:latest . --no-cache

# 3. 重启服务
docker-compose down
docker-compose up -d
```

### Q3: docker-compose.yml 和自动生成的配置有什么区别?

**详细说明**: [Docker Compose 配置说明](docs/docker-compose-configuration-2026-02-18.md)

**简要对比**:

| 配置文件 | 用途 | 特点 |
|---------|-----|------|
| `docker-compose.yml` | 生产/独立运行 | 数据持久化、灵活镜像 |
| `.https-toolkit/output/docker-compose-local.yml` | 本地 HTTPS 开发 | 自动生成、临时文件 |

### Q4: 如何配置本地 HTTPS?

使用 [https-toolkit](https://github.com/yourusername/https-toolkit):

```bash
# 安装工具
make install

# 启动 HTTPS 开发环境
cd /path/to/top-ai-news
https-deploy --dev

# 访问
open https://local.yeanhua.asia/news
```

### Q5: 数据存储在哪里?

```bash
# 查看数据卷
docker volume ls

# 数据持久化在 app-data 卷中
docker volume inspect top-ai-news_app-data

# 备份数据
docker run --rm -v top-ai-news_app-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz /data
```

### Q6: 健康检查端点是什么?

服务提供 `/health` 端点用于健康检查:

```bash
# 检查服务状态
curl http://localhost:8080/health
# 输出: OK

# Docker 健康状态
docker ps
# 查看 STATUS 列的健康状态
```

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📝 License

MIT
