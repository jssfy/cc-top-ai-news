# 文档索引

本目录包含 Top AI News 项目的所有技术文档。

---

## 📚 快速导航

### 部署相关

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [quick-reference-2026-02-16.md](quick-reference-2026-02-16.md) | 快速参考 | **⭐ 常用命令速查** |
| [deploy-quickstart-2026-02-16.md](deploy-quickstart-2026-02-16.md) | 5 分钟快速上手 | **首次部署必读** |
| [code-update-guide-2026-02-16.md](code-update-guide-2026-02-16.md) | 代码更新部署指南 | **如何更新代码** |
| [single-domain-deployment-2026-02-16.md](single-domain-deployment-2026-02-16.md) | 单域名生产部署 | **data.yeanhua.asia** |
| [cert-generation-location-2026-02-16.md](cert-generation-location-2026-02-16.md) | 证书生成运行位置 | **HTTP-01 vs DNS-01 运行要求** |
| [deployment-guide-2026-02-16.md](deployment-guide-2026-02-16.md) | 完整部署指南 | 详细了解部署架构 |
| [ssl-certificate-setup-2026-02-16.md](ssl-certificate-setup-2026-02-16.md) | SSL 证书配置 | HTTPS 配置指南 |
| [cicd-ali-ecs-deployment-2026-02-15.md](cicd-ali-ecs-deployment-2026-02-15.md) | CI/CD 自动化部署 | GitHub Actions 配置 |

### 开发工具

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [local-dev-guide-2026-02-16.md](local-dev-guide-2026-02-16.md) | 本地开发指南 | **⭐ 一键启动开发环境** |
| [docker-commands-comparison-2026-02-16.md](docker-commands-comparison-2026-02-16.md) | Docker 命令对比 | **dev vs up-https** |
| [makefile-usage-2026-02-16.md](makefile-usage-2026-02-16.md) | Makefile 使用指南 | **本地开发必读** |
| [makefile-integration-2026-02-16.md](makefile-integration-2026-02-16.md) | Makefile 集成总结 | 了解设计思路 |
| [local-domain-setup-2026-02-16.md](local-domain-setup-2026-02-16.md) | 本地域名配置 | 使用本地域名开发 |
| [local-https-setup-2026-02-16.md](local-https-setup-2026-02-16.md) | 本地 HTTPS 配置 | **HTTPS 开发环境** |
| [letsencrypt-setup-2026-02-16.md](letsencrypt-setup-2026-02-16.md) | Let's Encrypt 配置 | **生产环境证书** |
| [cert-generation-location-2026-02-16.md](cert-generation-location-2026-02-16.md) | 证书生成运行位置 | **在哪运行命令** |
| [cert-default-letsencrypt-2026-02-16.md](cert-default-letsencrypt-2026-02-16.md) | 默认改用 Let's Encrypt | **重要变更说明** |
| [https-feature-summary-2026-02-16.md](https-feature-summary-2026-02-16.md) | HTTPS 功能总结 | 了解 HTTPS 实现 |
| [certificate-comparison-2026-02-16.md](certificate-comparison-2026-02-16.md) | 证书方案对比 | mkcert vs Let's Encrypt |
| [why-mkcert-for-local-2026-02-16.md](why-mkcert-for-local-2026-02-16.md) | 为何本地用 mkcert | 理解本地证书选型 |
| [http01-implementation-2026-02-16.md](http01-implementation-2026-02-16.md) | HTTP-01 实现说明 | 技术实现细节 |

### 架构与重构

| 文档 | 说明 | 适用场景 |
|------|------|----------|
| [rss-news-fetcher-refactor-2026-02-15.md](rss-news-fetcher-refactor-2026-02-15.md) | RSS 抓取架构重构 | 了解核心功能实现 |

---

## 🚀 推荐阅读路径

### 新手入门

1. [deploy-quickstart-2026-02-16.md](deploy-quickstart-2026-02-16.md) - 快速启动项目
2. [makefile-usage-2026-02-16.md](makefile-usage-2026-02-16.md) - 学习常用命令
3. [local-domain-setup-2026-02-16.md](local-domain-setup-2026-02-16.md) - 配置本地域名
4. [local-https-setup-2026-02-16.md](local-https-setup-2026-02-16.md) - 配置 HTTPS（可选）

### 生产部署

1. [deployment-guide-2026-02-16.md](deployment-guide-2026-02-16.md) - 了解完整部署流程
2. [ssl-certificate-setup-2026-02-16.md](ssl-certificate-setup-2026-02-16.md) - 配置 HTTPS
3. [cicd-ali-ecs-deployment-2026-02-15.md](cicd-ali-ecs-deployment-2026-02-15.md) - 配置自动化部署

### 深入了解

1. [rss-news-fetcher-refactor-2026-02-15.md](rss-news-fetcher-refactor-2026-02-15.md) - 核心功能实现
2. [makefile-integration-2026-02-16.md](makefile-integration-2026-02-16.md) - 工具链设计

---

## 📝 文档命名规范

所有文档遵循以下命名格式：

```
{主题}-{yyyy-mm-dd}.md
```

**示例**：
- ✅ `deployment-guide-2026-02-16.md`
- ✅ `ssl-certificate-setup-2026-02-16.md`
- ✅ `makefile-usage-2026-02-16.md`

**规则**：
- 主题使用英文小写
- 单词之间用连字符 `-` 分隔
- 日期格式：`yyyy-mm-dd`
- 文件扩展名：`.md`

---

## 📂 文档分类

### 按日期查看

**2026-02-16**（本次更新）：
- deployment-guide-2026-02-16.md
- deploy-quickstart-2026-02-16.md
- ssl-certificate-setup-2026-02-16.md
- letsencrypt-setup-2026-02-16.md
- cert-default-letsencrypt-2026-02-16.md
- makefile-usage-2026-02-16.md
- makefile-integration-2026-02-16.md
- local-domain-setup-2026-02-16.md
- local-https-setup-2026-02-16.md
- https-feature-summary-2026-02-16.md
- certificate-comparison-2026-02-16.md
- why-mkcert-for-local-2026-02-16.md

**2026-02-15**（历史文档）：
- cicd-ali-ecs-deployment-2026-02-15.md
- rss-news-fetcher-refactor-2026-02-15.md

### 按主题查看

**部署（Deployment）**：
- deployment-guide-2026-02-16.md
- deploy-quickstart-2026-02-16.md
- cicd-ali-ecs-deployment-2026-02-15.md

**安全（Security）**：
- ssl-certificate-setup-2026-02-16.md

**开发工具（Development Tools）**：
- makefile-usage-2026-02-16.md
- makefile-integration-2026-02-16.md
- local-domain-setup-2026-02-16.md
- local-https-setup-2026-02-16.md
- letsencrypt-setup-2026-02-16.md
- cert-default-letsencrypt-2026-02-16.md
- https-feature-summary-2026-02-16.md
- certificate-comparison-2026-02-16.md
- why-mkcert-for-local-2026-02-16.md

**架构（Architecture）**：
- rss-news-fetcher-refactor-2026-02-15.md

---

## 🔍 快速查找

### 我想...

- **快速参考** → [quick-reference-2026-02-16.md](quick-reference-2026-02-16.md) ⭐
- **本地开发** → [local-dev-guide-2026-02-16.md](local-dev-guide-2026-02-16.md) ⭐
- **命令对比** → [docker-commands-comparison-2026-02-16.md](docker-commands-comparison-2026-02-16.md)
- **启动项目** → [deploy-quickstart-2026-02-16.md](deploy-quickstart-2026-02-16.md)
- **更新代码** → [code-update-guide-2026-02-16.md](code-update-guide-2026-02-16.md) ⭐
- **查看 make 命令** → [makefile-usage-2026-02-16.md](makefile-usage-2026-02-16.md)
- **配置 HTTPS** → [ssl-certificate-setup-2026-02-16.md](ssl-certificate-setup-2026-02-16.md)
- **配置 Let's Encrypt** → [letsencrypt-setup-2026-02-16.md](letsencrypt-setup-2026-02-16.md)
- **证书在哪运行** → [cert-generation-location-2026-02-16.md](cert-generation-location-2026-02-16.md) ⭐
- **单域名部署** → [single-domain-deployment-2026-02-16.md](single-domain-deployment-2026-02-16.md)
- **本地 HTTPS 开发** → [local-https-setup-2026-02-16.md](local-https-setup-2026-02-16.md)
- **了解证书选型** → [why-mkcert-for-local-2026-02-16.md](why-mkcert-for-local-2026-02-16.md)
- **设置自动部署** → [cicd-ali-ecs-deployment-2026-02-15.md](cicd-ali-ecs-deployment-2026-02-15.md)
- **使用本地域名** → [local-domain-setup-2026-02-16.md](local-domain-setup-2026-02-16.md)
- **了解 RSS 实现** → [rss-news-fetcher-refactor-2026-02-15.md](rss-news-fetcher-refactor-2026-02-15.md)

---

## 📊 文档统计

- **总文档数**：21 篇
- **部署相关**：7 篇
- **开发工具**：13 篇
- **架构设计**：1 篇
- **最新更新**：2026-02-16

---

## ✏️ 贡献指南

### 创建新文档

1. 使用规范的命名格式：`{主题}-{yyyy-mm-dd}.md`
2. 文档必须包含"核心结论"章节（放在开头）
3. 使用 Markdown 格式
4. 放置在 `docs/` 目录下
5. 更新本 README.md 索引

### 文档结构规范

```markdown
# 文档标题

## 核心结论

- 核心发现 1
- 核心发现 2
- 行动建议

---

## 详细内容

...

---

## 参考资料

- 相关文档链接
```

---

## 📮 反馈与建议

如有文档问题或改进建议，请：
1. 提交 GitHub Issue
2. 创建 Pull Request
3. 联系项目维护者
