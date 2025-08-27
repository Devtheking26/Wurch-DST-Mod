local brain = require("brains/lavaewflybrain")

local assets =
{
    Asset("ANIM", "anim/lavae.zip"),
    Asset("SOUND", "sound/together.fsb"),
}

local prefabs =
{
    "lavae_move_fx",
    "lavae_cocoon",
}

SetSharedLootTable( 'lavae_pet_frozen',
{
    {'lavae_cocoon',1.0},
})

local WAKE_TO_FOLLOW_DISTANCE = 13
local SLEEP_NEAR_LEADER_DISTANCE = 7
local MIN_HEAT = 3--15
local MAX_HEAT = 50--100

local function RetargetFn(inst)
    --Find things attacking leader
    local leader = inst.components.follower:GetLeader()
    return leader ~= nil
        and FindEntity(
            leader,
            TUNING.SHADOWWAXWELL_TARGET_DIST,
            function(guy)
                return guy ~= inst
                    and (guy.components.combat:TargetIs(leader) or
                        guy.components.combat:TargetIs(inst))
                    and inst.components.combat:CanTarget(guy)
            end,
            { "_combat" },
            { "playerghost", "INLIMBO" }
        )
        or nil
end

local function RetargetFn(inst)
    return FindEntity(inst, TUNING.HOUND_FOLLOWER_TARGET_DIST, function(guy)
        return inst.components.health:GetPercent() > 0.25 and inst.components.combat:CanTarget(guy) and guy.prefab == "catcoon"
    end)
end

local function KeepTargetFn(inst, target)
    --Is your leader nearby and your target not dead? Stay on it.
    --Match KEEP_WORKING_DIST in brain
    return inst.components.follower:IsNearLeader(14)
        and inst.components.combat:CanTarget(target)
		and target.components.minigame_participator == nil
end

local function OnAttacked(inst, data)
    if data.attacker == nil then
        inst.components.combat:SetTarget(nil)
	elseif data.attacker:HasTag("player") and not TheNet:GetPVPEnabled() then
	    inst.components.combat:SetTarget(nil)
    elseif data.attacker.components.combat ~= nil then
        inst.components.combat:SetTarget(data.attacker)
    end
end

local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst)
    or not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
    or inst.components.hunger:GetPercent() <= 0.25
end

local function ShouldSleep(inst)
    return DefaultSleepTest(inst)
    and not TheWorld.state.isfullmoon
    and inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE)
    and inst.components.hunger:GetPercent() > 0.25
end

local function OnNewTargetFn(inst, data)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

--Lavae are fed Ashes too, restores og values
local function OnEat(inst, food)
	if food and food.components.edible.foodtype == FOODTYPE.BURNT then
	   inst.components.health:DoDelta(18)--Restores values back to their original 20
       inst.components.hunger:DoDelta(25)--17.5
	end
end

local function ShouldAcceptItem(inst, item)
    --Can I eat it?
    return not (inst.components.sleeper:IsAsleep() or
                inst.components.inventory:IsFull())
        and item.components.edible ~= nil
        and inst.components.eater:CanEat(item)
end

local function OnHungerDelta(inst, data)
    --Adjust heat and light put off.
    inst.components.heater.heat = Lerp(MIN_HEAT, MAX_HEAT, data.newpercent)
    inst.Light:SetRadius(Lerp(.33, 1, data.newpercent))
    inst.Light:SetIntensity(Lerp(.25, .75, data.newpercent))
end

local function OnHaunt(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        inst.components.hauntable.panic = true
        inst.components.hauntable.panictimer = TUNING.HAUNT_PANIC_TIME_SMALL
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function describe(inst)
    local hunger = inst.components.hunger:GetPercent()
    if hunger <= 0.25 then
        return "STARVING"
    elseif hunger <= 0.5 then
        return "HUNGRY"
    elseif hunger <= 0.75 then
        return "CONTENT"
    else
        return "GENERIC"
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()
	inst.nameoverride = "lavae_pet"

    inst.DynamicShadow:SetSize(2, 1)
    inst.Transform:SetSixFaced()
    MakeCharacterPhysics(inst, 10, .5)

    inst.AnimState:SetBank("lavae")
    inst.AnimState:SetBuild("lavae")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("companion")
    inst:AddTag("noauradamage")
    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddTag("notraptrigger")
    inst:AddTag("smallcreature")
	inst:AddTag("NOBLOCK")
	inst:AddTag("wragonflyminion")

    --cooker (from cooker component) added to pristine state for optimization
    inst:AddTag("cooker")

    --trader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")

    inst.Light:SetRadius(1)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetColour(235/255, 121/255, 12/255)
    inst.Light:Enable(true)
    
    inst.Transform:SetScale(0.75, 0.75, 0.75)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst:AddComponent("inspectable")
    inst:AddComponent("locomotor")
    inst:AddComponent("follower")
    inst:AddComponent("cooker")
    inst:AddComponent("heater")
    inst:AddComponent("knownlocations")
    inst:AddComponent("sleeper")
    inst:AddComponent("trader")
    inst:AddComponent("eater")
    inst:AddComponent("inventory")
    inst:AddComponent("hunger")
    inst:AddComponent("lootdropper")

    inst:SetStateGraph("SGlavae")
    inst:SetBrain(brain)
	
	inst.components.combat:SetDefaultDamage(TUNING.WFLY_LAVAE_DAMAGE)--50
    inst.components.combat:SetRange(TUNING.LAVAE_ATTACK_RANGE, TUNING.LAVAE_HIT_RANGE)
    inst.components.combat:SetAttackPeriod(TUNING.LAVAE_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
	
	inst.components.follower:KeepLeaderOnAttacked()
    inst.components.follower.keepdeadleader = true
	inst.components.follower.keepleaderduringminigame = true

    inst.components.inspectable.getstatus = describe

    inst.components.hunger:SetRate(TUNING.LAVAE_HUNGER_RATE)
	inst.components.eater:SetOnEatFn(OnEat)

    inst.components.inventory.maxslots = 2

    inst.components.eater:SetDiet({ FOODTYPE.BURNT })

    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.deleteitemonaccept = false

    inst.components.heater.heat = MAX_HEAT

    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)
	inst:ListenForEvent("newcombattarget", OnNewTargetFn)

    inst.components.health:SetMaxHealth(500)--250
    inst.components.health.fire_damage_scale = 0

    inst.components.locomotor.walkspeed = 7.5

	inst.NormalLootTable = ""
	inst.FrozenLootTable = "lavae_pet_frozen"

    inst:ListenForEvent("hungerdelta", OnHungerDelta)

	inst:ListenForEvent("attacked", OnAttacked)

    MakeLargeFreezableCharacter(inst)
    AddHauntableCustomReaction(inst, OnHaunt, false, false, true)

    return inst
end

return Prefab("lavae_wragonfly", fn, assets, prefabs)
