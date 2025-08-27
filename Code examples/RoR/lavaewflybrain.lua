require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/panic"
require "behaviours/faceentity"
require "behaviours/follow"

local MIN_FOLLOW_DIST = 0
local MAX_FOLLOW_DIST = 8
local TARGET_FOLLOW_DIST = 5
local MAX_CHASE_TIME = 6
local MAX_WANDER_DIST = 3

local function GetOwner(inst)
    return inst.components.follower.leader
end

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

local function EatFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return nil
    end

    if inst.components.inventory ~= nil and inst.components.eater ~= nil then
        local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        return target ~= nil
            and BufferedAction(inst, target, ACTIONS.EAT)
            or nil
    end
end

local function OwnerIsClose(inst)
    local owner = GetOwner(inst)
    return owner ~= nil and owner:IsNear(inst, 2.5)
end

local function LoveOwner(inst)
    if inst.sg:HasStateTag("busy") then
        return nil
    end

    local owner = GetOwner(inst)
    return owner ~= nil
        and owner:HasTag("player")
        and inst.components.hunger:GetPercent() > 0.2
        and math.random() < 0.9
        and BufferedAction(inst, owner, ACTIONS.NUZZLE)
        or nil
end

local LavaeWflyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function ShouldWatchMinigame(inst)
	if inst.components.follower.leader ~= nil and inst.components.follower.leader.components.minigame_participator ~= nil then
		if inst.components.combat.target == nil or inst.components.combat.target.components.minigame_participator ~= nil then
			return true
		end
	end
	return false
end

local function WatchingMinigame(inst)
	return (inst.components.follower.leader ~= nil and inst.components.follower.leader.components.minigame_participator ~= nil) and inst.components.follower.leader.components.minigame_participator:GetMinigame() or nil
end

function LavaeWflyBrain:OnStart()
	local watch_game = WhileNode( function() return ShouldWatchMinigame(self.inst) end, "Watching Game",
        PriorityNode({
            Follow(self.inst, WatchingMinigame, TUNING.MINIGAME_CROWD_DIST_MIN, TUNING.MINIGAME_CROWD_DIST_TARGET, TUNING.MINIGAME_CROWD_DIST_MAX),
            RunAway(self.inst, "minigame_participator", 5, 7),
            FaceEntity(self.inst, WatchingMinigame, WatchingMinigame),
		}, 0.25))

    local root =
    PriorityNode({
	
	    watch_game,

        WhileNode(function() return self.inst.components.hauntable ~= nil and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),
        --[[
        WhileNode(function() return self.inst.components.hunger:GetPercent() < 0.05 end, "STARVING BABY ALERT!",
            PriorityNode{
                --Eat the foods
                DoAction(self.inst, EatFoodAction),
                --Find the foods
                DoAction(self.inst, FindFoodAction),
                --Make the foods!
                SequenceNode{
                    DoAction(self.inst, MakeFoodAction),
                    WaitNode(10),
                },
            }),--]]

        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
        Follow(self.inst, GetOwner, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),

        DoAction(self.inst, EatFoodAction),
        
        WhileNode(function() return GetOwner(self.inst) ~= nil end, "Has Leader",
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),

        WhileNode(function() return OwnerIsClose(self.inst) end, "Owner Is Close",
            SequenceNode{
                WaitNode(4),
                DoAction(self.inst, LoveOwner),
            }),

    }, 1)
    self.bt = BT(self.inst, root)
end

return LavaeWflyBrain
