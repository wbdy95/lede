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
    entry({"admin", "services", "multi_proxy", "api", "restart"}, post("api_restart")).leaf = true
    entry({"admin", "services", "multi_proxy", "api", "start"}, post("api_start")).leaf = true
    entry({"admin", "services", "multi_proxy", "api", "stop"}, post("api_stop")).leaf = true

    -- Proxy management API (POST methods)
    entry({"admin", "services", "multi_proxy", "api", "proxy", "list"}, call("api_proxy_list")).leaf = true
    entry({"admin", "services", "multi_proxy", "api", "proxy", "add"}, post("api_proxy_add")).leaf = true
    entry({"admin", "services", "multi_proxy", "api", "proxy", "delete"}, post("api_proxy_delete")).leaf = true
    entry({"admin", "services", "multi_proxy", "api", "proxy", "update"}, post("api_proxy_update")).leaf = true
    entry({"admin", "services", "multi_proxy", "api", "proxy", "get"}, call("api_proxy_get")).leaf = true
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
        local proxy = {
            id = s[".name"],
            name = s.name or s[".name"],
            enabled = s.enabled == "1",
            type = s.type or "socks5",
            server = s.server,
            port = s.port,
            source_ips = s.source_ip or {}
        }
        if type(proxy.source_ips) == "string" then
            proxy.source_ips = {proxy.source_ips}
        end
        table.insert(result.proxies, proxy)
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

-- List all proxies
function api_proxy_list()
    local uci = require "luci.model.uci".cursor()
    local json = require "luci.jsonc"

    local proxies = {}

    uci:foreach("multi_proxy", "proxy", function(s)
        local proxy = {
            id = s[".name"],
            name = s.name or s[".name"],
            enabled = s.enabled == "1",
            type = s.type or "socks5",
            server = s.server or "",
            port = s.port or "",
            username = s.username or "",
            source_ips = s.source_ip or {}
        }
        if type(proxy.source_ips) == "string" then
            proxy.source_ips = {proxy.source_ips}
        end
        table.insert(proxies, proxy)
    end)

    luci.http.prepare_content("application/json")
    luci.http.write(json.stringify({status = "ok", proxies = proxies}))
end

-- Get a single proxy by ID
function api_proxy_get()
    local uci = require "luci.model.uci".cursor()
    local json = require "luci.jsonc"
    local http = require "luci.http"

    local id = http.formvalue("id")

    if not id or id == "" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Missing proxy id"}')
        return
    end

    local proxy_type = uci:get("multi_proxy", id)
    if proxy_type ~= "proxy" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Proxy not found"}')
        return
    end

    local source_ips = uci:get("multi_proxy", id, "source_ip") or {}
    if type(source_ips) == "string" then
        source_ips = {source_ips}
    end

    local proxy = {
        id = id,
        name = uci:get("multi_proxy", id, "name") or id,
        enabled = uci:get("multi_proxy", id, "enabled") == "1",
        type = uci:get("multi_proxy", id, "type") or "socks5",
        server = uci:get("multi_proxy", id, "server") or "",
        port = uci:get("multi_proxy", id, "port") or "",
        username = uci:get("multi_proxy", id, "username") or "",
        source_ips = source_ips
    }

    luci.http.prepare_content("application/json")
    luci.http.write(json.stringify({status = "ok", proxy = proxy}))
end

-- Add a new proxy
function api_proxy_add()
    local uci = require "luci.model.uci".cursor()
    local json = require "luci.jsonc"
    local http = require "luci.http"

    -- Get parameters
    local name = http.formvalue("name")
    local proxy_type = http.formvalue("type") or "socks5"
    local server = http.formvalue("server")
    local port = http.formvalue("port")
    local username = http.formvalue("username") or ""
    local password = http.formvalue("password") or ""
    local source_ips = http.formvalue("source_ips") -- comma separated
    local enabled = http.formvalue("enabled")

    -- Validate required fields
    if not name or name == "" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Missing proxy name"}')
        return
    end

    if not server or server == "" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Missing server address"}')
        return
    end

    if not port or port == "" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Missing server port"}')
        return
    end

    if not source_ips or source_ips == "" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Missing source IPs"}')
        return
    end

    -- Create new section
    local section_id = uci:add("multi_proxy", "proxy")

    uci:set("multi_proxy", section_id, "name", name)
    uci:set("multi_proxy", section_id, "enabled", enabled == "1" and "1" or "1")
    uci:set("multi_proxy", section_id, "type", proxy_type)
    uci:set("multi_proxy", section_id, "server", server)
    uci:set("multi_proxy", section_id, "port", port)

    if username ~= "" then
        uci:set("multi_proxy", section_id, "username", username)
    end

    if password ~= "" then
        uci:set("multi_proxy", section_id, "password", password)
    end

    -- Parse source IPs (comma separated)
    local ips = {}
    for ip in source_ips:gmatch("[^,]+") do
        ip = ip:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
        if ip ~= "" then
            table.insert(ips, ip)
        end
    end

    if #ips > 0 then
        uci:set("multi_proxy", section_id, "source_ip", ips)
    end

    uci:commit("multi_proxy")

    -- Restart service to apply changes
    os.execute("/etc/init.d/multi_proxy restart >/dev/null 2>&1 &")

    luci.http.prepare_content("application/json")
    luci.http.write(json.stringify({
        status = "ok",
        message = "Proxy added successfully",
        id = section_id
    }))
end

-- Delete a proxy
function api_proxy_delete()
    local uci = require "luci.model.uci".cursor()
    local json = require "luci.jsonc"
    local http = require "luci.http"

    local id = http.formvalue("id")

    if not id or id == "" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Missing proxy id"}')
        return
    end

    -- Check if section exists and is a proxy
    local proxy_type = uci:get("multi_proxy", id)
    if proxy_type ~= "proxy" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Proxy not found"}')
        return
    end

    uci:delete("multi_proxy", id)
    uci:commit("multi_proxy")

    -- Restart service to apply changes
    os.execute("/etc/init.d/multi_proxy restart >/dev/null 2>&1 &")

    luci.http.prepare_content("application/json")
    luci.http.write(json.stringify({
        status = "ok",
        message = "Proxy deleted successfully"
    }))
end

-- Update a proxy
function api_proxy_update()
    local uci = require "luci.model.uci".cursor()
    local json = require "luci.jsonc"
    local http = require "luci.http"

    local id = http.formvalue("id")

    if not id or id == "" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Missing proxy id"}')
        return
    end

    -- Check if section exists and is a proxy
    local proxy_type = uci:get("multi_proxy", id)
    if proxy_type ~= "proxy" then
        luci.http.prepare_content("application/json")
        luci.http.write('{"status":"error","message":"Proxy not found"}')
        return
    end

    -- Get parameters (only update if provided)
    local name = http.formvalue("name")
    local ptype = http.formvalue("type")
    local server = http.formvalue("server")
    local port = http.formvalue("port")
    local username = http.formvalue("username")
    local password = http.formvalue("password")
    local source_ips = http.formvalue("source_ips")
    local enabled = http.formvalue("enabled")

    if name and name ~= "" then
        uci:set("multi_proxy", id, "name", name)
    end

    if enabled then
        uci:set("multi_proxy", id, "enabled", enabled == "1" and "1" or "0")
    end

    if ptype and ptype ~= "" then
        uci:set("multi_proxy", id, "type", ptype)
    end

    if server and server ~= "" then
        uci:set("multi_proxy", id, "server", server)
    end

    if port and port ~= "" then
        uci:set("multi_proxy", id, "port", port)
    end

    if username then
        if username ~= "" then
            uci:set("multi_proxy", id, "username", username)
        else
            uci:delete("multi_proxy", id, "username")
        end
    end

    if password then
        if password ~= "" then
            uci:set("multi_proxy", id, "password", password)
        else
            uci:delete("multi_proxy", id, "password")
        end
    end

    if source_ips then
        -- Parse source IPs (comma separated)
        local ips = {}
        for ip in source_ips:gmatch("[^,]+") do
            ip = ip:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
            if ip ~= "" then
                table.insert(ips, ip)
            end
        end

        if #ips > 0 then
            uci:set("multi_proxy", id, "source_ip", ips)
        else
            uci:delete("multi_proxy", id, "source_ip")
        end
    end

    uci:commit("multi_proxy")

    -- Restart service to apply changes
    os.execute("/etc/init.d/multi_proxy restart >/dev/null 2>&1 &")

    luci.http.prepare_content("application/json")
    luci.http.write(json.stringify({
        status = "ok",
        message = "Proxy updated successfully"
    }))
end
