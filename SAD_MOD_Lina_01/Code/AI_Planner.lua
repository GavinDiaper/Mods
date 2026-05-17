ModLina = rawget(_G, "ModLina") or {}

---------------------------------------------------------
-- ACTION EXECUTION & PLANNING
---------------------------------------------------------

local INITIAL_ACTION_ALLOWLIST = {
    NotifyPlayer = true,
    ReportThreat = true,
    FormAttackSquad = true,
    AssignAttackShriekerNest = true,
}

local MUTATING_ACTIONS = {
    SetPriority = true,
}

local THREAT_LABELS = {
    ["Hostiles Lurking"] = true,
    ["Hostiles Nearby"] = true,
    ["Attacking now"] = true,
    ["Attacking in 10s"] = true,
    ["Attacking in 20s"] = true,
    ["Attacking in 30s"] = true,
    ["Attacking in 40s"] = true,
    ["Attacking in 50s"] = true,
    ["Attacking in 60s"] = true,
    ["Attacking in 70s"] = true,
    ["Nest Nearby"] = true,
}

local function is_non_empty_string(value)
    return type(value) == "string" and value ~= ""
end

local function validate_notify_player(args)
    if type(args) ~= "table" then
        return false, "invalid_args"
    end
    if not is_non_empty_string(args.message) then
        return false, "missing_message"
    end
    return true, nil
end

local function validate_report_threat(args)
    if type(args) ~= "table" then
        return false, "invalid_args"
    end

    local label = args.label or args.threat_type
    if not is_non_empty_string(label) then
        return false, "missing_threat_label"
    end
    if not THREAT_LABELS[label] then
        return false, "invalid_threat_label"
    end

    if args.enemy_count ~= nil and type(args.enemy_count) ~= "number" then
        return false, "invalid_enemy_count"
    end
    if args.eta_seconds ~= nil and type(args.eta_seconds) ~= "number" then
        return false, "invalid_eta_seconds"
    end

    return true, nil
end

local function validate_form_attack_squad(args)
    if type(args) ~= "table" then
        return false, "invalid_args"
    end
    if type(args.squad) ~= "table" or #args.squad == 0 then
        return false, "missing_squad"
    end
    return true, nil
end

local function validate_assign_attack_shrieker_nest(args)
    if type(args) ~= "table" then
        return false, "invalid_args"
    end
    if not is_non_empty_string(args.survivor) then
        return false, "missing_survivor"
    end
    if not is_non_empty_string(args.nestId) then
        return false, "missing_nest_id"
    end
    return true, nil
end

local function validate_set_priority(args)
    if type(args) ~= "table" then
        return false, "invalid_args"
    end
    if not is_non_empty_string(args.survivor) then
        return false, "missing_survivor"
    end
    if not is_non_empty_string(args.task) then
        return false, "missing_task"
    end
    if type(args.level) ~= "number" then
        return false, "missing_level"
    end
    if args.level < 1 or args.level > 5 then
        return false, "invalid_level"
    end
    return true, nil
end

function ModLina.ValidateLLMAction(action, arguments)
    if type(action) ~= "string" or action == "" then
        return false, "missing_action"
    end

    local is_mutating = MUTATING_ACTIONS[action] and true or false
    if is_mutating then
        local allow_mutating = ModLina.Config
            and ModLina.Config.GetAISetting
            and ModLina.Config.GetAISetting("allow_mutating_actions")
        if not allow_mutating then
            return false, "mutating_action_blocked"
        end
    elseif not INITIAL_ACTION_ALLOWLIST[action] then
        return false, "action_not_allowlisted"
    end

    if action == "NotifyPlayer" then
        return validate_notify_player(arguments)
    end
    if action == "ReportThreat" then
        return validate_report_threat(arguments)
    end
    if action == "FormAttackSquad" then
        return validate_form_attack_squad(arguments)
    end
    if action == "AssignAttackShriekerNest" then
        return validate_assign_attack_shrieker_nest(arguments)
    end
    if action == "SetPriority" then
        return validate_set_priority(arguments)
    end

    return false, "unhandled_action_validator"
end

function ModLina.ExecuteLLMAction(result)
    if not result or not result.action then
        if rawget(_G, "print") then
            print("[ModLina:AI_Planner] ExecuteLLMAction called with null result")
        end
        return false
    end

    if rawget(_G, "print") then
        print("[ModLina:AI_Planner] ExecuteLLMAction - action: " .. tostring(result.action))
    end

    local skill = ModLina.Skills[result.action]
    if not skill then
        ModLina.LinaSay("Lina received unknown action: " .. tostring(result.action))
        if rawget(_G, "print") then
            print("[ModLina:AI_Planner] Skill not found: " .. tostring(result.action))
        end
        return false
    end

    local args = result.arguments or {}
    local ok, reason = ModLina.ValidateLLMAction(result.action, args)
    if not ok then
        ModLina.LinaSay("Lina could not execute AI action (AINA): " .. tostring(reason))
        if rawget(_G, "print") then
            print("[ModLina:AI_Planner] Validation failed for action " .. tostring(result.action) .. ": " .. tostring(reason))
        end
        return false
    end

    -- Execute the skill with provided arguments
    if rawget(_G, "print") then
        print("[ModLina:AI_Planner] Executing skill: " .. tostring(result.action))
    end
    skill(args)
    
    -- Optionally explain reasoning
    if result.reasoning and result.action ~= "ReportThreat" then
        ModLina.LinaSay("Reasoning: " .. result.reasoning)
    end
    
    return true
end

-- High-level entry: called when player asks Lina something
function ModLina.HandlePlayerRequest(text)
    if not text or text == "" then return end
    
    local result = ModLina.QueryLLM(text)
    ModLina.ExecuteLLMAction(result)
end

---------------------------------------------------------
-- THREAT RESPONSE AUTOMATION
---------------------------------------------------------

function ModLina.CheckThreats()
    -- Called periodically or on combat start
    -- Analyzes threats and recommends/executes defensive actions
    
    if rawget(_G, "print") then
        print("[ModLina:AI_Planner] CheckThreats() called")
    end
    
    ModLina.UpdateState()
    local threats = ModLina.State.Threats or {}
    
    local total_enemies = (threats.ActiveEnemies and threats.ActiveEnemies.Total) or 0
    local total_nests = #(threats.ShriekerNests or {})
    
    if rawget(_G, "print") then
        print("[ModLina:AI_Planner] Threat check - Enemies: " .. tostring(total_enemies) .. ", Nests: " .. tostring(total_nests))
    end
    
    if total_enemies > 0 then
        local nearest = ModLina.GetNearestThreatSummary and ModLina.GetNearestThreatSummary() or nil
        local eta_seconds = nearest and nearest.EtaSeconds or nil
        local threat_message = "Hostiles Lurking"

        if eta_seconds and eta_seconds > 0 then
            if eta_seconds <= 10 then
                threat_message = "Attacking now"
            elseif eta_seconds <= 90 then
                local rounded = eta_seconds - (eta_seconds % 10)
                if rounded < 10 then rounded = 10 end
                threat_message = "Attacking in " .. tostring(rounded) .. "s"
            else
                threat_message = "Hostiles Nearby"
            end
        elseif nearest and nearest.Distance then
            threat_message = "Hostiles Nearby"
        end
        
        -- Report threat
        local result = {
            action = "ReportThreat",
            arguments = {
                threat_type = threat_message,
                count = total_enemies,
                details = nil,
                eta_seconds = eta_seconds,
            },
            reasoning = nil,
        }
        if rawget(_G, "print") then
            print("[ModLina:AI_Planner] Executing threat report: " .. tostring(threat_message))
        end
        ModLina.ExecuteLLMAction(result)
    end
    
    if total_nests > 0 then
        local result = {
            action = "ReportThreat",
            arguments = {
                threat_type = "Nest Nearby",
                count = total_nests,
                details = nil,
            },
            reasoning = nil,
        }
        if rawget(_G, "print") then
            print("[ModLina:AI_Planner] Executing nest threat report")
        end
        ModLina.ExecuteLLMAction(result)
    end
end

---------------------------------------------------------
-- PLANNING & MULTI-STEP ACTIONS
---------------------------------------------------------

ModLina.CurrentPlan = {
    steps = {},
    current_step = 0,
    active = false
}

function ModLina.StartPlan(description)
    ModLina.CurrentPlan = {
        steps = {},
        current_step = 0,
        active = true,
        description = description
    }
    ModLina.LinaSay("Starting plan: " .. description)
end

function ModLina.AddPlanStep(action, arguments, description)
    table.insert(ModLina.CurrentPlan.steps, {
        action = action,
        arguments = arguments,
        description = description or action
    })
end

function ModLina.ExecuteNextPlanStep()
    if not ModLina.CurrentPlan.active then return end
    if ModLina.CurrentPlan.current_step >= #ModLina.CurrentPlan.steps then
        ModLina.LinaSay("Plan complete.")
        ModLina.CurrentPlan.active = false
        return
    end
    
    ModLina.CurrentPlan.current_step = ModLina.CurrentPlan.current_step + 1
    local step = ModLina.CurrentPlan.steps[ModLina.CurrentPlan.current_step]
    
    ModLina.ExecuteLLMAction({
        action = step.action,
        arguments = step.arguments,
        reasoning = step.description
    })
end

function ModLina.CancelPlan()
    if ModLina.CurrentPlan.active then
        ModLina.LinaSay("Plan cancelled.")
        ModLina.CurrentPlan.active = false
    end
end

---------------------------------------------------------
-- PERIODIC THREAT MONITORING
---------------------------------------------------------

function ModLina.StartThreatMonitoring()
    -- Called once to set up recurring threat checks
    CreateGameTimeThread(function()
        while true do
            local delay = 30000  -- Check every 30 seconds (in milliseconds)
            Sleep(delay)
            
            ModLina.CheckThreats()
        end
    end)
end

---------------------------------------------------------
-- CHAT INTERFACE (Future UI Integration)
---------------------------------------------------------

function ModLina.Chat(text)
    ModLina.LinaSay("You: " .. text)
    ModLina.HandlePlayerRequest(text)
end
