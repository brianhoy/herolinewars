
require('hlw_functions')
require('libraries/notifications')

function GameMode:HInitGameMode()
	GameMode:HLWPrint("HInitGameMode")

	--Register panorama events
	CustomGameEventManager:RegisterListener( "OnPlayerBuyCreep", Dynamic_Wrap(GameMode, 'OnPlayerSpawnedCreep') )
	CustomGameEventManager:RegisterListener( "OnPlayerUpgrade", Dynamic_Wrap(GameMode, 'OnPlayerUpgrade') )
	CustomGameEventManager:RegisterListener( "OnPlayerBuyAllCreeps", Dynamic_Wrap(GameMode, 'OnPlayerBuyAllCreeps') )

	CustomGameEventManager:RegisterListener( "OnRecievedCreepPanorama", Dynamic_Wrap(GameMode, 'OnRecievedCreepPanorama') )
	CustomGameEventManager:RegisterListener( "OnRecievedIncomePanorama",Dynamic_Wrap(GameMode, 'OnRecievedIncomePanorama') ) 

	CustomGameEventManager:RegisterListener( "SetSetting", Dynamic_Wrap(GameMode, 'SetSetting') )
	CustomGameEventManager:RegisterListener( "RecievedSetHost", function() 
																	GameMode.RecievedSetHost = true 
																	return 
																end)
end

function GameMode:OnRecievedCreepPanorama(keys) print('Recieved creep panorama for player ' .. keys.PlayerID) GameMode.RecievedCreepPanorama[keys.PlayerID] = true end
function GameMode:OnRecievedIncomePanorama(keys) print('Recieved creep panorama for player ' .. keys.PlayerID) GameMode.RecievedIncomePanorama[keys.PlayerID] = true end

function GameMode:OnPlayerSpawnedCreep(keys)
	local playerID = keys.PlayerID
	local caster = PlayerResource:GetSelectedHeroEntity(playerID)
	local creepNumber = keys.CreepID + (10 * (GameMode.PlayerLevels[playerID] - 1))
	local gold = PlayerResource:GetGold(playerID)
	local team = PlayerResource:GetTeam(playerID)
	local otherTeam = GameMode:HGetOtherTeam(caster)

	if creepNumber == 0 then
		return
	end

	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameMode:SendErrorMessage(playerID, "#hlw_error_game_hasnt_started")
		return nil
	end

	if gold < GameMode.CreepCost[creepNumber] then
		GameMode:SendErrorMessage(playerID, "#hlw_error_not_enough_gold")
		return
	end

	if GameMode.PlayerCharges[playerID][creepNumber] == 0 then
		GameMode:SendErrorMessage(playerID, "#hlw_error_out_of_charges")
		return
	end

	if GameMode.TeamCreepCounts[team] >= GameMode.MaxCreepCountPerTeam then
		GameMode:SendErrorMessage(playerID, "#hlw_error_team_spawned_max_creeps")
		return
	end

	local otherTeamsIncomes = 0
	local otherTeamCount = 0
	for k, v in pairs(GameMode.PlayerIncomes) do
		if PlayerResource:GetTeam(k) == otherTeam then
			otherTeamsIncomes = otherTeamsIncomes + v
			otherTeamCount = otherTeamCount + 1
		end
	end
	
	local weighted
	if otherTeamCount > 0 then
		local otherTeamIncomeAverage = otherTeamsIncomes / otherTeamCount
		local infrac = otherTeamIncomeAverage / GameMode.PlayerIncomes[playerID]
		weighted = 0.85 + (0.1 * infrac)
		weighted = weighted * 100
		weighted = math.ceil(weighted - 0.5)
		weighted = weighted / 100
	else
		weighted = 1
	end
	
	if weighted > 1.5 then
		weighted = 1.5
	end

	if weighted < 0.5 then
		weighted = 0.5
	end

	PlayerResource:SpendGold(playerID, GameMode.CreepCost[creepNumber], 0)

	local big = (GameMode.PlayerIncomes[playerID] + (weighted*GameMode.CreepIncome[creepNumber]) ) * 100
	local bigrounded = math.floor(big + 0.5)
	local final = bigrounded/100

	GameMode.PlayerIncomes[playerID] = final
	GameMode.PlayerCharges[playerID][creepNumber] = GameMode.PlayerCharges[playerID][creepNumber] - 1	      
	GameMode.TeamCreepCounts[team] = GameMode.TeamCreepCounts[team] + 1

	local random = RandomInt(1, 2)
	local spawnLoc = GameMode.CreepSpawnPoints[otherTeam][random]
	local ancientPos = GameMode.AncientPosition[otherTeam]
	
	local unit = CreateUnitByName("npc_dota_unit_hlw_level" .. creepNumber, spawnLoc, true, caster, caster, team)
	FindClearSpaceForUnit(unit, spawnLoc, true)  
    
	-- Queue up waypoints
	for _, waypointEnt in pairs(GameMode.WaypointEnts[otherTeam][random]) do
		local attackOrder = 
		{
	 		UnitIndex = unit:entindex(), 
	 		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
	 		Position = waypointEnt:GetAbsOrigin() + (RandomVector(50) - 25),
 			Queue = true
 		}
		ExecuteOrderFromTable(attackOrder)
	end

	local attackOrder = 
	{
 		UnitIndex = unit:entindex(), 
 		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
 		Position = GameMode.AncientPosition[otherTeam],
		Queue = true
	}
	ExecuteOrderFromTable(attackOrder)

	GameMode:ApplyStats(unit, creepNumber)
	unit:SetAdditionalBattleMusicWeight(creepNumber*10)

	local data = {
		PlayerGold = PlayerResource:GetGold(playerID),
		PlayerCharges = GameMode.PlayerCharges[playerID]
	}
	CustomNetTables:SetTableValue("income", tostring(playerID), { gold=GameMode.PlayerIncomes[playerID] } );
	print("Nettable.")
	print("Nettable: ", CustomNetTables:GetTableValue("income", tostring(playerID)) )

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "UpdateButtons", data)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "UpdateButtonStatuses", GameMode:GetButtonUpdateData(playerID))

	EmitSoundOnClient("ui.quest_highlight", PlayerResource:GetPlayer(playerID))
end

function GameMode:ApplyStats(unit, factor)
	local playercount = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) + PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)

	local exponentialComponent = ((factor/30) * (factor/30) * (factor/30) * (factor/30) * (factor/30) * (factor/30) * (factor/30) * 8) +0.7 + (playercount * 0.03)
	unit:SetMaxHealth(GameMode.CreepBaseHP * (factor * 0.9) * (((( (GameMode.Difficulty - 0.3) * 0.7) + 0.3) + 2) * 0.4) * exponentialComponent)
	unit:SetBaseMaxHealth(unit:GetMaxHealth())
	unit:SetHealth(unit:GetMaxHealth())
	unit:SetBaseHealthRegen(unit:GetMaxHealth() / 200)
	unit:SetMinimumGoldBounty(math.ceil(GameMode.CreepCost[factor] / 12))
	unit:SetMaximumGoldBounty(math.ceil(GameMode.CreepCost[factor] / 12))
	unit:SetDeathXP(GameMode.CreepXPBounty * ((factor + 1) / 4))
	unit:SetBaseDamageMin( (GameMode.CreepAttackDamage * (factor/1.2) * ( (((GameMode.Difficulty * 0.34) + 0.66) * 0.6) + 0.4)) * ( (((factor/30) * (factor/30) * (factor/30)) * 2) +0.6 + (playercount * 0.02)) )
	unit:SetBaseDamageMax((GameMode.CreepAttackDamage * (factor/1.2) * ( ((((GameMode.Difficulty - 0.3) * 0.34) + 0.66) * 0.6) + 0.4)) * ( (((factor/30) * (factor/30) * (factor/30)) * 3) +0.6 + (playercount * 0.02)) )
	unit:SetBaseAttackTime((GameMode.CreepAttackRate + 0.8) - (factor / 25))
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

function GameMode:OnPlayerBuyAllCreeps(keys)
	local playerID = keys.PlayerID
	local creepNumber = keys.CreepID + (10 * (GameMode.PlayerLevels[playerID] - 1))
	local team = PlayerResource:GetTeam(playerID)
	local gold = PlayerResource:GetGold(playerID)

	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameMode:SendErrorMessage(playerID, "#hlw_error_game_hasnt_started_plural")
		return nil
	end

	local i = 0

	if gold < GameMode.CreepCost[creepNumber] then
		GameMode:SendErrorMessage(playerID, "#hlw_error_not_enough_gold_plural")
		return nil
	end

	if GameMode.PlayerCharges[playerID][creepNumber] == 0 then
		GameMode:SendErrorMessage(playerID, "#hlw_error_out_of_charges_plural")
		return nil
	end

	if GameMode.TeamCreepCounts[team] >= GameMode.MaxCreepCountPerTeam then
		GameMode:SendErrorMessage(playerID, "#hlw_error_team_spawned_max_creeps")
		return nil
	end

	while gold >= GameMode.CreepCost[creepNumber] and GameMode.PlayerCharges[playerID][creepNumber] ~= 0 and GameMode.TeamCreepCounts[team] < GameMode.MaxCreepCountPerTeam do
		GameMode:OnPlayerSpawnedCreep(keys)
		gold = PlayerResource:GetGold(playerID)
	end
end