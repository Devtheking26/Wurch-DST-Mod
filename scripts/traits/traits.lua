local Traits = {}

local function IsTree(ent)
    if ent == nil then
        return false
    end
    if ent:HasTag("tree") or ent:HasTag("evergreen") or ent:HasTag("deciduoustree") then
        if not ent:HasTag("burnt") and not ent:HasTag("stump") then
            return true
        else
            return false
        end
    else
        return false
    end
end

function Traits.photosyntheticRegen(inst)
    -- Tuning values
    local DAY_MULT   = -0.4    -- negative = hunger regen
    local DUSK_MULT  = 1     -- normal drain
    local NIGHT_MULT = 1.5     -- heavy drain

    local function updateHungerRate(mult, phase)
        if inst.components.hunger then
            inst.components.hunger:SetRate(mult * TUNING.WILSON_HUNGER_RATE)
        end
    end

    -- Reactive updates
    inst:WatchWorldState("startday",   function() updateHungerRate(DAY_MULT,   "Day")   end)
    inst:WatchWorldState("startdusk",  function() updateHungerRate(DUSK_MULT,  "Dusk")  end)
    inst:WatchWorldState("startnight", function() updateHungerRate(NIGHT_MULT, "Night") end)

    -- Immediate initialization based on current time
    inst:DoTaskInTime(0, function()
        if TheWorld.state.isday then
            updateHungerRate(DAY_MULT, "Day")
        elseif TheWorld.state.isdusk then
            updateHungerRate(DUSK_MULT, "Dusk")
        elseif TheWorld.state.isnight then
            updateHungerRate(NIGHT_MULT, "Night")
        end
    end)
end

function Traits.temperatureResistant(inst)
    local INSULATION_60 = TUNING.INSULATION_LARGE * 0.6
    inst.components.temperature.inherentinsulation = INSULATION_60
    inst.components.temperature.inherentsummerinsulation = INSULATION_60
end

function Traits.seasonalStats(inst)
    if not TheWorld.ismastersim then
        return
    end

    local function ApplySeasonalStats()
        local season = TheWorld.state.season

        -- Reset to baseline
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "trait_seasonal_speed", 1)
        inst.components.hunger.burnratemodifiers:RemoveModifier("trait_seasonal_hunger")

        if season == "spring" then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "trait_seasonal_speed", 1.10)
            inst.components.hunger.burnratemodifiers:SetModifier("trait_seasonal_hunger", 0.90)

        elseif season == "summer" then
            inst.components.hunger.burnratemodifiers:SetModifier("trait_seasonal_hunger", 1.10)

        elseif season == "winter" then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "trait_seasonal_speed", 0.90)
            inst.components.hunger.burnratemodifiers:SetModifier("trait_seasonal_hunger", 1.10)
        end
    end

    inst:WatchWorldState("season", ApplySeasonalStats)
    inst:DoTaskInTime(0, ApplySeasonalStats) -- Apply immediately on spawn
end

function Traits.birchkinAlly(inst)
    if not TheWorld.ismastersim then
        return
    end

    -- Tag for AI recognition
    inst:AddTag("birchkin_ally")

    -- Ignore logic for newly spawned birchkin
    inst:ListenForEvent("entity_spawned", function(_, data)
        local ent = data and data.entity
        if not ent then return end

        -- Birchnutters
        if ent:HasTag("birchnutdrake") then
            ent:AddTag("ignore_"..inst.prefab)

        -- Poison birch trees
        elseif ent.prefab == "deciduoustree" and ent.monster then
            if ent.components.combat then
                ent.components.combat:SuggestTarget(nil)
            end
        end
    end, TheWorld)
end

function Traits.timberGuilt(inst)
    if not TheWorld.ismastersim then
        return
    end

    local SANITY_CHOP    = -1

    -- Sanity hit on chopping
    inst:ListenForEvent("working", function(_, data)
        --print("[working] Event triggered")

        if not data or not data.target then
            --print("[working] No data or target")
            return
        end

        --print("[working] Target prefab:", data.target.prefab)

        local is_tree = IsTree(data.target)
        --print("[working] IsTree returned:", tostring(is_tree))

        -- Check workable.action instead of data.action
        if is_tree
           and data.target.components.workable
           and data.target.components.workable.action == ACTIONS.CHOP then
            --print("[working] Sanity penalty applied:", SANITY_CHOP)
            inst.components.sanity:DoDelta(SANITY_CHOP)
        else
            --print("[working] Conditions not met — no sanity change")
        end
    end)
end

function Traits.sanityOnPlant(inst)
  local SANITY_PLANT   = 5
  -- Sanity gain on planting specific trees
  local valid_saplings = {
      pinecone       = true, -- Evergreen
      acorn          = true, -- Birchnut Tree
      twiggy_nut     = true, -- Twiggy Tree
      palmcone_seed  = true -- Palm Tree
  }

  inst:ListenForEvent("deployitem", function(_, data)
      if data and data.prefab and valid_saplings[data.prefab] then
          inst.components.sanity:DoDelta(SANITY_PLANT)
      end
  end)
end

function Traits.sanityImmunities(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.sanity then
        inst.components.sanity:SetNegativeAuraImmunity(true)  -- Ignores monster auras
        inst.components.sanity:SetPlayerGhostImmunity(true)   -- Ignores nearby ghost drain
    end
end

local TUNING_FIREPANIC = {
    RADIUS = 10,           -- Search radius for burning entities
    MAX_DRAIN = 10,        -- Max entities contributing to drain
    DPS = 0.05             -- Drain per second per entity
}

function Traits.naturesHarmony(inst)
    if not TheWorld.ismastersim then
        return
    end

    -- ===== Tuning =====
    local TREE_RADIUS     = 10
    local SMALL_RATE      = 2 / 60     -- sanity/sec for 1–2 trees
    local MEDIUM_RATE     = 5 / 60     -- sanity/sec for 3–5 trees
    local LARGE_RATE      = 9 / 60     -- sanity/sec for 6+ trees

    -- ===== Combined Rate Function =====
    local function CombinedSanityRate()
        -- --- Tree bonus ---
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, TREE_RADIUS)

        local count = 0
        for _, ent in ipairs(ents) do
            if IsTree(ent) then
                count = count + 1
            end
        end

        local tree_rate = 0
        if count >= 6 then
            tree_rate = LARGE_RATE
        elseif count >= 3 then
            tree_rate = MEDIUM_RATE
        elseif count >= 1 then
            tree_rate = SMALL_RATE
        end

        -- --- Fire panic drain ---
        local burning = 0
        local fire_ents = TheSim:FindEntities(x, y, z, TUNING_FIREPANIC.RADIUS)

        --print(string.format("[firePanic] Found %d entities in radius %d", #fire_ents, TUNING_FIREPANIC.RADIUS))

        for _, ent in ipairs(fire_ents) do
            local prefab = ent.prefab or "nil prefab"
            local has_burning = ent:HasTag("burning")
            local has_fire = ent:HasTag("fire")
            local is_burning_comp = ent.components.burnable and ent.components.burnable:IsBurning() or false

            --print(string.format("[firePanic] Checking: %s | burning=%s | fire=%s | IsBurning()=%s",
                --prefab, tostring(has_burning), tostring(has_fire), tostring(is_burning_comp)))

            -- Exclude torches and campfires
            if prefab ~= "torch" and prefab ~= "campfire" and prefab ~= "firepit" then
                if ent:IsValid() and (has_burning or has_fire or is_burning_comp) then
                    burning = burning + 1
                    --print("[firePanic] burning count incremented to:", burning)
                end
            else
                --print("[firePanic] Skipped excluded prefab:", prefab)
            end
        end

        local burn_count = math.min(burning, TUNING_FIREPANIC.MAX_DRAIN)
        local fire_rate = burn_count > 0 and -(TUNING_FIREPANIC.DPS * burn_count) or 0

        return tree_rate + fire_rate
    end -- ✅ closes CombinedSanityRate

    -- ===== Hook into sanity component =====
    if inst.components.sanity then
        inst.components.sanity.custom_rate_fn = CombinedSanityRate
        inst.components.sanity.rate_modifier = 1 -- ensures function runs every tick
    end
end

return Traits
