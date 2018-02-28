require('libraries/notifications')

function GameMode:HLWPrint(string)
	if GameMode.DebugMode ~= true then
		return
	end
	print("[HLW-debug] " .. string)
end

function GameMode:SetSetting(keys)
	local setting = keys.setting
	local value = keys.value

	if setting == "DifficultyRow" then
		GameMode.Settings[1] = value
		CustomGameEventManager:Send_ServerToAllClients("SetSettingFromServer", {panel=1, choice=value})
		GameMode.Difficulty = value * 0.5
	elseif setting == "MaxCreepPerTeamRow" then
		GameMode.Settings[2] = value
		CustomGameEventManager:Send_ServerToAllClients("SetSettingFromServer", {panel=2, choice=value})
		GameMode.MaxCreepCountPerTeam = (value * 50) + 100
	elseif setting == "MaxChargesPerCreepRow" then
		GameMode.Settings[3] = value
		CustomGameEventManager:Send_ServerToAllClients("SetSettingFromServer", {panel=3, choice=value})
		if keys.value ~= 4 then
			GameMode.MaxCharges = (value*2) + 1
		else
			GameMode.MaxCharges = 10
		end
	end
end

function GameMode:ExecuteOrderFilter(keys)
	-- Glyph is used
	if keys.order_type == DOTA_UNIT_ORDER_GLYPH then
		local playerID = keys.issuer_player_id_const
		GameMode:OnGlyphUsed( { TeamNumber = PlayerResource:GetTeam(playerID) } )
	end

	return true
end

function GameMode:GetButtonArrayData(level)
	local data = {
		level = level,
		CreepCosts = {},
		CreepImagePaths = {},
		CreepCharges = GameMode.MaxCharges
	}
	
	level = level - 1

	for i = 1,10 do
		data.CreepImagePaths[i] = "file://{images}/custom_game/hlw_creeps/creep" .. (i + (10 * level)) .. ".png"
		data.CreepCosts[i] = GameMode.CreepCost[(i + (10 * level))]
	end
	
	if(level < 2) then
		data.CreepCosts[0] = GameMode.UpgradeCost[level + 1]
		data.CreepImagePaths[0] = "file://{images}/custom_game/hlw_creeps/upgrade1.png"
	end

	return data
end

function GameMode:GetButtonUpdateData(PlayerID)
	local data = 
	{
		PlayerGold = PlayerResource:GetGold(PlayerID),
		PlayerCharges = {},
	}
	
	for i = 1, PlayerResource:GetPlayerCount() do
		data.PlayerCharges[i] = GameMode.PlayerCharges[PlayerID][i + (10 * (GameMode.PlayerLevels[PlayerID] - 1))]
	end

	return data
end

function GameMode:GetIncomeTableData()
	local data = {}

	local size = 0

	for PlayerID, Income in pairs(GameMode.PlayerIncomes) do
		data[PlayerID] = {}
		data[PlayerID].Income = Income
		data[PlayerID].PlayerID = PlayerID
		data[PlayerID].SteamID = PlayerResource:GetPlayerName(PlayerID)
		data[PlayerID].Team = PlayerResource:GetTeam(PlayerID)
		size = size + 1
	end

	data.size = size
	
	return data
end

function GameMode:InitializeCreepPanoramaForPlayer(PlayerID)
	GameMode.RecievedCreepPanorama[PlayerID] = false

	local player = PlayerResource:GetPlayer(PlayerID)
	local i = 0

	Timers:CreateTimer(0.1, function()
		i = i + 1
		if i > 50 then
			return nil
		end
		if not player then return end
		if GameMode.RecievedCreepPanorama[PlayerID] == true then
			GameMode.RecievedCreepPanorama[PlayerID] = false
			CustomGameEventManager:Send_ServerToPlayer(player, "UpdateButtonStatuses", GameMode:GetButtonUpdateData(PlayerID))
			return nil
		end
		if PlayerResource:GetConnectionState(PlayerID) == DOTA_CONNECTION_STATE_DISCONNECTED then
			return nil
		end
		CustomGameEventManager:Send_ServerToPlayer(player, "SetButtonConfig", GameMode:GetButtonArrayData(GameMode.PlayerLevels[PlayerID]))
		return 1.0
	end)
end

function GameMode:HGetOtherTeam(unit)
	if unit:GetTeamNumber() == 2 then
		return 3
	else
		return 2
	end
end

function GameMode:StartSuddenDeath()
	local centerMessage =  { message = "#hlw_sudden_death", duration = 3 }
	FireGameEvent("show_center_message", centerMessage)
	for i = 2, 3 do
		GameRules:GetGameModeEntity():SetTopBarTeamValue ( i, 1 )
		GameMode.Lives[i] = 1
	end

	CustomGameEventManager:Send_ServerToAllClients("UpdateScore", {teamID = DOTA_TEAM_GOODGUYS, score = GameMode.Lives[DOTA_TEAM_GOODGUYS]})
	CustomGameEventManager:Send_ServerToAllClients("UpdateScore", {teamID = DOTA_TEAM_BADGUYS, score = GameMode.Lives[DOTA_TEAM_BADGUYS]})

	EmitGlobalSound("HLW.SuddenDeathMusic")
end

function GameMode:GetRandomTip()
	local tipavailable = false
	local size = 0

	for _, v in pairs(GameMode.UsedTips) do
		if v == false then
			tipavailable = true
		end
		size = size + 1
	end

	if tipavailable == false then
		for i, _ in pairs(GameMode.UsedTips) do
			GameMode.UsedTips[i] = false
		end
	end
	
	local random
	while true do
		random = RandomInt(1, size)
		if GameMode.UsedTips[random] == false then
			break
		end
	end

	local tip = GameMode.Tips[random]
	GameMode.UsedTips[random] = true

	return tip
end

function GameMode:SendErrorMessage( pID, string )
	Notifications:ClearBottom(pID)
	Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
	EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end
