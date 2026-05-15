ModLina = ModLina or {}
ModLina.Skills = {}

---------------------------------------------------------
-- BASIC UTILS
---------------------------------------------------------

local function find_survivor_by_name(name)
    for _, s in ipairs(GetAllCharacters()) do
        if s.Name == name then return s end
    end
end

local function find_enemy_by_id(id, enemies)
    enemies = enemies or (ModLina.State.Threats.ActiveEnemies or {})
    
    -- Search all enemy types
    for _, category in pairs(enemies) do
        if type(category) == "table" then
            for _, enemy in ipairs(category) do
                if enemy.Id == id then
                    return enemy
                end
            end
        end
    end
    return nil
end

local function find_nest_by_id(id)
    local nests = ModLina.State.Threats.ShriekerNests or {}
    for _, n in ipairs(nests) do
        if n.Id == id then return n end
    end
    return nil
end

---------------------------------------------------------
-- CORE SKILLS
---------------------------------------------------------

ModLina.Skills.NotifyPlayer = function(args)
    ModLina.LinaSay(args.message or "No message provided.")
end

ModLina.Skills.SetPriority = function(args)
    local survivor = find_survivor_by_name(args.survivor)
    if not survivor then 
        ModLina.LinaSay("Could not find survivor: " .. (args.survivor or "unknown"))
        return 
    end
    -- Pseudocode: depends on how priorities are stored in-game
    -- survivor:SetTaskPriority(args.task, args.level)
    ModLina.LinaSay("Setting " .. args.survivor .. "'s " .. args.task .. " priority to " .. tostring(args.level))
end

ModLina.Skills.AssignRelaxation = function(args)
    local survivor = find_survivor_by_name(args.survivor)
    if not survivor then 
        ModLina.LinaSay("Could not find survivor: " .. (args.survivor or "unknown"))
        return 
    end
    ModLina.LinaSay("Assigning " .. args.survivor .. " to relaxation.")
end

ModLina.Skills.AssignSleep = function(args)
    local survivor = find_survivor_by_name(args.survivor)
    if not survivor then 
        ModLina.LinaSay("Could not find survivor: " .. (args.survivor or "unknown"))
        return 
    end
    ModLina.LinaSay("Assigning " .. args.survivor .. " to sleep.")
end

ModLina.Skills.AssignEat = function(args)
    local survivor = find_survivor_by_name(args.survivor)
    if not survivor then 
        ModLina.LinaSay("Could not find survivor: " .. (args.survivor or "unknown"))
        return 
    end
    ModLina.LinaSay("Assigning " .. args.survivor .. " to eat.")
end

ModLina.Skills.AssignHeal = function(args)
    local survivor = find_survivor_by_name(args.survivor)
    if not survivor then 
        ModLina.LinaSay("Could not find survivor: " .. (args.survivor or "unknown"))
        return 
    end
    ModLina.LinaSay("Assigning " .. args.survivor .. " to healing.")
end

ModLina.Skills.AssignWork = function(args)
    local survivor = find_survivor_by_name(args.survivor)
    if not survivor then 
        ModLina.LinaSay("Could not find survivor: " .. (args.survivor or "unknown"))
        return 
    end
    ModLina.LinaSay("Assigning " .. args.survivor .. " to " .. (args.task or "work") .. ".")
end

ModLina.Skills.FormAttackSquad = function(args)
    local squad = args.squad or {}
    if #squad == 0 then
        ModLina.LinaSay("No survivors specified for attack squad.")
        return
    end
    ModLina.LinaSay("Forming attack squad: " .. table.concat(squad, ", "))
    -- Future: group them, move to rally point, etc.
end

ModLina.Skills.AssignAttackShriekerNest = function(args)
    local survivor = find_survivor_by_name(args.survivor)
    if not survivor then 
        ModLina.LinaSay("Could not find survivor: " .. (args.survivor or "unknown"))
        return 
    end
    if not args.nestId then 
        ModLina.LinaSay("No nest ID specified.")
        return 
    end
    -- Pseudocode: issue attack order
    -- local nest = find_nest_by_id(args.nestId)
    -- survivor:Attack(nest)
    ModLina.LinaSay("Ordering " .. args.survivor .. " to attack Shrieker nest " .. args.nestId)
end

ModLina.Skills.AssignAttackEnemy = function(args)
    local survivor = find_survivor_by_name(args.survivor)
    if not survivor then 
        ModLina.LinaSay("Could not find survivor: " .. (args.survivor or "unknown"))
        return 
    end
    if not args.enemyId then 
        ModLina.LinaSay("No enemy ID specified.")
        return 
    end
    -- Pseudocode: issue attack order
    -- local enemy = find_enemy_by_id(args.enemyId)
    -- survivor:Attack(enemy)
    ModLina.LinaSay("Ordering " .. args.survivor .. " to attack enemy " .. args.enemyId)
end

ModLina.Skills.BoostWorkbench = function(args)
    ModLina.LinaSay("Boosting workbench: " .. (args.workbench or "unspecified"))
end

ModLina.Skills.ReorderProductionQueue = function(args)
    ModLina.LinaSay("Reordering production queue for: " .. (args.workbench or "unspecified"))
end

ModLina.Skills.StartHarvest = function(args)
    ModLina.LinaSay("Starting harvest of: " .. (args.resource or "unspecified"))
end

ModLina.Skills.StartHunt = function(args)
    ModLina.LinaSay("Starting hunt for: " .. (args.animal or "unspecified"))
end

ModLina.Skills.PlanStep = function(args)
    -- This is a meta-skill: record a step in a plan
    ModLina.LinaSay("Planned step: " .. (args.description or "No description"))
end

ModLina.Skills.ReportThreat = function(args)
    local threat_type = args.threat_type or "Unknown"
    local count = args.count or 0
    local message = "THREAT ALERT: " .. count .. " " .. threat_type
    if args.details then
        message = message .. " - " .. args.details
    end
    ModLina.LinaSay(message)
end

ModLina.Skills.ExplainReasoning = function(args)
    if args.reasoning then
        ModLina.LinaSay("Reasoning: " .. args.reasoning)
    end
end
