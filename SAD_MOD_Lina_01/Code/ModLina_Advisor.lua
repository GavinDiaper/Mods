-- ModLina_Advisor.lua
-- Advisor Mode (A) - monitoring and alerts only

if not rawget(_G, "ModLina") then
	ModLina = {}
end

ModLina.Advisor = ModLina.Advisor or {}

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

---------------------------------------------------------------------------
-- SURVIVOR NEEDS CHECKS
---------------------------------------------------------------------------

function ModLina.Advisor.CheckSurvivorStress()
	local stress_threshold = ModLina.Config.GetThreshold("stress")
	
	for _, survivor in ipairs(GetSurvivors()) do
		if survivor and IsValid(survivor) and not survivor:IsDead() then
			-- Use relaxation indicator (low relax = high stress, similar to InfoBeacon pattern)
			local relax = (survivor.GetRelaxationPct and survivor:GetRelaxationPct()) or 100
			if relax ~= nil and relax < stress_threshold then
				ModLina.Notify.SurvivorAlert(
					GetSurvivorName(survivor),
					T(732519874108, "is highly stressed. Consider scheduling rest or relaxation."),
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
					T(732519874109, "is hungry. Prioritize meal production."),
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
	local cloth_count = (Resources and Resources["Cloth"]) or 0
	
	if cloth_count < cloth_threshold then
		ModLina.Notify.ResourceAlert(
			T(732519874110, "Cloth reserves are low. Recommend increasing tailoring priority.")
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
				T(732519874111, workbench_name .. " appears to be stalled. Check resource availability and task queue.")
			)
			
			-- Reset so we don't spam alerts
			tracking.last_time = current_game_time
		end
		
		::continue::
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
end
