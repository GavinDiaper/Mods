-- ModLina_SettingsUI.lua
-- In-game settings panel using XTemplate

ModLina = rawget(_G, "ModLina") or {}

ModLina.SettingsUI = ModLina.SettingsUI or {}

---------------------------------------------------------------------------
-- HELPER: Create settings options list
---------------------------------------------------------------------------

function ModLina.SettingsUI.GetOptions()
	return {
		{
			name = "Mode",
			value = "mode",
			default = "A",
			type = "choice",
			choices = {
				{ value = "A", label = "Advisor (Monitoring Only)" },
				{ value = "B", label = "Semi-Auto (Scaffolding)" },
				{ value = "C", label = "Full-Auto (Scaffolding)" },
			},
		},
		{
			name = "Stress Alert Threshold",
			value = "stress_threshold",
			default = 80,
			type = "number",
			min = 0,
			max = 100,
		},
		{
			name = "Hunger Alert Threshold",
			value = "hunger_threshold",
			default = 20,
			type = "number",
			min = 0,
			max = 100,
		},
		{
			name = "Cloth Alert Threshold",
			value = "cloth_threshold",
			default = 20,
			type = "number",
			min = 0,
		},
		{
			name = "Survivor Alert Cooldown (seconds)",
			value = "survivor_cooldown",
			default = 300,
			type = "number",
			min = 30,
		},
		{
			name = "Resource Alert Cooldown (seconds)",
			value = "resource_cooldown",
			default = 600,
			type = "number",
			min = 30,
		},
		{
			name = "Enable Survivor Alerts",
			value = "alerts_survivors",
			default = true,
			type = "bool",
		},
		{
			name = "Enable Resource Alerts",
			value = "alerts_resources",
			default = true,
			type = "bool",
		},
		{
			name = "Enable Production Alerts",
			value = "alerts_production",
			default = true,
			type = "bool",
		},
		{
			name = "Debug Logging",
			value = "debug",
			default = false,
			type = "bool",
		},
	}
end

---------------------------------------------------------------------------
-- HELPER: Get/Set individual setting
---------------------------------------------------------------------------

function ModLina.SettingsUI.GetSettingValue(setting_id)
	if setting_id == "mode" then
		return ModLina.Config.GetMode()
	elseif setting_id == "stress_threshold" then
		return ModLina.Config.GetThreshold("stress")
	elseif setting_id == "hunger_threshold" then
		return ModLina.Config.GetThreshold("hunger")
	elseif setting_id == "cloth_threshold" then
		return ModLina.Config.GetThreshold("cloth")
	elseif setting_id == "survivor_cooldown" then
		return ModLina.Config.GetCooldown("survivor")
	elseif setting_id == "resource_cooldown" then
		return ModLina.Config.GetCooldown("resources")
	elseif setting_id == "alerts_survivors" then
		return ModLina.Config.IsAlertEnabled("survivors")
	elseif setting_id == "alerts_resources" then
		return ModLina.Config.IsAlertEnabled("resources")
	elseif setting_id == "alerts_production" then
		return ModLina.Config.IsAlertEnabled("production")
	elseif setting_id == "debug" then
		return ModLina.Config.IsDebugEnabled()
	end
	return nil
end

function ModLina.SettingsUI.SetSettingValue(setting_id, value)
	if setting_id == "mode" then
		if value == "A" or value == "B" or value == "C" then
			ModLinaState.mode = value
			ModLina.Config.SaveSettings()
			return true
		end
	elseif setting_id == "stress_threshold" then
		return ModLina.Config.SetThreshold("stress", tonumber(value) or 80)
	elseif setting_id == "hunger_threshold" then
		return ModLina.Config.SetThreshold("hunger", tonumber(value) or 20)
	elseif setting_id == "cloth_threshold" then
		return ModLina.Config.SetThreshold("cloth", tonumber(value) or 20)
	elseif setting_id == "survivor_cooldown" then
		return ModLina.Config.SetCooldown("survivor", tonumber(value) or 300)
	elseif setting_id == "resource_cooldown" then
		return ModLina.Config.SetCooldown("resources", tonumber(value) or 600)
	elseif setting_id == "alerts_survivors" then
		return ModLina.Config.SetAlertEnabled("survivors", value)
	elseif setting_id == "alerts_resources" then
		return ModLina.Config.SetAlertEnabled("resources", value)
	elseif setting_id == "alerts_production" then
		return ModLina.Config.SetAlertEnabled("production", value)
	elseif setting_id == "debug" then
		return ModLina.Config.SetDebugEnabled(value)
	end
	return false
end

---------------------------------------------------------------------------
-- SETTINGS GROUP (XTemplate)
---------------------------------------------------------------------------

if rawget(_G, "DefineClass") then
	DefineClass.ModLinaSettingsGroup = {
		__parents = { "SettingsGroup" },
		properties = {
			{ category = "General", id = "name", default = "ModLina Settings" },
		},
	}

	function ModLinaSettingsGroup:GetItems()
		local items = {}
		for _, opt in ipairs(ModLina.SettingsUI.GetOptions()) do
			table.insert(items, {
				id = opt.value,
				name = T(732519874114 + _, opt.name),
				default = opt.default,
				type = opt.type,
				min = opt.min,
				max = opt.max,
				choices = opt.choices,
			})
		end
		return items
	end

	function ModLinaSettingsGroup:GetValue(id)
		return ModLina.SettingsUI.GetSettingValue(id)
	end

	function ModLinaSettingsGroup:SetValue(id, value)
		ModLina.SettingsUI.SetSettingValue(id, value)
	end
end
