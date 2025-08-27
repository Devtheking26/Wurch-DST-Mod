local prefabs = {}
table.insert(prefabs, CreatePrefabSkin("wragonfly_none",{
	base_prefab = "wragonfly",
	build_name_override = "wragonfly",
	type = "base",
	rarity = "Character",
	skins = {
		normal_skin = "wragonfly",
		ghost_skin = "ghost_wragonfly_build",
	    powerup = "wragonfly_enraged",
	},
	assets = {
		Asset( "ANIM", "anim/wragonfly.zip" ),
		Asset( "ANIM", "anim/wragonfly_enraged.zip" ),
		Asset( "ANIM", "anim/ghost_wragonfly_build.zip" ),
	},
	skin_tags = { "BASE", "WRAGONFLY", },
	torso_tuck_builds = { "wragonfly", "wragonfly_enraged", },
	torso_untuck_wide_builds = { "wragonfly", "wragonfly_enraged", },
	has_alternate_for_body = { "wragonfly", "wragonfly_enraged", },
	skip_item_gen = true,
	skip_giftable_gen = true,
}))

table.insert(prefabs, CreatePrefabSkin("wragonfly_ice",
{
	base_prefab = "wragonfly",
	build_name_override = "wragonfly_ice",
	type = "base",
	rarity = "Elegant",
	rarity_modifier = "Woven",
	skip_item_gen = true,
	skip_giftable_gen = true,
	skins = {
		normal_skin = "wragonfly_ice",
		ghost_skin = "ghost_wragonfly_build",
	    powerup = "wragonfly_ice_enraged",
	},
	assets = {
		Asset( "ANIM", "anim/wragonfly_ice.zip" ),
		Asset( "ANIM", "anim/wragonfly_ice_enraged.zip" ),
		Asset( "ANIM", "anim/ghost_wragonfly_build.zip" ),
	},
	skin_tags = { "BASE", "WRAGONFLY", "ICE" },
	torso_tuck_builds = { "wragonfly_ice", "wragonfly_ice_enraged", },
	torso_untuck_wide_builds = { "wragonfly_ice", "wragonfly_ice_enraged", },
	has_alternate_for_body = { "wragonfly_ice", "wragonfly_ice_enraged", },
}))

table.insert(prefabs, CreatePrefabSkin("wragonfly_shadow",
{
	base_prefab = "wragonfly",
	build_name_override = "wragonfly_shadow",
	type = "base",
	rarity = "Elegant",
	rarity_modifier = "Woven",
	skip_item_gen = true,
	skip_giftable_gen = true,
	skins = {
		normal_skin = "wragonfly_shadow",
		ghost_skin = "ghost_wragonfly_build",
	    powerup = "wragonfly_shadow_enraged",
	},
	assets = {
		Asset( "ANIM", "anim/wragonfly_shadow.zip" ),
		Asset( "ANIM", "anim/wragonfly_shadow_enraged.zip" ),
		Asset( "ANIM", "anim/ghost_wragonfly_build.zip" ),
	},
	skin_tags = { "BASE", "WRAGONFLY", "SHADOW" },
	torso_tuck_builds = { "wragonfly_shadow", "wragonfly_shadow_enraged", },
	torso_untuck_wide_builds = { "wragonfly_shadow", "wragonfly_shadow_enraged", },
	has_alternate_for_body = { "wragonfly_shadow", "wragonfly_shadow_enraged", },
}))

table.insert(prefabs, CreatePrefabSkin("wragonfly_haunted",
{
	base_prefab = "wragonfly",
	build_name_override = "wragonfly_haunted",
	type = "base",
	rarity = "Elegant",
	rarity_modifier = "Woven",
	skip_item_gen = true,
	skip_giftable_gen = true,
	skins = {
		normal_skin = "wragonfly_haunted",
		ghost_skin = "ghost_wragonfly_build",
	    powerup = "wragonfly_haunted_enraged",
	},
	assets = {
		Asset( "ANIM", "anim/wragonfly_haunted.zip" ),
		Asset( "ANIM", "anim/wragonfly_haunted_enraged.zip" ),
		Asset( "ANIM", "anim/ghost_wragonfly_build.zip" ),
	},
	skin_tags = { "BASE", "WRAGONFLY", "HALLOWED" },
	torso_tuck_builds = { "wragonfly_haunted", "wragonfly_haunted_enraged", },
	torso_untuck_wide_builds = { "wragonfly_haunted", "wragonfly_haunted_enraged", },
	has_alternate_for_body = { "wragonfly_haunted", "wragonfly_haunted_enraged", },
}))

return unpack(prefabs)
