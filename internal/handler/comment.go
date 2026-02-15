package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"top-ai-news/internal/database"
	"top-ai-news/internal/model"
)

type CommentHandler struct {
	db *database.DB
}

func NewCommentHandler(db *database.DB) *CommentHandler {
	return &CommentHandler{db: db}
}

func (h *CommentHandler) GetComments(w http.ResponseWriter, r *http.Request) {
	newsID, err := parseNewsID(r.URL.Path, "/api/news/", "/comments")
	if err != nil {
		http.Error(w, "无效的新闻ID", http.StatusBadRequest)
		return
	}

	comments, err := h.db.GetCommentsByNewsID(newsID)
	if err != nil {
		http.Error(w, "获取评论失败", http.StatusInternalServerError)
		return
	}

	if comments == nil {
		comments = []model.Comment{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(comments)
}

func (h *CommentHandler) PostComment(w http.ResponseWriter, r *http.Request) {
	newsID, err := parseNewsID(r.URL.Path, "/api/news/", "/comments")
	if err != nil {
		http.Error(w, "无效的新闻ID", http.StatusBadRequest)
		return
	}

	var input model.CommentInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		http.Error(w, "请求格式无效", http.StatusBadRequest)
		return
	}

	content := strings.TrimSpace(input.Content)
	if content == "" {
		http.Error(w, "评论内容不能为空", http.StatusBadRequest)
		return
	}
	if len(content) > 1000 {
		http.Error(w, "评论内容过长（最多1000字）", http.StatusBadRequest)
		return
	}

	author := strings.TrimSpace(input.Author)
	if len(author) > 50 {
		author = author[:50]
	}

	id, err := h.db.InsertComment(newsID, author, content)
	if err != nil {
		http.Error(w, "发表评论失败", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"id":      id,
		"message": "评论发表成功",
	})
}

func parseNewsID(path, prefix, suffix string) (int64, error) {
	path = strings.TrimPrefix(path, prefix)
	path = strings.TrimSuffix(path, suffix)
	return strconv.ParseInt(path, 10, 64)
}
