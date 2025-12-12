#!/bin/bash
# OpenWrt 防火墙配置脚本 - 用于 Squid 代理
# 允许 Squid 代理流量通过防火墙

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SQUID_PORT=${1:-3128}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [[ $EUID -ne 0 ]]; then
    log_error "此脚本需要 root 权限"
    exit 1
fi

log_info "配置防火墙以允许 Squid 代理流量..."
log_info "Squid 代理端口: $SQUID_PORT"

# 检查是否已存在相同规则
if uci show firewall | grep -q "squid_rule"; then
    log_warn "Squid 防火墙规则已存在，跳过添加"
else
    log_info "添加防火墙规则..."

    # 添加规则允许 LAN 到 Squid 端口的流量
    uci add firewall rule
    uci set firewall.@rule[-1].name='Allow Squid'
    uci set firewall.@rule[-1].dest='lan'
    uci set firewall.@rule[-1].dest_port="$SQUID_PORT"
    uci set firewall.@rule[-1].proto='tcp'
    uci set firewall.@rule[-1].target='ACCEPT'
    uci set firewall.@rule[-1].family='ipv4'

    # 保存配置
    uci commit firewall

    log_success "防火墙规则已添加"
fi

# 重启防火墙使规则生效
log_info "重启防火墙..."
/etc/init.d/firewall restart > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
    log_success "防火墙重启成功"
else
    log_warn "防火墙重启可能失败"
fi

# 验证规则
log_info "验证防火墙规则..."
if iptables -L -n | grep -q "ACCEPT.*tcp.*$SQUID_PORT"; then
    log_success "防火墙规则已生效"
else
    log_warn "无法验证防火墙规则"
fi

echo ""
log_success "防火墙配置完成！"
echo ""
echo "允许的流量:"
echo "  - 来源: LAN 网络"
echo "  - 目标端口: $SQUID_PORT"
echo "  - 协议: TCP"
echo ""
echo "查看规则:"
echo "  uci show firewall | grep -i squid"
echo ""
echo "删除规则:"
echo "  uci delete firewall.@rule[<num>]"
echo "  uci commit firewall"
echo "  /etc/init.d/firewall restart"
