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
    for _, s in ipairs(GetAllCharacters()) do
        list[#list+1] = {
            Name = s.Name,
            Health = s.Health or 100,
            Stress = s.Stress or 0,
            Combat = s.Combat or 0,
            Position = s:GetPos() and { x = s:GetPos():x(), y = s:GetPos():y() } or nil,
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
    -- Query territorial nests (shriekers, etc.)
    local all = MapGet("map", "TerritorialNest") or {}
    for _, n in ipairs(all) do
        nests[#nests+1] = {
            Id = n.handle or tostring(n),
            Class = n.class or "TerritorialNest",
            AdultClass = n.adult_class,
            HatchlingClass = n.hatchling_class,
            ElderClass = n.elder_class,
            Position = n:GetPos() and { x = n:GetPos():x(), y = n:GetPos():y() } or nil,
            Health = n.Health or 100,
            MaxHealth = n.MaxHealth or 100,
            Visible = n:GetVisible() or false,
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
    
    -- Collect hostile animals
    MapForEach("map", "UnitAnimal", function(u)
        if u:IsHostile() then
            enemies.Animals[#enemies.Animals+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "UnitAnimal",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = u:GetUnitHealthPercent() or 100,
                Position = u:GetPos() and { x = u:GetPos():x(), y = u:GetPos():y() } or nil,
                Aggressive = u:IsAggressive() or false,
            }
            enemies.Total = enemies.Total + 1
        end
    end)
    
    -- Collect invaders
    MapForEach("map", "UnitInvader", function(u)
        if u:IsHostile() then
            enemies.Invaders[#enemies.Invaders+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "UnitInvader",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = u:GetUnitHealthPercent() or 100,
                Position = u:GetPos() and { x = u:GetPos():x(), y = u:GetPos():y() } or nil,
                Aggressive = u:IsAggressive() or false,
            }
            enemies.Total = enemies.Total + 1
        end
    end)
    
    -- Collect combat robots
    MapForEach("map", "CombatRobot", function(u)
        if u:IsHostile() then
            enemies.Robots[#enemies.Robots+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "CombatRobot",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = u:GetUnitHealthPercent() or 100,
                Position = u:GetPos() and { x = u:GetPos():x(), y = u:GetPos():y() } or nil,
                Aggressive = u:IsAggressive() or false,
            }
            enemies.Total = enemies.Total + 1
        end
    end)
    
    return enemies
end
