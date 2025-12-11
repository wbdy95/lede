-- Copyright 2024 OpenWrt.org
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.multi_proxy", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/multi_proxy") then
        return
    end

    local page

    page = entry({"admin", "services", "multi_proxy"}, alias("admin", "services", "multi_proxy", "settings"), _("Multi-Proxy"), 80)
    page.dependent = true
    page.acl_depends = { "luci-app-multi-proxy" }

    entry({"admin", "services", "multi_proxy", "settings"}, cbi("multi_proxy/settings"), _("Settings"), 10).leaf = true
    entry({"admin", "services", "multi_proxy", "proxies"}, cbi("multi_proxy/proxies"), _("Proxy List"), 20).leaf = true
    entry({"admin", "services", "multi_proxy", "status"}, template("multi_proxy/status"), _("Status"), 30).leaf = true

    -- API endpoints
    entry({"admin", "services", "multi_proxy", "api", "status"}, call("api_status")).leaf = true
    entry({"admin", "services", "multi_proxy", "api", "restart"}, call("api_restart")).leaf = true
    entry({"admin", "services", "multi_proxy", "api", "start"}, call("api_start")).leaf = true
    entry({"admin", "services", "multi_proxy", "api", "stop"}, call("api_stop")).leaf = true
end

function api_status()
    local sys = require "luci.sys"
    local uci = require "luci.model.uci".cursor()
    local json = require "luci.jsonc"

    local result = {
        enabled = uci:get("multi_proxy", "config", "enabled") == "1",
        running = sys.call("pgrep -f redsocks2 > /dev/null 2>&1") == 0,
        proxies = {}
    }

    -- Count configured proxies
    uci:foreach("multi_proxy", "proxy", function(s)
        if s.enabled == "1" then
            local proxy = {
                name = s.name or s[".name"],
                type = s.type or "socks5",
                server = s.server,
                port = s.port,
                source_ips = s.source_ip or {}
            }
            table.insert(result.proxies, proxy)
        end
    end)

    -- Get iptables rule count
    local rule_count = tonumber(sys.exec("iptables -t nat -L MULTI_PROXY_NAT 2>/dev/null | wc -l")) or 0
    result.rule_count = math.max(0, rule_count - 2)

    luci.http.prepare_content("application/json")
    luci.http.write(json.stringify(result))
end

function api_restart()
    luci.http.prepare_content("application/json")

    local result = os.execute("/etc/init.d/multi_proxy restart >/dev/null 2>&1")

    if result == 0 then
        luci.http.write('{"status":"ok","message":"Service restarted"}')
    else
        luci.http.write('{"status":"error","message":"Failed to restart service"}')
    end
end

function api_start()
    luci.http.prepare_content("application/json")

    local result = os.execute("/etc/init.d/multi_proxy start >/dev/null 2>&1")

    if result == 0 then
        luci.http.write('{"status":"ok","message":"Service started"}')
    else
        luci.http.write('{"status":"error","message":"Failed to start service"}')
    end
end

function api_stop()
    luci.http.prepare_content("application/json")

    local result = os.execute("/etc/init.d/multi_proxy stop >/dev/null 2>&1")

    if result == 0 then
        luci.http.write('{"status":"ok","message":"Service stopped"}')
    else
        luci.http.write('{"status":"error","message":"Failed to stop service"}')
    end
end
