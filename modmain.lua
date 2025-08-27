PrefabFiles = {
    "wurch",
    "wurch_none",
    "wurchminion",
}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/wurch.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/wurch.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/wurch.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/wurch.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/wurch_silho.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/wurch_silho.xml" ),

    Asset( "IMAGE", "bigportraits/wurch.tex" ),
    Asset( "ATLAS", "bigportraits/wurch.xml" ),

    Asset( "IMAGE", "images/map_icons/wurch.tex" ),
    Asset( "ATLAS", "images/map_icons/wurch.xml" ),

    Asset( "IMAGE", "images/avatars/avatar_wurch.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_wurch.xml" ),

    Asset( "IMAGE", "images/avatars/avatar_ghost_wurch.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_wurch.xml" ),

    Asset( "IMAGE", "images/avatars/self_inspect_wurch.tex" ),
    Asset( "ATLAS", "images/avatars/self_inspect_wurch.xml" ),

    Asset( "IMAGE", "images/names_wurch.tex" ),
    Asset( "ATLAS", "images/names_wurch.xml" ),

    Asset( "IMAGE", "images/names_gold_wurch.tex" ),
    Asset( "ATLAS", "images/names_gold_wurch.xml" ),
}

AddMinimapAtlas("images/map_icons/wurch.xml")

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS

-- The character select screen lines
STRINGS.CHARACTER_TITLES.wurch = "The Birch Wonder"
STRINGS.CHARACTER_NAMES.wurch = "wurch"
STRINGS.CHARACTER_DESCRIPTIONS.wurch = "*Eats the Sun\n*Tough on weather\n*Hidden birch powers"
STRINGS.CHARACTER_QUOTES.wurch = "\"Quote\""
STRINGS.CHARACTER_SURVIVABILITY.wurch = "Slim"

-- Custom speech strings
STRINGS.CHARACTERS.wurch = require "speech_wurch"

-- The character's name as appears in-game
STRINGS.NAMES.wurch = "wurch"
STRINGS.SKIN_NAMES.wurch_none = "wurch"

-- The skins shown in the cycle view window on the character select screen.
local skin_modes = {
    {
        type = "ghost_skin",
        anim_bank = "ghost",
        idle_anim = "idle",
        scale = 0.75,
        offset = { 0, -25 }
    },
}

-- Add mod character to mod character list
AddModCharacter("wurch", "MALE", skin_modes)

-------------------------------------------------
-- 🌱 Wurch Minion Spawn Helper
-------------------------------------------------
local function SpawnWurchMinion(leader)
    if leader == nil or not leader:IsValid() then
        return
    end

    local minion = GLOBAL.SpawnPrefab("wurchminion")
    if minion ~= nil then
        minion.Transform:SetPosition(leader.Transform:GetWorldPosition())
        if minion.components.follower ~= nil then
            minion.components.follower:SetLeader(leader)
        end
    end
    return minion
end

-- Console-friendly global command
GLOBAL.SpawnWurchMinion = function()
    local player = GLOBAL.ThePlayer
    if player ~= nil then
        return SpawnWurchMinion(player)
    end
end
