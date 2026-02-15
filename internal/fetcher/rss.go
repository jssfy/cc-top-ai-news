package fetcher

import (
	"context"
	"net/url"
	"strings"
	"time"

	"github.com/mmcdole/gofeed"
)

// FeedSource defines an RSS feed to aggregate.
type FeedSource struct {
	Name     string
	URL      string
	Category string // "domestic" or "global"
	AIOnly   bool   // true = all items are AI-related, no filtering needed
	Weight   float64
}

// RawArticle is an intermediate representation of a parsed RSS item.
type RawArticle struct {
	Title       string
	Summary     string
	SourceURL   string
	SourceName  string
	Category    string
	PublishDate time.Time
	Score       float64
}

// DomesticFeeds returns pre-configured Chinese AI news sources.
func DomesticFeeds() []FeedSource {
	return []FeedSource{
		{Name: "机器之心", URL: "https://www.jiqizhixin.com/rss", Category: "domestic", AIOnly: true, Weight: 1.0},
		{Name: "36氪", URL: "https://36kr.com/feed", Category: "domestic", AIOnly: false, Weight: 0.8},
		{Name: "InfoQ中国", URL: "https://www.infoq.cn/feed", Category: "domestic", AIOnly: false, Weight: 0.7},
	}
}

// GlobalFeeds returns pre-configured international AI news sources.
func GlobalFeeds() []FeedSource {
	return []FeedSource{
		{Name: "TechCrunch AI", URL: "https://techcrunch.com/category/artificial-intelligence/feed/", Category: "global", AIOnly: true, Weight: 1.0},
		{Name: "The Verge AI", URL: "https://www.theverge.com/rss/ai-artificial-intelligence/index.xml", Category: "global", AIOnly: true, Weight: 1.0},
		{Name: "AI News", URL: "https://www.artificialintelligence-news.com/feed/", Category: "global", AIOnly: true, Weight: 1.0},
		{Name: "Ars Technica", URL: "https://feeds.arstechnica.com/arstechnica/technology-lab", Category: "global", AIOnly: false, Weight: 0.7},
	}
}

// AI keywords for filtering non-pure-AI sources.
var domesticKeywords = []string{
	"ai", "人工智能", "大模型", "llm", "gpt", "deepseek", "通义", "文心",
	"机器学习", "深度学习", "神经网络", "自然语言处理", "nlp", "chatgpt",
	"生成式", "智能体", "agent", "多模态", "diffusion", "transformer",
	"openai", "anthropic", "claude", "gemini", "copilot", "sora",
}

var globalKeywords = []string{
	"ai", "artificial intelligence", "llm", "openai", "anthropic", "deepmind",
	"machine learning", "deep learning", "neural network", "gpt", "chatgpt",
	"generative", "transformer", "diffusion", "large language model",
	"claude", "gemini", "copilot", "midjourney", "stable diffusion",
	"ai model", "ai agent", "foundation model", "sora", "deepseek",
}

// FetchFeed parses a single RSS source and returns filtered articles.
func FetchFeed(ctx context.Context, source FeedSource) ([]RawArticle, error) {
	fp := gofeed.NewParser()
	fp.UserAgent = "Mozilla/5.0 (compatible; TopAINews/1.0)"

	feed, err := fp.ParseURLWithContext(source.URL, ctx)
	if err != nil {
		return nil, err
	}

	var keywords []string
	if !source.AIOnly {
		if source.Category == "domestic" {
			keywords = domesticKeywords
		} else {
			keywords = globalKeywords
		}
	}

	var articles []RawArticle
	for _, item := range feed.Items {
		title := strings.TrimSpace(item.Title)
		if title == "" {
			continue
		}

		// Extract publish time
		pubTime := time.Now()
		if item.PublishedParsed != nil {
			pubTime = *item.PublishedParsed
		} else if item.UpdatedParsed != nil {
			pubTime = *item.UpdatedParsed
		}

		// For non-AI-only sources, filter by keywords
		if !source.AIOnly {
			text := strings.ToLower(title + " " + item.Description)
			if !matchesAnyKeyword(text, keywords) {
				continue
			}
		}

		// Build summary from description or content
		summary := stripHTML(item.Description)
		if summary == "" {
			summary = stripHTML(item.Content)
		}
		// Truncate to reasonable length
		if len([]rune(summary)) > 200 {
			summary = string([]rune(summary)[:200]) + "..."
		}

		link := item.Link
		sourceName := extractDomainFromURL(link)
		if sourceName == "" {
			sourceName = source.Name
		}

		articles = append(articles, RawArticle{
			Title:       title,
			Summary:     summary,
			SourceURL:   link,
			SourceName:  sourceName,
			Category:    source.Category,
			PublishDate: pubTime,
		})
	}

	return articles, nil
}

// matchesAnyKeyword checks if text contains any of the given keywords (case-insensitive).
func matchesAnyKeyword(text string, keywords []string) bool {
	for _, kw := range keywords {
		if strings.Contains(text, kw) {
			return true
		}
	}
	return false
}

// stripHTML removes HTML tags and decodes common entities, returning plain text.
func stripHTML(s string) string {
	if s == "" {
		return ""
	}
	var b strings.Builder
	inTag := false
	for _, r := range s {
		switch {
		case r == '<':
			inTag = true
		case r == '>':
			inTag = false
		case !inTag:
			b.WriteRune(r)
		}
	}
	result := b.String()
	// Decode common HTML entities
	replacer := strings.NewReplacer(
		"&amp;", "&", "&lt;", "<", "&gt;", ">",
		"&quot;", "\"", "&#39;", "'", "&apos;", "'",
		"&nbsp;", " ", "&#x27;", "'", "&#x2F;", "/",
	)
	result = replacer.Replace(result)
	// Collapse whitespace
	fields := strings.Fields(result)
	return strings.Join(fields, " ")
}

// extractDomainFromURL parses a URL and returns the domain without "www." prefix.
func extractDomainFromURL(rawURL string) string {
	u, err := url.Parse(rawURL)
	if err != nil {
		return ""
	}
	host := u.Hostname()
	host = strings.TrimPrefix(host, "www.")
	return host
}
