#!/bin/bash
set -e

PORT=${1:-8080}
echo "==================================="
echo "  AI 新闻热榜 - 一键启动"
echo "==================================="

# Check Go installation
if ! command -v go &> /dev/null; then
    echo "❌ 未检测到 Go 环境，请先安装 Go: https://go.dev/dl/"
    exit 1
fi

echo "📦 安装依赖..."
go mod tidy

echo "🔨 编译项目..."
go build -o bin/top-ai-news .

echo "🚀 启动服务 (端口: $PORT)..."
echo "   访问地址: http://localhost:$PORT"
echo "   按 Ctrl+C 停止服务"
echo "-----------------------------------"
./bin/top-ai-news -port "$PORT"
