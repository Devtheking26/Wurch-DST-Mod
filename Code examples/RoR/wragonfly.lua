local MakePlayerCharacter = require "prefabs/player_common"

local assets = 
{
		Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
		Asset("ANIM", "anim/wragonfly.zip"),
		Asset("ANIM", "anim/wragonfly_enraged.zip"),
	    Asset("ANIM", "anim/ghost_wragonfly_build.zip" ),
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WRAGONFLY
end
local prefabs = FlattenTree(start_inv, true)

local function GetRageStatus(inst)
    return inst:HasTag("playerghost")
        and string.upper("GHOST")
        or string.upper("ENRAGED")
end

local function EnragedSanityFn()
    return -TUNING.SANITYAURA_SMALL
end

local function ChangeNormalBuild(inst)
	if inst.components.timer:TimerExists("enraged") then
	    inst.components.timer:StopTimer("enraged")
	end

	if inst.components.inspectable.getstatus == GetRageStatus then
        inst.components.inspectable.getstatus = inst._getstatus
        inst._getstatus = nil
    end
	---(change build back to normal here)---
	if not inst.sg:HasStateTag("ghostbuild") then
		inst.components.skinner:SetSkinMode("normal_skin", "wragonfly")
	end

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())

	inst:RemoveTag("Enraged")
	inst.components.timer:StartTimer("cooldown", TUNING.WFLY_ENRAGED_CDTIME)

    if inst.components.health ~= nil and not inst.components.health:IsDead() then
	inst.components.health.maxhealth = 200
	inst.components.health:DoDelta(0)
	end

	inst.components.health.fire_damage_scale = TUNING.WFLY_FIRE_IMMUNE

	inst.components.combat.damagemultiplier = 1

	inst.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE)
	inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED

	inst.components.temperature.mintemp = TUNING.MIN_ENTITY_TEMP
	inst.components.temperature.maxtemp = TUNING.MAX_ENTITY_TEMP + 9

    if inst.components.freezable ~= nil then
	inst.components.freezable:SetResistance(4)
	end

	inst.components.sanity.custom_rate_fn = nil

	inst.enraged = false
end

local function onisraining(inst, issnowing)
	if issnowing then
	if inst:HasTag("Enraged") then--Currently only fires when precip starts but not if it was already falling
		inst:DoTaskInTime(10, function()
			ChangeNormalBuild(inst)
			inst.components.talker:Say(GetString(inst, "ANNOUNCE_ENRAGED_EXTINGUISHED"))
			inst.sg:PushEvent("powerdown")
		end)
	end
	end
end

local function UpdateMoist(self, dt)
    if self.inst.components.timer:TimerExists("enraged") then
	if self.inst.components.moisture ~= nil and self.inst.components.moisture:GetMoisture() > 30 then
		ChangeNormalBuild(self.inst)
		self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_ENRAGED_EXTINGUISHED"))
		self.inst.sg:PushEvent("powerdown")
	end
	end

	if self.forceddrymodifiers:Get() then
        --can still get here even if we're not in the update list
        --i.e. LongUpdate or OnUpdate called explicitly
        return
    end

    local sleepingbagdryingrate = self:GetSleepingBagDryingRate()
    if sleepingbagdryingrate ~= nil then
        self.rate = -sleepingbagdryingrate
    else
        local moisturerate = self:GetMoistureRate()
        local dryingrate = self:GetDryingRate(moisturerate)
        local equippedmoisturerate = self:GetEquippedMoistureRate(dryingrate)

        self.rate = moisturerate + equippedmoisturerate - dryingrate
    end

    self.ratescale =
        (self.rate > .3 and RATE_SCALE.INCREASE_HIGH) or
        (self.rate > .15 and RATE_SCALE.INCREASE_MED) or
        (self.rate > .001 and RATE_SCALE.INCREASE_LOW) or
        (self.rate < -3 and RATE_SCALE.DECREASE_HIGH) or
        (self.rate < -1.5 and RATE_SCALE.DECREASE_MED) or
        (self.rate < -.001 and RATE_SCALE.DECREASE_LOW) or
        RATE_SCALE.NEUTRAL

    self:DoDelta(self.rate * dt)
end

local function SetEnrageBuild(inst)
	if not inst:HasTag("Enraged") then
		inst.components.skinner:SetSkinMode("powerup", "wragonfly_enraged")
	end

	if inst.components.inspectable.getstatus ~= GetRageStatus then
        inst._getstatus = inst.components.inspectable.getstatus
        inst.components.inspectable.getstatus = GetRageStatus
    end

	inst.components.moisture.OnUpdate = UpdateMoist

	inst.components.health.maxhealth = inst.components.health.maxhealth + TUNING.WFLY_ENRAGE_MAXHP
    inst.components.health:DoDelta(0)

	inst.components.health.fire_damage_scale = 0 --0

	inst.components.combat.damagemultiplier = 1.1 --10%

    inst.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE * 3) --Not weapons, unarmed only
	inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED + 1.2 --7 --20%

	inst.components.temperature.mintemp = 60
	inst.components.temperature.maxtemp = 60

	inst.components.moisture:DoDelta(-inst.components.moisture:GetMoisture())--Remove any moisture, since she can still have a little before she cannot enrage

    if inst.components.freezable ~= nil then
    inst.components.freezable:SetResistance(8)--Default is 4, willow 3, real enraged dfly 12
	end

	inst.components.sanity.custom_rate_fn = EnragedSanityFn

	inst.enraged = true
end

local function DoFireRing(inst, x, z)
	local ring = SpawnPrefab("firering_fx")
	ring.Transform:SetScale(.75, .75, .75)
	ring.Transform:SetPosition(x, 0, z)
	SpawnPrefab("firesplash_fx").Transform:SetPosition(x, 0, z)
end

local function FireFx(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
        local numFX = math.random(2, 4)
        for i = 1, numFX do
            inst:DoTaskInTime(math.random() * .25, DoFireRing, x, z)
			inst:DoTaskInTime(math.random() * .45, inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh"), x, z)
	    end
	local tauntfx = SpawnPrefab("tauntfire_fx")
	tauntfx.Transform:SetScale(.75, .75, .75)
	tauntfx.Transform:SetPosition(x, 0, z)
end

local function EnRage(inst)
	local x, y, z = inst.Transform:GetWorldPosition()

	inst:DoTaskInTime(math.random() * .25, ShakeAllCameras(CAMERASHAKE.FULL, 1, .015, .3, inst, 30))
	FireFx(inst)
	inst.components.talker:Say(GetString(inst, "ANNOUNCE_ENRAGED"))
	inst.SoundEmitter:PlaySound("dontstarve/characters/wragonfly/emote")
	SetEnrageBuild(inst)-- here is where we make the change to the build and stats
	inst.AnimState:PlayAnimation("boat_jump_pre")
	inst.AnimState:PushAnimation("boat_jump_pst", false)

    if not inst:HasTag("icedfly") then
	local ents = TheSim:FindEntities(x, y, z, 8, nil)
	for k,v in pairs(ents) do
	    if v and v:IsValid() and v.components.combat ~= nil and
		v.components.health ~= nil and not v.components.health:IsDead() then
		if not (v:HasTag("player") or v:HasTag("wragonflyminion") or v:HasTag("abigail") or v:HasTag("wall") or v:HasTag("companion") or
		    v:HasTag("INLIMBO") or 
			v:HasTag("structure")) then
				v.components.combat:GetAttacked(v, 5)
				--if v.components.burnable ~= nil and math.random() < TUNING.TORCH_ATTACK_IGNITE_PERCENT * v.components.burnable.flammability then 
				--v.components.burnable:Ignite(nil, v) end
				if TheNet:GetServerGameMode() == "lavaarena" then
                    v.components.debuffable:AddDebuff("debuff_fire", "debuff_fire")
		        end
		end
	    elseif v and v:HasTag("campfire") then
		if v.components.fueled ~= nil then
		    v.components.fueled:DoDelta(TUNING.MED_FUEL)
		end
	    end
	end
	end
    
end

local function ontimerdone(inst, data)
	if data.name == "enraged" then
	   if not inst:HasTag("playerghost") then
	    ChangeNormalBuild(inst)
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_ENRAGED_OVER"))
	   end
    end

	if data.name == "cooldown" then
	    inst.tick = 0
	    inst.starttime = nil
	    inst.endtime = nil
	    --(some visuals to let me know when wragonfly is off of cooldown)--
	    local readyfx = SpawnPrefab("deer_fire_burst")
	    readyfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_ENRAGE_CD_OVER"))
    end

	if data.name == "iced" then
		inst:RemoveTag("icedfly")
	end
end

local function oneat(inst, food)
	if food and food.prefab == "ash" then--Charcoal is BURNT too, stick with only ash
	    if inst.starttime ~= nil and inst.endtime ~= nil then
			if GetTime() < inst.endtime then
				inst.tick = inst.tick + 1 --quick eat timing set up for how long it would take to rack up ticks
			end
			if GetTime() > inst.endtime then
			    inst.starttime = nil
			end
			if inst.tick ~= nil and inst.tick == TUNING.WFLY_MAX_ASHES then--8
				if inst.components.timer:TimerExists("enraged") or inst.components.timer:TimerExists("cooldown") 
				or inst.components.moisture:GetMoisture() > 30 or inst.components.temperature:GetCurrent() < 10 then
		            return
	            else
				EnRage(inst)
				inst:AddTag("Enraged")
				inst.components.timer:StartTimer("enraged", TUNING.WFLY_ENRAGED_TIME)
				end
			end
			if inst.tick ~= nil and inst.tick >= TUNING.WFLY_MAX_ASHES + 2 then--10
                if inst.components.grogginess ~= nil then
                inst.components.grogginess:AddGrogginess(1, 2)
                end
			end
		end
		if inst.starttime == nil then
			inst.starttime = GetTime()
			inst.endtime = inst.starttime + 20
			inst.tick = 1
		end
	end

	if food and food.prefab == "ice" then
	if inst.components.timer:TimerExists("iced") then
		return
	else
		inst:AddTag("icedfly")
		inst.components.timer:StartTimer("iced", TUNING.WFLY_ENRAGED_TIME)
	end
	end
end

local function wfly_onhit(attacker, data)
	if data.target ~= nil then

	if attacker:HasTag("Enraged") and not attacker:HasTag("icedfly") then
	if data.target ~= nil and data.target:IsValid() and attacker:IsValid() and not data.target:HasTag("shadowcreature") then
	    if math.random() < .66 then
	    local atkfx = SpawnPrefab("attackfire_fx")
	    atkfx.Transform:SetScale(.20, .30, .30)
	    atkfx.Transform:SetPosition(data.target.Transform:GetWorldPosition())
		end
		if math.random() < .25 then--25%
			local atkfx1 = SpawnPrefab("halloween_firepuff_1")
	        atkfx1.Transform:SetScale(.45, .45, .45)
	        atkfx1.Transform:SetPosition(data.target.Transform:GetWorldPosition())
			data.target.components.combat:GetAttacked(data.target, 7)
		end
		if math.random() < .15 then--15%
			local atkfx2 = SpawnPrefab("halloween_firepuff_2")
			atkfx2.Transform:SetScale(.75, .7, .7)
	        atkfx2.Transform:SetPosition(data.target.Transform:GetWorldPosition())
			data.target.components.combat:GetAttacked(data.target, 15)
		end
		if math.random() < .07 then--7%
			local atkfx3 = SpawnPrefab("halloween_firepuff_3")
	        atkfx3.Transform:SetPosition(data.target.Transform:GetWorldPosition())
			data.target.components.combat:GetAttacked(data.target, 33)
		end
    end
	end

	end
end

local function OnAttacked(inst)
	if inst:HasTag("playerghost") or
        inst.components.health:IsDead() or 
		inst.components.timer:TimerExists("enraged") or inst.components.timer:TimerExists("cooldown") or 
		inst.components.moisture:GetMoisture() > 30 or inst.components.temperature:GetCurrent() < 10 then
        return
    end
    --If attacked when hp is 100 to 1 then 70% chance enrage each hit
    if inst.components.health.currenthealth <= inst.components.health.maxhealth / 2 and math.random() < .7 then
	EnRage(inst)
	inst:AddTag("Enraged")
	inst.components.timer:StartTimer("enraged", TUNING.WFLY_ENRAGED_TIME)
	end
end

---------------------------Pet stuff
local function KillPet(pet)
    pet.components.health:Kill()
end

local function OnSpawnPet(inst, pet)
    if pet:HasTag("wragonflyminion") then
        if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
        inst:ListenForEvent("onremove", inst._onpetlost, pet)
        elseif pet._killtask == nil then
            pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
        end
    elseif inst._OnSpawnPet ~= nil then
        inst:_OnSpawnPet(pet)
    end
end

local function OnDespawnPet(inst, pet)
    if pet:HasTag("wragonflyminion") then
        pet:Remove()
    elseif inst._OnDespawnPet ~= nil then
        inst:_OnDespawnPet(pet)
    end
end

local function OnDeath(inst)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("wragonflyminion") and v._killtask == nil then
            v._killtask = v:DoTaskInTime(math.random(), KillPet)
        end
    end
	if inst.components.timer:TimerExists("enraged") then
	ChangeNormalBuild(inst)--extinguish her rage on death instead of keeping it
	end
end

local function OnReroll(inst)
    local todespawn = {}
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("wragonflyminion") then
            table.insert(todespawn, v)
        end
    end
    for i, v in ipairs(todespawn) do
        inst.components.petleash:DespawnPet(v)
    end
end
---------------------------

local function GnawUpdate(inst)
	if TheWorld.net.components.quagmire_hangriness:GetLevel() > 2 then
	if not inst:HasTag("Enraged") or inst.components.timer:TimerExists("cooldown") then
		EnRage(inst)
	    inst:AddTag("Enraged")
	--	inst.components.timer:StartTimer("enraged", TUNING.WFLY_ENRAGED_TIME) --Lasts as long as it's hangry
	end
	elseif inst:HasTag("Enraged") then
	    ChangeNormalBuild(inst)
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_ENRAGED_OVER"))
	end
end

local function onload(inst, data)
    if data.enraged then
       SetEnrageBuild(inst)
    end
end

local function onsave(inst, data)
   data.enraged = inst.enraged
end

local forge_fn = function(inst)
    event_server_data("lavaarena", "prefabs/wragonfly").master_postinit(inst)
	inst:AddComponent("itemtyperestrictions")
	inst.components.itemtyperestrictions:SetRestrictions({"darts", "books"})
end

local common_postinit = function(inst) 
	inst.MiniMapEntity:SetIcon( "wragonfly.tex" )
	inst:AddTag("wragonfly")
end

local master_postinit = function(inst)
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	inst.soundsname = "wragonfly"

	inst.components.health:SetMaxHealth(TUNING.WRAGONFLY_HEALTH)
	inst.components.hunger:SetMax(TUNING.WRAGONFLY_HUNGER)
	inst.components.sanity:SetMax(TUNING.WRAGONFLY_SANITY)

	inst.components.foodaffinity:AddPrefabAffinity("dragonchilisalad", TUNING.AFFINITY_15_CALORIES_MED)

	inst.tick = 0

	inst.enraged = false

	inst._getstatus = nil

	if inst.components.petleash ~= nil then
        inst._OnSpawnPet = inst.components.petleash.onspawnfn
        inst._OnDespawnPet = inst.components.petleash.ondespawnfn
        inst.components.petleash:SetMaxPets(inst.components.petleash:GetMaxPets() + TUNING.WFLY_MAX_LAVAE)
    else
        inst:AddComponent("petleash")
        inst.components.petleash:SetMaxPets(TUNING.WFLY_MAX_LAVAE)--10
    end
    inst.components.petleash:SetOnSpawnFn(OnSpawnPet)
    inst.components.petleash:SetOnDespawnFn(OnDespawnPet)

	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", ontimerdone)

    inst:ListenForEvent("onhitother", wfly_onhit)

	inst:ListenForEvent("attacked", OnAttacked)

	inst.components.moisture.OnUpdate = UpdateMoist

	inst.components.temperature.overheattemp = TUNING.WFLY_OVERHEAT_TEMP --Overheat temp is hard coded to the default in some places
	inst.components.temperature.maxtemp = 99
	inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_MED

	inst.components.health.fire_damage_scale = TUNING.WFLY_FIRE_IMMUNE

    inst:WatchWorldState("issnowing", onisraining)
    onisraining(inst, TheWorld.state.issnowing)

	if inst.components.eater ~= nil then
        inst.components.eater:SetCanEatBurnt()
        inst.components.eater:SetOnEatFn(oneat)
    end

    if TheNet:GetServerGameMode() == "lavaarena" then
        inst.forge_fn = forge_fn
		return
    elseif TheNet:GetServerGameMode() == "quagmire" then
		inst:DoPeriodicTask(0.7, GnawUpdate)
    end

	inst._onpetlost = function(pet)
	if inst:HasTag("playerghost") or inst.components.timer:TimerExists("enraged") or inst.components.timer:TimerExists("cooldown") 
		or inst.components.moisture:GetMoisture() > 30 or inst.components.temperature:GetCurrent() < 10 then
		return
		else
	    if inst.components.petleash:GetNumPets() < 1 then
		EnRage(inst)
	    inst:AddTag("Enraged")
	    inst.components.timer:StartTimer("enraged", TUNING.WFLY_ENRAGED_TIME)
	    end
	end
	end

    inst:ListenForEvent("ms_respawnedfromghost", function()
 	    ChangeNormalBuild(inst)
	end)

	inst:ListenForEvent("ms_becameghost", function()
		inst.tick = 0
		inst.enraged = false
	end)
	inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_playerreroll", OnReroll)

    inst.OnSave = onsave
	inst.OnLoad = onload
end

return MakePlayerCharacter("wragonfly", prefabs, assets, common_postinit, master_postinit)
