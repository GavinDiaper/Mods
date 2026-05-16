-- AI_HTTPTransport.lua
-- HTTP transport layer for Azure OpenAI API calls
-- Implements ModLina.LLMTransport.Send hook

if not rawget(_G, "ModLina") then
	ModLina = {}
end

ModLina.LLMTransport = ModLina.LLMTransport or {}

local function now_ms()
	return (RealTime and RealTime()) or 0
end

local function format_headers(headers_table)
	if type(headers_table) ~= "table" then
		return ""
	end
	local parts = {}
	for key, value in pairs(headers_table) do
		if type(key) == "string" and type(value) == "string" then
			table.insert(parts, key .. ": " .. value)
		end
	end
	return table.concat(parts, "\r\n")
end

---------------------------------------------------------------------------
-- STRATEGY 1: LuaSocket (socket.http)
---------------------------------------------------------------------------
local function try_luasocket(url, headers, body, timeout_ms)
	local ok, socket = pcall(require, "socket")
	if not ok or not socket then
		return nil, "socket_unavailable"
	end

	local ok2, http = pcall(require, "socket.http")
	if not ok2 or not http then
		return nil, "socket_http_unavailable"
	end

	local timeout_sec = math.max(1, (timeout_ms or 6000) / 1000)

	local request_body = body or ""
	local headers_str = format_headers(headers)

	local function make_request()
		local respbody, statuscode, responseheaders = http.request {
			url = url,
			method = "POST",
			headers = headers or {},
			source = ltn12.source.string(request_body),
			sink = ltn12.sink.table({}),
			timeout = timeout_sec,
		}
		return respbody, statuscode
	end

	local ok3, result = pcall(make_request)
	if ok3 and result and type(result) == "string" then
		if rawget(_G, "print") then
			print("[ModLina:AI_HTTPTransport] LuaSocket: Success (" .. #result .. " bytes)")
		end
		return result, nil
	end

	return nil, "socket_request_failed"
end

---------------------------------------------------------------------------
-- STRATEGY 2: Lua 5.4+ native http.request (if available)
---------------------------------------------------------------------------
local function try_native_http(url, headers, body, timeout_ms)
	local ok, http = pcall(require, "http")
	if not ok or not http or not http.request then
		return nil, "native_http_unavailable"
	end

	local timeout_sec = math.max(1, (timeout_ms or 6000) / 1000)
	local function make_request()
		return http.request("POST", url, {
			headers = headers or {},
			body = body or "",
		})
	end

	local ok2, result = pcall(make_request)
	if ok2 and result then
		if rawget(_G, "print") then
			print("[ModLina:AI_HTTPTransport] Native HTTP: Success (" .. (#result or 0) .. " bytes)")
		end
		return result, nil
	end

	return nil, "native_http_failed"
end

---------------------------------------------------------------------------
-- STRATEGY 3: cURL via os.execute (sync, fallback)
---------------------------------------------------------------------------
local function try_curl(url, headers, body, timeout_ms)
	local timeout_sec = math.max(1, (timeout_ms or 6000) / 1000)
	local output_file = os.tmpname()
	local header_file = os.tmpname()

	local cmd_parts = {
		"curl",
		"--max-time", tostring(timeout_sec),
		"--silent",
		"--show-error",
		"-X", "POST",
	}

	-- Add headers
	if type(headers) == "table" then
		for key, value in pairs(headers) do
			if type(key) == "string" and type(value) == "string" then
				table.insert(cmd_parts, "-H")
				table.insert(cmd_parts, key .. ": " .. value)
			end
		end
	end

	-- Add body
	if type(body) == "string" and body ~= "" then
		table.insert(cmd_parts, "-d")
		table.insert(cmd_parts, body)
	end

	-- Output file
	table.insert(cmd_parts, "-o")
	table.insert(cmd_parts, output_file)

	-- Headers file
	table.insert(cmd_parts, "-D")
	table.insert(cmd_parts, header_file)

	-- URL (must be last)
	table.insert(cmd_parts, url)

	local cmd = table.concat(cmd_parts, " ")

	local ok = os.execute(cmd)
	if ok ~= 0 and ok ~= true then
		if rawget(_G, "print") then
			print("[ModLina:AI_HTTPTransport] cURL: Command failed with code " .. tostring(ok))
		end
		pcall(os.remove, output_file)
		pcall(os.remove, header_file)
		return nil, "curl_exec_failed"
	end

	-- Read response
	local f = io.open(output_file, "r")
	if not f then
		pcall(os.remove, header_file)
		return nil, "curl_read_failed"
	end

	local response = f:read("*a")
	f:close()
	pcall(os.remove, output_file)
	pcall(os.remove, header_file)

	if type(response) == "string" and response ~= "" then
		if rawget(_G, "print") then
			print("[ModLina:AI_HTTPTransport] cURL: Success (" .. #response .. " bytes)")
		end
		return response, nil
	end

	return nil, "curl_empty_response"
end

---------------------------------------------------------------------------
-- STRATEGY 4: Game engine hook (if provided at runtime)
---------------------------------------------------------------------------
local function try_game_engine_hook(url, headers, body, timeout_ms)
	if rawget(_G, "LuaHTTPRequest") and type(LuaHTTPRequest) == "function" then
		local ok, result = pcall(LuaHTTPRequest, {
			method = "POST",
			url = url,
			headers = headers or {},
			body = body or "",
			timeout_ms = timeout_ms or 6000,
		})
		if ok and result then
			if rawget(_G, "print") then
				print("[ModLina:AI_HTTPTransport] Game engine hook: Success (" .. (#result or 0) .. " bytes)")
			end
			return result, nil
		end
	end
	return nil, "engine_hook_unavailable"
end

---------------------------------------------------------------------------
-- MAIN TRANSPORT INTERFACE
---------------------------------------------------------------------------

function ModLina.LLMTransport.Send(request)
	if type(request) ~= "table" then
		return nil, "invalid_request"
	end

	local url = request.url
	local headers = request.headers or {}
	local body = request.body or ""
	local timeout_ms = request.timeout_ms or 6000

	if type(url) ~= "string" or url == "" then
		return nil, "invalid_url"
	end

	if rawget(_G, "print") then
		print("[ModLina:AI_HTTPTransport] Attempting HTTP POST to: " .. url)
	end

	-- Try strategies in order
	local strategies = {
		{ try_game_engine_hook, "game_engine_hook" },
		{ try_luasocket, "luasocket" },
		{ try_native_http, "native_http" },
		{ try_curl, "curl" },
	}

	for i = 1, #strategies do
		local strategy_fn, strategy_name = strategies[i][1], strategies[i][2]
		if rawget(_G, "print") then
			print("[ModLina:AI_HTTPTransport] Trying strategy: " .. strategy_name)
		end

		local ok, result = pcall(strategy_fn, url, headers, body, timeout_ms)
		if ok and result then
			return result, nil
		end

		local err = result or "unknown_error"
		if rawget(_G, "print") then
			print("[ModLina:AI_HTTPTransport] Strategy failed (" .. strategy_name .. "): " .. tostring(err))
		end
	end

	if rawget(_G, "print") then
		print("[ModLina:AI_HTTPTransport] All HTTP strategies exhausted")
	end
	return nil, "all_strategies_failed"
end

---------------------------------------------------------------------------
-- DIAGNOSTIC FUNCTION
---------------------------------------------------------------------------

function ModLina.LLMTransport.GetAvailableStrategies()
	local available = {}

	if rawget(_G, "LuaHTTPRequest") and type(LuaHTTPRequest) == "function" then
		table.insert(available, "game_engine_hook")
	end

	local ok1, socket = pcall(require, "socket.http")
	if ok1 and socket then
		table.insert(available, "luasocket")
	end

	local ok2, http = pcall(require, "http")
	if ok2 and http and http.request then
		table.insert(available, "native_http")
	end

	if rawget(_G, "os") and os.execute then
		table.insert(available, "curl")
	end

	return available
end

if rawget(_G, "print") then
	print("[ModLina:AI_HTTPTransport] Loaded. Available strategies: " .. table.concat(ModLina.LLMTransport.GetAvailableStrategies(), ", "))
end
