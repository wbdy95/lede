# Copyright (C) 2024 OpenWrt.org
# Bypass Router Mode Configuration for Single NIC
# Licensed under GPLv3

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-bypass-mode
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=OpenWrt Developer
PKG_LICENSE:=GPL-3.0

LUCI_TITLE:=LuCI Bypass Router Mode Configuration
LUCI_DESCRIPTION:=Configure single NIC bypass router mode with IPv4/IPv6 dual-stack support
LUCI_DEPENDS:=+ip6tables +kmod-ipt-nat6 +odhcp6c +odhcpd-ipv6only +luci-proto-ipv6
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildance framework
