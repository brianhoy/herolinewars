--trigger functions
function AncientTriggered(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameRules.HeroLineWars:AncientTriggered(keys.activator)
	end
end

function BaseTriggered(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameRules.HeroLineWars:BaseTriggered(keys.activator)
	end
end