-- Copyright 2024 OpenWrt.org
-- Licensed to the public under the Apache License 2.0.

local sys = require "luci.sys"

local m, s, o

m = Map("multi_proxy", translate("Multi-Proxy Settings"),
    translate("Configure per-IP SOCKS5/HTTP proxy routing. Each internal IP can use a different upstream proxy."))

-- Apply changes and restart service
m.on_after_commit = function(self)
    os.execute("/etc/init.d/multi_proxy restart >/dev/null 2>&1 &")
end

s = m:section(TypedSection, "multi_proxy", translate("General Settings"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("Enable Multi-Proxy"))
o.rmempty = false
o.default = "0"

o = s:option(Value, "base_port", translate("Base Local Port"))
o.datatype = "port"
o.default = "12300"
o.description = translate("Base port for redsocks2 instances. Each proxy uses base_port + index.")

o = s:option(Value, "rt_table_base", translate("Routing Table Base"))
o.datatype = "uinteger"
o.default = "100"
o.description = translate("Base routing table number for policy routing.")

o = s:option(Value, "fwmark_base", translate("Firewall Mark Base"))
o.datatype = "uinteger"
o.default = "100"
o.description = translate("Base firewall mark for traffic marking.")

o = s:option(ListValue, "log_level", translate("Log Level"))
o:value("0", translate("Emergency"))
o:value("1", translate("Alert"))
o:value("2", translate("Critical"))
o:value("3", translate("Error"))
o:value("4", translate("Warning"))
o:value("5", translate("Notice"))
o:value("6", translate("Info"))
o:value("7", translate("Debug"))
o.default = "4"

return m
