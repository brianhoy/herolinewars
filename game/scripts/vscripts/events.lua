function GameMode:OnDisconnect(keys)
	GameMode:HLWPrint("OnDisconnect")

	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid

	local playerID = keys.PlayerID
end



function GameMode:OnGameRulesStateChange(keys)
	GameMode:HLWPrint("OnGameRulesStateChange")

	GameMode:_OnGameRulesStateChange(keys)

	local newState = GameRules:State_Get()

	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		Timers:CreateTimer(1, function()
			local centerMessage =  { message = "#hlw_tutorial_message_controller", duration = 5 }
			FireGameEvent("show_center_message", centerMessage)
			EmitGlobalSound("HLW.TutorialSound")
		end)
		Timers:CreateTimer(7, function()
			local centerMessage =  { message = "#hlw_tutorial_message_income", duration = 5 }
			FireGameEvent("show_center_message", centerMessage)
			EmitGlobalSound("HLW.TutorialSound")
		end)
		Timers:CreateTimer(13, function()
			local centerMessage =  { message = "#hlw_tutorial_message_objective", duration = 5 }
			FireGameEvent("show_center_message", centerMessage)
			EmitGlobalSound("HLW.TutorialSound")
		end)
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then		

		--[[for k, v in pairs(GameMode.UpgradeCost) do
			GameMode.UpgradeCost[k] = v * GameMode.GoldMultiplier
		end

		for k, v in pairs(GameMode.CreepCost) do
			GameMode.CreepCost[k] = v * GameMode.GoldMultiplier
		end

		for k, v in pairs(GameMode.CreepIncome) do
			GameMode.CreepIncome[k] = v * GameMode.GoldMultiplier
		end]]
	end
end

-- An NPC has spawned somewhere in game.	This includes heroes
function GameMode:OnNPCSpawned(keys)
	--GameMode:HLWPrint("OnNPCSpawned")
	GameMode:_OnNPCSpawned(keys)

	--local npc = EntIndexToHScript(keys.entindex)
end

-- An entity somewhere has been hurt.	This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)

	--[[local damagebits = keys.damagebits -- This might always be 0 and therefore useless
	if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
		local entCause = EntIndexToHScript(keys.entindex_attacker)
		local entVictim = EntIndexToHScript(keys.entindex_killed)

		-- The ability/item used to damage, or nil if not damaged by an item/ability
		local damagingAbility = nil

		if keys.entindex_inflictor ~= nil then
			damagingAbility = EntIndexToHScript( keys.entindex_inflictor )
		end
	end]]
end

function GameMode:OnItemPickedUp(keys)
	GameMode:HLWPrint("OnItemPickedUp")

	--[[local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname]]
end

function GameMode:OnPlayerReconnect(keys)
	GameMode:HLWPrint("OnPlayerReconnect")
	local PlayerID = keys.PlayerID

	GameMode:InitializeCreepPanoramaForPlayer(PlayerID)
	GameMode:InitializeIncomePanoramaForPlayer(PlayerID)
end

function GameMode:OnItemPurchased( keys )
	GameMode:HLWPrint("OnItemPurchased")

	local plyID = keys.PlayerID
	if not plyID then return end

	local itemName = keys.itemname 
	local itemcost = keys.itemcost
	
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(plyID), "UpdateButtonStatuses", GameMode:GetButtonUpdateData(plyID) )
end

function GameMode:OnAbilityUsed(keys)
	GameMode:HLWPrint("OnAbilityUsed: " .. keys.abilityname)

	--[[local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityname = keys.abilityname]]
end

function GameMode:OnNonPlayerUsedAbility(keys)
	GameMode:HLWPrint("OnNonPlayerUsedAbility: " .. keys.abilityname)

	local abilityname=	keys.abilityname
end

-- A player changed their name
function GameMode:OnPlayerChangedName(keys)

end

function GameMode:OnPlayerLearnedAbility( keys)
	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
end

function GameMode:OnAbilityChannelFinished(keys)
	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

function GameMode:OnPlayerLevelUp(keys)
	local player = EntIndexToHScript(keys.player)
	local level = keys.level
end

function GameMode:OnLastHit(keys)
	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local killedEnt = EntIndexToHScript(keys.EntKilled)
end

function GameMode:OnTreeCut(keys)
	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

function GameMode:OnRuneActivated (keys)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local rune = keys.rune

	--[[ Rune Can be one of the following types
	DOTA_RUNE_DOUBLEDAMAGE
	DOTA_RUNE_HASTE
	DOTA_RUNE_HAUNTED
	DOTA_RUNE_ILLUSION
	DOTA_RUNE_INVISIBILITY
	DOTA_RUNE_BOUNTY
	DOTA_RUNE_MYSTERY
	DOTA_RUNE_RAPIER
	DOTA_RUNE_REGENERATION
	DOTA_RUNE_SPOOKY
	DOTA_RUNE_TURBO
	]]
end

-- A player took damage from a tower
function GameMode:OnPlayerTakeTowerDamage(keys)
	GameMode:HLWPrint("OnPlayerTakeTowerDamage")

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
	GameMode:HLWPrint("OnPlayerPickHero")

	local heroClass = keys.hero
	local heroEntity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)
	GameMode:HLWPrint("OnTeamKillCredit")

	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	local numKills = keys.herokills
	local killerTeamNumber = keys.teamnumber
end

-- An entity died
function GameMode:OnEntityKilled( keys )
	GameMode:HLWPrint("OnEntityKilled")

	GameMode:_OnEntityKilled( keys )
	
	-- The Unit that was Killed
	local killedUnit = EntIndexToHScript( keys.entindex_killed )
	-- The Killing entity
	local killerEntity = nil

	if keys.entindex_attacker ~= nil then
		killerEntity = EntIndexToHScript( keys.entindex_attacker )
	end

	-- The ability/item used to kill, or nil if not killed by an item/ability
	local killerAbility = nil

	if keys.entindex_inflictor ~= nil then
		killerAbility = EntIndexToHScript( keys.entindex_inflictor )
	end
	
	if killedUnit.IsRealHero and killedUnit:IsRealHero() then
		local newOrder = 
		{
			UnitIndex = keys.entindex_inflictor, 
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			TargetIndex = nil, --Optional.  Only used when targeting units
			AbilityIndex = 0, --Optional.  Only used when casting abilities
			Position = GameMode.AncientPosition[killedUnit:GetTeam()], --Optional.  Only used when targeting the ground
			Queue = 1 --Optional.  Used for queueing up abilities
		}

		ExecuteOrderFromTable(newOrder)
	end

	if string.sub(killedUnit:GetUnitName(), 1, 23) == "npc_dota_unit_hlw_level" then
		GameMode.TeamCreepCounts[killedUnit:GetTeamNumber()] = GameMode.TeamCreepCounts[killedUnit:GetTeamNumber()] - 1
	end
	-- Put code here to handle when an entity gets killed
	if killerEntity.IsRealHero and killerEntity:IsRealHero() then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(killerEntity:GetPlayerID()), "UpdateButtonStatuses", GameMode:GetButtonUpdateData(killerEntity:GetPlayerID()) )
	end
end


-- This function is called 1 to 2 times as the player connects initially but before they 
-- have completely connected
function GameMode:PlayerConnect(keys)
	DebugPrint('[BAREBONES] PlayerConnect')
	DebugPrintTable(keys)
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
	DebugPrint('[BAREBONES] OnConnectFull')
	DebugPrintTable(keys)

	GameMode:_OnConnectFull(keys)
	
	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)
	
	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	if GameMode.FirstPlayerLoaded ~= true then
		Timers:CreateTimer(0.1, function()
			if GameMode.RecievedSetHost ~= true then
				CustomGameEventManager:Send_ServerToPlayer(ply, "SetHost", nil)
				return 0.5
			end
		end)
		GameMode.FirstPlayerLoaded = true
	else
		Timers:CreateTimer(1, function()
			for k, v in pairs(GameMode.Settings) do
				CustomGameEventManager:Send_ServerToAllClients("SetSettingFromServer", {panel=k, choice=v})
			end
		end)
	end
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function GameMode:OnIllusionsCreated(keys)
	DebugPrint('[BAREBONES] OnIllusionsCreated')
	DebugPrintTable(keys)

	local originalEntity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever an item is combined to create a new item
function GameMode:OnItemCombined(keys)
	DebugPrint('[BAREBONES] OnItemCombined')
	DebugPrintTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end
	local player = PlayerResource:GetPlayer(plyID)

	-- The name of the item purchased
	local itemName = keys.itemname 
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
end

-- This function is called whenever an ability begins its PhaseStart phase (but before it is actually cast)
function GameMode:OnAbilityCastBegins(keys)
	DebugPrint('[BAREBONES] OnAbilityCastBegins')
	DebugPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityName = keys.abilityname
end

-- This function is called whenever a tower is killed
function GameMode:OnTowerKill(keys)
	DebugPrint('[BAREBONES] OnTowerKill')
	DebugPrintTable(keys)

	local gold = keys.gold
	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local team = keys.teamnumber
end

-- This function is called whenever a player changes there custom team selection during Game Setup 
function GameMode:OnPlayerSelectedCustomTeam(keys)
	DebugPrint('[BAREBONES] OnPlayerSelectedCustomTeam')
	DebugPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.player_id)
	local success = (keys.success == 1)
	local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
function GameMode:OnNPCGoalReached(keys)
	DebugPrint('[BAREBONES] OnNPCGoalReached')
	DebugPrintTable(keys)

	local goalEntity = EntIndexToHScript(keys.goal_entindex)
	local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
	local npc = EntIndexToHScript(keys.npc_entindex)
end