function GameMode:HInitGameMode()
	GameMode:HLWPrint("HInitGameMode")

	--Register panorama events
	CustomGameEventManager:RegisterListener( "OnPlayerBuyCreep", Dynamic_Wrap(GameMode, 'OnPlayerSpawnedCreep') )
	CustomGameEventManager:RegisterListener( "OnPlayerUpgrade", Dynamic_Wrap(GameMode, 'OnPlayerUpgrade') )
	CustomGameEventManager:RegisterListener( "OnPlayerBuyAllCreeps", Dynamic_Wrap(GameMode, 'OnPlayerBuyAllCreeps') )

	CustomGameEventManager:RegisterListener( "OnPlayerBuyAttribute",Dynamic_Wrap(GameMode, 'OnPlayerBuyAttribute') ) 
	CustomGameEventManager:RegisterListener( "OnPlayerBuyAllAttributes",Dynamic_Wrap(GameMode, 'OnPlayerBuyAllAttributes') ) 

	CustomGameEventManager:RegisterListener( "OnRecievedCreepPanorama", Dynamic_Wrap(GameMode, 'OnRecievedCreepPanorama') )

	CustomGameEventManager:RegisterListener( "SetSetting", Dynamic_Wrap(GameMode, 'SetSetting') )
	CustomGameEventManager:RegisterListener( "RecievedSetHost", function() 
																	GameMode.RecievedSetHost = true 
																	return 
																end)
end

function GameMode:OnRecievedCreepPanorama(keys) 
	GameMode.RecievedCreepPanorama[keys.PlayerID] = true 
end

function GameMode:OnPlayerUpgrade(keys)
	local PlayerID = keys.PlayerID
	local Gold = PlayerResource:GetGold(PlayerID)

	if GameMode.PlayerLevels[PlayerID] >= 3 then
		return
	end

	if Gold < GameMode.UpgradeCost[GameMode.PlayerLevels[PlayerID]] then
		GameMode:SendErrorMessage(PlayerID, "#hlw_error_upgrade_not_enough_gold")
		return
	end

	PlayerResource:SpendGold(PlayerID, GameMode.UpgradeCost[GameMode.PlayerLevels[PlayerID]], GameMode.PlayerLevels[PlayerID])
	GameMode.PlayerLevels[PlayerID] = GameMode.PlayerLevels[PlayerID] + 1

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(PlayerID), "SetButtonConfig", GameMode:GetButtonArrayData(GameMode.PlayerLevels[PlayerID]))
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(PlayerID), "UpdateButtonStatuses", GameMode:GetButtonUpdateData(PlayerID))
end

function GameMode:OnGlyphUsed(keys)
	local team = keys.TeamNumber

	local units = FindUnitsInRadius(team, Vector(0, 0, 0), nil, 
		FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, 
		DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, 0, false)

	for _, unit in pairs(units) do
		if string.sub(unit:GetUnitName(), 1, 23) == "npc_dota_unit_hlw_level" then
			unit:AddNewModifier(unit, nil, "modifier_knockback", 
			{
				duration = 0.6, 
				should_stun = 0, 
				knockback_distance = 1500, 
				knockback_height = 200, 
				center_x = GameMode.AncientPosition[team].x + 5800, 
				center_y = GameMode.AncientPosition[team].y, 
				center_z = GameMode.AncientPosition[team].z, 
				knockback_duration = 1
			})
			unit:AddNewModifier(unit, nil, "modifier_stunned", {duration = 30.0})
			local newOrder = 
			{
				UnitIndex = unit:entindex(), 
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				TargetIndex = nil, --Optional.  Only used when targeting units
				AbilityIndex = 0, --Optional.  Only used when casting abilities
				Position = GameMode.AncientPosition[team], --Optional.  Only used when targeting the ground
				Queue = 0 --Optional.  Used for queueing up abilities
			}
			ExecuteOrderFromTable(newOrder)
		end
	end			
end

function GameMode:HOnUnitHitAncient(unit)
	if unit:GetClassname() == "npc_dota_creature" then
		GameMode.Lives[GameMode:HGetOtherTeam(unit)] = GameMode.Lives[GameMode:HGetOtherTeam(unit)] - 1
		GameMode.TeamCreepCounts[unit:GetTeamNumber()] = GameMode.TeamCreepCounts[unit:GetTeamNumber()] - 1
		GameRules:GetGameModeEntity():SetTopBarTeamValue(GameMode:HGetOtherTeam(unit), GameMode.Lives[GameMode:HGetOtherTeam(unit)])
		CustomGameEventManager:Send_ServerToAllClients("UpdateScore", {teamID = GameMode:HGetOtherTeam(unit), score = GameMode.Lives[GameMode:HGetOtherTeam(unit)]})

		local particleName1 = "particles/units/heroes/hero_phoenix/phoenix_supernova_death_streak.vpcf"
		local soundName1 = "HeroPicker.Selected"

		StartSoundEventFromPosition(soundName1, unit:GetAbsOrigin())

		local particle1 = ParticleManager:CreateParticle(particleName1, PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle1, 1, unit:GetAbsOrigin())

		if GameMode.Lives[GameMode:HGetOtherTeam(unit)] <= 0 then
			GameRules:SetGameWinner(unit:GetTeamNumber())
			GameRules:MakeTeamLose(GameMode:HGetOtherTeam(unit))
			GameRules:Defeated()
		end
	end
	unit:RemoveSelf()
end
