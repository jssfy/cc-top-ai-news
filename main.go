package main

import (
	"embed"
	"flag"
	"io/fs"
	"log"
	"net/http"
	"strings"
	"time"
	"top-ai-news/internal/database"
	"top-ai-news/internal/fetcher"
	"top-ai-news/internal/handler"
)

//go:embed web/*
var webFS embed.FS

func main() {
	port := flag.String("port", "8080", "服务端口")
	dbPath := flag.String("db", "data.db", "数据库文件路径")
	flag.Parse()

	// Initialize database
	db, err := database.New(*dbPath)
	if err != nil {
		log.Fatalf("数据库初始化失败: %v", err)
	}
	defer db.Close()

	// Initialize fetcher with RSS scheduler
	f := fetcher.New(db)
	f.StartScheduler(4 * time.Hour)
	defer f.Stop()

	// Initialize handlers
	newsHandler := handler.NewNewsHandler(db, f)
	commentHandler := handler.NewCommentHandler(db)

	// Setup routes
	mux := http.NewServeMux()

	// Health check
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// API routes
	mux.HandleFunc("/api/news", corsMiddleware(newsHandler.GetNews))
	mux.HandleFunc("/api/news/fetch", corsMiddleware(methodOnly("POST", newsHandler.FetchNews)))
	mux.HandleFunc("/api/news/dates", corsMiddleware(newsHandler.GetDates))
	mux.HandleFunc("/api/news/navigate", corsMiddleware(newsHandler.Navigate))
	mux.HandleFunc("/api/news/", corsMiddleware(func(w http.ResponseWriter, r *http.Request) {
		// Route: /api/news/{id}/comments
		if !strings.HasSuffix(r.URL.Path, "/comments") {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodGet:
			commentHandler.GetComments(w, r)
		case http.MethodPost:
			commentHandler.PostComment(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	// Static files
	webContent, err := fs.Sub(webFS, "web")
	if err != nil {
		log.Fatalf("加载静态文件失败: %v", err)
	}
	mux.Handle("/", http.FileServer(http.FS(webContent)))

	addr := ":" + *port
	log.Printf("🚀 AI 新闻聚合服务启动 http://localhost%s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("服务启动失败: %v", err)
	}
}

func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}
		next(w, r)
	}
}

func methodOnly(method string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != method {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		next(w, r)
	}
}
