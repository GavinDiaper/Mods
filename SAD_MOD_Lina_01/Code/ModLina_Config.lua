-- ModLina_Config.lua
-- Player configuration, settings persistence, and defaults

if not rawget(_G, "ModLina") then
	ModLina = {}
end

ModLina.Config = ModLina.Config or {}

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
		provider = "",    -- "OpenAI", "AzureOpenAI", "Claude", etc.
		key = "",
		endpoint = "",
		model = "",
	},

	-- AI call governance (cloud calls are disabled by default)
	ai = {
		enabled = false,
		cooldown_seconds = 120,
		max_calls_per_hour = 8,
		max_calls_per_day = 25,
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
