-- This information tells other players more about the mod
name = "Wurch"
description =
"Wurch – The Birch Wonder\n" ..
"A nature‑bound wanderer whose mood and pace shift with the seasons. Thrives on plants, shuns meat, and feels every change in the world around them.\n\n" ..
"Strengths:\n" ..
"🌱 Gains sanity in nature.\n" ..
"🌳 Restores sanity when planting trees.\n" ..
"🥕 Benefits from vegetarian diet.\n" ..
"❄️ Spring: +10% speed, –10% hunger burn.\n" ..
"☀️ Summer: Buffed temperature resistance.\n\n" ..
"Weaknesses:\n" ..
"🍖 Cannot eat meat.\n" ..
"🌳 Loses sanity when chopping trees.\n" ..
"🔥 Loses sanity near wildfires.\n" ..
"🌙 Increased hunger burn at night.\n" ..
"☀️ Summer: +10% hunger burn.\n" ..
"❄️ Winter: –10% speed, +10% hunger burn."

author = "Afro Daddy"
version = "1.0.0" -- This is the version of the template. Change it to your own number.


startingitem  = {
  wurch = {
    "acorn", "acorn",
  "acorn", "acorn",
  "acorn" 
    }
}
-- This is the URL name of the mod's thread on the forum; the part after the ? and before the first & in the url
forumthread = "/404/"

-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10
api_version_dst = 10

-- Compatible with Don't Starve Together
dst_compatible = true

-- Not compatible with Don't Starve
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- Character mods are required by all clients
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- The mod's tags displayed on the server list
server_filter_tags = {
"character",
}

--configuration_options = {}
