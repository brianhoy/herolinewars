BAREBONES_DEBUG_SPEW = false 

if GameMode == nil then
		DebugPrint( "[BAREBONES] creating barebones game mode" )
		_G.GameMode = class({})
end

require("libraries/timers")
require("libraries/physics")
require("libraries/projectiles")
require("libraries/notifications")
require("libraries/animations")
require("internal/gamemode")
require("internal/events")
require("settings")
require("events")

-- Modifiers
require("modifiers/modifier_bonus_agility")
require("modifiers/modifier_bonus_strength")
require("modifiers/modifier_bonus_intelligence")
require("modifiers/modifier_unattackable")
require("modifiers/modifier_cleavable")

-- HLW-specific files
require("hlw_events")
require("hlw_functions")
require("hlw_attributes")
require("hlw_creeps")
require("hlw_creep_ai")

function GameMode:PostLoadPrecache()
end

function GameMode:OnFirstPlayerLoaded()
	
end

function GameMode:OnAllPlayersLoaded()
end

function GameMode:OnHeroInGame(hero)
	local playerID = hero:GetPlayerID()
	local team = hero:GetTeamNumber()
	print("[HLW]  Spawning hero for player " .. playerID)

	-- Ends the function if hero is a controller or if the NPC"s playerID has already been started
	if hero:GetClassname() == "npc_dota_hero_abyssal_underlord" then
		return
	end
	if GameMode.StartedPlayerIDs[playerID] == true then
		return
	end

	-- Initialize the kill counts
	Timers:CreateTimer(5, function()
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "UpdateScore", {teamID = DOTA_TEAM_GOODGUYS, score = GameMode.Lives[DOTA_TEAM_GOODGUYS]})
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "UpdateScore", {teamID = DOTA_TEAM_BADGUYS, score = GameMode.Lives[DOTA_TEAM_BADGUYS]})
	end)

	-- Initializes basic variables for the player
	local TeamCount = GameMode.PlayerCounts[hero:GetTeamNumber()] + 1
	GameMode.StartedPlayerIDs[playerID] = true
	hero:SetGold(GameMode.StartingGold, false)
	GameMode.PlayerCounts[hero:GetTeamNumber()] = TeamCount
	GameMode.ControllerIncreaseManaCost[playerID] = GameMode.ControllerInitialIncreaseManaCost

	-- This code removes the player"s hero, creates a new one that is the exact same, creates a controller, then sets them all to the correct position
	local player = PlayerResource:GetPlayer(playerID)	

	local unit = CreateUnitByName("npc_dota_hero_abyssal_underlord", Vector(0, 0, 0), false, nil, nil, team)

	hero:SetControllableByPlayer(playerID, true)
	hero:SetPlayerID(playerID)
	unit:SetControllableByPlayer(playerID, true)
	unit:SetPlayerID(playerID)
	local teams_ = {  }
	teams_[DOTA_TEAM_GOODGUYS] = "good"
	teams_[DOTA_TEAM_BADGUYS] = "bad"
	local spawnents = Entities:FindAllByClassname("info_player_start_" .. teams_[hero:GetTeamNumber()] .. "guys")
	local spwncnt = 0
	for k, v in pairs(spawnents) do spwncnt = spwncnt + 1 end
	FindClearSpaceForUnit(unit, GameMode.ControllerLocations[hero:GetTeamNumber()][TeamCount], false)
	FindClearSpaceForUnit(hero, spawnents[RandomInt(1, spwncnt)]:GetAbsOrigin(), false)
	GameMode.ControllerLocations[hero:GetTeamNumber()][playerID + 50] = GameMode.ControllerLocations[hero:GetTeamNumber()][TeamCount]
	hero.unit = unit
	CustomNetTables:SetTableValue("controllers", tostring(playerID), { controller=unit:entindex() } );

	-- Centers the camera on the controller for a tutorial
	Timers:CreateTimer(1, function()
		if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
			PlayerResource:SetCameraTarget(playerID, unit)

			Timers:CreateTimer(4, function()
				PlayerResource:SetCameraTarget(playerID, nil)
			end)

			Timers:CreateTimer(4.1, function()
				PlayerResource:SetCameraTarget(playerID, PlayerResource:GetSelectedHeroEntity(playerID))
				PlayerResource:SetCameraTarget(playerID, nil)
			end)
		end
	end)

	-- Notification that appears when a player doesn"t send creeps
	local sndCrpNtfctnItr = 0
	Timers:CreateTimer(60, function()
		if GameMode.PlayerIncomes[playerID] < 3 then
			Notifications:Top(playerID, {text="#hlw_notification_not_sending_creeps", style={--[[color="#E36129"]]}, duration=10})
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "ShowArrow", {duration=10})
			sndCrpNtfctnItr = sndCrpNtfctnItr + 1
			if sndCrpNtfctnItr >= 10 then
				Notifications:Top(playerID, {text="#hlw_notification_gave_up", style={--[[color="#E36129"]]}, duration=20})
				return
			end
			return 10
		end
	end)

	-- Leveling all the controller"s abilities to level 1
	for i = 1, 5 do
		unit:HeroLevelUp( false)
	end
	for i = 0, unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability ~= nil then
			unit:UpgradeAbility(ability)
		end
	end

	-- Silencing and making invulnerable the controller
	unit:SetMana(0)
	unit:AddNewModifier(unit, nil, "modifier_invulnerable", {duration=-1})
	Timers:CreateTimer(0.9, function()
		if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			unit:AddNewModifier(unit, nil, "modifier_silence", {duration=-1})
			return 1
		else
			unit:RemoveModifierByName("modifier_silence")
			return nil
		end
	end)

	-- Initializing levels, charges, incomes, and panorama
	GameMode.PlayerIncomes[playerID] = 2
	GameMode.PlayerCharges[playerID] = {}
	GameMode.PlayerLevels[playerID] = 1
	for i = 1, 30 do
		GameMode.PlayerCharges[playerID][i] = GameMode.MaxCharges
	end
	GameMode:InitializeCreepPanoramaForPlayer(playerID)

	-- Set up Income and attribute nettable for this player
	CustomNetTables:SetTableValue("income", tostring(playerID), { gold=GameMode.PlayerIncomes[playerID] } );
	
	hero.strength_bonus = 0
	hero.agility_bonus = 0
	hero.intelligence_bonus = 0

	local attrTable = 
	{ 
		["strength"] = GameMode:GetAttributeCost("strength", hero), 
		["agility"] = GameMode:GetAttributeCost("agility", hero), 
		["intelligence"] = GameMode:GetAttributeCost("intelligence", hero)
	}
	CustomNetTables:SetTableValue("attributecost", tostring(playerID), attrTable);

	-- Levels up the controller every 90 seconds
	local i = 0
	Timers:CreateTimer(60.0, function()
		i = i + 1
		hero.unit:HeroLevelUp(false)
		if hero.unit:GetLevel() >= 24 then
			return nil
		else
			return 90.0
		end
	end)

end

function GameMode:OnGameInProgress()
	-- Sends random tip to the log every once in awhile
	Timers:CreateTimer(60.0, function()
		GameRules:SendCustomMessage(GameMode:GetRandomTip(), 0, 0)
		return 120.0
	end)
	-- Prints credit/feedback strings
	CustomGameEventManager:Send_ServerToAllClients("StartIncomeBar", nil)
	GameRules:SendCustomMessage("#hlw_welcome_credit", 0, 0)
	GameRules:SendCustomMessage("#hlw_welcome_feedback", 0, 0)

	-- After 7 seconds, the settings are printed
	local difficulties = { "#hlw_setting_creep_difficulty_1", "#hlw_setting_creep_difficulty_2", "#hlw_setting_creep_difficulty_3", "#hlw_setting_creep_difficulty_4" }
	Timers:CreateTimer(7.0, function()
		GameRules:SendCustomMessage("#hlw_setting_header", 0, 0)
		GameRules:SendCustomMessage("#hlw_setting_creep_difficulty", 0, 0)
		GameRules:SendCustomMessage(difficulties[GameMode.Difficulty * 2], 0, 0)
		GameRules:SendCustomMessage("#hlw_setting_max_amount_of_creeps_on_map", 0, 0)
		GameRules:SendCustomMessage(tostring(GameMode.MaxCreepCountPerTeam), 0, 0)
		GameRules:SendCustomMessage("#hlw_setting_max_creep_charges", 0, 0)
		GameRules:SendCustomMessage(tostring(GameMode.MaxCharges), 0, 0)

	end)

	-- After a certain time stored in a variable, Sudden Death phase starts
	Timers:CreateTimer(GameMode.SuddenDeath, function()
		GameMode:StartSuddenDeath()

		for PlayerID, _ in pairs(GameMode.PlayerIncomes) do
				local hero = PlayerResource:GetSelectedHeroEntity(PlayerID)
				local item = CreateItem("item_hlw_portal", hero, hero)
				local container = CreateItemOnPositionForLaunch(hero:GetAbsOrigin(), item)
				container:SetRenderColor(255, 100, 100)
				item:LaunchLoot(false, 200, 0.9, hero:GetAbsOrigin() + RandomVector(200))
		end
		return nil
	end)

	-- Gives income to each player every 10 seconds
	Timers:CreateTimer(10, function()
		EmitGlobalSound("lockjaw_Courier.gold")
		for PlayerID, Income in pairs(GameMode.PlayerIncomes) do
			PlayerResource:ModifyGold(PlayerID, Income, false, 0)
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(PlayerID), "UpdateButtonStatuses", GameMode:GetButtonUpdateData(PlayerID))
		end
		CustomGameEventManager:Send_ServerToAllClients("StartIncomeBar", nil)
		return 10 
	end)

	-- Increases each players" charges by 1 every 3 seconds
	Timers:CreateTimer(3, function()
		for PlayerID, ChargesTable in pairs(GameMode.PlayerCharges) do
			for CreepNumber, Charges in pairs(ChargesTable) do
				if Charges < GameMode.MaxCharges then
					GameMode.PlayerCharges[PlayerID][CreepNumber] = Charges + 1
				end
			end
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(PlayerID), "UpdateButtonStatuses", GameMode:GetButtonUpdateData(PlayerID))
		end
		return 3 
	end)
end

function GameMode:InitGameMode()
	GameMode = self
	
	local locations = {
		Vector(-3000, 3000, 0),
		Vector(3000, 3000, 0),
		Vector(-3000, -3000, 0),
		Vector(3000, -3000, 0)
	}

	for k, v in pairs(locations) do
		AddFOWViewer(DOTA_TEAM_GOODGUYS, v, 10000, -1, false)
		AddFOWViewer(DOTA_TEAM_BADGUYS, v, 10000, -1, false)
	end

	GameMode.DebugMode = false
	GameMode.ConnectedPlayerIDs = {}

	GameMode:_InitGameMode()
	GameMode:HInitGameMode()
		
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( GameMode, "ExecuteOrderFilter" ), GameMode )

	GameMode.AttributeLevels = {}
	
	GameMode.RecievedIncomePanorama = {}
	GameMode.RecievedCreepPanorama = {}

	GameMode.RecievedSetHost = false
	GameMode.FirstPlayerLoaded = false
	GameMode.Settings = {}

	GameMode.CreepBaseHP = 35	
	GameMode.CreepAttackDamage = 5	
	GameMode.CreepAttackRate = 1	
	GameMode.CreepXPBounty = 45

	GameMode.SuddenDeath = 1200

	GameMode.PlayerControllers = {}
	GameMode.ControllerIncreaseManaCost = {}
	GameMode.ControllerInitialIncreaseManaCost = 200
	GameMode.ControllerIncreaseManaCostIncrement = 100
	GameMode.ControllerManaIncreaseAmount = 300	

	GameMode.Tips = {}
	GameMode.Tips[1] = "hlw_tutorial_message_glyph"
	GameMode.Tips[2] = "hlw_tutorial_message_income_scaling"
	GameMode.Tips[3] = "hlw_tutorial_message_selection"
	GameMode.Tips[4] = "hlw_tutorial_message_sudden_death"
	GameMode.Tips[5] = "hlw_tutorial_message_right_click"
	GameMode.Tips[6] = "hlw_tutorial_message_buy_mana"
	GameMode.Tips[7] = "hlw_tutorial_message_move_creepbar"
	GameMode.Tips[8] = "hlw_tutorial_message_move_income"
	GameMode.Tips[9] = "hlw_tutorial_message_controller_tip"

	GameMode.UsedTips = {}
	for i = 1, 9 do
		GameMode.UsedTips[i] = false
	end

	-- Settings
	GameMode.MaxCharges = 10
	GameMode.MaxCreepCountPerTeam = 200	
	GameMode.Difficulty = 1

	GameMode.TeamCreepCounts = {}
	GameMode.TeamCreepCounts[DOTA_TEAM_GOODGUYS] = 0
	GameMode.TeamCreepCounts[DOTA_TEAM_BADGUYS] = 0

	-- [PlayerID].Income
	GameMode.PlayerIncomes = {}

	-- [PlayerID][CreepNumber].Charges
	GameMode.PlayerCharges = {}

	-- [PlayerID].Level
	GameMode.PlayerLevels = {}

	GameMode.StartedPlayerIDs = {}
	for i = 0, 10 do
		GameMode.StartedPlayerIDs[i] = false
	end

	GameMode.UpgradeCost = {
		--Level 1 -> 2 
		2000,

		--Level 2 -> 3
		8000		
	}

	GameMode.CreepCost = {
		-- Level 1
		3, 5, 10, 20, 30, 40, 50, 70, 100, 120,
 
		-- Level 2
		150, 180, 210, 230, 270, 310, 350, 400, 450, 500,

		-- Level 3
		500, 560, 620, 680, 750, 1000, 2500, 5000, 8000, 10000
	}

	GameMode.CreepIncome = {
		-- Level 1
		0.7, 1, 1.8, 2.1, 2.7, 3.7, 5, 6.5, 8, 9.5, 

		-- Level 2
		9.5, 11, 12.5, 14, 15.5, 17, 18.5, 20, 22, 24,

		-- Level 3
		26, 28.5, 31, 33.5, 36, 38, 41, 44, 47, 50
	}

	GameMode.StartingGold = 15
	
	GameMode.Lives = {}
	GameMode.Lives[DOTA_TEAM_GOODGUYS] = 50 -- Radiant
	GameMode.Lives[DOTA_TEAM_BADGUYS] = 50 -- Dire
	
	for i = 2, 3 do
		GameRules:GetGameModeEntity():SetTopBarTeamValue(i, GameMode.Lives[i])
	end
	
	GameMode.AncientPosition = {}
	GameMode.AncientPosition[DOTA_TEAM_GOODGUYS] = Entities:FindAllByName("hlw_good_ancient")[1]:GetAbsOrigin()
	GameMode.AncientPosition[DOTA_TEAM_BADGUYS] = Entities:FindAllByName("hlw_bad_ancient")[1]:GetAbsOrigin()



	GameMode.ControllerLocations = {}
	GameMode.ControllerLocations[DOTA_TEAM_GOODGUYS] = {}
	GameMode.ControllerLocations[DOTA_TEAM_BADGUYS] = {}
	for i = 1, 6 do
		GameMode.ControllerLocations[DOTA_TEAM_GOODGUYS][i] = (Entities:FindAllByName("hlw_good_controller_" .. tostring(i))[1]):GetAbsOrigin()
		GameMode.ControllerLocations[DOTA_TEAM_BADGUYS][i] = (Entities:FindAllByName("hlw_bad_controller_" .. tostring(i))[1]):GetAbsOrigin()
	end

	GameMode.PlayerCounts = {}
	GameMode.PlayerCounts[DOTA_TEAM_GOODGUYS] = 0
	GameMode.PlayerCounts[DOTA_TEAM_BADGUYS] = 0

	GameMode.CreepSpawnPoints = {}
	GameMode.CreepSpawnPoints[DOTA_TEAM_GOODGUYS] = {}
	GameMode.CreepSpawnPoints[DOTA_TEAM_BADGUYS] = {}


	GameMode.CreepSpawnPoints[DOTA_TEAM_GOODGUYS][1] = Entities:FindAllByName("hlw_good_bot_spawn")[1]
	GameMode.CreepSpawnPoints[DOTA_TEAM_GOODGUYS][2] = Entities:FindAllByName("hlw_good_top_spawn")[1]

	GameMode.CreepSpawnPoints[DOTA_TEAM_BADGUYS][1] = Entities:FindAllByName("hlw_bad_bot_spawn")[1]
	GameMode.CreepSpawnPoints[DOTA_TEAM_BADGUYS][2] = Entities:FindAllByName("hlw_bad_top_spawn")[1]

	GameMode.WaypointEnts = {}
	for team = 2, 3 do
		GameMode.WaypointEnts[team] = {}   
		for side = 1,2 do
			GameMode.WaypointEnts[team][side] = {}
			GameMode:SetWaypointEnts(team, side)
		end
	end

	for i = 2, 3 do
		for teamNo, ent in pairs(GameMode.CreepSpawnPoints[i]) do
			GameMode.CreepSpawnPoints[i][teamNo] = ent:GetAbsOrigin()
		end
	end

	GameRules:GetGameModeEntity():SetCameraDistanceOverride( 1350 )

	-- Commands 
	Convars:RegisterCommand( "RebuildPanoramaUI", Dynamic_Wrap(GameMode, "RebuildPanoramaUI"), "Rebuilds panorama interface", FCVAR_CHEAT )
	Convars:RegisterCommand( "TestNettable", Dynamic_Wrap(GameMode, "TestNettable"), "Tests a given nettable", FCVAR_CHEAT )

end

function GameMode:SetWaypointEnts(team, side)
	-- Finds all the waypoint entities for a given team and side
	local i = 1
	local teams = {}
	teams[DOTA_TEAM_GOODGUYS] = "good"
	teams[DOTA_TEAM_BADGUYS] = "bad"

	local sides = {}
	sides[1] = "bot"
	sides[2] = "top"

	waypointEnt = Entities:FindAllByName("hlw_" .. teams[team] .. "_" .. sides[side] .. "_wp_" .. tostring(i))[1]
	while waypointEnt ~= nil do 
		GameMode.WaypointEnts[team][side][i] = waypointEnt
		i = i + 1 
		waypointEnt = Entities:FindAllByName("hlw_" .. teams[team] .. "_" .. sides[side] .. "_wp_" .. tostring(i))[1]
	end

	GameMode.WaypointEnts[team][side][i] = Entities:FindAllByName("hlw_" .. teams[team] .. "_ancient")[1]
end

function GameMode:RebuildPanoramaUI(_)
	-- Command: initialzes panorama for player 0
	GameMode:HLWPrint("RebuildPanoramaUI")
	GameMode:InitializeCreepPanoramaForPlayer(0)
end

function GameMode:TestNettable(nettable)
	CustomNetTables:SetTableValue( nettable, "key_1", { value = "hello" } );
	print("Nettable: ", CustomNetTables:GetTableValue(nettable, value) )
end