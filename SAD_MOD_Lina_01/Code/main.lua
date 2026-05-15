-- main.lua
-- Entry point - event hooks and initialization

---------------------------------------------------------------------------
-- NEW GAME - Initialize Lina on new map
---------------------------------------------------------------------------

function OnMsg.NewMapLoaded()
	if rawget(_G, "ModLina") and ModLina.Initialize then
		ModLina.Initialize()
	end
end

---------------------------------------------------------------------------
-- HOURLY TICK
---------------------------------------------------------------------------

function OnMsg.NewHour()
	if rawget(_G, "ModLina") and ModLina.TickHourly then
		ModLina.TickHourly()
	end
end

---------------------------------------------------------------------------
-- DAILY TICK
---------------------------------------------------------------------------

function OnMsg.NewDay()
	if rawget(_G, "ModLina") and ModLina.TickDaily then
		ModLina.TickDaily()
	end
end

---------------------------------------------------------------------------
-- SAVE/LOAD CYCLE HOOKS
---------------------------------------------------------------------------

function OnMsg.NewGame()
	if rawget(_G, "ModLina") and ModLina.ResetStateForNewGame then
		ModLina.ResetStateForNewGame()
	end
end

function OnMsg.PostLoadGame()
	if rawget(_G, "ModLina") and ModLina.OnGameLoaded then
		ModLina.OnGameLoaded()
	end
end

---------------------------------------------------------------------------
-- MOD RELOAD (development)
---------------------------------------------------------------------------

function OnMsg.ModsReloaded()
	-- Reset initialization flag so Lina reinitializes on next map
	if rawget(_G, "ModLinaState") then
		ModLinaState.initialized = false
	end
end

---------------------------------------------------------------------------
-- COMBAT START - Threat Detection
---------------------------------------------------------------------------

function OnMsg.CombatStart()
	if rawget(_G, "ModLina") and ModLina.CheckThreats then
		ModLina.CheckThreats()
	end
end

---------------------------------------------------------------------------
-- UNIT SPAWNED - Enemy Detection
---------------------------------------------------------------------------

function OnMsg.UnitSpawned(unit)
	if unit and unit:IsHostile() then
		if rawget(_G, "ModLina") and ModLina.UpdateState then
			ModLina.UpdateState()
		end
	end
end
