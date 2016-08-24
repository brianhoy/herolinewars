function GameMode:OnPlayerBuyAllAttributes(keys)
	local playerID = keys.PlayerID
	local attribute = keys.Attribute
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)

	local cost = GameMode:GetAttributeCost(attribute, hero)

	if hero:GetGold() < cost then
		GameMode:SendErrorMessage(playerID, "#hlw_error_attribute_not_enough_gold_plural")
	end

	while hero:GetGold() >= GameMode:GetAttributeCost(attribute, hero) do
		GameMode:OnPlayerBuyAttribute(keys)
	end
end

function GameMode:GetAttributeCost(attribute, hero)
	if attribute == "strength" then
		return (hero.strength_bonus * 10) + 100
	elseif attribute == "agility" then
		return (hero.agility_bonus * 10) + 100
	elseif attribute == "intelligence" then
		return (hero.intelligence_bonus * 10) + 100
	end
end

function GameMode:OnPlayerBuyAttribute(keys)
	local playerID = keys.PlayerID
	local attribute = keys.Attribute
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)

	if hero:GetGold() < GameMode:GetAttributeCost(attribute, hero) then
		GameMode:SendErrorMessage(playerID, "#hlw_error_attribute_not_enough_gold")
		return
	end

	hero:SpendGold(GameMode:GetAttributeCost(attribute, hero), 0)	

	if attribute == "strength" then
		hero.strength_bonus = hero.strength_bonus + 1
		if hero:HasModifier("modifier_bonus_strength_lua") then
			hero:RemoveModifierByName("modifier_bonus_strength_lua")
		end
		hero:AddNewModifier(hero, nil, "modifier_bonus_strength_lua", {duration=-1})

	elseif attribute == "agility" then
		hero.agility_bonus = hero.agility_bonus + 1
		if hero:HasModifier("modifier_bonus_agility_lua") then
			hero:RemoveModifierByName("modifier_bonus_agility_lua")
		end
		hero:AddNewModifier(hero, nil, "modifier_bonus_agility_lua", {duration=-1})

	elseif attribute == "intelligence" then
		hero.intelligence_bonus = hero.intelligence_bonus + 1
		if hero:HasModifier("modifier_bonus_intelligence_lua") then
			hero:RemoveModifierByName("modifier_bonus_intelligence_lua")
		end
		hero:AddNewModifier(hero, nil, "modifier_bonus_intelligence_lua", {duration=-1})
	end

	local attrTable = 
	{ 
		["strength"] = GameMode:GetAttributeCost("strength", hero), 
		["agility"] = GameMode:GetAttributeCost("agility", hero), 
		["intelligence"] = GameMode:GetAttributeCost("intelligence", hero)
	}
	CustomNetTables:SetTableValue("attributecost", tostring(playerID), attrTable);
end