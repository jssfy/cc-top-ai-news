# Stage 1: Build
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache gcc musl-dev

ENV GOPROXY=https://goproxy.cn,https://proxy.golang.org,direct

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build -o /app/top-ai-news .

# Stage 2: Runtime
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata
ENV TZ=Asia/Shanghai

WORKDIR /app
COPY --from=builder /app/top-ai-news .

# Data volume for SQLite persistence
VOLUME ["/app/data"]

EXPOSE 8080

ENTRYPOINT ["./top-ai-news", "-port", "8080", "-db", "/app/data/data.db"]
