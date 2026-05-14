return {
PlaceObj('ModItemCode', {
	'name', "ModLina_Main",
	'CodeFileName', "Code/main.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_Core",
	'CodeFileName', "Code/ModLina_Core.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_Config",
	'CodeFileName', "Code/ModLina_Config.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_Notifications",
	'CodeFileName', "Code/ModLina_Notifications.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_Advisor",
	'CodeFileName', "Code/ModLina_Advisor.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_SemiAuto",
	'CodeFileName', "Code/ModLina_SemiAuto.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_FullAuto",
	'CodeFileName', "Code/ModLina_FullAuto.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_Settings",
	'CodeFileName', "Code/ModLina_Settings.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_SettingsUI",
	'CodeFileName', "Code/ModLina_SettingsUI.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_Integration",
	'CodeFileName', "Code/ModLina_Integration.lua",
}),
PlaceObj('ModItemCode', {
	'name', "ModLina_HUD",
	'CodeFileName', "Code/ModLina_HUD.lua",
}),

-- Settings using individual ModItemOption* entries (matches SAD_CommonLib pattern)
PlaceObj('ModItemOptionChoice', {
	'name', "Mode",
	'DisplayName', T(732519874114, "Mode"),
	'Help', T(732519874114, "Mode"),
	'DefaultValue', "A",
	'ChoiceList', {
		"A",
		"B",
		"C",
	},
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetMode(value)
		end
	end,
}),
PlaceObj('ModItemOptionNumber', {
	'name', "StressThreshold",
	'DisplayName', T(732519874115, "Stress Alert Threshold"),
	'Help', T(732519874115, "Stress Alert Threshold"),
	'DefaultValue', 60,
	'MinValue', 0,
	'MaxValue', 100,
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetThreshold("stress", tonumber(value) or 60)
		end
	end,
}),
PlaceObj('ModItemOptionNumber', {
	'name', "HungerThreshold",
	'DisplayName', T(732519874116, "Hunger Alert Threshold"),
	'Help', T(732519874116, "Hunger Alert Threshold"),
	'DefaultValue', 20,
	'MinValue', 0,
	'MaxValue', 100,
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetThreshold("hunger", tonumber(value) or 20)
		end
	end,
}),
PlaceObj('ModItemOptionNumber', {
	'name', "ClothThreshold",
	'DisplayName', T(732519874117, "Cloth Alert Threshold"),
	'Help', T(732519874117, "Cloth Alert Threshold"),
	'DefaultValue', 20,
	'MinValue', 0,
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetThreshold("cloth", tonumber(value) or 20)
		end
	end,
}),
PlaceObj('ModItemOptionToggle', {
	'name', "EnableSurvivorAlerts",
	'DisplayName', T(732519874118, "Enable Survivor Alerts"),
	'Help', T(732519874118, "Enable Survivor Alerts"),
	'DefaultValue', true,
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetAlertEnabled("survivors", value)
		end
	end,
}),
PlaceObj('ModItemOptionToggle', {
	'name', "EnableResourceAlerts",
	'DisplayName', T(732519874119, "Enable Resource Alerts"),
	'Help', T(732519874119, "Enable Resource Alerts"),
	'DefaultValue', true,
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetAlertEnabled("resources", value)
		end
	end,
}),
PlaceObj('ModItemOptionToggle', {
	'name', "EnableProductionAlerts",
	'DisplayName', T(732519874123, "Enable Production Alerts"),
	'Help', T(732519874123, "Enable Production Alerts"),
	'DefaultValue', true,
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetAlertEnabled("production", value)
		end
	end,
}),
PlaceObj('ModItemOptionToggle', {
	'name', "EnableNormalNotifications",
	'DisplayName', "Enable Normal Notifications",
	'Help', "Show Lina alerts as normal popup notifications.",
	'DefaultValue', true,
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetNormalNotificationsEnabled(value)
		end
	end,
}),
PlaceObj('ModItemOptionToggle', {
	'name', "ShowLinaHUD",
	'DisplayName', "Show Lina HUD",
	'Help', "Show or hide the in-play Lina HUD widget.",
	'DefaultValue', true,
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetHudVisible(value)
		end
		if ModLina and ModLina.HUD then
			if value then
				ModLina.HUD.Start()
			else
				ModLina.HUD.Stop()
			end
		end
	end,
}),
PlaceObj('ModItemOptionChoice', {
	'name', "LinaHUDMode",
	'DisplayName', "Lina HUD Mode",
	'Help', "Choose compact or verbose HUD layout.",
	'DefaultValue', "compact",
	'ChoiceList', {
		"compact",
		"verbose",
	},
	'OnApply', function(self, value, prev_value)
		if ModLina and ModLina.Config then
			ModLina.Config.SetHudMode(value)
		end
		if ModLina and ModLina.HUD and ModLina.Config and ModLina.Config.IsHudVisible() then
			ModLina.HUD.Start()
		end
	end,
}),
}
