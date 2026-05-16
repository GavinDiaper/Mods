ModLina = ModLina or {}

---------------------------------------------------------
-- ACTION EXECUTION & PLANNING
---------------------------------------------------------

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

    -- Execute the skill with provided arguments
    if rawget(_G, "print") then
        print("[ModLina:AI_Planner] Executing skill: " .. tostring(result.action))
    end
    skill(result.arguments or {})
    
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
