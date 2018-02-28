function GameMode:OnPlayerSpawnedCreep(keys)
	local playerID = keys.PlayerID
	local caster = PlayerResource:GetSelectedHeroEntity(playerID)
	local creepNumber = keys.CreepID + (10 * (GameMode.PlayerLevels[playerID] - 1))
	local gold = PlayerResource:GetGold(playerID)

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

	if GameMode.TeamCreepCounts[caster:GetTeamNumber()] >= GameMode.MaxCreepCountPerTeam then
		GameMode:SendErrorMessage(playerID, "#hlw_error_team_spawned_max_creeps")
		return
	end

	local income = GameMode:GetIncome(creepNumber, caster)
	GameMode:SpawnCreep(creepNumber, caster)

	PlayerResource:SpendGold(playerID, GameMode.CreepCost[creepNumber], 0)
	GameMode.PlayerIncomes[playerID] = income
	GameMode.PlayerCharges[playerID][creepNumber] = GameMode.PlayerCharges[playerID][creepNumber] - 1	      

	local data = {
		PlayerGold = PlayerResource:GetGold(playerID),
		PlayerCharges = GameMode.PlayerCharges[playerID]
	}
	CustomNetTables:SetTableValue("income", tostring(playerID), { gold=GameMode.PlayerIncomes[playerID] } );

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "UpdateButtons", data)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "UpdateButtonStatuses", GameMode:GetButtonUpdateData(playerID))
end

function GameMode:GetIncome(creepNumber, caster)
	local otherTeamsIncomes = 0
	local yourTeamsIncome = 0
	local otherTeamCount = 0

	for k, v in pairs(GameMode.PlayerIncomes) do
		if PlayerResource:GetTeam(k) == caster:GetOpposingTeamNumber() then
			otherTeamsIncomes = otherTeamsIncomes + v
			otherTeamCount = otherTeamCount + 1
		else
			yourTeamsIncome = yourTeamsIncome + v
		end
	end
	
	local lead = otherTeamsIncomes - yourTeamsIncome
	if lead < 0 then
		lead = 0
	end
	local weighted = 0.001 * lead

	local income = (GameMode.PlayerIncomes[caster:GetPlayerID()] + (weighted + GameMode.CreepIncome[creepNumber]) ) * 100
	return math.floor(income + 0.5)/100
end

function GameMode:SpawnCreep(factor, caster)
	local random = RandomInt(1, 2)
	local spawnLoc = GameMode.CreepSpawnPoints[caster:GetOpposingTeamNumber()][random]
	local ancientPos = GameMode.AncientPosition[caster:GetOpposingTeamNumber()]

	GameMode.TeamCreepCounts[caster:GetTeamNumber()] = GameMode.TeamCreepCounts[caster:GetTeamNumber()] + 1
	local unit = CreateUnitByName("npc_dota_unit_hlw_level" .. factor, spawnLoc, true, caster, caster, caster:GetTeamNumber())
	FindClearSpaceForUnit(unit, spawnLoc, true)
	GameMode:ApplyStats(unit, factor)

--	print("Team: ", caster:GetOpposingTeamNumber(), " side: ", random)
	GameMode:QueueWaypoints(unit, GameMode.WaypointEnts[caster:GetOpposingTeamNumber()][random])

	unit:SetAdditionalBattleMusicWeight(factor*10)
	EmitSoundOnClient("ui.quest_highlight", PlayerResource:GetPlayer(caster:GetPlayerID()))
end

function GameMode:QueueWaypoints(unit, waypoints)
	for index, waypoint in pairs(waypoints) do
		local moveOrder = 
		{
	 		UnitIndex = unit:entindex(), 
	 		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
	 		Position = waypoint:GetAbsOrigin(), 
	 		Queue = 1
 		}
		ExecuteOrderFromTable(moveOrder)
	end
end

function GameMode:RequeueWaypoints(unit, waypoints, starting_waypoint_team, starting_waypoint_side, starting_waypoint_index)
	local waypoint_count = 0
	for _, __ in pairs(waypoints[starting_waypoint_team][starting_waypoint_side]) do 
		waypoint_count = waypoint_count + 1 
	end
	for index = starting_waypoint_index, waypoint_count do
		local waypoint = waypoints[starting_waypoint_team][starting_waypoint_side][index]
		local moveOrder = 
		{
	 		UnitIndex = unit:entindex(), 
	 		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
	 		Position = waypoint:GetAbsOrigin(), 
	 		Queue = 1
 		}
		ExecuteOrderFromTable(moveOrder)
	end

end

function GameMode:ApplyStats(unit, factor)
	local playercount = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) + PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)
	local exponentialComponent = ((factor/30) * (factor/30) * (factor/30) * (factor/30) * (factor/30) * (factor/30) * (factor/30) * 8) +0.7 + (playercount * 0.03)
	unit:SetMaxHealth(GameMode.CreepBaseHP * (factor * 0.9) * (((( (GameMode.Difficulty - 0.3) * 0.7) + 0.2) + 2) * 0.4) * exponentialComponent)
	unit:SetBaseMaxHealth(unit:GetMaxHealth())
	unit:SetHealth(unit:GetMaxHealth())
	unit:SetBaseHealthRegen(unit:GetMaxHealth() / 200)
	unit:SetMinimumGoldBounty(math.ceil(GameMode.CreepCost[factor] / 12))
	unit:SetMaximumGoldBounty(math.ceil(GameMode.CreepCost[factor] / 12))
	unit:SetDeathXP(GameMode.CreepXPBounty * ((factor + 1) / 4))
	unit:SetBaseDamageMin((GameMode.CreepAttackDamage * (factor/1.2) * ( ((((GameMode.Difficulty - 0.3) * 0.34) + 0.66) * 0.6) + 0.4)) * ( (((factor/30) * (factor/30) * (factor/30) * (factor/30) * (factor/30)) * 2) +0.6 + (playercount * 0.02)) )
	unit:SetBaseDamageMax((GameMode.CreepAttackDamage * (factor/1.2) * ( ((((GameMode.Difficulty - 0.3) * 0.34) + 0.66) * 0.6) + 0.4)) * ( (((factor/30) * (factor/30) * (factor/30) * (factor/30) * (factor/30)) * 3.5) +0.6 + (playercount * 0.02)) )
	unit:SetBaseAttackTime((GameMode.CreepAttackRate + 0.8) - (factor / 25))
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