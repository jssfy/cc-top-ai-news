package fetcher

import (
	"context"
	"log"
	"sync"
	"time"
	"top-ai-news/internal/database"
	"top-ai-news/internal/model"
)

type Fetcher struct {
	db     *database.DB
	stopCh chan struct{}
	mu     sync.Mutex
}

func New(db *database.DB) *Fetcher {
	return &Fetcher{
		db:     db,
		stopCh: make(chan struct{}),
	}
}

// FetchAndStore fetches RSS feeds concurrently, ranks articles, and stores top 5 per category.
func (f *Fetcher) FetchAndStore(date string) error {
	f.mu.Lock()
	defer f.mu.Unlock()

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	allFeeds := append(DomesticFeeds(), GlobalFeeds()...)
	sourceWeights := BuildSourceWeights(allFeeds)

	// Fetch all feeds concurrently
	type fetchResult struct {
		source   FeedSource
		articles []RawArticle
		err      error
	}

	results := make(chan fetchResult, len(allFeeds))
	var wg sync.WaitGroup

	for _, feed := range allFeeds {
		wg.Add(1)
		go func(src FeedSource) {
			defer wg.Done()
			articles, err := FetchFeed(ctx, src)
			results <- fetchResult{source: src, articles: articles, err: err}
		}(feed)
	}

	// Close results channel when all goroutines finish
	go func() {
		wg.Wait()
		close(results)
	}()

	// Collect results, split by category
	var domestic, global []RawArticle
	for r := range results {
		if r.err != nil {
			log.Printf("⚠ 抓取 %s 失败: %v", r.source.Name, r.err)
			continue
		}
		log.Printf("✓ 从 %s 获取 %d 篇文章", r.source.Name, len(r.articles))
		for _, a := range r.articles {
			if a.Category == "domestic" {
				domestic = append(domestic, a)
			} else {
				global = append(global, a)
			}
		}
	}

	// Rank and select top 5 per category
	topDomestic := RankAndSelect(domestic, 5, sourceWeights)
	topGlobal := RankAndSelect(global, 5, sourceWeights)

	// Delete existing news for the date to avoid duplicates
	if err := f.db.DeleteNewsByDate(date); err != nil {
		return err
	}

	// Store results
	stored := 0
	for i, a := range topDomestic {
		n := rawToNews(a, "domestic", date, i+1)
		if _, err := f.db.InsertNews(n); err != nil {
			log.Printf("保存国内新闻失败: %v", err)
		} else {
			stored++
		}
	}
	for i, a := range topGlobal {
		n := rawToNews(a, "global", date, i+1)
		if _, err := f.db.InsertNews(n); err != nil {
			log.Printf("保存全球新闻失败: %v", err)
		} else {
			stored++
		}
	}

	log.Printf("✓ 共保存 %d 条新闻 (国内: %d, 全球: %d)", stored, len(topDomestic), len(topGlobal))
	return nil
}

// StartScheduler starts a background goroutine that fetches news on startup (if needed)
// and refreshes periodically at the given interval.
func (f *Fetcher) StartScheduler(interval time.Duration) {
	go func() {
		// Initial fetch: check if today has data
		today := time.Now().Format("2006-01-02")
		has, _ := f.db.HasNewsForDate(today)
		if !has {
			log.Println("📡 首次启动，正在拉取今日新闻...")
			if err := f.FetchAndStore(today); err != nil {
				log.Printf("首次拉取新闻失败: %v", err)
			}
		} else {
			log.Println("✓ 今日新闻已存在，跳过首次拉取")
		}

		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				date := time.Now().Format("2006-01-02")
				log.Printf("📡 定时刷新新闻 (%s)...", date)
				if err := f.FetchAndStore(date); err != nil {
					log.Printf("定时拉取新闻失败: %v", err)
				}
			case <-f.stopCh:
				log.Println("新闻调度器已停止")
				return
			}
		}
	}()
}

// Stop gracefully shuts down the scheduler.
func (f *Fetcher) Stop() {
	close(f.stopCh)
}

// rawToNews converts a RawArticle to a model.News for database storage.
func rawToNews(a RawArticle, category, date string, rank int) model.News {
	return model.News{
		Title:       a.Title,
		Summary:     a.Summary,
		SourceURL:   a.SourceURL,
		SourceName:  a.SourceName,
		Category:    category,
		PublishDate: date,
		Rank:        rank,
	}
}
