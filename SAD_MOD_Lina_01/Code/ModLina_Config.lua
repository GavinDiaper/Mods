-- ModLina_Config.lua
-- Player configuration, settings persistence, and defaults

if not rawget(_G, "ModLina") then
	ModLina = {}
end

ModLina.Config = ModLina.Config or {}

local function SetSecretsStatus(status, reason)
	if not rawget(_G, "ModLinaState") or not ModLinaState then
		return
	end
	ModLinaState.ai_secrets_status = status
	ModLinaState.ai_secrets_reason = reason
end

local function ApplySecretsTable(secrets)
	if type(secrets) ~= "table" then
		return false, "secrets_not_table"
	end

	if not ModLinaState.api then
		return false, "api_state_uninitialized"
	end

	if type(secrets.provider) == "string" and secrets.provider ~= "" then
		ModLinaState.api.provider = secrets.provider
	end
	if type(secrets.endpoint) == "string" and secrets.endpoint ~= "" then
		ModLinaState.api.endpoint = secrets.endpoint
	end
	if type(secrets.deployment) == "string" and secrets.deployment ~= "" then
		ModLinaState.api.deployment = secrets.deployment
	end
	if type(secrets.model) == "string" and secrets.model ~= "" then
		ModLinaState.api.model = secrets.model
	end
	if type(secrets.api_version) == "string" and secrets.api_version ~= "" then
		ModLinaState.api.api_version = secrets.api_version
	end
	if type(secrets.key) == "string" then
		ModLinaState.api.key = secrets.key
	end

	if ModLinaState.api.key == "" then
		return false, "empty_api_key"
	end

	return true, nil
end

---------------------------------------------------------------------------
-- DEFAULT SETTINGS
---------------------------------------------------------------------------

local CONFIG_DEFAULTS = {
	-- Mode: A = Advisor, B = Semi-Auto, C = Full-Auto
	mode = "A",

	-- Thresholds for Advisor alerts
	thresholds = {
		stress = 60,      -- Alert if survivor stress > this (mood < 40)
		hunger = 20,      -- Alert if survivor food < this
		cloth = 20,       -- Alert if Cloth resource < this
	},

	-- Notification cooldowns (in seconds)
	cooldowns = {
		survivor = 300,   -- Per survivor, per alert type
		resources = 600,  -- Global for resource alerts
		production = 300, -- Per workbench type
	},

	-- Alert categories (enable/disable by type)
	alerts_enabled = {
		survivors = true,
		resources = true,
		production = true,
	},

	-- API credentials (stored but not used in v1)
	api = {
		provider = "LocalBridge",    -- "LocalBridge" or "AzureOpenAI"
		key = "",
		endpoint = "http://127.0.0.1:8787",
		model = "gpt-5-mini",
		deployment = "gpt-5-mini",
		api_version = "2025-01-01-preview",
	},

	-- AI call governance (cloud calls are disabled by default)
	ai = {
		enabled = false,
		cooldown_seconds = 120,
		max_calls_per_hour = 8,
		max_calls_per_day = 25,
		timeout_seconds = 6,
		allow_mutating_actions = false,
	},

	-- Debug mode
	debug = false,

	-- UI behavior
	ui = {
		normal_notifications = true,
		show_hud = true,
		hud_mode = "compact", -- compact | verbose
	},
}

---------------------------------------------------------------------------
-- HELPER: Ensure config is initialized
---------------------------------------------------------------------------

local function EnsureConfigLoaded()
	if not ModLinaState.thresholds then
		ModLinaState.thresholds = table.copy(CONFIG_DEFAULTS.thresholds)
	end
	if not ModLinaState.cooldowns then
		ModLinaState.cooldowns = table.copy(CONFIG_DEFAULTS.cooldowns)
	end
	if not ModLinaState.alerts_enabled then
		ModLinaState.alerts_enabled = table.copy(CONFIG_DEFAULTS.alerts_enabled)
	end
	if not ModLinaState.api then
		ModLinaState.api = table.copy(CONFIG_DEFAULTS.api)
	end
	if not ModLinaState.ai then
		ModLinaState.ai = table.copy(CONFIG_DEFAULTS.ai)
	end
	if not ModLinaState.ui then
		ModLinaState.ui = table.copy(CONFIG_DEFAULTS.ui)
	end
end

---------------------------------------------------------------------------
-- SETTINGS GETTERS
---------------------------------------------------------------------------

function ModLina.Config.GetMode()
	EnsureConfigLoaded()
	return ModLinaState.mode or CONFIG_DEFAULTS.mode
end

function ModLina.Config.SetMode(new_mode)
	if new_mode == "A" or new_mode == "B" or new_mode == "C" then
		EnsureConfigLoaded()
		ModLinaState.mode = new_mode
		ModLina.Config.SaveSettings()
		return true
	end
	return false
end

function ModLina.Config.GetThreshold(threshold_key)
	EnsureConfigLoaded()
	local val = table.get(ModLinaState, "thresholds", threshold_key)
	if val == nil then
		val = table.get(CONFIG_DEFAULTS, "thresholds", threshold_key)
	end
	return val
end

function ModLina.Config.GetCooldown(cooldown_key)
	EnsureConfigLoaded()
	local val = table.get(ModLinaState, "cooldowns", cooldown_key)
	if val == nil then
		val = table.get(CONFIG_DEFAULTS, "cooldowns", cooldown_key)
	end
	return val
end

function ModLina.Config.IsAlertEnabled(alert_type)
	EnsureConfigLoaded()
	local val = table.get(ModLinaState, "alerts_enabled", alert_type)
	if val == nil then
		val = table.get(CONFIG_DEFAULTS, "alerts_enabled", alert_type)
	end
	return val
end

function ModLina.Config.GetAPICredential(key)
	EnsureConfigLoaded()
	local val = table.get(ModLinaState, "api", key)
	if val == nil then
		val = table.get(CONFIG_DEFAULTS, "api", key)
	end
	return val
end

function ModLina.Config.IsDebugEnabled()
	return ModLinaState.debug or CONFIG_DEFAULTS.debug
end

function ModLina.Config.GetAISetting(key)
	EnsureConfigLoaded()
	local val = table.get(ModLinaState, "ai", key)
	if val == nil then
		val = table.get(CONFIG_DEFAULTS, "ai", key)
	end
	return val
end

function ModLina.Config.IsAIEnabled()
	return ModLina.Config.GetAISetting("enabled") and true or false
end

function ModLina.Config.GetSecretsStatus()
	if not rawget(_G, "ModLinaState") or not ModLinaState then
		return "unknown", "state_unavailable"
	end
	return ModLinaState.ai_secrets_status or "unknown", ModLinaState.ai_secrets_reason
end

function ModLina.Config.IsNormalNotificationsEnabled()
	EnsureConfigLoaded()
	local val = table.get(ModLinaState, "ui", "normal_notifications")
	if val == nil then
		val = table.get(CONFIG_DEFAULTS, "ui", "normal_notifications")
	end
	return val
end

function ModLina.Config.IsHudVisible()
	EnsureConfigLoaded()
	local val = table.get(ModLinaState, "ui", "show_hud")
	if val == nil then
		val = table.get(CONFIG_DEFAULTS, "ui", "show_hud")
	end
	return val
end

function ModLina.Config.GetHudMode()
	EnsureConfigLoaded()
	local val = table.get(ModLinaState, "ui", "hud_mode")
	if val ~= "compact" and val ~= "verbose" then
		val = table.get(CONFIG_DEFAULTS, "ui", "hud_mode") or "compact"
	end
	return val
end

---------------------------------------------------------------------------
-- SETTINGS SETTERS
---------------------------------------------------------------------------

function ModLina.Config.SetThreshold(threshold_key, value)
	EnsureConfigLoaded()
	-- Validate bounds
	if threshold_key == "stress" and value >= 0 and value <= 100 then
		ModLinaState.thresholds.stress = value
		ModLina.Config.SaveSettings()
		return true
	elseif threshold_key == "hunger" and value >= 0 and value <= 100 then
		ModLinaState.thresholds.hunger = value
		ModLina.Config.SaveSettings()
		return true
	elseif threshold_key == "cloth" and value >= 0 then
		ModLinaState.thresholds.cloth = value
		ModLina.Config.SaveSettings()
		return true
	end
	return false
end

function ModLina.Config.SetCooldown(cooldown_key, value)
	EnsureConfigLoaded()
	if value >= 0 then
		ModLinaState.cooldowns[cooldown_key] = value
		ModLina.Config.SaveSettings()
		return true
	end
	return false
end

function ModLina.Config.SetAlertEnabled(alert_type, enabled)
	EnsureConfigLoaded()
	ModLinaState.alerts_enabled[alert_type] = enabled
	ModLina.Config.SaveSettings()
	return true
end

function ModLina.Config.SetAPICredential(key, value)
	EnsureConfigLoaded()
	ModLinaState.api[key] = value or ""
	ModLina.Config.SaveSettings()
	return true
end

function ModLina.Config.SetDebugEnabled(enabled)
	ModLinaState.debug = enabled
	ModLina.Config.SaveSettings()
	return true
end

function ModLina.Config.SetAIEnabled(enabled)
	EnsureConfigLoaded()
	ModLinaState.ai.enabled = enabled and true or false
	ModLina.Config.SaveSettings()
	return true
end

function ModLina.Config.SetAISetting(key, value)
	EnsureConfigLoaded()
	if key == "cooldown_seconds" then
		value = Max(0, tonumber(value) or CONFIG_DEFAULTS.ai.cooldown_seconds)
	elseif key == "max_calls_per_hour" then
		value = Max(0, tonumber(value) or CONFIG_DEFAULTS.ai.max_calls_per_hour)
	elseif key == "max_calls_per_day" then
		value = Max(0, tonumber(value) or CONFIG_DEFAULTS.ai.max_calls_per_day)
	elseif key == "timeout_seconds" then
		value = Max(1, tonumber(value) or CONFIG_DEFAULTS.ai.timeout_seconds)
	elseif key == "allow_mutating_actions" then
		value = value and true or false
	else
		return false
	end

	ModLinaState.ai[key] = value
	ModLina.Config.SaveSettings()
	return true
end

function ModLina.Config.SetNormalNotificationsEnabled(enabled)
	EnsureConfigLoaded()
	ModLinaState.ui.normal_notifications = enabled and true or false
	ModLina.Config.SaveSettings()
	return true
end

function ModLina.Config.SetHudVisible(enabled)
	EnsureConfigLoaded()
	ModLinaState.ui.show_hud = enabled and true or false
	ModLina.Config.SaveSettings()
	return true
end

function ModLina.Config.SetHudMode(mode)
	EnsureConfigLoaded()
	if mode ~= "compact" and mode ~= "verbose" then
		return false
	end
	ModLinaState.ui.hud_mode = mode
	ModLina.Config.SaveSettings()
	return true
end

---------------------------------------------------------------------------
-- PERSISTENCE
---------------------------------------------------------------------------

function ModLina.Config.LoadSettings()
	-- Load from game storage if available
	if rawget(_G, "CurrentModStorageTable") and CurrentModStorageTable then
		CurrentModStorageTable.ModLina = CurrentModStorageTable.ModLina or {}
		local stored = CurrentModStorageTable.ModLina
		
		-- Merge stored settings into ModLinaState
		if stored.mode then ModLinaState.mode = stored.mode end
		if stored.thresholds then ModLinaState.thresholds = table.copy(stored.thresholds) end
		if stored.cooldowns then ModLinaState.cooldowns = table.copy(stored.cooldowns) end
		if stored.alerts_enabled then ModLinaState.alerts_enabled = table.copy(stored.alerts_enabled) end
		if stored.api then ModLinaState.api = table.copy(stored.api) end
		if stored.ai then ModLinaState.ai = table.copy(stored.ai) end
		if stored.ui then ModLinaState.ui = table.copy(stored.ui) end
		if stored.debug ~= nil then ModLinaState.debug = stored.debug end
	end
	
	-- Ensure all fields exist
	EnsureConfigLoaded()

	-- Load local secrets file after storage merge so local file can override saved values.
	if ModLina.Config.LoadSecretsFile then
		ModLina.Config.LoadSecretsFile()
	end
end

function ModLina.Config.LoadSecretsFile()
	EnsureConfigLoaded()
	if rawget(_G, "print") then
		print("[ModLina:AI_Config] Loading AI secrets file")
	end

	local preloaded_secrets = rawget(_G, "ModLinaLocalAISecrets")
	if type(preloaded_secrets) == "table" then
		local apply_ok, apply_reason = ApplySecretsTable(preloaded_secrets)
		if apply_ok then
			SetSecretsStatus("loaded", nil)
			if rawget(_G, "print") then
				print("[ModLina:AI_Config] AI secrets loaded successfully")
				print("[ModLina:AI_Config] Active AI secrets path: preloaded_global:ModLinaLocalAISecrets")
			end
			return true, nil
		end
		SetSecretsStatus("invalid", apply_reason)
		if rawget(_G, "print") then
			print("[ModLina:AI_Config] Preloaded AI secrets invalid: " .. tostring(apply_reason))
		end
		return false, apply_reason
	end

	local function ParseSecretsFromText(text)
		if type(text) ~= "string" or text == "" then
			return nil, "secrets_file_empty"
		end

		local load_fn = rawget(_G, "load")
		if type(load_fn) == "function" then
			local chunk
			local ok_chunk, chunk_or_err = pcall(load_fn, text, "=(ai.secrets.lua)", "t", {})
			if ok_chunk and type(chunk_or_err) == "function" then
				chunk = chunk_or_err
			else
				ok_chunk, chunk_or_err = pcall(load_fn, text, "=(ai.secrets.lua)")
				if ok_chunk and type(chunk_or_err) == "function" then
					chunk = chunk_or_err
				end
			end

			if type(chunk) == "function" then
				local ok_run, result = pcall(chunk)
				if ok_run and type(result) == "table" then
					return result, nil
				end
			end
		end

		local loadstring_fn = rawget(_G, "loadstring")
		if type(loadstring_fn) == "function" then
			local ok_chunk, chunk_or_err = pcall(loadstring_fn, text, "=(ai.secrets.lua)")
			if ok_chunk and type(chunk_or_err) == "function" then
				local ok_run, result = pcall(chunk_or_err)
				if ok_run and type(result) == "table" then
					return result, nil
				end
			end
		end

		-- Last-resort parser for simple key="value" secrets tables.
		local parsed = {}
		for key, value in text:gmatch("([%a_][%w_]*)%s*=%s*\"([^\"]*)\"") do
			parsed[key] = value
		end
		for key, value in text:gmatch("([%a_][%w_]*)%s*=%s*'([^']*)'") do
			parsed[key] = value
		end

		if next(parsed) then
			return parsed, nil
		end

		return nil, "secrets_parse_failed"
	end

	local function TryLoadSecretsViaFileRead(path)
		local io_table = rawget(_G, "io")
		if type(io_table) ~= "table" or type(io_table.open) ~= "function" then
			return false, "io_open_unavailable"
		end

		local f = io_table.open(path, "r")
		if not f then
			return false, "secrets_file_not_found"
		end

		local ok_read, text = pcall(f.read, f, "*a")
		pcall(f.close, f)
		if not ok_read then
			return false, "secrets_file_read_failed"
		end

		local parsed, parse_reason = ParseSecretsFromText(text)
		if type(parsed) == "table" then
			return true, parsed
		end
		return false, parse_reason or "secrets_parse_failed"
	end

	local dofile_fn = rawget(_G, "dofile")
	if type(dofile_fn) ~= "function" and rawget(_G, "print") then
		print("[ModLina:AI_Config] dofile unavailable; using fallback secrets loader")
	end

	local candidate_paths = {
		"ai.secrets.lua",
	}

	if rawget(_G, "CurrentModPath") and type(CurrentModPath) == "string" and CurrentModPath ~= "" then
		candidate_paths[#candidate_paths + 1] = CurrentModPath .. "ai.secrets.lua"
	end

	local saw_non_missing_error = false
	local last_load_error = nil

	for i = 1, #candidate_paths do
		local path = candidate_paths[i]
		if rawget(_G, "print") then
			print("[ModLina:AI_Config] Trying AI secrets path: " .. tostring(path))
		end

		local loaded = nil
		local load_reason = nil

		if type(dofile_fn) == "function" then
			local ok, result = pcall(dofile_fn, path)
			if ok and type(result) == "table" then
				loaded = result
			elseif ok and result ~= nil then
				load_reason = "secrets_not_table"
			else
				load_reason = tostring(result)
			end
		end

		if type(loaded) ~= "table" then
			local read_ok, read_result = TryLoadSecretsViaFileRead(path)
			if read_ok and type(read_result) == "table" then
				loaded = read_result
				load_reason = nil
			else
				load_reason = read_result or load_reason
			end
		end

		if type(loaded) == "table" then
			local apply_ok, apply_reason = ApplySecretsTable(loaded)
			if apply_ok then
				SetSecretsStatus("loaded", nil)
				if rawget(_G, "print") then
					print("[ModLina:AI_Config] AI secrets loaded successfully")
					print("[ModLina:AI_Config] Active AI secrets path: " .. tostring(path))
				end
				return true, nil
			end
			SetSecretsStatus("invalid", apply_reason)
			if rawget(_G, "print") then
				print("[ModLina:AI_Config] AI secrets invalid: " .. tostring(apply_reason))
			end
			return false, apply_reason
		end

		if load_reason and load_reason ~= "secrets_file_not_found" then
			saw_non_missing_error = true
			last_load_error = load_reason
		end
	end

	if saw_non_missing_error then
		SetSecretsStatus("unavailable", last_load_error or "secrets_loader_unavailable")
		if rawget(_G, "print") then
			print("[ModLina:AI_Config] AI secrets could not be loaded: " .. tostring(last_load_error))
		end
		if ModLinaState.api and ModLinaState.api.key and ModLinaState.api.key ~= "" then
			SetSecretsStatus("fallback_storage", nil)
			if rawget(_G, "print") then
				print("[ModLina:AI_Config] Using stored API credentials fallback")
			end
			return true, nil
		end

		if ModLinaState.api then
			ModLinaState.api.provider = "LocalBridge"
			if type(ModLinaState.api.endpoint) ~= "string" or ModLinaState.api.endpoint == "" then
				ModLinaState.api.endpoint = "http://127.0.0.1:8787"
			end
			if type(ModLinaState.api.deployment) ~= "string" or ModLinaState.api.deployment == "" then
				ModLinaState.api.deployment = "gpt-5-mini"
			end
			if type(ModLinaState.api.model) ~= "string" or ModLinaState.api.model == "" then
				ModLinaState.api.model = "gpt-5-mini"
			end
			if type(ModLinaState.api.api_version) ~= "string" or ModLinaState.api.api_version == "" then
				ModLinaState.api.api_version = "2025-01-01-preview"
			end
			if rawget(_G, "print") then
				print("[ModLina:AI_Config] Switched API provider to LocalBridge due to sandboxed secrets loading")
			end
		end

		return false, last_load_error or "secrets_loader_unavailable"
	end

	if ModLinaState.api and ModLinaState.api.key and ModLinaState.api.key ~= "" then
		SetSecretsStatus("fallback_storage", nil)
		if rawget(_G, "print") then
			print("[ModLina:AI_Config] AI secrets file missing, using stored API credentials fallback")
		end
		return true, nil
	end

	SetSecretsStatus("missing", "secrets_file_not_found")
	if rawget(_G, "print") then
		print("[ModLina:AI_Config] AI secrets file not found")
	end
	return false, "secrets_file_not_found"
end

function ModLina.Config.SaveSettings()
	-- Persist to game storage
	if rawget(_G, "CurrentModStorageTable") and CurrentModStorageTable then
		CurrentModStorageTable.ModLina = CurrentModStorageTable.ModLina or {}
		local storage = CurrentModStorageTable.ModLina
		
		storage.mode = ModLinaState.mode
		storage.thresholds = table.copy(ModLinaState.thresholds or {})
		storage.cooldowns = table.copy(ModLinaState.cooldowns or {})
		storage.alerts_enabled = table.copy(ModLinaState.alerts_enabled or {})
		storage.api = table.copy(ModLinaState.api or {})
		storage.ai = table.copy(ModLinaState.ai or {})
		storage.ui = table.copy(ModLinaState.ui or {})
		storage.debug = ModLinaState.debug
		
		if rawget(_G, "WriteModPersistentStorageTable") then
			WriteModPersistentStorageTable()
		end
	end
end
