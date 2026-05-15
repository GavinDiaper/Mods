ModLina = ModLina or {}

ModLina.State = {
    Survivors = {},
    Resources = {},
    Threats = {
        ActiveEnemies = {},
        ShriekerNests = {},
        Other = {},
    },
    Time = {
        Hour = 0,
        Day = 0,
    }
}

function ModLina.UpdateState()
    ModLina.State.Survivors = ModLina.CollectSurvivors()
    ModLina.State.Resources = ModLina.CollectResources()
    ModLina.State.Threats.ShriekerNests = ModLina.CollectShriekerNests()
    ModLina.State.Threats.ActiveEnemies = ModLina.CollectActiveEnemies()
    -- Future: other threats, defenses, turrets, etc.
end

function ModLina.CollectSurvivors()
    local list = {}
    if not rawget(_G, "GetAllCharacters") then
        return list
    end

    for _, s in ipairs(GetAllCharacters()) do
        local pos = nil
        if s.GetPos then
            local ok_pos, p = pcall(s.GetPos, s)
            if ok_pos and p then
                pos = { x = p:x(), y = p:y() }
            end
        end

        list[#list+1] = {
            Name = s.Name,
            Health = s.Health or 100,
            Stress = s.Stress or 0,
            Combat = s.Combat or 0,
            Position = pos,
            Traits = s.traits or {},
        }
    end
    return list
end

function ModLina.CollectResources()
    -- Simplified; you can expand this
    return {
        Cloth = Resources["Cloth"] or 0,
        Food = Resources["Food"] or 0,
        Metal = Resources["Metal"] or 0,
        Medicine = Resources["Medicine"] or 0,
    }
end

function ModLina.CollectShriekerNests()
    local nests = {}
    if not rawget(_G, "MapGet") then
        return nests
    end

    -- Query territorial nests (shriekers, etc.)
    local all = MapGet("map", "TerritorialNest") or {}
    for _, n in ipairs(all) do
        local pos = nil
        if n.GetPos then
            local ok_pos, p = pcall(n.GetPos, n)
            if ok_pos and p then
                pos = { x = p:x(), y = p:y() }
            end
        end

        local visible = false
        if n.GetVisible then
            local ok_vis, v = pcall(n.GetVisible, n)
            if ok_vis then
                visible = v and true or false
            end
        end

        nests[#nests+1] = {
            Id = n.handle or tostring(n),
            Class = n.class or "TerritorialNest",
            AdultClass = n.adult_class,
            HatchlingClass = n.hatchling_class,
            ElderClass = n.elder_class,
            Position = pos,
            Health = n.Health or 100,
            MaxHealth = n.MaxHealth or 100,
            Visible = visible,
        }
    end
    return nests
end

function ModLina.CollectActiveEnemies()
    local enemies = {
        Animals = {},
        Invaders = {},
        Robots = {},
        Total = 0,
    }

    if not rawget(_G, "MapForEach") then
        return enemies
    end

    local function is_hostile(u)
        if not u then return false end
        if u.IsHostile then
            local ok, val = pcall(u.IsHostile, u)
            if ok then return val and true or false end
        end
        return u.CombatHostile == true or u.Invader == true
    end

    local function is_aggressive(u)
        if not u then return false end
        if u.IsAggressive then
            local ok, val = pcall(u.IsAggressive, u)
            if ok then return val and true or false end
        end
        return false
    end

    local function get_pos(u)
        if not u or not u.GetPos then return nil end
        local ok, p = pcall(u.GetPos, u)
        if ok and p then
            return { x = p:x(), y = p:y() }
        end
        return nil
    end

    local function get_hp_percent(u)
        if not u then return 100 end
        if u.GetUnitHealthPercent then
            local ok, val = pcall(u.GetUnitHealthPercent, u)
            if ok and val ~= nil then
                return val
            end
        end
        return 100
    end
    
    -- Collect hostile animals
    MapForEach("map", "UnitAnimal", function(u)
        if is_hostile(u) then
            enemies.Animals[#enemies.Animals+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "UnitAnimal",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = get_hp_percent(u),
                Position = get_pos(u),
                Aggressive = is_aggressive(u),
            }
            enemies.Total = enemies.Total + 1
        end
    end)
    
    -- Collect invaders
    MapForEach("map", "UnitInvader", function(u)
        if is_hostile(u) then
            enemies.Invaders[#enemies.Invaders+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "UnitInvader",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = get_hp_percent(u),
                Position = get_pos(u),
                Aggressive = is_aggressive(u),
            }
            enemies.Total = enemies.Total + 1
        end
    end)
    
    -- Collect combat robots
    MapForEach("map", "Robot", function(u)
        if is_hostile(u) then
            enemies.Robots[#enemies.Robots+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "Robot",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = get_hp_percent(u),
                Position = get_pos(u),
                Aggressive = is_aggressive(u),
            }
            enemies.Total = enemies.Total + 1
        end
    end)

    -- Collect combat robots
    MapForEach("map", "CombatRobot", function(u)
        if is_hostile(u) then
            enemies.Robots[#enemies.Robots+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "CombatRobot",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = get_hp_percent(u),
                Position = get_pos(u),
                Aggressive = is_aggressive(u),
            }
            enemies.Total = enemies.Total + 1
        end
    end)
    
    return enemies
end
