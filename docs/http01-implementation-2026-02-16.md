# HTTP-01 验证实现 - 单域名部署

## 核心结论

- ✅ 添加 Let's Encrypt HTTP-01 验证支持
- ✅ 默认配置改为单域名 `data.yeanhua.asia`
- ✅ 无需 DNS API 配置（简化部署）
- ⚠️ **HTTP-01 必须在生产服务器上运行**
- ✅ 添加 Webroot 模式支持（与现有服务共存）
- ✅ 保留 DNS-01 支持（泛域名可选，可本地生成）
- ✅ 完整的文档和使用指南

---

## 实现内容

### 1. cert-manager.sh 增强

**新增函数**：

#### `generate_cert_letsencrypt_http()`
- HTTP-01 验证实现（standalone 模式）
- 独立 HTTP 服务器，临时占用 80 端口
- 支持单域名 `data.yeanhua.asia`

#### `generate_cert_letsencrypt_webroot()`
- HTTP-01 验证实现（webroot 模式）
- 与现有 Web 服务（Nginx/Apache）共存
- 无需停止 80 端口服务
- 写入验证文件到 `/var/www/html/.well-known/acme-challenge/`

#### `generate_cert_letsencrypt_dns()`
- DNS-01 验证实现（重命名原函数）
- 支持泛域名 `*.yeanhua.asia`
- 需要 DNS API 凭证

#### `generate_cert_letsencrypt()`
- 统一入口函数
- 自动检测 80 端口占用状态
- 端口空闲 → 使用 standalone 模式
- 端口占用 → 使用 webroot 模式

**配置变更**：
```bash
# 原配置
DOMAIN="*.yeanhua.asia"        # 泛域名

# 新配置
DOMAIN="data.yeanhua.asia"     # 单域名（HTTP-01 使用）
WILDCARD_DOMAIN="*.yeanhua.asia"  # 泛域名（DNS-01 使用）
```

---

### 2. Makefile 更新

**新增命令**：
```makefile
cert-generate-dns    # 生成泛域名证书（DNS-01）
```

**命令变更**：
```makefile
# cert-generate 行为变更
# 原：DNS-01（需 DNS API）
# 新：HTTP-01（无需 DNS API）
```

**帮助信息**：
```
HTTPS 证书管理:
  make cert-generate         - 生成证书（默认 Let's Encrypt HTTP-01）
  make cert-generate-mkcert  - 生成本地证书（mkcert，推荐开发）
  make cert-generate-dns     - 生成泛域名证书（DNS-01，需 DNS API）
```

---

### 3. 文档更新

**新增文档**：
- `single-domain-deployment-2026-02-16.md` - 单域名部署完整指南
- `http01-implementation-2026-02-16.md` - 本文档（实现说明）

**更新文档**：
- `README.md` - 更新快速开始和配置说明
- `docs/README.md` - 添加文档索引

---

## HTTP-01 vs DNS-01 对比

### HTTP-01 验证（新增，默认）

```bash
make cert-generate
```

**验证流程**：
```
certbot 启动临时 HTTP 服务器（端口 80）
    ↓
Let's Encrypt 访问：
http://data.yeanhua.asia/.well-known/acme-challenge/xxx
    ↓
验证域名所有权
    ↓
签发证书
```

**特点**：
- ✅ 无需 DNS API
- ✅ 配置简单
- ✅ 适合单域名
- ❌ 需要 80 端口公网可访问
- ❌ 不支持泛域名

**适用场景**：
- 生产环境单域名部署
- 快速启动项目
- 无 DNS API 访问权限

### DNS-01 验证（保留）

```bash
make cert-generate-dns
```

**验证流程**：
```
certbot 通过 DNS API 添加 TXT 记录
    ↓
_acme-challenge.yeanhua.asia. TXT "验证码"
    ↓
Let's Encrypt 查询 DNS
    ↓
验证域名所有权
    ↓
签发泛域名证书
```

**特点**：
- ✅ 支持泛域名 `*.yeanhua.asia`
- ✅ 无需 80 端口
- ✅ 适合多子域名
- ❌ 需要 DNS API 凭证
- ❌ 配置复杂

**适用场景**：
- 需要多个子域名
- 动态子域名
- 无法开放 80 端口

---

## ⚠️ 运行位置要求

### HTTP-01：必须在生产服务器运行

**原因**：Let's Encrypt 需要通过公网访问验证文件

```
你的本地电脑                  生产服务器（121.41.107.93）
    ❌                              ✅
    |                               |
    |                    data.yeanhua.asia 解析到此
    |                               |
    +------------------------------>|
         无法通过 HTTP-01 验证        |
                                    |
                          Let's Encrypt 服务器
                                    |
                    访问: http://data.yeanhua.asia/.well-known/...
                                    |
                              验证成功 ✅
```

**在服务器上运行**：
```bash
# SSH 到服务器
ssh user@121.41.107.93

# 生成证书
cd ~/top-ai-news
make cert-generate  # standalone 或 webroot
```

### DNS-01：可以在任何地方运行

**原因**：只需要 DNS API 访问权限，不需要 HTTP 服务器

**在本地运行**：
```bash
# 本地生成证书
make cert-generate-dns

# 上传到服务器
scp ~/.local-certs/yeanhua.asia/* user@121.41.107.93:~/certs/
```

**在服务器运行**：
```bash
# SSH 到服务器
ssh user@121.41.107.93
cd ~/top-ai-news
make cert-generate-dns
```

### 对比总结

| 验证方式 | 可运行位置 | 原因 |
|---------|-----------|------|
| **HTTP-01 Standalone** | ⚠️ **仅服务器** | 需临时占用服务器 80 端口 |
| **HTTP-01 Webroot** | ⚠️ **仅服务器** | 需写入文件到服务器 webroot |
| **DNS-01** | ✅ **服务器或本地** | 只需 DNS API，无需服务器 |
| **mkcert** | ✅ **任何地方** | 本地 CA，无外部依赖 |

---

## 使用场景决策

### 场景 1：只部署 data.yeanhua.asia（推荐）

**使用 HTTP-01**：

```bash
# ⚠️ 在生产服务器上运行
ssh user@121.41.107.93
cd ~/top-ai-news

# 前提：域名解析到服务器，80 端口开放
make cert-generate        # HTTP-01，无需 DNS API
make docker-up-https
```

**优势**：
- 配置最简单
- 无需额外凭证
- 5 分钟完成

**限制**：
- ⚠️ 必须在服务器上运行

### 场景 2：需要多个子域名

**使用 DNS-01**：

```bash
# ✅ 可以在本地运行
make cert-setup-dns       # 配置 DNS API
vim ~/.secrets/dns-credentials.ini
pip3 install certbot-dns-aliyun
make cert-generate-dns    # DNS-01，泛域名

# 上传到服务器
scp ~/.local-certs/yeanhua.asia/* user@121.41.107.93:~/certs/

# 在服务器上部署
ssh user@121.41.107.93
cd ~/top-ai-news
make docker-up-https
```

**支持的域名**：
- `data.yeanhua.asia` ✅
- `api.yeanhua.asia` ✅
- `www.yeanhua.asia` ✅
- `[任意].yeanhua.asia` ✅

**优势**：
- ✅ 可在本地生成证书
- ✅ 支持泛域名

### 场景 3：本地开发

**使用 mkcert**：

```bash
make cert-generate-mkcert
make docker-up-https
```

---

## 技术实现细节

### HTTP-01 验证实现

**关键代码**（`cert-manager.sh`）：

```bash
generate_cert_letsencrypt_http() {
    # 1. 检查 certbot
    if ! command -v certbot &> /dev/null; then
        error "certbot 未安装"
        return 1
    fi

    # 2. 用户确认
    echo "⚠️  HTTP-01 验证要求："
    echo "  1. 域名 $DOMAIN 必须解析到本机公网 IP"
    echo "  2. 80 端口必须可从公网访问"
    echo "  3. 申请期间会临时占用 80 端口"
    read -p "确认满足以上条件？[y/N]"

    # 3. 检查 80 端口
    if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
        warn "80 端口被占用，请先停止相关服务"
        return 1
    fi

    # 4. 申请证书
    sudo certbot certonly \
        --standalone \
        --non-interactive \
        --agree-tos \
        --email "admin@${DOMAIN_PLAIN}" \
        --preferred-challenges http-01 \
        -d "$DOMAIN"

    # 5. 复制证书
    sudo cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem \
        $CERT_DIR/fullchain.pem
    sudo cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem \
        $CERT_DIR/privkey.pem
}
```

**关键参数**：
- `--standalone`：使用独立 HTTP 服务器
- `--preferred-challenges http-01`：指定验证方式
- `-d "$DOMAIN"`：单域名（`data.yeanhua.asia`）

### HTTP-01 Webroot 模式实现

**关键代码**（`cert-manager.sh`）：

```bash
generate_cert_letsencrypt_webroot() {
    local webroot_path="/var/www/html"

    # 1. 创建 webroot 目录
    sudo mkdir -p "${webroot_path}/.well-known/acme-challenge"

    # 2. 用户确认
    echo "⚠️  Webroot 模式要求："
    echo "  1. 你的 Web 服务器（Nginx/Apache）必须配置 ACME 验证路径"
    echo "  2. 路径: /.well-known/acme-challenge/ 映射到 $webroot_path"

    # 3. 申请证书
    sudo certbot certonly \
        --webroot \
        -w "$webroot_path" \
        --non-interactive \
        --agree-tos \
        --email "admin@${DOMAIN_PLAIN}" \
        --preferred-challenges http-01 \
        -d "$DOMAIN"

    # 4. 复制证书
    sudo cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem \
        $CERT_DIR/fullchain.pem
    sudo cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem \
        $CERT_DIR/privkey.pem
}
```

**关键参数**：
- `--webroot`：使用 webroot 模式
- `-w "$webroot_path"`：指定 webroot 目录
- 无需占用 80 端口，与现有服务共存

**自动模式选择**：

```bash
generate_cert_letsencrypt() {
    # 检测 80 端口是否被占用
    if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
        warn "80 端口被占用，使用 Webroot 模式"
        generate_cert_letsencrypt_webroot
    else
        info "使用 Standalone 模式"
        generate_cert_letsencrypt_http
    fi
}
```

### DNS-01 验证实现

**关键代码**：

```bash
generate_cert_letsencrypt_dns() {
    # DNS API 配置检查
    local dns_config="$HOME/.secrets/dns-credentials.ini"
    if [ ! -f "$dns_config" ]; then
        error "DNS API 配置文件不存在"
        return 1
    fi

    # DNS 提供商检测
    if grep -q "dns_aliyun" "$dns_config"; then
        dns_plugin="dns-aliyun"
    fi

    # 申请泛域名证书
    sudo certbot certonly \
        --${dns_plugin} \
        --${dns_plugin}-credentials "$dns_config" \
        --${dns_plugin}-propagation-seconds 30 \
        -d "$WILDCARD_DOMAIN" \
        -d "$DOMAIN_PLAIN"
}
```

**关键参数**：
- `--dns-aliyun`：使用阿里云 DNS 插件
- `-d "$WILDCARD_DOMAIN"`：泛域名（`*.yeanhua.asia`）
- `--propagation-seconds 30`：等待 DNS 传播

---

## 配置文件变更

### scripts/cert-manager.sh

**域名配置**：
```bash
# 添加前
DOMAIN="*.yeanhua.asia"
DOMAIN_PLAIN="yeanhua.asia"

# 添加后
DOMAIN="data.yeanhua.asia"        # 单域名（HTTP-01）
DOMAIN_PLAIN="yeanhua.asia"
WILDCARD_DOMAIN="*.yeanhua.asia"  # 泛域名（DNS-01）
```

**函数结构**：
```
generate_cert_letsencrypt_http()   # 新增：HTTP-01
generate_cert_letsencrypt_dns()    # 重命名：DNS-01
generate_cert_letsencrypt()        # 统一入口：默认 HTTP-01
```

### Makefile

**命令映射**：
```makefile
cert-generate:
	@./scripts/cert-manager.sh generate letsencrypt  # HTTP-01

cert-generate-dns:
	@./scripts/cert-manager.sh generate letsencrypt-dns  # DNS-01

cert-generate-mkcert:
	@./scripts/cert-manager.sh generate mkcert
```

---

## 用户体验改进

### 改进前（需要 DNS API）

```bash
$ make cert-generate
[ERROR] DNS API 配置文件不存在
需要创建配置文件并填入 Access Key...
# 用户困惑：为什么需要这么多配置？
```

### 改进后（自动选择最简单的方式）

```bash
$ make cert-generate
[INFO] 使用 Let's Encrypt 生成证书（HTTP-01 验证）...
确认域名解析和 80 端口可访问？[y/N] y
[INFO] 申请证书...
[INFO] ✓ 证书生成成功
# 用户体验：简单快捷！
```

---

## 向后兼容

### 对现有用户的影响

**场景 1：已有 mkcert 证书的用户**
- ✅ 无影响，继续使用
- ✅ 可选择切换到 Let's Encrypt

**场景 2：已有 DNS API 配置的用户**
- ✅ 可继续使用 DNS-01
- ✅ 使用 `make cert-generate-dns`

**场景 3：新用户**
- ✅ 默认使用 HTTP-01（最简单）
- ✅ 可选 DNS-01 或 mkcert

---

## 测试验证

### 功能测试

```bash
# 1. 帮助信息
make help
./scripts/cert-manager.sh help

# 2. HTTP-01 验证（模拟）
make -n cert-generate

# 3. DNS-01 验证（模拟）
make -n cert-generate-dns

# 4. mkcert 验证
make cert-generate-mkcert
make cert-info
```

### 集成测试

```bash
# 完整流程测试
make cert-clean
make cert-generate        # HTTP-01
make cert-info
make docker-up-https
curl -I https://data.yeanhua.asia
```

---

## 故障排查

### HTTP-01 常见问题

**问题 1：80 端口被占用**
```bash
# 解决方案
docker compose down
make cert-generate
```

**问题 2：域名未解析**
```bash
# 检查
dig data.yeanhua.asia +short
# 等待 DNS 传播或修改 DNS 记录
```

**问题 3：防火墙阻止**
```bash
# 检查
sudo ufw status
# 开放端口
sudo ufw allow 80
```

### DNS-01 常见问题

参考：[letsencrypt-setup-2026-02-16.md](letsencrypt-setup-2026-02-16.md)

---

## 性能影响

### 证书生成时间

| 方法 | 时间 | 说明 |
|------|------|------|
| **HTTP-01** | 30-60 秒 | 网络速度影响 |
| **DNS-01** | 1-2 分钟 | DNS 传播延迟 |
| **mkcert** | 5 秒 | 本地生成 |

### 资源占用

- **HTTP-01**：短暂占用 80 端口（30-60 秒）
- **DNS-01**：无端口占用
- **mkcert**：无网络请求

---

## 安全考虑

### HTTP-01 安全性

✅ **优势**：
- Let's Encrypt 官方验证方式
- 无需暴露 API 凭证
- 标准 ACME 协议

⚠️ **注意**：
- 80 端口需临时开放
- 验证期间可被监听（非敏感信息）

### DNS-01 安全性

✅ **优势**：
- 无需开放端口
- 更灵活的验证方式

⚠️ **注意**：
- DNS API 凭证需妥善保管
- 权限最小化原则
- 定期轮换凭证

---

## 文档清单

| 文档 | 状态 | 内容 |
|------|------|------|
| `single-domain-deployment-2026-02-16.md` | ✅ 新增 | 单域名部署指南 |
| `http01-implementation-2026-02-16.md` | ✅ 新增 | 实现说明（本文档）|
| `README.md` | ✅ 更新 | 快速开始和配置说明 |
| `docs/README.md` | ✅ 更新 | 文档索引 |
| `letsencrypt-setup-2026-02-16.md` | ✅ 已有 | Let's Encrypt 完整指南 |

---

## 后续优化

### 短期

- [x] ✅ 添加 webroot 模式（与 Nginx 集成）
- [x] ✅ 自动检测 80 端口占用并选择模式
- [ ] 优化错误提示信息
- [ ] 添加证书申请进度显示
- [ ] 添加更多 DNS 提供商支持

### 长期

- [ ] 图形化配置界面
- [ ] 证书监控和告警
- [ ] 自动续期提醒

---

## 总结

### 核心改进

1. **简化配置**：HTTP-01 无需 DNS API，降低使用门槛
2. **灵活选择**：保留 DNS-01 和 mkcert，满足不同场景
3. **文档完善**：详细的部署指南和故障排查
4. **用户友好**：清晰的命令和交互式提示

### 技术亮点

- ✅ 自动检测 80 端口占用
- ✅ 友好的交互式确认
- ✅ 完整的错误处理
- ✅ 标准化的证书管理

### 适用场景

- ✅ **单域名生产部署**（推荐 HTTP-01）
- ✅ **多子域名部署**（使用 DNS-01）
- ✅ **本地开发测试**（使用 mkcert）

现在，部署 `data.yeanhua.asia` 只需要一条命令：`make cert-generate` 🎉
