-- ModLina_Settings.lua
-- In-game settings UI dialog and menu integration

ModLina = rawget(_G, "ModLina") or {}

ModLina.Settings = ModLina.Settings or {}

---------------------------------------------------------------------------
-- SETTINGS DIALOG CLASS (XTemplate-based)
---------------------------------------------------------------------------

-- Check if we can create UI templates
if rawget(_G, "XDialog") then
	
	DefineClass.ModLinaSettingsDialog = {
		__parents = { "XDialog" },
		Properties = {
			{ category = "ModLina", id = "mode_selector", default = "A" },
			{ category = "ModLina", id = "stress_threshold", default = 80 },
			{ category = "ModLina", id = "hunger_threshold", default = 20 },
			{ category = "ModLina", id = "cloth_threshold", default = 20 },
		},
	}

	function ModLinaSettingsDialog:Init()
		self:SetTitle(T(732519874107, "Mod_Lina Settings"))
	end

	function ModLinaSettingsDialog:OnOpen()
		-- Populate UI from current settings
		if self.idModeSelect then
			self.idModeSelect:SetValue(ModLina.Config.GetMode())
		end
		if self.idStressThreshold then
			self.idStressThreshold:SetValue(ModLina.Config.GetThreshold("stress"))
		end
		if self.idHungerThreshold then
			self.idHungerThreshold:SetValue(ModLina.Config.GetThreshold("hunger"))
		end
		if self.idClothThreshold then
			self.idClothThreshold:SetValue(ModLina.Config.GetThreshold("cloth"))
		end
	end

	function ModLinaSettingsDialog:ApplySettings()
		-- Save from UI
		if self.idModeSelect then
			local mode = self.idModeSelect:GetValue()
			if mode == "A" or mode == "B" or mode == "C" then
				ModLinaState.mode = mode
			end
		end

		if self.idStressThreshold then
			local val = tonumber(self.idStressThreshold:GetValue()) or 80
			ModLina.Config.SetThreshold("stress", val)
		end

		if self.idHungerThreshold then
			local val = tonumber(self.idHungerThreshold:GetValue()) or 20
			ModLina.Config.SetThreshold("hunger", val)
		end

		if self.idClothThreshold then
			local val = tonumber(self.idClothThreshold:GetValue()) or 20
			ModLina.Config.SetThreshold("cloth", val)
		end

		ModLina.Config.SaveSettings()
		ModLina.Notify.LinaSay(T(732519874112, "Settings saved successfully."))
	end

end

---------------------------------------------------------------------------
-- HELPER: Open settings dialog
---------------------------------------------------------------------------

function ModLina.Settings.OpenDialog()
	if not rawget(_G, "XDialog") then
		ModLina.Notify.DebugLog("UI system not available, cannot open settings dialog")
		return
	end

	-- For v1, we'll use a simple notification instead of full dialog
	-- Future versions can expand with full XTemplate UI
	ModLina.Notify.LinaSay(T(732519874113, "Settings UI coming soon. Use command: ModLina.Config.SetThreshold('stress', 75)"))
end

---------------------------------------------------------------------------
-- CONSOLE COMMANDS FOR SETTINGS (fallback for v1)
---------------------------------------------------------------------------

function ModLina_SetMode(mode)
	if mode == "A" or mode == "B" or mode == "C" then
		ModLina.SetMode(mode)
		print("ModLina mode set to: " .. mode)
	else
		print("Invalid mode. Use 'A', 'B', or 'C'.")
	end
end

function ModLina_SetThreshold(threshold_name, value)
	value = tonumber(value)
	if value and ModLina.Config.SetThreshold(threshold_name, value) then
		print("ModLina threshold '" .. threshold_name .. "' set to: " .. value)
	else
		print("Failed to set threshold. Check name and value.")
	end
end

function ModLina_GetSettings()
	print("=== ModLina Settings ===")
	print("Mode: " .. ModLina.Config.GetMode())
	print("Stress threshold: " .. ModLina.Config.GetThreshold("stress"))
	print("Hunger threshold: " .. ModLina.Config.GetThreshold("hunger"))
	print("Cloth threshold: " .. ModLina.Config.GetThreshold("cloth"))
	print("Alerts (survivors): " .. tostring(ModLina.Config.IsAlertEnabled("survivors")))
	print("Alerts (resources): " .. tostring(ModLina.Config.IsAlertEnabled("resources")))
	print("Alerts (production): " .. tostring(ModLina.Config.IsAlertEnabled("production")))
	print("Normal notifications: " .. tostring(ModLina.Config.IsNormalNotificationsEnabled and ModLina.Config.IsNormalNotificationsEnabled()))
	print("Show HUD: " .. tostring(ModLina.Config.IsHudVisible and ModLina.Config.IsHudVisible()))
	print("HUD mode: " .. tostring(ModLina.Config.GetHudMode and ModLina.Config.GetHudMode()))
end

function ModLina_TestNotification()
	if ModLina and ModLina.Notify and ModLina.Notify.LinaSay then
		ModLina.Notify.LinaSay("Manual test notification from Lina.")
		print("ModLina test notification sent.")
	else
		print("ModLina notification system is not initialized.")
	end
end

function ModLina_TestChecks()
	if ModLina and ModLina.Advisor and ModLina.Advisor.CheckAll then
		ModLina.Advisor.CheckAll()
		print("ModLina advisor checks executed.")
	else
		print("ModLina advisor system is not initialized.")
	end
end

function ModLina_TestHUD()
	if ModLina and ModLina.HUD and ModLina.HUD.Start then
		ModLina.HUD.Stop()
		ModLina.HUD.Start()
		print("ModLina HUD restarted.")
	else
		print("ModLina HUD is not initialized.")
	end
end
