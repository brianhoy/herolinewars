require('libraries/timers')

function OnUnitHitAncient(keys)
	GameRules.GameMode:HOnUnitHitAncient(keys.activator)
end

function BaseTriggered(keys)
	local unit = keys.activator;
	if string.sub(unit:GetUnitName(), 1, 23) == "npc_dota_unit_hlw_level" then
		print('[HLW] A creep hit the stairs!')
		local team = GameMode:HGetOtherTeam(unit) 
		unit:AddNewModifier(unit, nil, "modifier_knockback", 
		{
			duration = 0.6, 
			should_stun = 0, 
			knockback_distance = 1500, 
			knockback_height = 200, 
			center_x = GameMode.AncientPosition[team].x + 1800, 
			center_y = GameMode.AncientPosition[team].y, 
			center_z = GameMode.AncientPosition[team].z, 
			knockback_duration = 1
		})
		Timers:CreateTimer(0.7, function()
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
			return nil
		end)
	end
end

function InvulnerableTouched(keys)
	print('[HLW] InvulnerableTouched.')
	if keys.activator:IsRealHero() ~= true then
		return
	end
	keys.activator:AddNewModifier(unit, nil, "modifier_disarmed", {duration=-1})
	keys.activator:AddNewModifier(unit, nil, "modifier_silence", {duration=-1})
	keys.activator:AddNewModifier(unit, nil, "modifier_unattackable_lua", {duration=-1})
end

function InvulnerableLeft(keys)
	if keys.activator:IsRealHero() ~= true then
		return
	end

	if keys.activator:HasModifier("modifier_disarmed") then
		keys.activator:RemoveModifierByName("modifier_disarmed")
	end
	if keys.activator:HasModifier("modifier_silence") then
		keys.activator:RemoveModifierByName("modifier_silence")
	end
	if keys.activator:HasModifier("modifier_item_ghost_scepter") then
		keys.activator:RemoveModifierByName("modifier_item_ghost_scepter")
	end
	if keys.activator:HasModifier("modifier_unattackable_lua") then
		keys.activator:RemoveModifierByName("modifier_unattackable_lua")
	end
end

function NoNavTouched(keys)
	local activator = keys.activator
	local className = activator:GetClassname()

	if className == "npc_dota_hero_jakiro" then
		return
	else
		EnsureRightSide(activator)
	end
end

function EnsureRightSide(unit)
	local i = 0
	local origin = unit:GetAbsOrigin()
	if unit:GetTeamNumber() == DOTA_TEAM_BADGUYS then
		Timers:CreateTimer(0, function() 
			if unit:GetAbsOrigin().y > -1400 then
				PunishPlayer(unit)
				PunishPlayer(unit)
				if unit:GetAbsOrigin().x > 4000 then
					unit:SetAbsOrigin(Vector(4000, origin.y, origin.z))
				end
				if unit:GetAbsOrigin().x < -4000 then
					unit:SetAbsOrigin(Vector(-4000, origin.y, origin.z))
				end
				unit:SetAbsOrigin(Vector(unit:GetAbsOrigin().x, -1600, origin.z))
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
				EnsureRightSide(unit)
				return
			else
				if i ~= 20 then
					i = i + 1
					return 0.1
				end
			end
		end)
	else
		Timers:CreateTimer(0, function() 
			if unit:GetAbsOrigin().y < 1400 then
				PunishPlayer(unit)
				if unit:GetAbsOrigin().x > 4000 then
					unit:SetAbsOrigin(Vector(4000, origin.y, origin.z))
				end
				if unit:GetAbsOrigin().x < -4000 then
					unit:SetAbsOrigin(Vector(-4000, origin.y, origin.z))
				end
				unit:SetAbsOrigin(Vector(unit:GetAbsOrigin().x, 1600, origin.z))
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
				EnsureRightSide(unit)
				return
			else
				if i ~= 20 then
					i = i + 1
					return 0.1
				end
			end
		end)
	end
end

function PunishPlayer(unit)
	GameMode:SendErrorMessage(unit:GetPlayerID(), "Error moving: you are not allowed to be there. You will now be stunned.")
	unit:AddNewModifier(unit, nil, "modifier_stunned", {duration=10.0})
end

function UpgradeController(keys)
	local activator = keys.activator
	local className = activator:GetClassname()

	if className ~= "npc_dota_hero_jakiro" then
		return
	end

	local playerID = activator:GetPlayerID()
	local team = activator:GetTeamNumber()
	local gold = PlayerResource:GetGold(playerID)
	local goldCost = GameMode.ControllerIncreaseManaCost[playerID]
	local controllerLoc = GameMode.ControllerLocations[team][playerID + 50]
	local player = PlayerResource:GetSelectedHeroEntity(playerID)
	local soundName1 = "Loot_Drop_Stinger_Mythical"	
	local mana = activator:GetMana()
	local manaIncrease = GameMode.ControllerManaIncreaseAmount

	activator:SetAbsOrigin(controllerLoc)
	FindClearSpaceForUnit(activator, controllerLoc, false)	

	local stopOrder = {
 		UnitIndex = activator:entindex(), 
 		OrderType = DOTA_UNIT_ORDER_HOLD_POSITION,
 	}

	ExecuteOrderFromTable(stopOrder)
	activator:StartGesture(ACT_DOTA_SPAWN)

	if goldCost > gold then
		GameMode:SendErrorMessage(playerID, "Error purchasing mana: it costs " .. goldCost .. " gold. (You need " .. tostring(goldCost - gold) .. " more gold)")
		return
	end

	PlayerResource:SpendGold(playerID, goldCost, 0)
	GameMode.ControllerIncreaseManaCost[playerID] = goldCost + GameMode.ControllerIncreaseManaCostIncrement
	EmitSoundOnClient(soundName1, PlayerResource:GetPlayer(playerID))
	activator:SetMana(mana + manaIncrease)
end

function OnUnitEnterPhaseArea(keys)
	local activator = keys.activator
	if string.sub(activator:GetUnitName(), 1, 23) == "npc_dota_unit_hlw_level" then
		activator:AddNewModifier(activator, nil, "modifier_phased", {duration=-1})
	end
end

function OnUnitLeavePhaseArea(keys)
	local activator = keys.activator
	if activator and string.sub(activator:GetUnitName(), 1, 23) == "npc_dota_unit_hlw_level" then
		activator:RemoveModifierByName("modifier_phased")
	end
end