require('internal/util')
require('gamemode')

function Precache( context )
	DebugPrint("[BAREBONES] Performing pre-load precache")

	PrecacheResource("particle", "particles/units/heroes/hero_phoenix/phoenix_supernova_death_streak.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_drow/drow_frost_arrow.vpcf", context)
	PrecacheResource("particle", "particles/antimage_cleave_ring/dazzle_weave_circle_ray.vpcf", context)
	PrecacheResource( "particle", "particles/items2_fx/veil_of_discord.vpcf", context )	
	PrecacheResource( "particle", "particles/units/heroes/hero_invoker/invoker_sun_strike.vpcf", context ) -- Sunstrike particle

	PrecacheResource( "particle_folder", "particles/frostivus_gameplay", context )

	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_ui.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_hlw.vsndevts", context)
	
	PrecacheItemByNameSync("item_hlw_portal", context)
	PrecacheItemByNameSync("hlw_controller_sunstrike", context)

	PrecacheUnitByNameSync("npc_dota_unit_hlw_controller", context)
	PrecacheUnitByNameSync("npc_dota_hero_brewmaster", context)
	PrecacheUnitByNameSync("npc_dota_hero_jakiro", context)

	for i = 1, 30 do
	PrecacheUnitByNameSync("npc_dota_unit_hlw_level" .. i, context)
	end
end

-- Create the game mode when we activate
function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end