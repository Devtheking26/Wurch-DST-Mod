
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {

        Asset( "ANIM", "anim/player_basic.zip" ),
        Asset( "ANIM", "anim/player_idles_shiver.zip" ),
        Asset( "ANIM", "anim/player_actions.zip" ),
        Asset( "ANIM", "anim/player_actions_axe.zip" ),
        Asset( "ANIM", "anim/player_actions_pickaxe.zip" ),
        Asset( "ANIM", "anim/player_actions_shovel.zip" ),
        Asset( "ANIM", "anim/player_actions_blowdart.zip" ),
        Asset( "ANIM", "anim/player_actions_eat.zip" ),
        Asset( "ANIM", "anim/player_actions_item.zip" ),
        Asset( "ANIM", "anim/player_actions_uniqueitem.zip" ),
        Asset( "ANIM", "anim/player_actions_bugnet.zip" ),
        Asset( "ANIM", "anim/player_actions_fishing.zip" ),
        Asset( "ANIM", "anim/player_actions_boomerang.zip" ),
        Asset( "ANIM", "anim/player_bush_hat.zip" ),
        Asset( "ANIM", "anim/player_attacks.zip" ),
        Asset( "ANIM", "anim/player_idles.zip" ),
        Asset( "ANIM", "anim/player_rebirth.zip" ),
        Asset( "ANIM", "anim/player_jump.zip" ),
        Asset( "ANIM", "anim/player_amulet_resurrect.zip" ),
        Asset( "ANIM", "anim/player_teleport.zip" ),
        Asset( "ANIM", "anim/wilson_fx.zip" ),
        Asset( "ANIM", "anim/player_one_man_band.zip" ),
        Asset( "ANIM", "anim/shadow_hands.zip" ),
        Asset( "SOUND", "sound/sfx.fsb" ),
        Asset( "SOUND", "sound/wilson.fsb" ),
        Asset( "ANIM", "anim/beard.zip" ),
        Asset( "ANIM", "anim/spek.zip" ),
        Asset( "ANIM", "anim/speksum.zip" ),
        Asset( "ANIM", "anim/spekwin.zip" ),
        Asset( "ANIM", "anim/spekspr.zip" ),
        Asset( "ANIM", "anim/ghost_spek_build.zip" ),
}
local prefabs = {}
local start_inv = 
{
	"fireflies",
	"fireflies",
	"fireflies",
	"fireflies",
	"fireflies",
	"fireflies",
	"fireflies",
	"fireflies",
	"fireflies",
	"fireflies",
}
--Level Up

local function applyupgrades(inst)

	local max_upgrades = 30
	local upgrades = math.min(inst.level, max_upgrades)

	local hunger_percent = inst.components.hunger:GetPercent()
	local health_percent = inst.components.health:GetPercent()
	local sanity_percent = inst.components.sanity:GetPercent()

	inst.components.hunger.max = math.ceil (50 + upgrades * 2)
	inst.components.health.maxhealth = math.ceil (100 + upgrades * 2)
	inst.components.sanity.max = math.ceil (150 + upgrades * 2)
	
	inst.components.locomotor.walkspeed =  math.ceil (6 + upgrades / 6) --9
	inst.components.locomotor.runspeed = math.ceil (8 + upgrades / 5) --12
	
	inst.components.talker:Say("Level : ".. (inst.level))
	
	if inst.level >29 then
		inst.components.talker:Say("Level : Max!")
	end

	inst.components.hunger:SetPercent(hunger_percent)
	inst.components.health:SetPercent(health_percent)
	inst.components.sanity:SetPercent(sanity_percent)
	
end

local function oneat(inst, food)
	
	--if food and food.components.edible and food.components.edible.foodtype == "HELLO" then
	if food and food.components.edible and food.prefab == "dragonpie"  then
		--give an upgrade!
		inst.level = inst.level + 1
		applyupgrades(inst)	
		inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
		--inst.HUD.controls.status.heart:PulseGreen()
		--inst.HUD.controls.status.stomach:PulseGreen()
		--inst.HUD.controls.status.brain:PulseGreen()
		
		--inst.HUD.controls.status.brain:ScaleTo(1.3,1,.7)
		--inst.HUD.controls.status.heart:ScaleTo(1.3,1,.7)
		--inst.HUD.controls.status.stomach:ScaleTo(1.3,1,.7)
	end
end

local function onpreload(inst, data)
	if data then
		if data.level then
			inst.level = data.level
			applyupgrades(inst)
			--re-set these from the save data, because of load-order clipping issues
			if data.health and data.health.health then inst.components.health.currenthealth = data.health.health end
			if data.hunger and data.hunger.hunger then inst.components.hunger.current = data.hunger.hunger end
			if data.sanity and data.sanity.current then inst.components.sanity.current = data.sanity.current end
			inst.components.health:DoDelta(0)
			inst.components.hunger:DoDelta(0)
			inst.components.sanity:DoDelta(0)
		end
	end

end

local function WatchSeason( inst, season )
    if season == "summer" then
        inst.AnimState:SetBuild("speksum")
    elseif season == "winter" then
        inst.AnimState:SetBuild("spekwin")
    elseif season == "spring" then
        inst.AnimState:SetBuild("spekspr")
    else
        inst.AnimState:SetBuild("spek")
    end
end


local function sanityfn(inst) -- Function to determine sanity boost or drain based on precipitation / season
	local delta = 0

	if TheWorld.state.iswinter and not TheWorld.state.israining then -- Winter sanity drain
		delta = (-1*TUNING.DAPPERNESS_TINY)
	
	elseif TheWorld.state.iswinter and TheWorld.state.israining and TheWorld.state.temperature > 0 then	-- Winter and raining, so sanity boost
		delta = (TUNING.DAPPERNESS_MED*1.5*TheWorld.state.precipitationrate) + (TUNING.DAPPERNESS_TINY*5.3)

	elseif TheWorld.state.iswinter and TheWorld.state.israining and TheWorld.state.temperature < 0 then -- Winter and snowing, so sanity drain
		delta = (-1*TUNING.DAPPERNESS_TINY)
		
	elseif TheWorld.state.israining then -- Raining sanity boost
		delta = (TUNING.DAPPERNESS_MED*1.5*TheWorld.state.precipitationrate) + (TUNING.DAPPERNESS_TINY*5.3)
	
  	end	
    
    return delta -- TUNING
end


-- This initializes for both clients and the host
local common_postinit = function(inst) 
	-- choose which sounds this character will play
	inst.soundsname = "wendy"
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "spek.tex" )
end

local function onsave(inst, data)
	data.level = inst.level
	data.charge_time = inst.charge_time
end

-- Stats	
local function master_postinit(inst)
	inst.components.sanity.custom_rate_fn = sanityfn -- Takes care of sanity boost/drain at all times
	inst.level = 0
	inst.components.eater:SetOnEatFn(oneat)
	inst.OnSave = onsave
	inst.OnPreLoad = onpreload
	inst.components.sanity:SetMax(150)
	inst.components.health:SetMaxHealth(100)
	inst.components.hunger:SetMax(50)
	inst.components.eater:SetDiet({FOODGROUP.OMNI}, {FOODGROUP.OMNI_NOMEAT})
    inst:WatchWorldState("season", WatchSeason )
	WatchSeason( inst, TheWorld.state.season )

local function updateHungerRate(inst, mult)    
   inst.components.hunger:SetRate(mult*TUNING.WILSON_HUNGER_RATE)
end
inst:WatchWorldState( "startday", function() updateHungerRate(inst, -.5) end )
inst:WatchWorldState( "startdusk", function() updateHungerRate(inst, .3) end )
inst:WatchWorldState( "startnight", function() updateHungerRate(inst, 2) end )
local mult = 0
if TheWorld.state.isday then mult = -.5
elseif TheWorld.state.isnight then mult = 2 end
updateHungerRate(inst, mult)
end



return MakePlayerCharacter("spek", prefabs, assets, common_postinit, master_postinit, start_inv)
