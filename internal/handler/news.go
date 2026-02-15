package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
	"top-ai-news/internal/database"
	"top-ai-news/internal/fetcher"
)

type NewsHandler struct {
	db      *database.DB
	fetcher *fetcher.Fetcher
}

func NewNewsHandler(db *database.DB, f *fetcher.Fetcher) *NewsHandler {
	return &NewsHandler{db: db, fetcher: f}
}

func (h *NewsHandler) GetNews(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	if date == "" {
		latest, err := h.db.GetLatestDate()
		if err != nil {
			http.Error(w, "获取最新日期失败", http.StatusInternalServerError)
			return
		}
		date = latest
	}
	if _, err := time.Parse("2006-01-02", date); err != nil {
		http.Error(w, "日期格式无效，请使用 yyyy-MM-dd", http.StatusBadRequest)
		return
	}

	newsList, err := h.db.GetNewsByDate(date)
	if err != nil {
		http.Error(w, "获取新闻失败", http.StatusInternalServerError)
		return
	}

	resp := struct {
		Date     string      `json:"date"`
		Domestic interface{} `json:"domestic"`
		Global   interface{} `json:"global"`
		HasPrev  bool        `json:"has_prev"`
		HasNext  bool        `json:"has_next"`
	}{
		Date:     date,
		Domestic: []interface{}{},
		Global:   []interface{}{},
	}

	type newsWithComments struct {
		ID           int64  `json:"id"`
		Title        string `json:"title"`
		Summary      string `json:"summary"`
		SourceURL    string `json:"source_url"`
		SourceName   string `json:"source_name"`
		Category     string `json:"category"`
		PublishDate  string `json:"publish_date"`
		Rank         int    `json:"rank"`
		CommentCount int    `json:"comment_count"`
	}

	var domestic, global []newsWithComments
	for _, n := range newsList {
		count, _ := h.db.GetCommentCount(n.ID)
		item := newsWithComments{
			ID:           n.ID,
			Title:        n.Title,
			Summary:      n.Summary,
			SourceURL:    n.SourceURL,
			SourceName:   n.SourceName,
			Category:     n.Category,
			PublishDate:  n.PublishDate,
			Rank:         n.Rank,
			CommentCount: count,
		}
		if n.Category == "domestic" {
			domestic = append(domestic, item)
		} else {
			global = append(global, item)
		}
	}

	if domestic != nil {
		resp.Domestic = domestic
	}
	if global != nil {
		resp.Global = global
	}

	_, resp.HasPrev = h.db.GetPrevDate(date)
	_, resp.HasNext = h.db.GetNextDate(date)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *NewsHandler) GetDates(w http.ResponseWriter, r *http.Request) {
	dates, err := h.db.GetAllDates()
	if err != nil {
		http.Error(w, "获取日期列表失败", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(dates)
}

func (h *NewsHandler) FetchNews(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	if date == "" {
		date = time.Now().Format("2006-01-02")
	}
	if _, err := time.Parse("2006-01-02", date); err != nil {
		http.Error(w, "日期格式无效", http.StatusBadRequest)
		return
	}

	log.Printf("开始抓取 %s 的 AI 新闻...", date)
	if err := h.fetcher.FetchAndStore(date); err != nil {
		log.Printf("抓取新闻失败: %v", err)
		http.Error(w, "抓取新闻失败: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "ok",
		"message": "新闻抓取完成",
		"date":    date,
	})
}

func (h *NewsHandler) Navigate(w http.ResponseWriter, r *http.Request) {
	date := r.URL.Query().Get("date")
	direction := r.URL.Query().Get("dir") // "prev" or "next"

	if date == "" || direction == "" {
		http.Error(w, "缺少参数", http.StatusBadRequest)
		return
	}

	var targetDate string
	var found bool
	if direction == "prev" {
		targetDate, found = h.db.GetPrevDate(date)
	} else {
		targetDate, found = h.db.GetNextDate(date)
	}

	if !found {
		http.Error(w, "没有更多数据", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"date": targetDate})
}
