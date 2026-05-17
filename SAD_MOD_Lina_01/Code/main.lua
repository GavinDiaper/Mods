-- main.lua
-- Entry point - event hooks and initialization

local function ensure_cooldown_table()
	if not rawget(_G, "ModLinaState") or not ModLinaState then
		return nil
	end
	ModLinaState.alert_cooldowns = ModLinaState.alert_cooldowns or {}
	return ModLinaState.alert_cooldowns
end

local function should_send_threat_fallback(event_key, cooldown_ms)
	cooldown_ms = cooldown_ms or 90000
	local table_ref = ensure_cooldown_table()
	if not table_ref then
		return true
	end

	local key = "threat_fallback|" .. tostring(event_key or "generic")
	local now = RealTime and RealTime() or 0
	local last = table_ref[key]
	if last and (now - last) < cooldown_ms then
		return false
	end
	table_ref[key] = now
	return true
end

local function send_threat_fallback(message, event_key)
	if rawget(_G, "ModLina") and ModLina.Notify and ModLina.Notify.LinaSay then
		if should_send_threat_fallback(event_key, 300000) then
			if rawget(_G, "print") then
				print("[ModLina:DEBUG] Sending fallback threat alert: " .. tostring(message))
			end
			ModLina.Notify.LinaSay(message)
		end
	end
end

local function request_threat_ai_response(prompt, event_key)
	if not should_send_threat_fallback(event_key, 180000) then
		return
	end

	if rawget(_G, "print") then
		print("[ModLina:DEBUG] Requesting AI threat response: " .. tostring(prompt))
	end

	if not (rawget(_G, "ModLina") and ModLina.QueryLLM and ModLina.ExecuteLLMAction) then
		if rawget(_G, "print") then
			print("[ModLina:DEBUG] AI request path unavailable")
		end
		return
	end

	local result = ModLina.QueryLLM(prompt)
	ModLina.ExecuteLLMAction(result)
end

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
	if rawget(_G, "print") then
		print("[ModLina:DEBUG] OnMsg.CombatStart fired")
	end
	if rawget(_G, "ModLina") and ModLina.CheckThreats then
		if rawget(_G, "print") then
			print("[ModLina:DEBUG] Calling ModLina.CheckThreats()")
		end
		ModLina.CheckThreats()
	else
		if rawget(_G, "print") then
			print("[ModLina:DEBUG] ModLina or CheckThreats not available")
		end
		send_threat_fallback("Hostiles Lurking", "combat_start")
	end
end

---------------------------------------------------------------------------
-- UNIT SPAWNED - Enemy Detection
---------------------------------------------------------------------------

function OnMsg.UnitSpawned(unit)
	if not unit then
		return
	end
	if rawget(_G, "IsKindOf") and not (IsKindOf(unit, "UnitAnimal") or IsKindOf(unit, "UnitInvader") or IsKindOf(unit, "Robot") or IsKindOf(unit, "CombatRobot")) then
		return
	end

	local hostile = false
	if unit.IsHostile then
		local ok, is_hostile = pcall(unit.IsHostile, unit)
		hostile = ok and is_hostile and true or false
	else
		hostile = unit.CombatHostile == true or unit.Invader == true
	end

	if rawget(_G, "print") then
		print("[ModLina:DEBUG] OnMsg.UnitSpawned - unit class: " .. tostring(unit.class) .. ", hostile: " .. tostring(hostile))
	end

	if hostile and rawget(_G, "ModLina") and ModLina.UpdateState then
		if rawget(_G, "print") then
			print("[ModLina:DEBUG] Calling ModLina.UpdateState()")
		end
		ModLina.UpdateState()
		if ModLina.CheckThreats then
			if rawget(_G, "print") then
				print("[ModLina:DEBUG] Calling ModLina.CheckThreats()")
			end
			ModLina.CheckThreats()
		end
	elseif hostile then
		if rawget(_G, "print") then
			print("[ModLina:DEBUG] Hostile unit detected but UpdateState unavailable")
		end
		send_threat_fallback("Hostiles Lurking", "unit_spawned")
	end
end

---------------------------------------------------------------------------
-- RAID-SPECIFIC SPAWN HOOKS
---------------------------------------------------------------------------

function OnMsg.SpawnedAnimalThreat(unit)
	if rawget(_G, "print") then
		print("[ModLina:DEBUG] OnMsg.SpawnedAnimalThreat fired")
	end
	if rawget(_G, "ModLina") and ModLina.UpdateState then
		if rawget(_G, "print") then
			print("[ModLina:DEBUG] Calling ModLina.UpdateState() from SpawnedAnimalThreat")
		end
		ModLina.UpdateState()
		if ModLina.CheckThreats then
			if rawget(_G, "print") then
				print("[ModLina:DEBUG] Calling ModLina.CheckThreats() from SpawnedAnimalThreat")
			end
			ModLina.CheckThreats()
		elseif ModLina.Notify and ModLina.Notify.LinaSay then
			if rawget(_G, "print") then
				print("[ModLina:DEBUG] CheckThreats not available, using fallback message")
			end
			send_threat_fallback("Wildlife Lurking", "animal_threat")
		end
	else
		if rawget(_G, "print") then
			print("[ModLina:DEBUG] UpdateState unavailable in SpawnedAnimalThreat")
		end
		send_threat_fallback("Wildlife Lurking", "animal_threat")
	end
end

function OnMsg.SpawnedAnimalPest(unit)
	if rawget(_G, "print") then
		print("[ModLina:DEBUG] OnMsg.SpawnedAnimalPest fired")
	end
	if rawget(_G, "ModLina") and ModLina.Notify and ModLina.Notify.LinaSay then
		if rawget(_G, "print") then
			print("[ModLina:DEBUG] Sending pest alert via LinaSay")
		end
		send_threat_fallback("Pest Wave", "animal_pest")
	else
		if rawget(_G, "print") then
			print("[ModLina:DEBUG] ModLina or LinaSay not available for pest alert")
		end
	end
end

function OnMsg.InvaderBehaviorAssign(unit, new_behavior)
	if should_send_threat_fallback("invader_behavior_debug", 120000) and rawget(_G, "print") then
		print("[ModLina:DEBUG] OnMsg.InvaderBehaviorAssign fired (throttled)")
	end
	if rawget(_G, "ModLina") and ModLina.UpdateState then
		if should_send_threat_fallback("invader_behavior_update_debug", 120000) and rawget(_G, "print") then
			print("[ModLina:DEBUG] Calling ModLina.UpdateState() from InvaderBehaviorAssign")
		end
		if should_send_threat_fallback("invader_behavior_processing", 180000) then
			ModLina.UpdateState()
			if ModLina.CheckThreats then
				if rawget(_G, "print") then
					print("[ModLina:DEBUG] Calling ModLina.CheckThreats() from InvaderBehaviorAssign")
				end
				ModLina.CheckThreats()
			end
		end
	else
		if should_send_threat_fallback("invader_behavior_missing_debug", 120000) and rawget(_G, "print") then
			print("[ModLina:DEBUG] UpdateState unavailable in InvaderBehaviorAssign")
		end
		send_threat_fallback("Hostiles Lurking", "invader_behavior")
		request_threat_ai_response("Raid or hostile behavior detected. Provide one immediate defensive action.", "invader_behavior_llm")
	end
end
