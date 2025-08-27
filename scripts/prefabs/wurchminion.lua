local brain = require "brains/wurchminionbrain"

local assets =
{
    Asset("ANIM", "anim/treedrake.zip"),
    Asset("ANIM", "anim/treedrake_build.zip"),
}

local prefabs = {}

local SEE_TARGET_DIST = 15
local KEEP_TARGET_DIST = 14

local function IsHostile(inst, target)
    return target ~= nil
        and target:IsValid()
        and target.entity:IsVisible()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and target.components.combat ~= nil
        and not target:HasTag("player")
        and not target:HasTag("companion")
end

local function RetargetFn(inst)
    local leader = inst.components.follower ~= nil and inst.components.follower.leader or nil

    return leader ~= nil
        and FindEntity(
            leader,
            SEE_TARGET_DIST,
            function(ent)
                return IsHostile(inst, ent)
                    and (ent.components.combat:TargetIs(leader)
                         or ent.components.combat:TargetIs(inst))
            end,
            { "_combat" },
            { "playerghost", "INLIMBO" }
        )
        or nil
end

local function KeepTargetFn(inst, target)
    return inst.components.follower:IsNearLeader(KEEP_TARGET_DIST)
        and target ~= nil
        and target:IsValid()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
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

local function OnMinionAttacked(inst, data)
    local attacker = data.attacker
    if attacker == nil or attacker:HasTag("player") then return end

    local x, y, z = inst.Transform:GetWorldPosition()
    local nearby_minions = TheSim:FindEntities(x, y, z, SEE_TARGET_DIST, { "wurch_minion" }, { "INLIMBO" })

    for _, minion in ipairs(nearby_minions) do
        if minion ~= inst
            and minion.components.combat ~= nil
            and minion.components.health ~= nil
            and not minion.components.health:IsDead()
            and minion.components.combat:CanTarget(attacker) then
                minion.components.combat:SetTarget(attacker)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    inst.DynamicShadow:SetSize(1.5, .8)

    inst.AnimState:SetBank("treedrake")
    inst.AnimState:SetBuild("treedrake_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    MakeCharacterPhysics(inst, 50, .5)

    inst:AddTag("character")
    inst:AddTag("companion")
    inst:AddTag("wurch_minion")
    inst:AddTag("scarytoprey")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetBrain(brain)
    inst:SetStateGraph("SGwurchminion")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 5
    inst.components.locomotor.runspeed  = 9

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(150)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(20)
    inst.components.combat:SetRange(2)
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetRetargetFunction(0.5, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("follower")
    inst.components.follower:KeepLeaderOnAttacked()
    inst.components.follower.keepdeadleader = true
    inst.components.follower.keepleaderduringminigame = true

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:ListenForEvent("onkillother", function(inst)
        inst.components.combat:TryRetarget()
    end)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("attacked", OnMinionAttacked)

    return inst
end

return Prefab("wurchminion", fn, assets, prefabs)
