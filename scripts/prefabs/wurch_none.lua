local assets =
{
	Asset( "ANIM", "anim/wurch.zip" ),
	Asset( "ANIM", "anim/ghost_wurch_build.zip" ),
}

local skins =
{
	normal_skin = "wurch",
	ghost_skin = "ghost_wurch_build",
}

return CreatePrefabSkin("wurch_none",
{
	base_prefab = "wurch",
	type = "base",
	assets = assets,
	skins = skins,
	skin_tags = {"wurch", "CHARACTER", "BASE"},
	build_name_override = "wurch",
	rarity = "Character",
})
