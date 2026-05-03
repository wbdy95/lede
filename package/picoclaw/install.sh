#!/bin/sh
# PicoClaw 一键安装脚本

echo "=== PicoClaw OpenWrt 安装脚本 ==="

# 检查架构
ARCH=$(uname -m)
echo "检测到架构: $ARCH"

if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "x86_64" ]; then
    echo "警告: PicoClaw 可能不支持此架构"
    read -p "继续吗? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 选择对应的二进制
case "$ARCH" in
    aarch64)
        BINARY_URL="https://github.com/sipeed/picoclaw/releases/download/v0.2.4/picoclaw-linux-arm64"
        ;;
    x86_64)
        BINARY_URL="https://github.com/sipeed/picoclaw/releases/download/v0.2.4/picoclaw-linux-amd64"
        ;;
    *)
        echo "不支持的架构: $ARCH"
        exit 1
        ;;
esac

echo "下载 PicoClaw..."
cd /tmp
wget -O picoclaw "$BINARY_URL" || {
    echo "下载失败，尝试从镜像下载..."
    # 可以添加备用下载链接
    exit 1
}

chmod +x picoclaw

echo "安装到系统..."
mv picoclaw /usr/bin/

echo "创建配置目录..."
mkdir -p /etc/picoclaw

echo "生成配置文件..."
cat > /etc/picoclaw/config.yml << 'EOF'
server:
  host: "0.0.0.0"
  port: 8080

provider:
  type: "openai"
  api_key: ""
  base_url: ""
  model: "gpt-4o-mini"

memory:
  type: "jsonl"
  max_entries: 1000
  file_path: "/etc/picoclaw/memory.jsonl"

security:
  allowed_ips: []
  max_tokens: 4096
  timeout: 60

logging:
  level: "info"
  file: "/var/log/picoclaw.log"
  max_size: 10
  max_backups: 3
  max_age: 7
EOF

echo "创建启动脚本..."
cat > /etc/init.d/picoclaw << 'EOF'
#!/bin/sh /etc/rc.common

START=95
STOP=15
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_command /usr/bin/picoclaw -config /etc/picoclaw/config.yml -public
    procd_set_param respawn ${respawn_threshold:-3600} ${respawn_timeout:-5} ${respawn_retry:-5}
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    procd_kill picoclaw
}
EOF

chmod +x /etc/init.d/picoclaw

echo "创建公开模式启动脚本..."
cat > /usr/bin/picoclaw-public << 'EOF'
#!/bin/sh
/usr/bin/picoclaw -config /etc/picoclaw/config.yml -public "$@"
EOF

chmod +x /usr/bin/picoclaw-public

echo "启用并启动服务..."
/etc/init.d/picoclaw enable
/etc/init.d/picoclaw start

sleep 2

if /etc/init.d/picoclaw status >/dev/null 2>&1; then
    echo ""
    echo "✓ PicoClaw 安装成功!"
    echo ""
    echo "服务管理命令:"
    echo "  启动: /etc/init.d/picoclaw start"
    echo "  停止: /etc/init.d/picoclaw stop"
    echo "  重启: /etc/init.d/picoclaw restart"
    echo "  状态: /etc/init.d/picoclaw status"
    echo ""
    echo "配置文件: /etc/picoclaw/config.yml"
    echo "Web 访问: http://$(uci get network.lan.ipaddr 2>/dev/null || echo "路由器IP"):8080"
    echo ""
    echo "⚠️  下一步: 请编辑 /etc/picoclaw/config.yml 设置你的 API Key"
    echo "  vi /etc/picoclaw/config.yml"
    echo "  /etc/init.d/picoclaw restart"
else
    echo "✗ 启动失败，请查看日志:"
    echo "  logread | grep picoclaw"
    echo "  cat /var/log/picoclaw.log"
fi
