.PHONY: run build clean deps

# Default port
PORT ?= 8080

# Run in development mode
run: deps
	go run . -port $(PORT)

# Build binary
build: deps
	go build -o bin/top-ai-news .

# Run built binary
start: build
	./bin/top-ai-news -port $(PORT)

# Install dependencies
deps:
	go mod tidy

# Clean build artifacts and database
clean:
	rm -rf bin/ data.db
