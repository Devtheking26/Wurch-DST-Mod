local MakePlayerCharacter = require "prefabs/player_common"
local DietFilter = require("components/dietfilter")
local Traits = require("traits/traits")

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}

-- Your character's stats
TUNING.wurch_HEALTH = 128
TUNING.wurch_HUNGER = 80
TUNING.wurch_SANITY = 125

-- Custom starting inventory
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.wurch = {
  "acorn", "acorn",
"acorn", "acorn",
"acorn" }

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.wurch
end

local prefabs = FlattenTree(start_inv, true)

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when not a ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wurch_speed_mod", 1)
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
   inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wurch_speed_mod")
end

-- When loading or spawning the character
local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
end


-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst)
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "wurch.tex" )
  inst:AddTag("wurch")
  inst:AddTag("birchnutdrake")
end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
	-- Set starting inventory
  inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	-- choose which sounds this character will play
	inst.soundsname = "webber"

  --set stats
	inst.components.health:SetMaxHealth(TUNING.wurch_HEALTH)
	inst.components.hunger:SetMax(TUNING.wurch_HUNGER)
	inst.components.sanity:SetMax(TUNING.wurch_SANITY)

    --Add all components
    inst:AddComponent("equippable")

    --Add Diet
    inst:AddComponent("dietfilter")
    inst.components.dietfilter:Apply()

    --add traits
    Traits.photosyntheticRegen(inst) --Good To go
    Traits.temperatureResistant(inst) -- Probs working
    Traits.seasonalStats(inst) --Probs Working
    Traits.birchkinAlly(inst)--testing
    Traits.timberGuilt(inst)--good
    Traits.sanityImmunities(inst)--Should just work (lowkey)
    Traits.sanityOnPlant(inst)--Good to go
    Traits.naturesHarmony(inst)

	inst.OnLoad = onload
    inst.OnNewSpawn = onload

end

return MakePlayerCharacter("wurch", prefabs, assets, common_postinit, master_postinit)
