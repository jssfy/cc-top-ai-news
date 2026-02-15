package fetcher

import (
	"math"
	"sort"
	"strings"
	"time"
)

// High-value keywords that boost relevance score.
var highValueDomestic = []string{
	"发布", "开源", "突破", "首个", "领先", "gpt", "大模型", "融资",
	"deepseek", "通义", "文心", "商用", "上线", "芯片",
}

var highValueGlobal = []string{
	"release", "launch", "open source", "breakthrough", "gpt", "llm",
	"openai", "anthropic", "deepmind", "google", "meta", "nvidia",
	"funding", "billion", "regulation", "safety",
}

// RankAndSelect scores, deduplicates, sorts, and returns the top N articles.
func RankAndSelect(articles []RawArticle, topN int, sourceWeights map[string]float64) []RawArticle {
	if len(articles) == 0 {
		return nil
	}

	now := time.Now()

	// Score each article
	for i := range articles {
		articles[i].Score = computeScore(articles[i], now, sourceWeights)
	}

	// Sort by score descending
	sort.Slice(articles, func(i, j int) bool {
		return articles[i].Score > articles[j].Score
	})

	// Deduplicate by title similarity
	articles = dedup(articles)

	// Return top N
	if len(articles) > topN {
		articles = articles[:topN]
	}
	return articles
}

// computeScore calculates a weighted score for an article.
// Timeliness 50% + Relevance 30% + Source Weight 20%
func computeScore(a RawArticle, now time.Time, sourceWeights map[string]float64) float64 {
	// 1. Timeliness (50%) — exponential decay, 12-hour half-life
	hoursAgo := now.Sub(a.PublishDate).Hours()
	if hoursAgo < 0 {
		hoursAgo = 0
	}
	halfLife := 12.0
	timeliness := math.Exp(-0.693 * hoursAgo / halfLife) // ln(2) ≈ 0.693

	// 2. Relevance (30%) — high-value keyword hits, capped at 5
	relevance := computeRelevance(a)

	// 3. Source weight (20%)
	sw := 0.7 // default for unknown sources
	if w, ok := sourceWeights[a.SourceName]; ok {
		sw = w
	}

	return 0.5*timeliness + 0.3*relevance + 0.2*sw
}

// computeRelevance counts high-value keyword matches, normalized to [0, 1].
func computeRelevance(a RawArticle) float64 {
	text := strings.ToLower(a.Title + " " + a.Summary)

	var keywords []string
	if a.Category == "domestic" {
		keywords = highValueDomestic
	} else {
		keywords = highValueGlobal
	}

	hits := 0
	for _, kw := range keywords {
		if strings.Contains(text, kw) {
			hits++
		}
	}
	if hits > 5 {
		hits = 5
	}
	return float64(hits) / 5.0
}

// dedup removes articles with very similar titles (keeping the higher-scored one).
func dedup(sorted []RawArticle) []RawArticle {
	var result []RawArticle
	seen := make(map[string]bool)

	for _, a := range sorted {
		key := normalizeTitle(a.Title)
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, a)
	}
	return result
}

// normalizeTitle creates a simplified key for dedup comparison.
func normalizeTitle(title string) string {
	t := strings.ToLower(title)
	// Remove common punctuation and whitespace variations
	for _, ch := range []string{":", "：", "-", "—", "|", "｜", "'", "'", "\"", " "} {
		t = strings.ReplaceAll(t, ch, "")
	}
	// Truncate to first 30 runes for fuzzy match
	runes := []rune(t)
	if len(runes) > 30 {
		runes = runes[:30]
	}
	return string(runes)
}

// BuildSourceWeights creates a weight map from feed source definitions.
func BuildSourceWeights(feeds []FeedSource) map[string]float64 {
	// Map from source domain → weight
	weights := make(map[string]float64)
	for _, f := range feeds {
		domain := extractDomainFromURL(f.URL)
		weights[domain] = f.Weight
		// Also store by feed name for fallback matching
		weights[f.Name] = f.Weight
	}
	return weights
}
