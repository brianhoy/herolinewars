modifier_bonus_intelligence_lua = class({})
LinkLuaModifier("modifier_bonus_intelligence_lua", "modifiers/modifier_bonus_intelligence", LUA_MODIFIER_MOTION_NONE)

function modifier_bonus_intelligence_lua:DeclareFunctions(keys)
	local funcs = 
	{
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS  
	}
 
	return funcs
end

function modifier_bonus_intelligence_lua:GetModifierBonusStats_Intellect(keys)
	local bonus = self:GetCaster().intelligence_bonus
	self:SetStackCount(bonus)
	return bonus
end

function modifier_bonus_intelligence_lua:GetModifierModelScale(keys)
	local bonus = self:GetCaster().intelligence_bonus
	return bonus * 0.4
end

function modifier_bonus_intelligence_lua:GetTexture()
	return "orb-wand"
end

function modifier_bonus_intelligence_lua:RemoveOnDeath()
	return false
end