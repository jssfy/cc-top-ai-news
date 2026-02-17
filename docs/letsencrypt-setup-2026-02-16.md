# Let's Encrypt 证书配置指南

## 核心结论

- ✅ 默认使用 Let's Encrypt 生成证书（DNS-01 验证）
- ✅ 支持泛域名证书（`*.yeanhua.asia`）
- ✅ 支持阿里云、Cloudflare、DNSPod 等 DNS 提供商
- ⚠️ 需要配置 DNS API 凭证
- ⚠️ 证书有效期 90 天，需定期续期

---

## 快速开始

### 1. 配置 DNS API 凭证

```bash
# 创建配置文件模板
make cert-setup-dns

# 编辑配置文件，填入真实凭证
vim ~/.secrets/dns-credentials.ini
```

### 2. 安装 DNS 插件

```bash
# 阿里云（推荐）
pip3 install certbot-dns-aliyun

# 或 Cloudflare
pip3 install certbot-dns-cloudflare

# 或 DNSPod
pip3 install certbot-dns-dnspod
```

### 3. 生成证书

```bash
# 自动检测并生成
make cert-generate

# 或启动 HTTPS 服务（自动生成）
make docker-up-https
```

---

## DNS API 配置详解

### 阿里云 DNS API

**获取 Access Key**：
1. 登录 [阿里云 RAM 控制台](https://ram.console.aliyun.com/manage/ak)
2. 创建 AccessKey（建议创建子账号并授予 DNS 权限）
3. 记录 `AccessKeyId` 和 `AccessKeySecret`

**配置文件**（`~/.secrets/dns-credentials.ini`）：
```ini
dns_aliyun_access_key = LTAIxxxxxxxxxxxxx
dns_aliyun_access_key_secret = xxxxxxxxxxxxxxxxxxxxxxxx
```

**权限要求**：
- `AliyunDNSFullAccess`（完整权限）
- 或自定义权限策略（只读+修改 TXT 记录）

**安装插件**：
```bash
pip3 install certbot-dns-aliyun
```

---

### Cloudflare API Token

**获取 API Token**：
1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. 创建 Token → 使用 "Edit zone DNS" 模板
3. Zone Resources → Include → Specific zone → 选择你的域名
4. 记录 Token

**配置文件**：
```ini
dns_cloudflare_api_token = xxxxxxxxxxxxxxxxxxxxxxxx
```

**安装插件**：
```bash
pip3 install certbot-dns-cloudflare
```

---

### DNSPod API

**获取 API 凭证**：
1. 登录 [DNSPod 控制台](https://console.dnspod.cn/account/token)
2. 创建 API Token
3. 记录 ID 和 Token

**配置文件**：
```ini
dns_dnspod_api_id = 123456
dns_dnspod_api_token = xxxxxxxxxxxxxxxxxxxxxxxx
```

**安装插件**：
```bash
pip3 install certbot-dns-dnspod
```

---

## 常用命令

### 证书管理

```bash
# 检查证书状态
make cert-check

# 生成证书（Let's Encrypt）
make cert-generate

# 生成本地开发证书（mkcert，无需 DNS API）
make cert-generate-mkcert

# 查看证书信息
make cert-info

# 续期证书
make cert-renew

# 删除证书
make cert-clean
```

### 服务启动

```bash
# HTTPS 模式（自动检查/生成证书）
make docker-up-https

# HTTP 模式（无需证书）
make docker-up-http
```

---

## Let's Encrypt vs mkcert

| 维度 | Let's Encrypt | mkcert |
|------|--------------|--------|
| **信任范围** | 全球浏览器信任 | 仅本机信任 |
| **配置复杂度** | ⭐⭐⭐ 中等 | ⭐ 简单 |
| **前置条件** | DNS API 凭证 | 无 |
| **证书有效期** | 90 天 | 1-10 年 |
| **续期** | 需定期续期 | 无需续期 |
| **适用场景** | 生产环境 | 本地开发 |

**建议**：
- **生产环境**：使用 Let's Encrypt
- **本地开发**：使用 mkcert（更简单）

---

## DNS-01 验证流程

### 工作原理

```
1. certbot 向 Let's Encrypt 请求证书
   ↓
2. Let's Encrypt 返回验证 token
   ↓
3. certbot 通过 DNS API 添加 TXT 记录
   _acme-challenge.yeanhua.asia. TXT "验证码"
   ↓
4. 等待 DNS 传播（30-60 秒）
   ↓
5. Let's Encrypt 查询 DNS TXT 记录验证
   ↓
6. 验证成功 → 签发证书
```

### 为什么使用 DNS-01？

- ✅ **支持泛域名**：`*.yeanhua.asia`
- ✅ **无需公网 IP**：不需要服务器公网可访问
- ✅ **无需 80/443 端口**：不干扰现有服务
- ⚠️ **需要 DNS API**：必须配置 DNS 提供商 API

### 对比 HTTP-01 验证

| 验证方式 | 泛域名 | 公网要求 | 端口要求 | API 要求 |
|---------|--------|---------|---------|---------|
| DNS-01 | ✅ 支持 | ❌ 不需要 | ❌ 不需要 | ✅ 需要 DNS API |
| HTTP-01 | ❌ 不支持 | ✅ 需要 | ✅ 需要 80 | ❌ 不需要 |

---

## 证书续期

### 自动续期

Let's Encrypt 证书有效期 90 天，建议设置自动续期：

```bash
# 测试续期（不实际执行）
sudo certbot renew --dry-run

# 手动续期
make cert-renew

# 或使用 certbot 命令
sudo certbot renew
```

### 自动续期脚本

创建 cron 任务：

```bash
# 编辑 crontab
crontab -e

# 每周一凌晨 2 点检查并续期
0 2 * * 1 /usr/local/bin/certbot renew --quiet && make docker-nginx-reload
```

或使用 systemd timer（推荐）：

```bash
# 启用 certbot 自动续期
sudo systemctl enable certbot-renew.timer
sudo systemctl start certbot-renew.timer

# 查看状态
sudo systemctl status certbot-renew.timer
```

---

## 故障排查

### 1. DNS API 验证失败

**错误信息**：
```
Failed to authenticate with DNS provider
```

**解决方案**：
1. 检查 API 凭证是否正确
2. 检查 API 权限是否足够
3. 检查网络连接

```bash
# 测试 DNS API
dig _acme-challenge.yeanhua.asia TXT
```

---

### 2. DNS 传播延迟

**错误信息**：
```
DNS TXT record not found
```

**解决方案**：
增加 DNS 传播等待时间：

```bash
# 修改 cert-manager.sh
--dns-aliyun-propagation-seconds 60  # 增加到 60 秒
```

---

### 3. certbot 插件未安装

**错误信息**：
```
ModuleNotFoundError: No module named 'certbot_dns_aliyun'
```

**解决方案**：
```bash
# 安装对应插件
pip3 install certbot-dns-aliyun
```

---

### 4. 证书路径权限问题

**错误信息**：
```
Permission denied: /etc/letsencrypt/...
```

**解决方案**：
```bash
# 使用 sudo 运行
sudo make cert-generate

# 或修改证书目录权限
sudo chown -R $(whoami) /etc/letsencrypt
```

---

## 证书存储位置

### Let's Encrypt 证书

```
/etc/letsencrypt/live/yeanhua.asia/
├── fullchain.pem    # 完整证书链
├── privkey.pem      # 私钥
├── cert.pem         # 域名证书
└── chain.pem        # 中间证书

复制到：
~/.local-certs/yeanhua.asia/
├── fullchain.pem
└── privkey.pem
```

### mkcert 证书

```
~/.local-certs/yeanhua.asia/
├── fullchain.pem
└── privkey.pem
```

---

## 安全建议

### 保护 DNS API 凭证

```bash
# 正确的权限设置
chmod 600 ~/.secrets/dns-credentials.ini

# 不要提交到 Git
echo ".secrets/" >> .gitignore
```

### 使用子账号

建议为证书管理创建独立的子账号：
- 最小权限原则（只授予 DNS 权限）
- 定期轮换 Access Key
- 启用 MFA（多因素认证）

### 私钥保护

```bash
# 私钥权限
chmod 600 ~/.local-certs/yeanhua.asia/privkey.pem

# 不要在公开渠道分享私钥
# 不要提交到代码仓库
```

---

## 参考资料

### 官方文档

- [Let's Encrypt 官网](https://letsencrypt.org/)
- [Certbot 文档](https://certbot.eff.org/docs/)
- [certbot-dns-aliyun](https://github.com/justjavac/certbot-dns-aliyun)

### 相关文档

- [certificate-comparison-2026-02-16.md](certificate-comparison-2026-02-16.md) - 证书方案对比
- [why-mkcert-for-local-2026-02-16.md](why-mkcert-for-local-2026-02-16.md) - 本地开发为何用 mkcert
- [local-https-setup-2026-02-16.md](local-https-setup-2026-02-16.md) - 本地 HTTPS 配置

---

## 常见问题

### Q1: 为什么不能为 localhost 申请证书？

Let's Encrypt 只能为公网域名签发证书，`localhost` 和内网 IP 无法验证所有权。

**解决方案**：本地开发使用 mkcert

```bash
make cert-generate-mkcert
```

---

### Q2: DNS-01 验证需要多久？

通常 30-60 秒，取决于 DNS 传播速度。

---

### Q3: 泛域名证书能用于 localhost 吗？

不能。证书中的 `*.yeanhua.asia` 不匹配 `localhost`。

**解决方案**：同时添加 localhost 到证书

```bash
# Let's Encrypt 不支持，使用 mkcert
mkcert "*.yeanhua.asia" localhost
```

---

### Q4: 如何切换回 mkcert？

```bash
# 删除现有证书
make cert-clean

# 使用 mkcert 生成
make cert-generate-mkcert

# 重启服务
make docker-restart
```

---

## 统计信息

- **文档创建**：2026-02-16
- **Let's Encrypt 证书有效期**：90 天
- **推荐续期时间**：30 天前
- **DNS 传播等待时间**：30-60 秒
