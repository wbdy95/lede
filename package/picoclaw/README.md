# PicoClaw OpenWrt 集成指南

## 📦 包信息

- **包名**: picoclaw
- **版本**: 0.2.4
- **大小**: 3KB (脚本包，二进制文件在路由器上自动下载约15MB)

## 🚀 快速开始

### 方案 1：集成到固件（已配置）

```bash
# picoclaw 已在 .config 中，重新编译固件即可
make -j$(nproc)
```

编译完成后，picoclaw 会自动包含在固件中，首次启动时自动下载二进制文件。

### 方案 2：在现有路由器上安装

```bash
# 1. 上传 ipk 包到路由器
scp bin/packages/aarch64_cortex_a53/base/picoclaw_0.2.4-1_aarch64_cortex_a53.ipk root@192.168.1.1:/tmp/

# 2. SSH 登录路由器
ssh root@192.168.1.1

# 3. 安装包
opkg install /tmp/picoclaw_0.2.4-1_aarch64_cortex_a53.ipk

# 4. 配置 API Key
vi /etc/picoclaw/config.yml
# 修改 api_key: "sk-your-openai-api-key"

# 5. 启动服务
/etc/init.d/picoclaw enable
/etc/init.d/picoclaw start
```

### 方案 3：使用一键安装脚本

```bash
# 复制安装脚本到路由器
scp package/picoclaw/install.sh root@192.168.1.1:/tmp/

# SSH 登录并执行
ssh root@192.168.1.1
sh /tmp/install.sh
```

## 🎯 使用 picoclaw-launcher

### 启动 Web UI（公开模式）

```bash
# 方法 1：使用快捷脚本（推荐）
picoclaw-public

# 方法 2：完整命令
/usr/bin/picoclaw -config /etc/picoclaw/config.yml launcher -public

# 方法 3：作为后台服务启动
/etc/init.d/picoclaw start
```

### 访问 Web UI

在浏览器中打开：
```
http://路由器IP:18800
```

例如：`http://192.168.1.1:18800`

你会看到 PicoClaw 的 Web 界面！

### 命令行模式

如果需要使用命令行模式（不启动 Web UI）：

```bash
/usr/bin/picoclaw -config /etc/picoclaw/config.yml -public
```

## ⚙️ 配置文件

编辑 `/etc/picoclaw/config.yml`:

```yaml
# 服务器配置
server:
  host: "0.0.0.0"
  port: 18800  # Web UI 端口

# AI 提供商配置
provider:
  type: "openai"  # 或: anthropic, gemini, ollama 等
  api_key: "sk-your-api-key-here"  # ⬅️ 设置你的 API Key
  base_url: ""  # 可选：自定义 API 端点
  model: "gpt-4o-mini"  # 默认模型

# 内存配置
memory:
  type: "jsonl"  # jsonl 或 redis
  max_entries: 1000
  file_path: "/etc/picoclaw/memory.jsonl"

# 安全配置
security:
  allowed_ips: []  # 空表示允许所有访问（建议配置为 LAN 网段）
  max_tokens: 4096
  timeout: 60

# 日志配置
logging:
  level: "info"
  file: "/var/log/picoclaw.log"
  max_size: 10  # MB
  max_backups: 3
  max_age: 7  # 天
```

## 🛠️ 服务管理

```bash
# 启用服务（开机自启）
/etc/init.d/picoclaw enable

# 禁用服务
/etc/init.d/picoclaw disable

# 启动服务
/etc/init.d/picoclaw start

# 停止服务
/etc/init.d/picoclaw stop

# 重启服务
/etc/init.d/picoclaw restart

# 查看状态
/etc/init.d/picoclaw status
```

## 📊 故障排查

### 检查服务状态

```bash
# 查看服务是否运行
/etc/init.d/picoclaw status

# 查看进程
ps | grep picoclaw

# 检查端口监听
netstat -tuln | grep 18800

# 或使用 ss 命令
ss -tuln | grep 18800
```

### 查看日志

```bash
# 实时日志
logread -f | grep picoclaw

# 查看完整日志
cat /var/log/picoclaw.log

# 查看最近 50 行
tail -50 /var/log/picoclaw.log
```

### 手动启动测试

```bash
# 前台运行，查看详细输出
/usr/bin/picoclaw -config /etc/picoclaw/config.yml launcher -public -v
```

### 常见问题

1. **无法访问 Web UI**
   ```bash
   # 检查服务是否启动
   /etc/init.d/picoclaw status
   
   # 检查防火墙
   uci show firewall
   ```

2. **二进制文件下载失败**
   ```bash
   # 手动下载
   cd /tmp
   wget https://github.com/sipeed/picoclaw/releases/download/v0.2.4/picoclaw-linux-arm64 -O /usr/bin/picoclaw
   chmod +x /usr/bin/picoclaw
   
   # 重启服务
   /etc/init.d/picoclaw restart
   ```

3. **API Key 错误**
   ```bash
   # 编辑配置文件
   vi /etc/picoclaw/config.yml
   
   # 确保 api_key 字段正确填写
   api_key: "sk-..."
   
   # 重启服务
   /etc/init.d/picoclaw restart
   ```

## 🌐 支持的 AI 提供商

- OpenAI (`openai`)
- Anthropic (`anthropic`)
- Google Gemini (`gemini`)
- Ollama (`ollama`) - 本地模型
- AWS Bedrock (`bedrock`)
- Azure OpenAI (`azure`)
- 以及更多...

切换提供商：
```bash
vi /etc/picoclaw/config.yml
# 修改 provider.type
# 修改对应的 api_key
```

## 📱 客户端访问

PicoClaw 支持多种客户端方式：

### Web UI（浏览器）
```
http://路由器IP:18800
```

### API 调用
```bash
curl http://路由器IP:18800/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"你好"}'
```

### WebSocket
```javascript
const ws = new WebSocket('ws://路由器IP:18800/ws');
```

## 🔒 安全建议

1. **修改默认端口**（可选）
2. **配置 API Key 限额控制**
3. **使用 LAN 防火墙规则限制访问**
4. **定期检查日志**
5. **及时更新版本**

## 📈 性能优化

- **内存占用**: <10MB（运行时）
- **磁盘空间**: ~15MB（二进制 + 日志）
- **CPU 占用**: 待机接近 0，请求时短暂上升
- **并发支持**: 取决于模型和 API Key 限额

## 📚 更多资源

- **PicoClaw 官网**: https://picoclaw.io
- **GitHub**: https://github.com/sipeed/picoclaw
- **官方文档**: https://docs.picoclaw.io
- **配置示例**: https://github.com/sipeed/picoclaw/tree/main/examples

## 🎉 快速测试

安装完成后：

```bash
# 1. 配置 API Key
echo 'provider:
  type: "openai"
  api_key: "sk-xxx"
  model: "gpt-4o-mini"' > /etc/picoclaw/config.yml

# 2. 启动服务
/etc/init.d/picoclaw start

# 3. 打开浏览器访问
# http://192.168.1.1:18800
```

开始使用你的 AI 助手！🚀
