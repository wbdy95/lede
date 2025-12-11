-- Copyright 2024 OpenWrt.org
-- Licensed to the public under the Apache License 2.0.

local m, s, o

m = Map("multi_proxy", translate("Proxy List"),
    translate("Configure upstream proxies and assign internal IPs to each proxy."))

-- Apply changes and restart service
m.on_after_commit = function(self)
    os.execute("/etc/init.d/multi_proxy restart >/dev/null 2>&1 &")
end

s = m:section(TypedSection, "proxy", translate("Proxy Servers"))
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"
s.sortable = true

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false
o.default = "1"
o.width = "5%"

o = s:option(Value, "name", translate("Name"))
o.rmempty = false
o.placeholder = "proxy1"
o.width = "10%"

o = s:option(ListValue, "type", translate("Type"))
o:value("socks5", "SOCKS5")
o:value("socks4", "SOCKS4")
o:value("http-connect", "HTTP CONNECT")
o:value("http-relay", "HTTP Relay")
o.default = "socks5"
o.width = "10%"

o = s:option(Value, "server", translate("Server"))
o.datatype = "host"
o.rmempty = false
o.placeholder = "192.168.1.100"
o.width = "15%"

o = s:option(Value, "port", translate("Port"))
o.datatype = "port"
o.rmempty = false
o.placeholder = "1080"
o.width = "8%"

o = s:option(Value, "username", translate("Username"))
o.placeholder = translate("Optional")
o.width = "10%"

o = s:option(Value, "password", translate("Password"))
o.password = true
o.placeholder = translate("Optional")
o.width = "10%"

o = s:option(DynamicList, "source_ip", translate("Source IPs"))
o.datatype = "ip4addr"
o.rmempty = false
o.description = translate("Internal IP addresses to route through this proxy")
o.placeholder = "192.168.1.10"
o.width = "22%"

-- Add a section for quick IP assignment
local quick = m:section(NamedSection, "config", "multi_proxy", translate("Quick Setup"))
quick.anonymous = true

o = quick:option(DummyValue, "_hint", "")
o.rawhtml = true
o.value = [[
<div class="cbi-value-description">
<strong>]] .. translate("Usage Instructions") .. [[:</strong>
<ol>
<li>]] .. translate("Add proxy servers with their SOCKS5/HTTP connection details") .. [[</li>
<li>]] .. translate("Assign internal IPs to each proxy in the 'Source IPs' field") .. [[</li>
<li>]] .. translate("Save and apply, then restart the service") .. [[</li>
<li>]] .. translate("Traffic from assigned IPs will automatically route through the corresponding proxy") .. [[</li>
</ol>
<p><strong>]] .. translate("Example") .. [[:</strong></p>
<ul>
<li>192.168.1.10 → proxy1 (US server)</li>
<li>192.168.1.11 → proxy2 (JP server)</li>
<li>192.168.1.12 → proxy2 (JP server)</li>
</ul>
</div>
]]

return m
