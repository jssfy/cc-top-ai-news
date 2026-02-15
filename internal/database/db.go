package database

import (
	"database/sql"
	"fmt"
	"time"
	"top-ai-news/internal/model"

	_ "modernc.org/sqlite"
)

type DB struct {
	conn *sql.DB
}

func New(dbPath string) (*DB, error) {
	conn, err := sql.Open("sqlite", dbPath+"?_pragma=journal_mode(wal)&_pragma=busy_timeout(5000)")
	if err != nil {
		return nil, fmt.Errorf("open database: %w", err)
	}
	db := &DB{conn: conn}
	if err := db.migrate(); err != nil {
		return nil, fmt.Errorf("migrate: %w", err)
	}
	return db, nil
}

func (db *DB) Close() error {
	return db.conn.Close()
}

func (db *DB) migrate() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS news (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			title TEXT NOT NULL,
			summary TEXT DEFAULT '',
			source_url TEXT DEFAULT '',
			source_name TEXT DEFAULT '',
			category TEXT NOT NULL CHECK(category IN ('domestic', 'global')),
			publish_date TEXT NOT NULL,
			rank INTEGER DEFAULT 0,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)`,
		`CREATE TABLE IF NOT EXISTS comments (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			news_id INTEGER NOT NULL,
			author TEXT DEFAULT '匿名',
			content TEXT NOT NULL,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (news_id) REFERENCES news(id) ON DELETE CASCADE
		)`,
		`CREATE INDEX IF NOT EXISTS idx_news_date_category ON news(publish_date, category)`,
		`CREATE INDEX IF NOT EXISTS idx_comments_news_id ON comments(news_id)`,
	}
	for _, q := range queries {
		if _, err := db.conn.Exec(q); err != nil {
			return fmt.Errorf("exec %q: %w", q[:40], err)
		}
	}
	return nil
}

func (db *DB) GetNewsByDate(date string) ([]model.News, error) {
	rows, err := db.conn.Query(
		`SELECT id, title, summary, source_url, source_name, category, publish_date, rank, created_at
		 FROM news WHERE publish_date = ? ORDER BY category, rank`,
		date,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var news []model.News
	for rows.Next() {
		var n model.News
		if err := rows.Scan(&n.ID, &n.Title, &n.Summary, &n.SourceURL, &n.SourceName,
			&n.Category, &n.PublishDate, &n.Rank, &n.CreatedAt); err != nil {
			return nil, err
		}
		news = append(news, n)
	}
	return news, rows.Err()
}

func (db *DB) HasNewsForDate(date string) (bool, error) {
	var count int
	err := db.conn.QueryRow(`SELECT COUNT(*) FROM news WHERE publish_date = ?`, date).Scan(&count)
	return count > 0, err
}

func (db *DB) GetPrevDate(date string) (string, bool) {
	var prev string
	err := db.conn.QueryRow(
		`SELECT publish_date FROM news WHERE publish_date < ? GROUP BY publish_date ORDER BY publish_date DESC LIMIT 1`,
		date,
	).Scan(&prev)
	if err != nil {
		return "", false
	}
	return prev, true
}

func (db *DB) GetNextDate(date string) (string, bool) {
	var next string
	err := db.conn.QueryRow(
		`SELECT publish_date FROM news WHERE publish_date > ? GROUP BY publish_date ORDER BY publish_date ASC LIMIT 1`,
		date,
	).Scan(&next)
	if err != nil {
		return "", false
	}
	return next, true
}

func (db *DB) GetLatestDate() (string, error) {
	var date string
	err := db.conn.QueryRow(
		`SELECT publish_date FROM news ORDER BY publish_date DESC LIMIT 1`,
	).Scan(&date)
	if err == sql.ErrNoRows {
		return time.Now().Format("2006-01-02"), nil
	}
	return date, err
}

func (db *DB) InsertNews(n model.News) (int64, error) {
	result, err := db.conn.Exec(
		`INSERT INTO news (title, summary, source_url, source_name, category, publish_date, rank)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		n.Title, n.Summary, n.SourceURL, n.SourceName, n.Category, n.PublishDate, n.Rank,
	)
	if err != nil {
		return 0, err
	}
	return result.LastInsertId()
}

func (db *DB) DeleteNewsByDate(date string) error {
	_, err := db.conn.Exec(`DELETE FROM news WHERE publish_date = ?`, date)
	return err
}

func (db *DB) GetCommentsByNewsID(newsID int64) ([]model.Comment, error) {
	rows, err := db.conn.Query(
		`SELECT id, news_id, author, content, created_at
		 FROM comments WHERE news_id = ? ORDER BY created_at DESC`,
		newsID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var comments []model.Comment
	for rows.Next() {
		var c model.Comment
		if err := rows.Scan(&c.ID, &c.NewsID, &c.Author, &c.Content, &c.CreatedAt); err != nil {
			return nil, err
		}
		comments = append(comments, c)
	}
	return comments, rows.Err()
}

func (db *DB) InsertComment(newsID int64, author, content string) (int64, error) {
	if author == "" {
		author = "匿名"
	}
	result, err := db.conn.Exec(
		`INSERT INTO comments (news_id, author, content) VALUES (?, ?, ?)`,
		newsID, author, content,
	)
	if err != nil {
		return 0, err
	}
	return result.LastInsertId()
}

func (db *DB) GetCommentCount(newsID int64) (int, error) {
	var count int
	err := db.conn.QueryRow(`SELECT COUNT(*) FROM comments WHERE news_id = ?`, newsID).Scan(&count)
	return count, err
}

func (db *DB) GetAllDates() ([]string, error) {
	rows, err := db.conn.Query(
		`SELECT DISTINCT publish_date FROM news ORDER BY publish_date DESC`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var dates []string
	for rows.Next() {
		var d string
		if err := rows.Scan(&d); err != nil {
			return nil, err
		}
		dates = append(dates, d)
	}
	return dates, rows.Err()
}
