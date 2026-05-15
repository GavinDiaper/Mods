ModLina = ModLina or {}

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
