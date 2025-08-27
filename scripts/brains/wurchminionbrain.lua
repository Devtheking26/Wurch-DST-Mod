require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/wander"

-- Tight follow band like Lavae
local CLOSE_MIN  = 2.5   -- stop following inside this
local CLOSE_TGT  = 3.5   -- preferred settle distance
local CLOSE_MAX  = 5.5   -- start following if beyond this

-- Combat detection
local SEE_DIST    = 15   -- start chasing enemies at this range
local GIVEUP_DIST = 20   -- stop chasing if enemy escapes this far

-- Idle wander distance when parked
local WANDER_DIST_NEAR = 1.5

-- Catch-up settings
local CATCHUP_DIST   = 6
local CATCHUP_WALK_M = 1.6
local CATCHUP_RUN_M  = 1.6

local function GetLeader(inst)
    return inst.components.follower ~= nil and inst.components.follower.leader or nil
end

-- Speed logic: sprint when far, match leader when close
local function UpdateFollowSpeed(inst)
    local leader = GetLeader(inst)
    if leader == nil or not leader:IsValid() then return end
    local locomotor = inst.components.locomotor
    if locomotor == nil then return end

    if inst._base_walk == nil then
        inst._base_walk = locomotor.walkspeed
        inst._base_run  = locomotor.runspeed
    end

    local dist_sq = inst:GetDistanceSqToInst(leader)
    if dist_sq > (CATCHUP_DIST * CATCHUP_DIST) then
        locomotor.walkspeed = inst._base_walk * CATCHUP_WALK_M
        locomotor.runspeed  = inst._base_run  * CATCHUP_RUN_M
        return
    end

    local ll = leader.components.locomotor
    if ll ~= nil then
        locomotor.walkspeed = ll.walkspeed
        locomotor.runspeed  = ll.runspeed
    else
        locomotor.walkspeed = inst._base_walk
        locomotor.runspeed  = inst._base_run
    end
end

local WurchMinionBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function WurchMinionBrain:OnStart()
    if TheWorld.ismastersim then
        -- Update speed frequently for responsiveness
        self.inst:DoPeriodicTask(0.25, UpdateFollowSpeed)
    end

    local root = PriorityNode(
    {
        -- Combat first: detect early, give up late
        ChaseAndAttack(self.inst, SEE_DIST, GIVEUP_DIST),

        -- Tight follow band: idle when close, move if slightly away
        Follow(self.inst, GetLeader, CLOSE_MIN, CLOSE_TGT, CLOSE_MAX),

        -- Small idle wander when right next to leader
        Wander(self.inst, function()
            local leader = GetLeader(self.inst)
            return leader ~= nil and leader:GetPosition() or self.inst:GetPosition()
        end, WANDER_DIST_NEAR),
    }, 0.25)

    self.bt = BT(self.inst, root)
end

return WurchMinionBrain
