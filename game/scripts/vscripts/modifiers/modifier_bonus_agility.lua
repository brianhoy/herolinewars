modifier_bonus_agility_lua = class({})
LinkLuaModifier("modifier_bonus_agility_lua", "modifiers/modifier_bonus_agility", LUA_MODIFIER_MOTION_NONE)

function modifier_bonus_agility_lua:DeclareFunctions(keys)
	local funcs = 
	{
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
	}
 
	return funcs
end

function modifier_bonus_agility_lua:GetModifierBonusStats_Agility(keys)
	local hero = self:GetCaster()
	local bonus = hero.agility_bonus
	self:SetStackCount(bonus)
	return bonus
end

function modifier_bonus_agility_lua:GetModifierModelScale(keys)
	local bonus = self:GetCaster().agility_bonus
	return bonus * 0.4
end

function modifier_bonus_agility_lua:GetTexture()
	return "wind-slap"
end

function modifier_bonus_agility_lua:RemoveOnDeath()
	return false
end