-- ModLina_HUD.lua
-- Compact in-play Lina HUD widget (InfoBeacon style).

if not rawget(_G, "ModLina") then
	ModLina = {}
end

ModLina.HUD = ModLina.HUD or {}

local REFRESH_MS = 2000
local HUD_ID = "idModLinaHud"
local HUD_TEXT_ID = "idModLinaHudText"
local function floor(val)
	return val - (val % 1)
end

local function clamp(val, min_val, max_val)
	if val < min_val then return min_val end
	if val > max_val then return max_val end
	return val
end

local function safe_percent(num, denom)
	if not denom or denom == 0 then
		return 0
	end
	return (num * 100) / denom
end

local function abs(val)
	if val < 0 then return -val end
	return val
end

local function GetResourceCount(resource_name, aliases)
	if not rawget(_G, "Resources") or not Resources then
		return 0
	end

	local names = { resource_name }
	if aliases then
		for i = 1, #aliases do
			names[#names + 1] = aliases[i]
		end
	end

	for i = 1, #names do
		local name = names[i]
		local direct = Resources[name]
		if direct ~= nil then
			local count = tonumber(direct) or 0
			if count > 0 or i == #names then
				return count
			end
		end

		if Resources.GetResourceAmount then
			local ok, value = pcall(Resources.GetResourceAmount, Resources, name)
			if ok and value ~= nil then
				local count = tonumber(value) or 0
				if count > 0 or i == #names then
					return count
				end
			end
		end

		if Resources.GetCount then
			local ok, value = pcall(Resources.GetCount, Resources, name)
			if ok and value ~= nil then
				local count = tonumber(value) or 0
				if count > 0 or i == #names then
					return count
				end
			end
		end
	end

	return 0
end

local function GetSurvivorName(survivor)
	if not survivor then
		return "Unknown"
	end
	if survivor.FirstName then
		if IsT and IsT(survivor.FirstName) and rawget(_G, "_InternalTranslate") then
			return _InternalTranslate(survivor.FirstName)
		end
		return tostring(survivor.FirstName)
	end
	if survivor.Name and IsT and IsT(survivor.Name) and rawget(_G, "_InternalTranslate") then
		return _InternalTranslate(survivor.Name)
	end
	return tostring(survivor.Name or "Unknown")
end

local function TrimName(name, max_len)
	name = tostring(name or "?")
	if #name <= max_len then
		return name
	end
	return string.sub(name, 1, max_len - 1) .. "."
end

local function GetEquipmentConditionPct(survivor)
	if survivor.GetEquipmentConditionPct then
		local ok, value = pcall(survivor.GetEquipmentConditionPct, survivor)
		if ok and value ~= nil then
			return clamp(value, 0, 100)
		end
	end
	local raw = survivor.EquipmentConditionPct or survivor.equipment_condition_pct or 100
	return clamp(raw, 0, 100)
end

local function CalculateCompositeStress(survivor)
	local hp = survivor.GetUnitHealthPercent and survivor:GetUnitHealthPercent() or 100
	local food = safe_percent(survivor.EnergyAvailable or 0, survivor.MaxEnergyAvailable or 0)
	local rest = safe_percent((survivor.MaxFatigue or 0) - (survivor.Fatigue or 0), survivor.MaxFatigue or 0)
	local mood = survivor.GetIPHappiness and survivor:GetIPHappiness() or 100
	local relax = survivor.GetRelaxationPct and survivor:GetRelaxationPct() or 100
	local temp = survivor.temperature_perception or 0
	local bleed = (survivor.Bleeding or 0) / 1000
	local sleeping = survivor.sleeping == true
	local equip = GetEquipmentConditionPct(survivor)

	local distress_risk = 0.6 * (100 - clamp(relax, 0, 100)) + 0.4 * (100 - clamp(mood, 0, 100))
	local hunger_risk = 100 - clamp(food, 0, 100)
	local fatigue_risk = 100 - clamp(rest, 0, 100)
	local health_risk = 100 - clamp(hp, 0, 100)
	local bleed_risk = clamp(bleed * 100, 0, 100)
	temp = clamp(abs(temp) * 125, 0, 100)
	local equip_risk = 100 - clamp(equip, 0, 100)

	local stress =
		distress_risk * 0.30 +
		hunger_risk * 0.23 +
		fatigue_risk * 0.17 +
		health_risk * 0.15 +
		bleed_risk * 0.10 +
		temp * 0.05 +
		equip_risk * 0.00

	if sleeping then
		stress = stress - 5
	end
	if bleed_risk >= 25 then
		stress = stress + 5
	end

	return floor(clamp(stress, 0, 100) + 0.5)
end

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

local function BuildVitalsSnapshot()
	local stress_threshold = (ModLina.Config and ModLina.Config.GetThreshold and ModLina.Config.GetThreshold("stress")) or 60
	local hunger_threshold = (ModLina.Config and ModLina.Config.GetThreshold and ModLina.Config.GetThreshold("hunger")) or 20
	local hungry = 0
	local stressed = 0
	local entries = {}
	for _, survivor in ipairs(GetSurvivors()) do
		if survivor and IsValid(survivor) and not survivor:IsDead() then
			local food_pct = safe_percent(survivor.EnergyAvailable or 0, survivor.MaxEnergyAvailable or 0)
			local stress_score = CalculateCompositeStress(survivor)
			local rest_pct = safe_percent((survivor.MaxFatigue or 0) - (survivor.Fatigue or 0), survivor.MaxFatigue or 0)
			local mood_pct = survivor.GetIPHappiness and survivor:GetIPHappiness() or 100
			local entry = {
				name = GetSurvivorName(survivor),
				stress = floor(clamp(stress_score, 0, 100) + 0.5),
				food = floor(clamp(food_pct, 0, 100) + 0.5),
				rest = floor(clamp(rest_pct, 0, 100) + 0.5),
				mood = floor(clamp(mood_pct, 0, 100) + 0.5),
				sleeping = survivor.sleeping == true,
				bleeding = (survivor.Bleeding or 0) > 0,
			}
			entries[#entries + 1] = entry

			if food_pct < hunger_threshold then
				hungry = hungry + 1
			end
			if stress_score >= stress_threshold then
				stressed = stressed + 1
			end
		end
	end

	table.sort(entries, function(a, b)
		if a.stress == b.stress then
			if a.food == b.food then
				return a.name < b.name
			end
			return a.food < b.food
		end
		return a.stress > b.stress
	end)

	return hungry, stressed, entries
end

local function BuildCompactVitalsLine(entries, max_entries)
	if not entries or #entries == 0 then
		return "Top: none"
	end
	local parts = {}
	local limit = max_entries or 2
	for i = 1, #entries do
		if i > limit then
			break
		end
		local e = entries[i]
		local flags = ""
		if e.bleeding then
			flags = flags .. "!"
		end
		if e.sleeping then
			flags = flags .. "z"
		end
		parts[#parts + 1] = string.format("%s S:%d F:%d%s", TrimName(e.name, 8), e.stress, e.food, flags ~= "" and (" " .. flags) or "")
	end
	return "Top: " .. table.concat(parts, " | ")
end

local function BuildVerboseVitalsLines(entries, max_entries)
	if not entries or #entries == 0 then
		return "No survivor vitals available"
	end
	local lines = {}
	local limit = max_entries or 4
	for i = 1, #entries do
		if i > limit then
			break
		end
		local e = entries[i]
		local flags = ""
		if e.bleeding then
			flags = flags .. " !"
		end
		if e.sleeping then
			flags = flags .. " z"
		end
		lines[#lines + 1] = string.format("%s  S:%d  F:%d  R:%d  M:%d%s", TrimName(e.name, 14), e.stress, e.food, e.rest, e.mood, flags)
	end
	if #entries > limit then
		lines[#lines + 1] = string.format("+%d more survivors", #entries - limit)
	end
	return table.concat(lines, "\n")
end

local function GetClothCount()
	return GetResourceCount("Cloth", { "Fabric" })
end

local function TrimText(text, max_len)
	text = tostring(text or "")
	if #text <= max_len then
		return text
	end
	return string.sub(text, 1, max_len - 3) .. "..."
end

local function BuildHudText()
	local hungry, stressed, entries = BuildVitalsSnapshot()
	local cloth = GetClothCount()
	local mode = GetModeText()
	local latest = (rawget(_G, "ModLinaState") and ModLinaState.latest_alert_text) or "No alerts yet"
	local hud_mode = GetHudMode()
	if hud_mode == "verbose" then
		return string.format("<color 110 190 255>Lina Assistant</color>\nMode: %s\nHungry: %d | Stressed: %d | Cloth: %d\n%s\nLast: %s", mode, hungry, stressed, cloth, BuildVerboseVitalsLines(entries, 4), TrimText(latest, 180))
	end
	latest = TrimText(latest, 72)
	return string.format("<color 110 190 255>Lina</color>  M:%s  H:%d  S:%d  Cloth:%d\n<color 180 220 255>%s</color>\n<color 220 220 170>Last:</color> %s", mode, hungry, stressed, cloth, TrimText(BuildCompactVitalsLine(entries, 2), 72), latest)
end

local function BuildRolloverText()
	local mode = GetModeText()
	local hungry, stressed, entries = BuildVitalsSnapshot()
	local cloth = GetClothCount()
	local latest = (rawget(_G, "ModLinaState") and ModLinaState.latest_alert_text) or "No alerts yet"
	local last_time = (rawget(_G, "ModLinaState") and ModLinaState.latest_alert_time) or 0
	local ago = "n/a"
	if last_time and last_time > 0 then
		local sec = Max(0, (RealTime() - last_time) / 1000)
		ago = string.format("%.0fs", sec)
	end
	return string.format("Mode: %s\nHungry survivors: %d\nStressed survivors: %d\nCloth: %d\n\nLive vitals:\n%s\n\nLatest alert (%s ago):\n%s", mode, hungry, stressed, cloth, BuildVerboseVitalsLines(entries, 8), ago, tostring(latest))
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
