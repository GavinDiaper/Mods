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
	
	-- Initialize AI state snapshot system
	if ModLina.UpdateState then
		ModLina.UpdateState()
		if ModLina.Notify and ModLina.Notify.LinaSay then
			ModLina.Notify.LinaSay("AI threat monitoring system online.")
		end
	end
	
	-- Start threat monitoring loop
	if ModLina.StartThreatMonitoring then
		ModLina.StartThreatMonitoring()
	end
end

---------------------------------------------------------------------------
-- SESSION STATE MANAGEMENT
---------------------------------------------------------------------------

function ModLina.ResetStateForNewGame()
	-- Called on NewGame to reset session state while preserving global config
	ModLinaState.workbench_last_output = {}
	ModLinaState.alert_cooldowns = {}
end

function ModLina.OnGameLoaded()
	-- Called on PostLoadGame - config already loaded, restore workbench tracking if needed
	-- Workbench data is transient per game session, so reset
	ModLinaState.workbench_last_output = {}
	ModLinaState.alert_cooldowns = {}
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
