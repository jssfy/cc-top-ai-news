#!/bin/bash
# 本地开发 HTTPS 证书管理脚本
# 支持 mkcert（推荐）和 Let's Encrypt

set -e

CERT_DIR="$HOME/.local-certs/yeanhua.asia"
DOMAIN="data.yeanhua.asia"
DOMAIN_PLAIN="yeanhua.asia"
WILDCARD_DOMAIN="*.yeanhua.asia"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查证书是否存在且有效
check_cert_exists() {
    if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ]; then
        return 0
    else
        return 1
    fi
}

# 检查证书是否过期（30 天内）
check_cert_expiry() {
    local cert_file="$CERT_DIR/fullchain.pem"

    if [ ! -f "$cert_file" ]; then
        return 1
    fi

    # 获取证书过期时间
    local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    local expiry_epoch=$(date -j -f "%b %d %T %Y %Z" "$expiry_date" +%s 2>/dev/null || date -d "$expiry_date" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))

    if [ $days_left -gt 30 ]; then
        info "证书有效期剩余 $days_left 天"
        return 0
    else
        warn "证书即将过期（剩余 $days_left 天），需要续期"
        return 1
    fi
}

# 使用 mkcert 生成本地开发证书（推荐）
generate_cert_mkcert() {
    info "使用 mkcert 生成本地开发证书..."

    # 检查 mkcert 是否安装
    if ! command -v mkcert &> /dev/null; then
        error "mkcert 未安装"
        echo ""
        echo "请安装 mkcert:"
        echo "  Mac:   brew install mkcert"
        echo "  Linux: https://github.com/FiloSottile/mkcert#installation"
        echo ""
        return 1
    fi

    # 创建证书目录
    mkdir -p "$CERT_DIR"

    # 安装本地 CA（如果还未安装）
    info "安装本地 CA 根证书..."
    mkcert -install

    # 生成泛域名证书
    info "生成 *.yeanhua.asia 泛域名证书..."
    cd "$CERT_DIR"
    mkcert "$DOMAIN" "$DOMAIN_PLAIN" "local.yeanhua.asia" "localhost" "127.0.0.1" "::1"

    # 重命名为标准名称
    mv _wildcard.yeanhua.asia+5.pem fullchain.pem 2>/dev/null || \
        mv *.yeanhua.asia+*.pem fullchain.pem 2>/dev/null || true
    mv _wildcard.yeanhua.asia+5-key.pem privkey.pem 2>/dev/null || \
        mv *.yeanhua.asia+*-key.pem privkey.pem 2>/dev/null || true

    info "✓ mkcert 证书生成成功"
    echo ""
    echo "证书位置: $CERT_DIR"
    echo "  - fullchain.pem (证书)"
    echo "  - privkey.pem (私钥)"
    echo ""
    echo "支持的域名:"
    echo "  - *.yeanhua.asia"
    echo "  - yeanhua.asia"
    echo "  - local.yeanhua.asia"
    echo "  - localhost"
    echo ""

    return 0
}

# 使用 Let's Encrypt 生成证书（HTTP-01 验证，推荐）
generate_cert_letsencrypt_http() {
    info "使用 Let's Encrypt 生成证书（HTTP-01 验证）..."

    # 检查 certbot 是否安装
    if ! command -v certbot &> /dev/null; then
        error "certbot 未安装"
        echo ""
        echo "请安装 certbot:"
        echo "  Mac:   brew install certbot"
        echo "  Linux: apt install certbot / yum install certbot"
        echo ""
        return 1
    fi

    # 创建证书目录
    mkdir -p "$CERT_DIR"

    info "申请证书：$DOMAIN"
    echo ""
    echo "⚠️  HTTP-01 验证要求："
    echo "  1. 域名 $DOMAIN 必须解析到本机公网 IP"
    echo "  2. 80 端口必须可从公网访问"
    echo "  3. 申请期间会临时占用 80 端口"
    echo ""
    read -p "确认满足以上条件？[y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "已取消"
        return 1
    fi

    local certbot_dir="/etc/letsencrypt"
    local use_sudo=""

    # 检查是否需要 sudo
    if [ ! -w "/etc/letsencrypt" ] 2>/dev/null; then
        use_sudo="sudo"
        info "需要管理员权限运行 certbot"
    fi

    # 停止可能占用 80 端口的服务
    info "检查 80 端口占用..."
    if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
        warn "80 端口被占用，请先停止相关服务"
        echo ""
        echo "查看占用进程："
        lsof -Pi :80 -sTCP:LISTEN
        echo ""
        echo "停止服务示例："
        echo "  docker compose down  # 如果是 Docker"
        echo "  sudo nginx -s stop   # 如果是 Nginx"
        echo ""
        return 1
    fi

    # 使用 standalone 模式申请证书
    info "申请证书（standalone 模式）..."
    $use_sudo certbot certonly \
        --standalone \
        --non-interactive \
        --agree-tos \
        --email "admin@${DOMAIN_PLAIN}" \
        --preferred-challenges http-01 \
        -d "$DOMAIN" || return 1

    # 复制证书到本地目录
    info "复制证书到: $CERT_DIR"

    local le_cert_dir="/etc/letsencrypt/live/${DOMAIN}"
    $use_sudo cp "$le_cert_dir/fullchain.pem" "$CERT_DIR/fullchain.pem"
    $use_sudo cp "$le_cert_dir/privkey.pem" "$CERT_DIR/privkey.pem"
    $use_sudo chmod 644 "$CERT_DIR/fullchain.pem"
    $use_sudo chmod 600 "$CERT_DIR/privkey.pem"

    # 修改所有者为当前用户
    $use_sudo chown $(whoami):$(id -gn) "$CERT_DIR/fullchain.pem"
    $use_sudo chown $(whoami):$(id -gn) "$CERT_DIR/privkey.pem"

    info "✓ Let's Encrypt 证书生成成功"
    echo ""
    echo "证书位置: $CERT_DIR"
    echo "  - fullchain.pem (证书)"
    echo "  - privkey.pem (私钥)"
    echo ""
    echo "证书有效期: 90 天"
    echo "续期命令: make cert-renew 或 certbot renew"
    echo ""
    echo "支持的域名:"
    echo "  - $DOMAIN"
    echo ""

    return 0
}

# 使用 Let's Encrypt 生成证书（DNS-01 验证，泛域名）
generate_cert_letsencrypt_dns() {
    info "使用 Let's Encrypt 生成证书（DNS-01 验证）..."

    # 检查 certbot 是否安装
    if ! command -v certbot &> /dev/null; then
        error "certbot 未安装"
        echo ""
        echo "请安装 certbot:"
        echo "  Mac:   brew install certbot"
        echo "  Linux: apt install certbot / yum install certbot"
        echo ""
        return 1
    fi

    # 检查 DNS API 配置
    local dns_config="$HOME/.secrets/dns-credentials.ini"
    if [ ! -f "$dns_config" ]; then
        error "DNS API 配置文件不存在: $dns_config"
        echo ""
        echo "请创建 DNS API 配置文件:"
        echo ""
        echo "mkdir -p ~/.secrets"
        echo "cat > ~/.secrets/dns-credentials.ini <<EOF"
        echo "# 阿里云 DNS API（推荐）"
        echo "dns_aliyun_access_key = your_access_key_id"
        echo "dns_aliyun_access_key_secret = your_access_key_secret"
        echo ""
        echo "# 或使用其他 DNS 提供商"
        echo "# Cloudflare: dns_cloudflare_api_token"
        echo "# DNSPod: dns_dnspod_api_id 和 dns_dnspod_api_token"
        echo "EOF"
        echo "chmod 600 ~/.secrets/dns-credentials.ini"
        echo ""
        return 1
    fi

    # 检测 DNS 提供商
    local dns_plugin=""
    local dns_provider=""

    if grep -q "dns_aliyun" "$dns_config"; then
        dns_plugin="dns-aliyun"
        dns_provider="阿里云"

        # 检查阿里云 DNS 插件
        if ! python3 -c "import certbot_dns_aliyun" 2>/dev/null; then
            warn "certbot-dns-aliyun 插件未安装"
            echo ""
            echo "安装阿里云 DNS 插件:"
            echo "  pip3 install certbot-dns-aliyun"
            echo ""
            read -p "是否现在安装？[y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                pip3 install certbot-dns-aliyun || return 1
            else
                return 1
            fi
        fi
    elif grep -q "dns_cloudflare" "$dns_config"; then
        dns_plugin="dns-cloudflare"
        dns_provider="Cloudflare"
    elif grep -q "dns_dnspod" "$dns_config"; then
        dns_plugin="dns-dnspod"
        dns_provider="DNSPod"
    else
        error "无法识别 DNS 提供商配置"
        return 1
    fi

    info "使用 DNS 提供商: $dns_provider"

    # 创建证书目录
    mkdir -p "$CERT_DIR"

    # 使用 certbot 生成证书
    info "申请 Let's Encrypt 证书（DNS-01 验证）..."

    local certbot_dir="/etc/letsencrypt"
    local use_sudo=""

    # 检查是否需要 sudo
    if [ ! -w "/etc/letsencrypt" ] 2>/dev/null; then
        use_sudo="sudo"
        info "需要管理员权限运行 certbot"
    fi

    $use_sudo certbot certonly \
        --${dns_plugin} \
        --${dns_plugin}-credentials "$dns_config" \
        --${dns_plugin}-propagation-seconds 30 \
        -d "$WILDCARD_DOMAIN" \
        -d "$DOMAIN_PLAIN" \
        --non-interactive \
        --agree-tos \
        --email "admin@${DOMAIN_PLAIN}" \
        --preferred-challenges dns-01 || return 1

    # 复制证书到本地目录
    info "复制证书到: $CERT_DIR"

    local le_cert_dir="/etc/letsencrypt/live/${DOMAIN_PLAIN}"
    $use_sudo cp "$le_cert_dir/fullchain.pem" "$CERT_DIR/fullchain.pem"
    $use_sudo cp "$le_cert_dir/privkey.pem" "$CERT_DIR/privkey.pem"
    $use_sudo chmod 644 "$CERT_DIR/fullchain.pem"
    $use_sudo chmod 600 "$CERT_DIR/privkey.pem"

    # 修改所有者为当前用户
    $use_sudo chown $(whoami):$(id -gn) "$CERT_DIR/fullchain.pem"
    $use_sudo chown $(whoami):$(id -gn) "$CERT_DIR/privkey.pem"

    info "✓ Let's Encrypt 证书生成成功"
    echo ""
    echo "证书位置: $CERT_DIR"
    echo "  - fullchain.pem (证书)"
    echo "  - privkey.pem (私钥)"
    echo ""
    echo "证书有效期: 90 天"
    echo "续期命令: make cert-renew 或 certbot renew"
    echo ""
    echo "支持的域名:"
    echo "  - *.yeanhua.asia (泛域名)"
    echo "  - yeanhua.asia"
    echo ""

    return 0
}

# 使用 Let's Encrypt 生成证书（Webroot 模式，与现有 web 服务共存）
generate_cert_letsencrypt_webroot() {
    info "使用 Let's Encrypt 生成证书（Webroot 模式）..."

    # 检查 certbot 是否安装
    if ! command -v certbot &> /dev/null; then
        error "certbot 未安装"
        echo ""
        echo "请安装 certbot:"
        echo "  Mac:   brew install certbot"
        echo "  Linux: apt install certbot / yum install certbot"
        echo ""
        return 1
    fi

    # webroot 路径
    local webroot_path="/var/www/html"

    info "Webroot 模式适用于 80 端口已有 web 服务（如 Nginx）的情况"
    echo ""
    echo "⚠️  Webroot 验证要求："
    echo "  1. 80 端口上有 web 服务运行（Nginx/Apache）"
    echo "  2. Web 服务能访问 $webroot_path/.well-known/acme-challenge/"
    echo "  3. 域名 $DOMAIN 解析到服务器"
    echo ""
    read -p "确认满足以上条件？[y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "已取消"
        return 1
    fi

    # 创建 webroot 目录
    info "创建 webroot 目录..."
    sudo mkdir -p "$webroot_path/.well-known/acme-challenge"
    sudo chmod 755 "$webroot_path/.well-known/acme-challenge"

    # 创建证书目录
    mkdir -p "$CERT_DIR"

    local use_sudo=""
    if [ ! -w "/etc/letsencrypt" ] 2>/dev/null; then
        use_sudo="sudo"
        info "需要管理员权限运行 certbot"
    fi

    # 使用 webroot 模式申请证书
    info "申请证书（webroot 模式）..."
    $use_sudo certbot certonly \
        --webroot \
        -w "$webroot_path" \
        --non-interactive \
        --agree-tos \
        --email "admin@${DOMAIN_PLAIN}" \
        -d "$DOMAIN" || return 1

    # 复制证书到本地目录
    info "复制证书到: $CERT_DIR"

    local le_cert_dir="/etc/letsencrypt/live/${DOMAIN}"
    $use_sudo cp "$le_cert_dir/fullchain.pem" "$CERT_DIR/fullchain.pem"
    $use_sudo cp "$le_cert_dir/privkey.pem" "$CERT_DIR/privkey.pem"
    $use_sudo chmod 644 "$CERT_DIR/fullchain.pem"
    $use_sudo chmod 600 "$CERT_DIR/privkey.pem"

    # 修改所有者为当前用户
    $use_sudo chown $(whoami):$(id -gn) "$CERT_DIR/fullchain.pem"
    $use_sudo chown $(whoami):$(id -gn) "$CERT_DIR/privkey.pem"

    info "✓ Let's Encrypt 证书生成成功"
    echo ""
    echo "证书位置: $CERT_DIR"
    echo "  - fullchain.pem (证书)"
    echo "  - privkey.pem (私钥)"
    echo ""
    echo "证书有效期: 90 天"
    echo "续期命令: make cert-renew 或 certbot renew"
    echo ""
    echo "支持的域名:"
    echo "  - $DOMAIN"
    echo ""

    return 0
}

# Let's Encrypt 统一入口（自动选择验证方式）
generate_cert_letsencrypt() {
    # 检查 80 端口是否被占用
    if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
        warn "80 端口被占用，使用 Webroot 模式"
        generate_cert_letsencrypt_webroot
    else
        # 默认使用 HTTP-01 standalone
        generate_cert_letsencrypt_http
    fi
}

# 显示证书信息
show_cert_info() {
    local cert_file="$CERT_DIR/fullchain.pem"

    if [ ! -f "$cert_file" ]; then
        warn "证书不存在: $cert_file"
        return 1
    fi

    info "证书信息:"
    echo ""
    openssl x509 -in "$cert_file" -noout -text | grep -E "(Subject:|Issuer:|Not Before|Not After|DNS:)" | sed 's/^/  /'
    echo ""
}

# 主函数
main() {
    local command="${1:-check}"

    case "$command" in
        check)
            info "检查证书状态..."
            if check_cert_exists && check_cert_expiry; then
                info "✓ 证书有效，无需操作"
                show_cert_info
                return 0
            else
                warn "证书不存在或即将过期"
                return 1
            fi
            ;;

        generate)
            local method="${2:-letsencrypt}"

            if check_cert_exists; then
                warn "证书已存在: $CERT_DIR"
                read -p "是否覆盖现有证书？[y/N] " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    info "取消生成"
                    return 0
                fi
            fi

            case "$method" in
                mkcert)
                    generate_cert_mkcert
                    ;;
                letsencrypt)
                    generate_cert_letsencrypt
                    ;;
                letsencrypt-http)
                    generate_cert_letsencrypt_http
                    ;;
                letsencrypt-webroot)
                    generate_cert_letsencrypt_webroot
                    ;;
                letsencrypt-dns)
                    generate_cert_letsencrypt_dns
                    ;;
                *)
                    error "未知的证书生成方法: $method"
                    echo "支持的方法: mkcert, letsencrypt, letsencrypt-http, letsencrypt-webroot, letsencrypt-dns"
                    return 1
                    ;;
            esac
            ;;

        renew)
            info "续期证书..."
            if check_cert_exists && check_cert_expiry; then
                info "证书仍然有效，无需续期"
                return 0
            fi

            # 检测证书类型
            if openssl x509 -in "$CERT_DIR/fullchain.pem" -noout -issuer 2>/dev/null | grep -q "mkcert"; then
                info "检测到 mkcert 证书，重新生成..."
                generate_cert_mkcert
            else
                info "检测到 Let's Encrypt 证书..."
                generate_cert_letsencrypt
            fi
            ;;

        info)
            show_cert_info
            ;;

        clean)
            if [ -d "$CERT_DIR" ]; then
                warn "删除证书目录: $CERT_DIR"
                read -p "确认删除？[y/N] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rm -rf "$CERT_DIR"
                    info "✓ 证书已删除"
                else
                    info "取消删除"
                fi
            else
                info "证书目录不存在"
            fi
            ;;

        help|--help|-h)
            echo "HTTPS 证书管理工具"
            echo ""
            echo "用法: $0 <command> [method]"
            echo ""
            echo "命令:"
            echo "  check              检查证书状态（默认）"
            echo "  generate [method]  生成证书"
            echo "  renew              续期证书"
            echo "  info               显示证书信息"
            echo "  clean              删除证书"
            echo "  help               显示帮助"
            echo ""
            echo "证书生成方法:"
            echo "  mkcert             本地开发证书（推荐）"
            echo "  letsencrypt        Let's Encrypt HTTP-01（单域名，无需 DNS API）"
            echo "  letsencrypt-http   同上（显式指定 HTTP-01）"
            echo "  letsencrypt-dns    Let's Encrypt DNS-01（泛域名，需要 DNS API）"
            echo ""
            echo "示例:"
            echo "  $0 check                       # 检查证书状态"
            echo "  $0 generate mkcert             # 本地开发证书"
            echo "  $0 generate letsencrypt        # Let's Encrypt（HTTP-01）"
            echo "  $0 generate letsencrypt-dns    # Let's Encrypt（DNS-01，泛域名）"
            echo "  $0 renew                       # 续期证书"
            echo "  $0 info                        # 查看证书信息"
            echo ""
            echo "证书存储位置: $CERT_DIR"
            echo "域名配置:"
            echo "  - 单域名: $DOMAIN"
            echo "  - 泛域名: $WILDCARD_DOMAIN (DNS-01)"
            echo ""
            ;;

        *)
            error "未知命令: $command"
            echo "运行 '$0 help' 查看帮助"
            return 1
            ;;
    esac
}

main "$@"
