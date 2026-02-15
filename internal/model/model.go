package model

import "time"

type News struct {
	ID          int64     `json:"id"`
	Title       string    `json:"title"`
	Summary     string    `json:"summary"`
	SourceURL   string    `json:"source_url"`
	SourceName  string    `json:"source_name"`
	Category    string    `json:"category"` // "domestic" or "global"
	PublishDate string    `json:"publish_date"`
	Rank        int       `json:"rank"`
	CreatedAt   time.Time `json:"created_at"`
}

type Comment struct {
	ID        int64     `json:"id"`
	NewsID    int64     `json:"news_id"`
	Author    string    `json:"author"`
	Content   string    `json:"content"`
	CreatedAt time.Time `json:"created_at"`
}

type CommentInput struct {
	Author  string `json:"author"`
	Content string `json:"content"`
}

type NewsListResponse struct {
	Date     string `json:"date"`
	Domestic []News `json:"domestic"`
	Global   []News `json:"global"`
	HasPrev  bool   `json:"has_prev"`
	HasNext  bool   `json:"has_next"`
}
