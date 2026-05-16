ModLina = ModLina or {}

local function now_ms()
    return (RealTime and RealTime()) or 0
end

local function ensure_ai_windows()
    if not rawget(_G, "ModLinaState") or not ModLinaState then
        return
    end

    local now = now_ms()
    if not ModLinaState.ai_hour_window_start or ModLinaState.ai_hour_window_start <= 0 then
        ModLinaState.ai_hour_window_start = now
    end
    if not ModLinaState.ai_day_window_start or ModLinaState.ai_day_window_start <= 0 then
        ModLinaState.ai_day_window_start = now
    end

    if (now - ModLinaState.ai_hour_window_start) >= 3600000 then
        ModLinaState.ai_hour_window_start = now
        ModLinaState.ai_calls_hour = 0
    end
    if (now - ModLinaState.ai_day_window_start) >= 86400000 then
        ModLinaState.ai_day_window_start = now
        ModLinaState.ai_calls_day = 0
    end
end

function ModLina.CanCallLLM()
    if not rawget(_G, "ModLinaState") or not ModLinaState then
        return false, "AI state unavailable"
    end

    ensure_ai_windows()

    if not (ModLina.Config and ModLina.Config.IsAIEnabled and ModLina.Config.IsAIEnabled()) then
        return false, "AI cloud disabled"
    end

    local now = now_ms()
    local cooldown = (ModLina.Config.GetAISetting and ModLina.Config.GetAISetting("cooldown_seconds")) or 120
    local max_hour = (ModLina.Config.GetAISetting and ModLina.Config.GetAISetting("max_calls_per_hour")) or 8
    local max_day = (ModLina.Config.GetAISetting and ModLina.Config.GetAISetting("max_calls_per_day")) or 25

    if ModLinaState.ai_last_call_time and (now - ModLinaState.ai_last_call_time) < (cooldown * 1000) then
        local remaining = cooldown - ((now - ModLinaState.ai_last_call_time) / 1000)
        return false, "Cooldown " .. tostring(remaining - (remaining % 1)) .. "s"
    end

    if max_hour > 0 and (ModLinaState.ai_calls_hour or 0) >= max_hour then
        return false, "Hourly cap reached"
    end
    if max_day > 0 and (ModLinaState.ai_calls_day or 0) >= max_day then
        return false, "Daily cap reached"
    end

    return true, nil
end

function ModLina.RecordLLMCall()
    if not rawget(_G, "ModLinaState") or not ModLinaState then
        return
    end

    ensure_ai_windows()
    ModLinaState.ai_last_call_time = now_ms()
    ModLinaState.ai_calls_total = (ModLinaState.ai_calls_total or 0) + 1
    ModLinaState.ai_calls_hour = (ModLinaState.ai_calls_hour or 0) + 1
    ModLinaState.ai_calls_day = (ModLinaState.ai_calls_day or 0) + 1
end

-- Placeholder: later you'll implement real HTTP calls from C# bridge or external helper.
-- Here we just define the contract and structure for LLM interaction.

function ModLina.BuildLLMPrompt(user_request)
    ModLina.UpdateState()

    local state = ModLina.State
    local skills = {
        "NotifyPlayer(message)",
        "SetPriority(survivor, task, level)",
        "AssignRelaxation(survivor)",
        "AssignSleep(survivor)",
        "AssignEat(survivor)",
        "AssignHeal(survivor)",
        "AssignWork(survivor, task)",
        "FormAttackSquad(squad)",
        "AssignAttackShriekerNest(survivor, nestId)",
        "AssignAttackEnemy(survivor, enemyId)",
        "BoostWorkbench(workbench)",
        "ReorderProductionQueue(workbench)",
        "StartHarvest(resource)",
        "StartHunt(animal)",
        "PlanStep(description)",
        "ReportThreat(threat_type, count, details)",
        "ExplainReasoning(reasoning)"
    }

    local prompt = {
        system = "You are Mod_Lina - Survivor Assistant, an AI copilot for Stranded: Alien Dawn.",
        instructions = "You receive game state and a player request. Analyze the situation and choose ONE skill to address it. Prioritize threats and survival.",
        skills = skills,
        gamestate = state,
        request = user_request,
        response_format = [[{
  "action": "SkillName",
  "arguments": { ... },
  "reasoning": "Short explanation"
}]]
    }

    return prompt
end

function ModLina.QueryLLM(user_request)
    local prompt = ModLina.BuildLLMPrompt(user_request)

    local allowed, reason = ModLina.CanCallLLM()
    if not allowed then
        if rawget(_G, "print") then
            print("[ModLina:AI_LLM] Cloud call blocked: " .. tostring(reason))
        end
        return {
            action = "NotifyPlayer",
            arguments = {
                message = "Local mode: " .. tostring(reason)
            },
            reasoning = nil,
        }
    end

    ModLina.RecordLLMCall()

    -- In the future:
    -- 1. Serialize `prompt` to JSON
    -- 2. Send to OpenAI/Azure/Claude using ModLina.Config.API
    -- 3. Parse JSON response
    -- For now, return a hard-coded stub for testing.

    -- Example stub for "Plan an attack on the nearest Shrieker nest"
    return {
        action = "NotifyPlayer",
        arguments = {
            message = "I recommend forming a squad of your top 3 combat survivors and moving them near the nearest Shrieker nest before attacking."
        },
        reasoning = "Stubbed LLM response - real integration coming soon."
    }
end

function ModLina.SerializeGameState()
    -- Helper to convert ModLina.State to JSON-serializable format
    -- This will be needed when actually calling the LLM API
    local json = require("json") or nil
    if json then
        return json.encode(ModLina.State)
    else
        -- Fallback: return Lua table representation
        return tostring(ModLina.State)
    end
end

function ModLina.ParseLLMResponse(response_text)
    -- Helper to parse LLM JSON response
    -- This will be needed when actually calling the LLM API
    local json = require("json") or nil
    if json then
        return json.decode(response_text)
    else
        -- Fallback: return nil (no parsing available)
        return nil
    end
end
