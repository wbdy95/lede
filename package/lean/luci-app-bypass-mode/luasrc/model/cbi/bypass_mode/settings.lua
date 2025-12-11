-- Copyright (C) 2024 OpenWrt.org
-- Bypass Router Mode LuCI CBI Model
-- Licensed under GPLv3

local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()

m = Map("bypass_mode", translate("Bypass Router Mode"),
	translate("Configure single NIC bypass router mode with IPv4 and IPv6 dual-stack support. This mode allows your device to act as a secondary router/gateway in an existing network."))

-- Status section
m:section(SimpleSection).template = "bypass_mode/status"

--
-- Basic Settings
--
s = m:section(TypedSection, "bypass_mode", translate("Basic Settings"))
s.anonymous = true
s.addremove = false

s:tab("general", translate("General"))
s:tab("ipv4", translate("IPv4 Settings"))
s:tab("ipv6", translate("IPv6 Settings"))
s:tab("firewall", translate("Firewall"))
s:tab("advanced", translate("Advanced"))

-- General Tab
o = s:taboption("general", Flag, "enabled", translate("Enable Bypass Mode"),
	translate("Enable bypass router mode. This will modify your network configuration."))
o.rmempty = false

function o.write(self, section, value)
	if value == "1" then
		sys.init.enable("bypass-mode")
	else
		sys.init.disable("bypass-mode")
	end
	return Flag.write(self, section, value)
end

o = s:taboption("general", Value, "interface", translate("Network Interface"),
	translate("Physical network interface to use (usually eth0 for single NIC)"))
o.default = "eth0"
o.placeholder = "eth0"
o.rmempty = false

-- IPv4 Tab
o = s:taboption("ipv4", Value, "lan_ipaddr", translate("LAN IP Address"),
	translate("IP address of this bypass router"))
o.datatype = "ip4addr"
o.default = "192.168.1.2"
o.placeholder = "192.168.1.2"
o.rmempty = false

o = s:taboption("ipv4", Value, "lan_netmask", translate("LAN Netmask"),
	translate("Subnet mask for LAN"))
o.datatype = "ip4addr"
o.default = "255.255.255.0"
o.placeholder = "255.255.255.0"

o = s:taboption("ipv4", Value, "gateway", translate("Gateway"),
	translate("IP address of the main router (gateway)"))
o.datatype = "ip4addr"
o.default = "192.168.1.1"
o.placeholder = "192.168.1.1"
o.rmempty = false

o = s:taboption("ipv4", Value, "dns", translate("DNS Servers"),
	translate("DNS servers (space separated)"))
o.default = "192.168.1.1"
o.placeholder = "192.168.1.1 223.5.5.5"

o = s:taboption("ipv4", Flag, "disable_dhcp", translate("Disable DHCP Server"),
	translate("Disable DHCP server on this device (recommended for bypass mode)"))
o.default = "1"

-- IPv6 Tab
o = s:taboption("ipv6", ListValue, "ipv6_mode", translate("IPv6 Mode"),
	translate("Select IPv6 operation mode"))
o:value("disabled", translate("Disabled - No IPv6"))
o:value("nat6", translate("NAT6 - IPv6 Network Address Translation"))
o:value("relay", translate("Relay - Passthrough IPv6 from main router"))
o:value("hybrid", translate("Hybrid - NAT6 + Relay"))
o.default = "nat6"

o = s:taboption("ipv6", Value, "ipv6_ula_prefix", translate("IPv6 ULA Prefix"),
	translate("Unique Local Address prefix for NAT6 mode (e.g., fd00:ab:cd::/48)"))
o.datatype = "ip6addr"
o.default = "fd00:ab:cd::/48"
o.placeholder = "fd00:ab:cd::/48"
o:depends("ipv6_mode", "nat6")
o:depends("ipv6_mode", "hybrid")

o = s:taboption("ipv6", Value, "ipv6_lan_addr", translate("IPv6 LAN Address"),
	translate("IPv6 address for LAN interface"))
o.default = "fd00:ab:cd::2/64"
o.placeholder = "fd00:ab:cd::2/64"
o:depends("ipv6_mode", "nat6")
o:depends("ipv6_mode", "hybrid")

o = s:taboption("ipv6", Value, "ipv6_gateway", translate("IPv6 Gateway"),
	translate("IPv6 address of main router (required for relay mode)"))
o.datatype = "ip6addr"
o.placeholder = "fe80::1"
o:depends("ipv6_mode", "relay")
o:depends("ipv6_mode", "hybrid")

o = s:taboption("ipv6", Flag, "ipv6_masq", translate("Enable IPv6 NAT"),
	translate("Enable IPv6 MASQUERADE (NAT6) for outgoing traffic"))
o.default = "1"
o:depends("ipv6_mode", "nat6")
o:depends("ipv6_mode", "hybrid")

o = s:taboption("ipv6", Flag, "ipv6_accept_ra", translate("Accept RA"),
	translate("Accept Router Advertisements from upstream"))
o.default = "1"
o:depends("ipv6_mode", "relay")
o:depends("ipv6_mode", "hybrid")

o = s:taboption("ipv6", ListValue, "dhcpv6_mode", translate("DHCPv6 Mode"),
	translate("DHCPv6 server mode"))
o:value("disabled", translate("Disabled"))
o:value("server", translate("Server - Provide IPv6 addresses"))
o:value("relay", translate("Relay - Forward to main router"))
o:value("hybrid", translate("Hybrid"))
o.default = "disabled"
o:depends("ipv6_mode", "nat6")
o:depends("ipv6_mode", "relay")
o:depends("ipv6_mode", "hybrid")

o = s:taboption("ipv6", ListValue, "ra_mode", translate("RA Mode"),
	translate("Router Advertisement mode"))
o:value("disabled", translate("Disabled"))
o:value("server", translate("Server - Send RA to LAN"))
o:value("relay", translate("Relay - Forward RA"))
o:value("hybrid", translate("Hybrid"))
o.default = "server"
o:depends("ipv6_mode", "nat6")
o:depends("ipv6_mode", "relay")
o:depends("ipv6_mode", "hybrid")

o = s:taboption("ipv6", Value, "dns6", translate("IPv6 DNS Servers"),
	translate("IPv6 DNS servers (space separated). Leave empty to use IPv4 DNS"))
o.placeholder = "2400:3200::1 2400:3200:baba::1"
o:depends("ipv6_mode", "nat6")
o:depends("ipv6_mode", "relay")
o:depends("ipv6_mode", "hybrid")

-- Firewall Tab
o = s:taboption("firewall", Flag, "firewall_enabled", translate("Enable Firewall"),
	translate("Enable firewall rules for bypass mode"))
o.default = "1"

o = s:taboption("firewall", Flag, "syn_flood", translate("SYN Flood Protection"),
	translate("Enable SYN flood attack protection"))
o.default = "1"
o:depends("firewall_enabled", "1")

o = s:taboption("firewall", Flag, "fullcone_nat", translate("Full Cone NAT"),
	translate("Enable full cone NAT for better P2P and gaming performance"))
o.default = "1"
o:depends("firewall_enabled", "1")

-- Advanced Tab (Routing section)
s2 = m:section(TypedSection, "routing", translate("Routing Settings"),
	translate("Advanced routing configuration for bypass mode"))
s2.anonymous = true
s2.addremove = false

o = s2:option(Flag, "enabled", translate("Enable Custom Routing"),
	translate("Enable custom routing rules"))
o.default = "1"

o = s2:option(Flag, "dns_redirect", translate("DNS Redirect"),
	translate("Redirect all DNS queries to this device"))
o.default = "1"
o:depends("enabled", "1")

o = s2:option(Flag, "redirect_all", translate("Redirect All Traffic"),
	translate("Force all traffic through this bypass router"))
o.default = "0"
o:depends("enabled", "1")

o = s2:option(ListValue, "traffic_mode", translate("Traffic Mode"),
	translate("Which traffic should be handled by bypass router"))
o:value("all", translate("All Traffic"))
o:value("marked", translate("Marked Traffic Only"))
o:value("none", translate("None (Manual)"))
o.default = "all"
o:depends("enabled", "1")

--
-- Quick Setup Section
--
s3 = m:section(TypedSection, "bypass_mode", translate("Quick Setup"),
	translate("Use these presets for common bypass router scenarios"))
s3.anonymous = true
s3.addremove = false

o = s3:option(Button, "_preset_nat6", translate("Apply NAT6 Preset"))
o.inputtitle = translate("NAT6 Mode (Recommended)")
o.inputstyle = "apply"
function o.write()
	uci:set("bypass_mode", "config", "ipv6_mode", "nat6")
	uci:set("bypass_mode", "config", "ipv6_masq", "1")
	uci:set("bypass_mode", "config", "dhcpv6_mode", "server")
	uci:set("bypass_mode", "config", "ra_mode", "server")
	uci:commit("bypass_mode")
	luci.http.redirect(luci.dispatcher.build_url("admin/network/bypass_mode"))
end

o = s3:option(Button, "_preset_relay", translate("Apply Relay Preset"))
o.inputtitle = translate("Relay Mode (Pass-through)")
o.inputstyle = "apply"
function o.write()
	uci:set("bypass_mode", "config", "ipv6_mode", "relay")
	uci:set("bypass_mode", "config", "ipv6_masq", "0")
	uci:set("bypass_mode", "config", "ipv6_accept_ra", "1")
	uci:set("bypass_mode", "config", "dhcpv6_mode", "relay")
	uci:set("bypass_mode", "config", "ra_mode", "relay")
	uci:commit("bypass_mode")
	luci.http.redirect(luci.dispatcher.build_url("admin/network/bypass_mode"))
end

o = s3:option(Button, "_preset_ipv4only", translate("Apply IPv4 Only Preset"))
o.inputtitle = translate("IPv4 Only Mode")
o.inputstyle = "apply"
function o.write()
	uci:set("bypass_mode", "config", "ipv6_mode", "disabled")
	uci:commit("bypass_mode")
	luci.http.redirect(luci.dispatcher.build_url("admin/network/bypass_mode"))
end

return m
