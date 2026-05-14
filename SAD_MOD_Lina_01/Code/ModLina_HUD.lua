-- ModLina_HUD.lua
-- Compact in-play Lina HUD widget (InfoBeacon style).

if not rawget(_G, "ModLina") then
	ModLina = {}
end

ModLina.HUD = ModLina.HUD or {}

local REFRESH_MS = 2000
local HUD_ID = "idModLinaHud"
local HUD_TEXT_ID = "idModLinaHudText"

local function IsHudEnabled()
	if ModLina.Config and ModLina.Config.IsHudVisible then
		return ModLina.Config.IsHudVisible()
	end
	return true
end

local function GetHudMode()
	if ModLina.Config and ModLina.Config.GetHudMode then
		return ModLina.Config.GetHudMode()
	end
	return "compact"
end

local function GetModeText()
	if ModLina.Config and ModLina.Config.GetMode then
		return tostring(ModLina.Config.GetMode())
	end
	return "A"
end

local function GetSurvivors()
	local player = rawget(_G, "UIPlayer") and UIPlayer
	if not player or not player.labels or not player.labels.Survivors then
		return empty_table or {}
	end
	return player.labels.Survivors
end

local function CountVitals()
	local stress_threshold = (ModLina.Config and ModLina.Config.GetThreshold and ModLina.Config.GetThreshold("stress")) or 80
	local hunger_threshold = (ModLina.Config and ModLina.Config.GetThreshold and ModLina.Config.GetThreshold("hunger")) or 20
	local hungry = 0
	local stressed = 0
	for _, survivor in ipairs(GetSurvivors()) do
		if survivor and IsValid(survivor) and not survivor:IsDead() then
			local energy = survivor.EnergyAvailable
			local max_energy = survivor.MaxEnergyAvailable
			if energy ~= nil and max_energy and max_energy > 0 then
				local hunger_pct = (energy * 100) / max_energy
				if hunger_pct < hunger_threshold then
					hungry = hungry + 1
				end
			end
			local mood = survivor.GetIPHappiness and survivor:GetIPHappiness() or nil
			if mood ~= nil and (100 - mood) > stress_threshold then
				stressed = stressed + 1
			end
		end
	end
	return hungry, stressed
end

local function GetClothCount()
	if rawget(_G, "Resources") and Resources then
		return tonumber(Resources["Cloth"]) or 0
	end
	return 0
end

local function TrimText(text, max_len)
	text = tostring(text or "")
	if #text <= max_len then
		return text
	end
	return string.sub(text, 1, max_len - 3) .. "..."
end

local function BuildHudText()
	local hungry, stressed = CountVitals()
	local cloth = GetClothCount()
	local mode = GetModeText()
	local latest = (rawget(_G, "ModLinaState") and ModLinaState.latest_alert_text) or "No alerts yet"
	local hud_mode = GetHudMode()
	if hud_mode == "verbose" then
		return string.format("<color 110 190 255>Lina Assistant</color>\nMode: %s\nHungry: %d | Stressed: %d\nCloth: %d\nLast: %s", mode, hungry, stressed, cloth, TrimText(latest, 180))
	end
	latest = TrimText(latest, 72)
	return string.format("<color 110 190 255>Lina</color>  M:%s  H:%d  S:%d  Cloth:%d\n<color 220 220 170>Last:</color> %s", mode, hungry, stressed, cloth, latest)
end

local function BuildRolloverText()
	local mode = GetModeText()
	local hungry, stressed = CountVitals()
	local cloth = GetClothCount()
	local latest = (rawget(_G, "ModLinaState") and ModLinaState.latest_alert_text) or "No alerts yet"
	local last_time = (rawget(_G, "ModLinaState") and ModLinaState.latest_alert_time) or 0
	local ago = "n/a"
	if last_time and last_time > 0 then
		local sec = Max(0, (RealTime() - last_time) / 1000)
		ago = string.format("%.0fs", sec)
	end
	return string.format("Mode: %s\nHungry survivors: %d\nStressed survivors: %d\nCloth: %d\nLatest alert (%s ago):\n%s", mode, hungry, stressed, cloth, ago, tostring(latest))
end

local function GetHudParent(igi)
	if not igi then
		return nil
	end
	return igi:ResolveId("idTopRight") or igi
end

local function EnsureHUD()
	if not IsHudEnabled() then
		if ModLina.HUD and ModLina.HUD.widget and ModLina.HUD.widget.window_state ~= "destroying" then
			DoneObject(ModLina.HUD.widget)
			ModLina.HUD.widget = false
		end
		return false
	end

	local igi = rawget(_G, "GetInGameInterface") and GetInGameInterface()
	if not igi then
		return false
	end
	local parent = GetHudParent(igi)
	if not parent then
		return false
	end

	local existing = igi:ResolveId(HUD_ID)
	if existing then
		ModLina.HUD.widget = existing
		return true
	end

	local hud = XContextWindow:new({
		Id = HUD_ID,
		IdNode = true,
		HAlign = "right",
		VAlign = "top",
		Margins = box(0, 140, 12, 0),
		Padding = box(8, 6, 8, 6),
		LayoutMethod = "VList",
		Background = RGBA(0, 0, 0, 160),
		BorderWidth = 1,
		BorderColor = RGBA(110, 190, 255, 120),
		HandleMouse = true,
		RolloverTemplate = "Rollover",
		RolloverTranslate = false,
	}, parent)

	XText:new({
		Id = HUD_TEXT_ID,
		HandleMouse = false,
		TextStyle = "HUDText",
		Translate = false,
		Text = "",
		TextHAlign = "right",
		TextVAlign = "center",
	}, hud)

	function hud:GetRolloverText()
		return BuildRolloverText()
	end

	ModLina.HUD.widget = hud
	return true
end

function ModLina.HUD.Refresh()
	if not IsHudEnabled() then
		return
	end

	if not ModLina.HUD.widget or ModLina.HUD.widget.window_state == "destroying" then
		return
	end
	local txt = ModLina.HUD.widget:ResolveId(HUD_TEXT_ID)
	if txt then
		txt:SetText(BuildHudText())
	end
end

function ModLina.HUD.Start()
	if not IsHudEnabled() then
		ModLina.HUD.Stop()
		return
	end

	if not EnsureHUD() then
		return
	end
	ModLina.HUD.Refresh()
	if ModLina.HUD.thread then
		DeleteThread(ModLina.HUD.thread)
		ModLina.HUD.thread = false
	end
	ModLina.HUD.thread = CreateRealTimeThread(function()
		while true do
			Sleep(REFRESH_MS)
			if not EnsureHUD() then
				break
			end
			pcall(ModLina.HUD.Refresh)
		end
	end)
end

function ModLina.HUD.Stop()
	if ModLina.HUD.thread then
		DeleteThread(ModLina.HUD.thread)
		ModLina.HUD.thread = false
	end
	if ModLina.HUD.widget and ModLina.HUD.widget.window_state ~= "destroying" then
		DoneObject(ModLina.HUD.widget)
	end
	ModLina.HUD.widget = false
end

function OnMsg.InGameInterfaceCreated()
	ModLina.HUD.Start()
end

function OnMsg.GameStarted()
	ModLina.HUD.Start()
end

function OnMsg.LoadGame()
	ModLina.HUD.Start()
end

function OnMsg.ChangeMap()
	ModLina.HUD.Stop()
end
