# PicoClaw OpenWrt 集成指南

## 方案一：在路由器上直接运行（推荐）

### 1. SSH 登录路由器
```bash
ssh root@192.168.1.1
```

### 2. 安装必要的包
```bash
opkg update
opkg install ca-certificates wget bash
```

### 3. 下载 PicoClaw（预编译版本）
```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.4/picoclaw-linux-arm64 -O picoclaw
chmod +x picoclaw
```

### 4. 安装到系统
```bash
mkdir -p /etc/picoclaw
mv picoclaw /usr/bin/

# 创建配置文件
cat > /etc/picoclaw/config.yml << 'EOF'
server:
  host: "0.0.0.0"
  port: 8080

provider:
  type: "openai"
  api_key: "YOUR_API_KEY"
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
EOF
```

### 5. 创建启动脚本
```bash
cat > /etc/init.d/picoclaw << 'EOF'
#!/bin/sh /etc/rc.common

START=95
STOP=15
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_command /usr/bin/picoclaw -config /etc/picoclaw/config.yml -public
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    procd_kill picoclaw
}
EOF

chmod +x /etc/init.d/picoclaw
/etc/init.d/picoclaw enable
/etc/init.d/picoclaw start
```

### 6. 启动服务
```bash
/etc/init.d/picoclaw start
```

### 7. 验证运行
```bash
# 查看日志
logread | grep picoclaw

# 测试服务
curl http://localhost:8080/health
```

## 方案二：集成到固件（完整编译）

### 在编译主机上操作：

```bash
# 1. 准备交叉编译环境
cd /tmp
git clone --depth 1 https://github.com/sipeed/picoclaw.git
cd picoclaw

# 2. 交叉编译到 ARM64
export GOOS=linux
export GOARCH=arm64
export CGO_ENABLED=0
go build -v -trimpath -ldflags "-s -w" -o picoclaw-arm64 ./cmd/picoclaw

# 3. 创建 OpenWrt 包结构
mkdir -p picoclaw-openwrt/files
cp picoclaw-arm64 picoclaw-openwroad/picoclaw

# 4. 创建 Makefile
cat > picoclaw-openwrt/Makefile << 'EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=picoclaw
PKG_VERSION:=0.2.4
PKG_RELEASE:=1
PKG_ARCH:=arm64

include $(INCLUDE_DIR)/package.mk

define Package/picoclaw
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Ultra-Efficient AI Assistant
  URL:=https://github.com/sipeed/picoclaw
  DEPENDS:=+ca-certificates @(aarch64||x86_64)
endef

define Package/picoclaw/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/picoclaw $(1)/usr/bin/picoclaw
	$(INSTALL_BIN) ./files/picoclaw-public $(1)/usr/bin/picoclaw-public
	$(INSTALL_DIR) $(1)/etc/picoclaw
	$(INSTALL_CONF) ./files/config.yml $(1)/etc/picoclaw/config.yml
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/picoclaw.init $(1)/etc/init.d/picoclaw
endef

$(eval $(call BuildPackage,picoclaw))
EOF

# 5. 复制配置文件（参考方案一）
# 6. 将整个包目录复制到 OpenWrt 的 package/ 目录
cp -r picoclaw-openwrt /path/to/openwrt/package/picoclaw

# 7. 在 OpenWrt 中添加到配置
echo "CONFIG_PACKAGE_picoclaw=y" >> .config

# 8. 编译
make package/picoclaw/compile
```

## 使用说明

### 配置 API Key
```bash
# 编辑配置
vi /etc/picoclaw/config.yml

# 或使用 UCI（如果创建了 UCI 支持）
uci set picoclaw.general.provider=openai
uci set picoclaw.general.model=gpt-4o-mini
uci set picoclay.keys.openai="sk-xxx"
uci commit picoclaw
/etc/init.d/picoclaw restart
```

### 公开模式启动
```bash
picoclaw-public
# 或
/usr/bin/picoclaw -config /etc/picoclaw/config.yml -public
```

### Web 访问
```
http://路由器IP:8080
```

## 故障排查

```bash
# 查看服务状态
/etc/init.d/picoclaw status

# 查看日志
cat /var/log/picoclaw.log
logread | grep picoclaw

# 手动启动测试
picoclaw -config /etc/picoclaw/config.yml -public -v
```

## 资源使用
- RAM: <10MB (运行时)
- 磁盘: ~15MB
- CPU: 极低（待机时几乎为0）

## 安全建议
1. 在 LAN 防火墙后使用
2. 设置强密码
3. 使用 OpenAI API Key 时注意额度控制
4. 考虑添加认证层（可选）
