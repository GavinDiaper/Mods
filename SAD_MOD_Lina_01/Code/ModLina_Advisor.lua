-- ModLina_Advisor.lua
-- Advisor Mode (A) - monitoring and alerts only

ModLina = rawget(_G, "ModLina") or {}

ModLina.Advisor = ModLina.Advisor or {}

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

local function GetSurvivors()
	local player = rawget(_G, "UIPlayer") and UIPlayer
	if not player or not player.labels or not player.labels.Survivors then
		return empty_table or {}
	end
	return player.labels.Survivors
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

---------------------------------------------------------------------------
-- SURVIVOR NEEDS CHECKS
---------------------------------------------------------------------------

function ModLina.Advisor.CheckSurvivorStress()
	local stress_threshold = ModLina.Config.GetThreshold("stress")
	
	for _, survivor in ipairs(GetSurvivors()) do
		if survivor and IsValid(survivor) and not survivor:IsDead() then
			local stress_score = CalculateCompositeStress(survivor)
			if stress_score >= stress_threshold then
				ModLina.Notify.SurvivorAlert(
					GetSurvivorName(survivor),
					"is highly stressed. Consider scheduling rest or relaxation.",
					"stress"
				)
			end
		end
	end
end

function ModLina.Advisor.CheckSurvivorHunger()
	local hunger_threshold = ModLina.Config.GetThreshold("hunger")
	
	for _, survivor in ipairs(GetSurvivors()) do
		if survivor and IsValid(survivor) and not survivor:IsDead() then
			local energy = survivor.EnergyAvailable
			local max_energy = survivor.MaxEnergyAvailable
			if energy ~= nil and max_energy and max_energy > 0 then
				local hunger_pct = (energy * 100) / max_energy
				if hunger_pct < hunger_threshold then
				ModLina.Notify.SurvivorAlert(
					GetSurvivorName(survivor),
					"is hungry. Prioritize meal production.",
					"hunger"
				)
				end
			end
		end
	end
end

---------------------------------------------------------------------------
-- RESOURCE CHECKS
---------------------------------------------------------------------------

function ModLina.Advisor.CheckResources()
	if not rawget(_G, "Resources") then
		return
	end

	local cloth_threshold = ModLina.Config.GetThreshold("cloth")
	local cloth_count = GetResourceCount("Cloth", { "Fabric" })
	
	if cloth_count < cloth_threshold then
		ModLina.Notify.ResourceAlert(
			"Cloth reserves are low. Recommend increasing tailoring priority."
		)
	end
end

---------------------------------------------------------------------------
-- PRODUCTION CHECKS - Stalled Workbench Detection
---------------------------------------------------------------------------

function ModLina.Advisor.CheckStalledWorkbenches()
	if not rawget(_G, "GetAllObjects") or not rawget(_G, "IsKindOf") then
		return
	end

	-- Collect all workbenches in the map
	local workbenches = {}
	for _, obj in ipairs(GetAllObjects()) do
		if obj and IsKindOf(obj, "Workbench") and not obj.destroyed then
			table.insert(workbenches, obj)
		end
	end

	local stall_threshold_hours = 4  -- Configurable in future
	local current_game_time = GameTime()
	
	for _, workbench in ipairs(workbenches) do
		local workbench_id = workbench.handle or tostring(workbench)
		
		-- Skip if workbench has no queue
		if not workbench.Queue or #workbench.Queue == 0 then
			ModLinaState.workbench_last_output[workbench_id] = nil
			goto continue
		end
		
		-- Get current produced item count (placeholder - adjust based on actual API)
		local current_output = 0
		if workbench.StorageDepotComponent and workbench.inventory then
			current_output = #workbench.inventory
		end
		
		-- Initialize tracking for this workbench
		if not ModLinaState.workbench_last_output[workbench_id] then
			ModLinaState.workbench_last_output[workbench_id] = {
				last_count = current_output,
				last_time = current_game_time,
			}
			goto continue
		end
		
		local tracking = ModLinaState.workbench_last_output[workbench_id]
		local time_elapsed_hours = (current_game_time - tracking.last_time) / 3600000  -- Convert milliseconds to hours
		
		-- If output changed, reset timer
		if current_output > tracking.last_count then
			tracking.last_count = current_output
			tracking.last_time = current_game_time
			goto continue
		end
		
		-- If no output change and time exceeded threshold, alert
		if time_elapsed_hours >= stall_threshold_hours then
			local workbench_name = workbench.display_name or workbench.class or "Unknown Workbench"
			ModLina.Notify.ProductionAlert(
				workbench_id,
				tostring(workbench_name) .. " appears to be stalled. Check resource availability and task queue."
			)
			
			-- Reset so we don't spam alerts
			tracking.last_time = current_game_time
		end
		
		::continue::
	end
end

---------------------------------------------------------------------------
-- THREAT CHECKS (AI SKILLS LAYER)
---------------------------------------------------------------------------

function ModLina.Advisor.CheckThreats()
	-- Delegates to AI_Planner threat checking
	if rawget(_G, "ModLina") and ModLina.CheckThreats then
		ModLina.CheckThreats()
	end
end

---------------------------------------------------------------------------
-- MAIN CHECK DISPATCHER
---------------------------------------------------------------------------

function ModLina.Advisor.CheckAll()
	ModLina.Advisor.CheckSurvivorStress()
	ModLina.Advisor.CheckSurvivorHunger()
	ModLina.Advisor.CheckResources()
	ModLina.Advisor.CheckStalledWorkbenches()
	ModLina.Advisor.CheckThreats()
end

---------------------------------------------------------------------------
-- CHAT INTERFACE (Future UI Integration)
---------------------------------------------------------------------------

function ModLina.Advisor.Chat(text)
	-- Delegates to AI_Planner chat interface
	if rawget(_G, "ModLina") and ModLina.Chat then
		ModLina.Chat(text)
	end
end
