-- ModLina_Notifications.lua
-- Notification system with anti-spam cooldowns

ModLina = rawget(_G, "ModLina") or {}

ModLina.Notify = ModLina.Notify or {}

local function RecordLatestAlert(message)
	if not rawget(_G, "ModLinaState") or not ModLinaState then
		return
	end
	ModLinaState.latest_alert_text = tostring(message or "")
	ModLinaState.latest_alert_time = RealTime()
end

---------------------------------------------------------------------------
-- HELPER: Format and send notification
---------------------------------------------------------------------------

function ModLina.Notify.SendRaw(title, message)
	if ModLina.Config and ModLina.Config.IsNormalNotificationsEnabled and not ModLina.Config.IsNormalNotificationsEnabled() then
		return
	end

	-- Prefer standard on-screen notifications that do not open narrative/story popups.
	if rawget(_G, "AddOnScreenNotification") then
		AddOnScreenNotification(title, message)
		return
	end

	if rawget(_G, "AddCustomOnScreenNotification") then
		AddCustomOnScreenNotification(
			title,
			message,
			"UI/Common/dialog_info_icon"
		)
		return
	end

	if rawget(_G, "print") then
		print(string.format("[ModLina] %s: %s", tostring(title), tostring(message)))
	end
end

function ModLina.Notify.LinaSay(message)
	local title = "Lina"
	RecordLatestAlert(message)
	ModLina.Notify.SendRaw(title, message)
end

ModLina.LinaSay = ModLina.Notify.LinaSay

---------------------------------------------------------------------------
-- COOLDOWN TRACKING
---------------------------------------------------------------------------

local function GetCooldownKey(alert_type, subject_id)
	return alert_type .. "|" .. (subject_id or "global")
end

local function IsOnCooldown(cooldown_group, subject_id, event_key)
	local key = GetCooldownKey(event_key or cooldown_group, subject_id)
	local last_time = ModLinaState.alert_cooldowns[key]
	if not last_time then
		return false
	end
	
	local current_time = RealTime()
	local cooldown_duration = (ModLina.Config.GetCooldown(cooldown_group) or 0) * 1000
	
	if current_time - last_time >= cooldown_duration then
		return false
	end
	
	return true
end

local function UpdateCooldown(cooldown_group, subject_id, event_key)
	local key = GetCooldownKey(event_key or cooldown_group, subject_id)
	ModLinaState.alert_cooldowns[key] = RealTime()
end

---------------------------------------------------------------------------
-- NOTIFICATION ROUTING WITH CATEGORY CHECKS AND COOLDOWN
---------------------------------------------------------------------------

function ModLina.Notify.SurvivorAlert(survivor_name, message, alert_type)
	local event_key = "survivor:" .. tostring(alert_type or "general")
	
	if not ModLina.Config.IsAlertEnabled("survivors") then
		return
	end
	
	-- Check cooldown per survivor
	if IsOnCooldown("survivor", survivor_name, event_key) then
		return
	end
	
	UpdateCooldown("survivor", survivor_name, event_key)
	ModLina.Notify.LinaSay(survivor_name .. ": " .. message)
end

function ModLina.Notify.ResourceAlert(message)
	if not ModLina.Config.IsAlertEnabled("resources") then
		return
	end
	
	if IsOnCooldown("resources", "global") then
		return
	end
	
	UpdateCooldown("resources", "global")
	ModLina.Notify.LinaSay(message)
end

function ModLina.Notify.ProductionAlert(workbench_id, message)
	if not ModLina.Config.IsAlertEnabled("production") then
		return
	end
	
	if IsOnCooldown("production", workbench_id) then
		return
	end
	
	UpdateCooldown("production", workbench_id)
	ModLina.Notify.LinaSay(message)
end

---------------------------------------------------------------------------
-- DEBUG LOGGING (optional)
---------------------------------------------------------------------------

function ModLina.Notify.DebugLog(message)
	if ModLina.Config.IsDebugEnabled() then
		print("[ModLina Debug] " .. tostring(message))
	end
end
