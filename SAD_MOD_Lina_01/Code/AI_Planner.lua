ModLina = ModLina or {}

---------------------------------------------------------
-- ACTION EXECUTION & PLANNING
---------------------------------------------------------

function ModLina.ExecuteLLMAction(result)
    if not result or not result.action then 
        return false
    end

    local skill = ModLina.Skills[result.action]
    if not skill then
        ModLina.LinaSay("Lina received unknown action: " .. tostring(result.action))
        return false
    end

    -- Execute the skill with provided arguments
    skill(result.arguments or {})
    
    -- Optionally explain reasoning
    if result.reasoning then
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
    
    ModLina.UpdateState()
    local threats = ModLina.State.Threats or {}
    
    local total_enemies = (threats.ActiveEnemies and threats.ActiveEnemies.Total) or 0
    local total_nests = #(threats.ShriekerNests or {})
    
    if total_enemies > 0 then
        local enemy_summary = ""
        if threats.ActiveEnemies.Animals and #threats.ActiveEnemies.Animals > 0 then
            enemy_summary = enemy_summary .. #threats.ActiveEnemies.Animals .. " animals"
        end
        if threats.ActiveEnemies.Invaders and #threats.ActiveEnemies.Invaders > 0 then
            if enemy_summary ~= "" then enemy_summary = enemy_summary .. ", " end
            enemy_summary = enemy_summary .. #threats.ActiveEnemies.Invaders .. " invaders"
        end
        if threats.ActiveEnemies.Robots and #threats.ActiveEnemies.Robots > 0 then
            if enemy_summary ~= "" then enemy_summary = enemy_summary .. ", " end
            enemy_summary = enemy_summary .. #threats.ActiveEnemies.Robots .. " robots"
        end
        
        -- Report threat
        local result = {
            action = "ReportThreat",
            arguments = {
                threat_type = "Active Enemies",
                count = total_enemies,
                details = enemy_summary
            },
            reasoning = "Combat detected. Alerting player to immediate threat."
        }
        ModLina.ExecuteLLMAction(result)
    end
    
    if total_nests > 0 then
        local result = {
            action = "ReportThreat",
            arguments = {
                threat_type = "Shrieker Nests",
                count = total_nests,
                details = "Nests detected in vicinity"
            },
            reasoning = "Territorial threats identified. Long-term concern."
        }
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
