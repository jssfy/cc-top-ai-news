# RSS 新闻抓取改造

## 核心结论

- **完全替换了假数据和 DuckDuckGo 抓取**，改用 7 个 RSS 源（3 国内 + 4 国际）实时聚合
- **零 API Key 依赖**，所有 RSS 源免费公开，使用 `gofeed` 库统一解析
- **启动即自动拉取** + 每 4 小时定时刷新，无需手动触发
- 前端、数据库层、Handler 层**无需改动**，完全兼容

## 文件变更清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `go.mod` | 修改 | 添加 `github.com/mmcdole/gofeed v1.3.0` |
| `internal/fetcher/fetcher.go` | 重写 | RSS 并发编排 + 定时调度器，删除 DuckDuckGo 和 SeedDemoData |
| `internal/fetcher/rss.go` | 新建 | Feed 源定义、gofeed 解析、AI 关键词过滤 |
| `internal/fetcher/ranker.go` | 新建 | 评分排名算法（时效50%+相关30%+来源20%）、标题去重 |
| `main.go` | 修改 | 用 `StartScheduler(4h)` + `defer Stop()` 替换 `SeedDemoData()` |

## 架构设计

### RSS 数据源

| 分类 | 来源 | 纯 AI | 权重 |
|------|------|-------|------|
| 国内 | 机器之心 | 是 | 1.0 |
| 国内 | 36氪 | 否（关键词过滤） | 0.8 |
| 国内 | InfoQ中国 | 否（关键词过滤） | 0.7 |
| 全球 | TechCrunch AI | 是 | 1.0 |
| 全球 | The Verge AI | 是 | 1.0 |
| 全球 | AI News | 是 | 1.0 |
| 全球 | Ars Technica | 否（关键词过滤） | 0.7 |

### 评分算法

```
总分 = 0.5 × 时效性 + 0.3 × 相关性 + 0.2 × 来源权重
```

- **时效性**：指数衰减，12h 半衰期（`e^(-0.693 × hours/12)`）
- **相关性**：高价值关键词命中数（封顶 5 个，归一化到 [0,1]）
- **来源权重**：纯 AI 源 = 1.0，通用源 = 0.7~0.8

### 调度机制

1. 启动时检查今日是否有数据 → 无则立即拉取
2. 之后每 4 小时自动刷新（ticker）
3. `Stop()` 通过 channel 优雅关闭
4. `FetchAndStore()` 用 mutex 防并发竞争，60s 超时

### 并发模型

```
StartScheduler
  └→ FetchAndStore(date)
       ├→ goroutine: FetchFeed(机器之心)
       ├→ goroutine: FetchFeed(36氪)
       ├→ goroutine: FetchFeed(InfoQ)
       ├→ goroutine: FetchFeed(TechCrunch)
       ├→ goroutine: FetchFeed(The Verge)
       ├→ goroutine: FetchFeed(AI News)
       └→ goroutine: FetchFeed(Ars Technica)
       ↓ channel 收集结果
       ↓ RankAndSelect(domestic, 5)
       ↓ RankAndSelect(global, 5)
       ↓ 写入数据库
```

## 验证方式

```bash
go build -o bin/top-ai-news .          # 编译
./bin/top-ai-news                       # 启动，观察日志
curl http://localhost:8080/api/news     # 确认返回真实新闻
curl -X POST http://localhost:8080/api/news/fetch  # 手动刷新
```
