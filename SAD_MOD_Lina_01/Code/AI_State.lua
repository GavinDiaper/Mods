ModLina = rawget(_G, "ModLina") or {}

ModLina.State = {
    Survivors = {},
    Resources = {},
    Colony = {
        BaseCenter = nil,
        BuildingCount = 0,
    },
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

local function get_tracking_table()
    if not rawget(_G, "ModLinaState") or not ModLinaState then
        return nil
    end

    ModLinaState.enemy_tracking = ModLinaState.enemy_tracking or {}
    return ModLinaState.enemy_tracking
end

local function get_point_xy(point)
    if not point then
        return nil, nil
    end

    local ok_x, x = pcall(point.x, point)
    local ok_y, y = pcall(point.y, point)
    if ok_x and ok_y then
        return x, y
    end

    return nil, nil
end

local function distance_2d(a, b)
    if not a or not b then
        return nil
    end

    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return ((dx * dx) + (dy * dy)) ^ 0.5
end

local function get_move_speed(u)
    if not u then return nil end

    local method_names = {
        "GetMoveSpeed",
        "GetMovementSpeed",
        "GetTravelSpeed",
        "GetSpeed",
    }

    for i = 1, #method_names do
        local name = method_names[i]
        local method = u[name]
        if method then
            local ok, value = pcall(method, u)
            if ok and type(value) == "number" and value > 0 then
                return value
            end
        end
    end

    local field_names = {
        "MoveSpeed",
        "MovementSpeed",
        "TravelSpeed",
        "Speed",
        "Movement",
    }

    for i = 1, #field_names do
        local value = u[field_names[i]]
        if type(value) == "number" and value > 0 then
            return value
        end
    end

    return nil
end

local function sample_speed(id, pos, direct_speed)
    if direct_speed and direct_speed > 0 then
        return direct_speed
    end

    local tracking = get_tracking_table()
    if not tracking or not id or not pos then
        return nil
    end

    local now = RealTime and RealTime() or 0
    local previous = tracking[id]
    tracking[id] = {
        x = pos.x,
        y = pos.y,
        time = now,
    }

    if not previous or not previous.time or previous.time >= now then
        return nil
    end

    local elapsed_seconds = (now - previous.time) / 1000
    if elapsed_seconds <= 0 then
        return nil
    end

    local dx = pos.x - previous.x
    local dy = pos.y - previous.y
    local distance = ((dx * dx) + (dy * dy)) ^ 0.5
    local sampled_speed = distance / elapsed_seconds
    if sampled_speed > 0 then
        return sampled_speed
    end

    return nil
end

function ModLina.UpdateState()
    if rawget(_G, "print") then
        print("[ModLina:AI_State] UpdateState() called")
    end
    ModLina.State.Survivors = ModLina.CollectSurvivors()
    ModLina.State.Resources = ModLina.CollectResources()
    ModLina.State.Colony = ModLina.CollectColonyData()
    ModLina.State.Threats.ShriekerNests = ModLina.CollectShriekerNests()
    ModLina.State.Threats.ActiveEnemies = ModLina.CollectActiveEnemies()
    if rawget(_G, "print") then
        print("[ModLina:AI_State] UpdateState() complete. Total enemies: " .. tostring(ModLina.State.Threats.ActiveEnemies.Total or 0))
    end
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

function ModLina.CollectColonyData()
    local colony = {
        BaseCenter = nil,
        BuildingCount = 0,
    }

    if not rawget(_G, "GetAllObjects") or not rawget(_G, "IsKindOf") then
        return colony
    end

    local sum_x = 0
    local sum_y = 0
    local count = 0

    for _, obj in ipairs(GetAllObjects()) do
        if obj and not obj.destroyed and (IsKindOf(obj, "Building") or IsKindOf(obj, "Workbench")) and obj.GetPos then
            local ok_pos, p = pcall(obj.GetPos, obj)
            if ok_pos and p then
                local x, y = get_point_xy(p)
                if x and y then
                    sum_x = sum_x + x
                    sum_y = sum_y + y
                    count = count + 1
                end
            end
        end
    end

    colony.BuildingCount = count
    if count > 0 then
        colony.BaseCenter = {
            x = sum_x / count,
            y = sum_y / count,
        }
    end

    return colony
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
        if rawget(_G, "print") then
            print("[ModLina:AI_State] MapForEach not available")
        end
        return enemies
    end

    if rawget(_G, "print") then
        print("[ModLina:AI_State] CollectActiveEnemies() starting scan")
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
            local x, y = get_point_xy(p)
            if x and y then
                return { x = x, y = y }
            end
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
            local pos = get_pos(u)
            local speed = sample_speed(u.handle or tostring(u), pos, get_move_speed(u))
            enemies.Animals[#enemies.Animals+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "UnitAnimal",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = get_hp_percent(u),
                Position = pos,
                Aggressive = is_aggressive(u),
                Speed = speed,
            }
            enemies.Total = enemies.Total + 1
        end
    end)
    
    if rawget(_G, "print") and #enemies.Animals > 0 then
        print("[ModLina:AI_State] Found " .. tostring(#enemies.Animals) .. " hostile animals")
    end
    
    -- Collect invaders
    MapForEach("map", "UnitInvader", function(u)
        if is_hostile(u) then
            local pos = get_pos(u)
            local speed = sample_speed(u.handle or tostring(u), pos, get_move_speed(u))
            enemies.Invaders[#enemies.Invaders+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "UnitInvader",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = get_hp_percent(u),
                Position = pos,
                Aggressive = is_aggressive(u),
                Speed = speed,
            }
            enemies.Total = enemies.Total + 1
        end
    end)
    
    if rawget(_G, "print") and #enemies.Invaders > 0 then
        print("[ModLina:AI_State] Found " .. tostring(#enemies.Invaders) .. " invaders")
    end
    
    if rawget(_G, "print") and #enemies.Robots > 0 then
        print("[ModLina:AI_State] Found " .. tostring(#enemies.Robots) .. " robots")
    end

    -- Collect combat robots
    MapForEach("map", "CombatRobot", function(u)
        if is_hostile(u) then
            local pos = get_pos(u)
            local speed = sample_speed(u.handle or tostring(u), pos, get_move_speed(u))
            enemies.Robots[#enemies.Robots+1] = {
                Id = u.handle or tostring(u),
                Class = u.class or "CombatRobot",
                Health = u.Health or 100,
                MaxHealth = u.MaxHealth or 100,
                HealthPercent = get_hp_percent(u),
                Position = pos,
                Aggressive = is_aggressive(u),
                Speed = speed,
            }
            enemies.Total = enemies.Total + 1
        end
    end)
    
    if rawget(_G, "print") then
        print("[ModLina:AI_State] CollectActiveEnemies() complete - Total: " .. tostring(enemies.Total))
    end
    
    return enemies
end

function ModLina.GetNearestThreatSummary()
    local threats = ModLina.State.Threats and ModLina.State.Threats.ActiveEnemies
    local colony = ModLina.State.Colony or {}
    local center = colony.BaseCenter
    if not threats or not center then
        return nil
    end

    local nearest = nil
    local categories = { threats.Animals or empty_table, threats.Invaders or empty_table, threats.Robots or empty_table }
    for i = 1, #categories do
        local category = categories[i]
        for j = 1, #category do
            local enemy = category[j]
            local dist = distance_2d(enemy.Position, center)
            if dist and (not nearest or dist < nearest.Distance) then
                local eta_seconds = nil
                if enemy.Speed and enemy.Speed > 0 then
                    eta_seconds = dist / enemy.Speed
                end

                nearest = {
                    Enemy = enemy,
                    Distance = dist,
                    EtaSeconds = eta_seconds,
                    BaseCenter = center,
                }
            end
        end
    end

    return nearest
end
