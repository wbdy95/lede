# Copyright (C) 2024 OpenWrt.org
#
# This is free software, licensed under the Apache License 2.0.

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-multi-proxy
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=OpenWrt Team
PKG_LICENSE:=Apache-2.0

LUCI_TITLE:=LuCI Multi-Proxy Manager
LUCI_DESCRIPTION:=Per-IP SOCKS5/HTTP proxy routing with iptables and policy routing
LUCI_DEPENDS:=+redsocks2 +ip-full +ipset +iptables-mod-extra +iptables-mod-ipset +kmod-ipt-extra +kmod-ipt-nat +kmod-ipt-tproxy +kmod-ipt-ipset +lua-cjson +luasocket
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildance Makefile
