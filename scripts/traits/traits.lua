local Traits = {}

function Traits.photosyntheticRegen(inst)
    -- Tuning values
    local DAY_MULT   = -0.4    -- negative = hunger regen
    local DUSK_MULT  = 1     -- normal drain
    local NIGHT_MULT = 1.5     -- 2x drain

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

return Traits
