PrefabFiles = {
	"spek",

}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/spek.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/spek.xml" ),


    Asset( "IMAGE", "images/selectscreen_portraits/spek.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/spek.xml" ),



    Asset( "IMAGE", "bigportraits/spek.tex" ),
    Asset( "ATLAS", "bigportraits/spek.xml" ),

	
	Asset( "IMAGE", "images/map_icons/spek.tex" ),
	Asset( "ATLAS", "images/map_icons/spek.xml" ),


	Asset( "IMAGE", "images/avatars/avatar_spek.tex" ),

    Asset( "ATLAS", "images/avatars/avatar_spek.xml" ),

	
	Asset( "IMAGE", "images/avatars/avatar_ghost_spek.tex" ),

    Asset( "ATLAS", "images/avatars/avatar_ghost_spek.xml" ),

}
FOODGROUP = GLOBAL.FOODGROUP
FOODTYPE = GLOBAL.FOODTYPE
 
FOODGROUP.OMNI_NOMEAT = {
    name = "OMNI_NOMEAT",
    types = {
        FOODTYPE.VEGGIE,
        FOODTYPE.INSECT,
        FOODTYPE.SEEDS,
        FOODTYPE.GENERIC
    }
}
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS

-- The character select screen lines
STRINGS.CHARACTER_TITLES.spek = "The Seasonal Fairy"
STRINGS.CHARACTER_NAMES.spek = "Spekkle"
STRINGS.CHARACTER_DESCRIPTIONS.spek = "*Photosynthetic\n*Vegetarian"
STRINGS.CHARACTER_QUOTES.spek = "\"My best friend's a tree!\""

-- Custom speech strings
STRINGS.CHARACTERS.SPEK = require "speech_spek"

-- The character's name as appears in-game 
STRINGS.NAMES.SPEK = "Spekkle"

-- The default responses of examining the character
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SPEK = 
{
	GENERIC = "I think that's, what's her name, Spekkle?",
	ATTACKER = "Spekkle sure is creepy...",
	MURDERER = "Spekkle is a killer!",
	REVIVER = "Spekkle, ally to the spirits.",
	GHOST = "Spekkle looks like they could use a heart.",
}


-- Let the game know character is male, female, or robot
table.insert(GLOBAL.CHARACTER_GENDERS.FEMALE, "spek")

AddMinimapAtlas("images/map_icons/spek.xml")
AddModCharacter("spek")