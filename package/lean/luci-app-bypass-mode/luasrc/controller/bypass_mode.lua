-- Copyright (C) 2024 OpenWrt.org
-- Bypass Router Mode LuCI Configuration
-- Licensed under GPLv3

module("luci.controller.bypass_mode", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/bypass_mode") then
		return
	end

	local page = entry({"admin", "network", "bypass_mode"}, cbi("bypass_mode/settings"), _("Bypass Router Mode"), 95)
	page.dependent = true
	page.acl_depends = { "luci-app-bypass-mode" }

	entry({"admin", "network", "bypass_mode", "status"}, call("action_status")).leaf = true
	entry({"admin", "network", "bypass_mode", "apply"}, call("action_apply")).leaf = true
	entry({"admin", "network", "bypass_mode", "restore"}, call("action_restore")).leaf = true
end

function action_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local json = require "luci.jsonc"

	local status = {}

	-- Check if enabled
	status.enabled = uci:get("bypass_mode", "config", "enabled") == "1"

	-- Get current IP addresses
	status.lan_ip = sys.exec("ip -4 addr show br-lan 2>/dev/null | grep inet | awk '{print $2}'"):gsub("%s+", "")
	status.lan_ip6 = sys.exec("ip -6 addr show br-lan scope global 2>/dev/null | grep inet6 | awk '{print $2}'"):gsub("%s+", "")

	-- Get gateway
	status.gateway = sys.exec("ip route | grep default | awk '{print $3}'"):gsub("%s+", "")
	status.gateway6 = sys.exec("ip -6 route | grep default | awk '{print $3}'"):gsub("%s+", "")

	-- Check IPv6 forwarding
	status.ipv6_forward = sys.exec("cat /proc/sys/net/ipv6/conf/all/forwarding"):gsub("%s+", "") == "1"

	-- Check NAT6 rules
	status.nat6_active = tonumber(sys.exec("ip6tables -t nat -L POSTROUTING -n 2>/dev/null | grep -c MASQUERADE"):gsub("%s+", "")) > 0

	-- IPv6 mode
	status.ipv6_mode = uci:get("bypass_mode", "config", "ipv6_mode") or "disabled"

	-- Network connectivity test
	status.ipv4_conn = sys.exec("ping -c 1 -W 2 223.5.5.5 >/dev/null 2>&1 && echo 1 || echo 0"):gsub("%s+", "") == "1"
	status.ipv6_conn = sys.exec("ping6 -c 1 -W 2 2400:3200::1 >/dev/null 2>&1 && echo 1 || echo 0"):gsub("%s+", "") == "1"

	luci.http.prepare_content("application/json")
	luci.http.write(json.stringify(status))
end

function action_apply()
	local sys = require "luci.sys"
	sys.call("/etc/init.d/bypass-mode restart >/dev/null 2>&1 &")
	luci.http.status(200, "OK")
end

function action_restore()
	local sys = require "luci.sys"
	sys.call("/etc/init.d/bypass-mode stop >/dev/null 2>&1 &")
	luci.http.status(200, "OK")
end
