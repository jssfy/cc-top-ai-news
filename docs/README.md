# 文档索引

本目录包含 Top AI News 项目的技术文档。

> **注意**: HTTPS 和证书相关文档已迁移至 [https-toolkit/docs/archive](../../https-toolkit/docs/archive/)

---

## 📚 快速导航

### 部署与配置

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [docker-compose-configuration-2026-02-18.md](docker-compose-configuration-2026-02-18.md) | Docker Compose 配置说明 | **⭐ 配置文件详解** |
| [deployment-guide-2026-02-16.md](deployment-guide-2026-02-16.md) | 完整部署指南 | 详细了解部署架构 |
| [cicd-ali-ecs-deployment-2026-02-15.md](cicd-ali-ecs-deployment-2026-02-15.md) | CI/CD 自动化部署 | GitHub Actions 配置 |

### 架构与重构

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [rss-news-fetcher-refactor-2026-02-15.md](rss-news-fetcher-refactor-2026-02-15.md) | RSS 抓取架构重构 | 了解核心功能实现 |
| [cleanup-https-files-2026-02-18.md](cleanup-https-files-2026-02-18.md) | HTTPS 文件清理记录 | 架构演进历史 |

### 历史文档(已过时)

以下文档已不适用于当前架构(HTTPS 功能已独立为 https-toolkit):

- ~~quick-reference-2026-02-16.md~~ (包含已删除的证书命令)
- ~~deploy-quickstart-2026-02-16.md~~ (包含已删除的部署方式)
- ~~local-dev-guide-2026-02-16.md~~ (使用已删除的 make docker-dev)
- ~~makefile-usage-2026-02-16.md~~ (包含已删除的证书命令)
- ~~docker-commands-comparison-2026-02-16.md~~ (对比已删除的命令)

**HTTPS 相关文档**: 已迁移至 [https-toolkit/docs/archive](../../https-toolkit/docs/archive/)

---

## 🚀 推荐阅读路径

### 新手入门

1. 查看项目 [README.md](../README.md) - 快速开始
2. [docker-compose-configuration-2026-02-18.md](docker-compose-configuration-2026-02-18.md) - 理解配置
3. [deployment-guide-2026-02-16.md](deployment-guide-2026-02-16.md) - 深入了解部署

### HTTPS 配置

使用 [https-toolkit](https://github.com/yourusername/https-toolkit) - 独立 HTTPS 工具

### 深入了解

1. [rss-news-fetcher-refactor-2026-02-15.md](rss-news-fetcher-refactor-2026-02-15.md) - 核心功能实现
2. [cleanup-https-files-2026-02-18.md](cleanup-https-files-2026-02-18.md) - 架构演进历史

---

## 🔍 快速查找

### 我想...

- **理解 Docker 配置** → [docker-compose-configuration-2026-02-18.md](docker-compose-configuration-2026-02-18.md) ⭐
- **了解完整部署** → [deployment-guide-2026-02-16.md](deployment-guide-2026-02-16.md)
- **配置 HTTPS** → [https-toolkit](https://github.com/yourusername/https-toolkit)
- **设置自动部署** → [cicd-ali-ecs-deployment-2026-02-15.md](cicd-ali-ecs-deployment-2026-02-15.md)
- **了解 RSS 实现** → [rss-news-fetcher-refactor-2026-02-15.md](rss-news-fetcher-refactor-2026-02-15.md)
- **查看架构演进** → [cleanup-https-files-2026-02-18.md](cleanup-https-files-2026-02-18.md)

---

## 📊 文档统计

- **当前文档数**: 5 篇
- **部署配置**: 2 篇
- **架构演进**: 2 篇
- **CI/CD**: 1 篇
- **已迁移文档**: 15 篇 (至 https-toolkit/docs/archive)
- **最新更新**: 2026-02-18

---

## 📝 文档命名规范

所有文档遵循以下命名格式:

```
{主题}-{yyyy-mm-dd}.md
```

**示例**:
- ✅ `docker-compose-configuration-2026-02-18.md`
- ✅ `deployment-guide-2026-02-16.md`

**规则**:
- 主题使用英文小写
- 单词之间用连字符 `-` 分隔
- 日期格式: `yyyy-mm-dd`
- 文件扩展名: `.md`

---

## ✏️ 贡献指南

### 创建新文档

1. 使用规范的命名格式: `{主题}-{yyyy-mm-dd}.md`
2. 文档必须包含"核心结论"章节(放在开头)
3. 使用 Markdown 格式
4. 放置在 `docs/` 目录下
5. 更新本 README.md 索引

### 文档结构规范

```markdown
# 文档标题

## 核心结论

✅ 核心发现和可操作建议

## 详细内容

...

## 相关文档

- 链接
```

---

## 📮 反馈与建议

如有文档问题或改进建议,请:
1. 提交 GitHub Issue
2. 创建 Pull Request
3. 联系项目维护者

---

## 🔗 相关链接

- [项目主页](../README.md)
- [https-toolkit](https://github.com/yourusername/https-toolkit) - HTTPS 工具
- [HTTPS 文档归档](../../https-toolkit/docs/archive/) - 历史文档
