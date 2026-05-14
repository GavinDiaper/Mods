-- ModLina_Core.lua
-- Namespace initialization, global state, and lifecycle management

-- Establish safe global namespace with FirstLoad guards
if not rawget(_G, "ModLina") then
	ModLina = {}
end

-- Persistent state tables (survive reload/game reload)
if rawget(_G, "ModLinaState") == nil then
	ModLinaState = {
		initialized = false,
		mode = "A",
		workbench_last_output = {}, -- workbench_id -> last_seen_produced_count, timestamp
		alert_cooldowns = {}, -- alert_type -> last_timestamp
		latest_alert_text = "",
		latest_alert_time = 0,
	}
end

-- Store reference for convenience
local ModLinaState = ModLinaState

local floor = math.floor
local has_translate = rawget(_G, "_InternalTranslate")

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

local VITALS_CACHE_TTL = 1500

ModLina._vitals_cache = false
ModLina._vitals_cache_time = 0

function ModLina.GetSurvivors()
	local player = rawget(_G, "UIPlayer") and UIPlayer
	if not player or not player.labels or not player.labels.Survivors then
		return empty_table or {}
	end
	return player.labels.Survivors
end

function ModLina.GetSurvivorName(unit)
	if not unit then return "" end
	local name = unit.FirstName
	if name and IsT and IsT(name) and has_translate then
		return _InternalTranslate(name)
	end
	if name ~= nil then
		return tostring(name)
	end
	name = unit.Name
	if name and IsT and IsT(name) and has_translate then
		return _InternalTranslate(name)
	end
	return tostring(name or "")
end

function ModLina.CalculateStressLevel(entry)
	if not entry then
		return 0
	end

	local hp_deficit = 100 - clamp(entry.hp or 100, 0, 100)
	local food_deficit = 100 - clamp(entry.food or 100, 0, 100)
	local rest_deficit = 100 - clamp(entry.rest or 100, 0, 100)
	local mood_deficit = 100 - clamp(entry.mood or 100, 0, 100)
	local relax_deficit = 100 - clamp(entry.relax or 100, 0, 100)
	local temp_penalty = clamp(abs(entry.temp or 0) * 125, 0, 100)
	local bleed_penalty = clamp((entry.bleed or 0) * 100, 0, 100)

	local stress =
		hp_deficit * 0.15 +
		food_deficit * 0.20 +
		rest_deficit * 0.20 +
		mood_deficit * 0.20 +
		relax_deficit * 0.15 +
		temp_penalty * 0.05 +
		bleed_penalty * 0.05

	if entry.sleeping then
		stress = stress - 5
	end

	return floor(clamp(stress, 0, 100) + 0.5)
end

function ModLina.CollectVitals()
	local list = {}
	for _, unit in ipairs(ModLina.GetSurvivors()) do
		if IsValid(unit) and not unit:IsDead() then
			local hp = unit.GetUnitHealthPercent and unit:GetUnitHealthPercent() or 100
			local food = safe_percent(unit.EnergyAvailable or 0, unit.MaxEnergyAvailable or 0)
			local rest = safe_percent((unit.MaxFatigue or 0) - (unit.Fatigue or 0), unit.MaxFatigue or 0)
			local mood = unit.GetIPHappiness and unit:GetIPHappiness() or 100
			local relax = unit.GetRelaxationPct and unit:GetRelaxationPct() or 100
			local temp = unit.temperature_perception or 0
			local bleed = (unit.Bleeding or 0) / 1000
			local sleeping = unit.sleeping == true

			local entry = {
				unit = unit,
				name = ModLina.GetSurvivorName(unit),
				hp = clamp(hp, 0, 100),
				food = clamp(food, 0, 100),
				rest = clamp(rest, 0, 100),
				mood = clamp(mood, 0, 100),
				relax = clamp(relax, 0, 100),
				temp = temp,
				bleed = bleed,
				sleeping = sleeping,
			}
			entry.stress_level = ModLina.CalculateStressLevel(entry)
			list[#list + 1] = entry
		end
	end
	return list
end

function ModLina.RefreshVitalsCache()
	ModLina._vitals_cache = ModLina.CollectVitals()
	ModLina._vitals_cache_time = RealTime()
	return ModLina._vitals_cache
end

function ModLina.GetVitals()
	local now = RealTime()
	if ModLina._vitals_cache and (now - ModLina._vitals_cache_time) < VITALS_CACHE_TTL then
		return ModLina._vitals_cache
	end
	return ModLina.RefreshVitalsCache()
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function ModLina.Initialize()
	-- Only initialize once per map load
	if ModLinaState.initialized then
		return
	end

	ModLinaState.initialized = true
	if ModLina.Notify and ModLina.Notify.LinaSay then
		ModLina.Notify.LinaSay("Lina online. Monitoring survivor wellbeing and colony status.")
	end
	
	-- Load configuration from storage
	if ModLina.Config and ModLina.Config.LoadSettings then
		ModLina.Config.LoadSettings()
	end
end

---------------------------------------------------------------------------
-- SESSION STATE MANAGEMENT
---------------------------------------------------------------------------

function ModLina.ResetStateForNewGame()
	-- Called on NewGame to reset session state while preserving global config
	ModLinaState.workbench_last_output = {}
	ModLinaState.alert_cooldowns = {}
	ModLina._vitals_cache = false
	ModLina._vitals_cache_time = 0
end

function ModLina.OnGameLoaded()
	-- Called on PostLoadGame - config already loaded, restore workbench tracking if needed
	-- Workbench data is transient per game session, so reset
	ModLinaState.workbench_last_output = {}
	ModLinaState.alert_cooldowns = {}
	ModLina._vitals_cache = false
	ModLina._vitals_cache_time = 0
end

---------------------------------------------------------------------------
-- TICK DISPATCHERS
---------------------------------------------------------------------------

function ModLina.TickHourly()
	if not ModLinaState.initialized then
		return
	end

	local mode = ModLina.Config.GetMode()

	-- Always run Advisor checks
	if mode == "A" or mode == "B" or mode == "C" then
		ModLina.Advisor.CheckAll()
	end

	-- Semi-Auto mode automation (scaffold only in v1)
	if mode == "B" then
		ModLina.SemiAuto.Tick()
	end

	-- Full-Auto mode automation (scaffold only in v1)
	if mode == "C" then
		ModLina.FullAuto.Tick()
	end
end

function ModLina.TickDaily()
	if not ModLinaState.initialized then
		return
	end

	-- Placeholder for daily long-term analysis
	-- Future: forecasting, trend analysis, etc.
end

---------------------------------------------------------------------------
-- HELPER: Get/Set Mode
---------------------------------------------------------------------------

function ModLina.SetMode(mode_char)
	if mode_char == "A" or mode_char == "B" or mode_char == "C" then
		ModLinaState.mode = mode_char
		if ModLina.Config and ModLina.Config.SaveSettings then
			ModLina.Config.SaveSettings()
		end
		if ModLina.Notify and ModLina.Notify.LinaSay then
			ModLina.Notify.LinaSay("Mode set to " .. mode_char .. ".")
		end
	end
end

function ModLina.GetMode()
	return ModLinaState.mode or "A"
end
