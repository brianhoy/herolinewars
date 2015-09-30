modifier_bonus_strength_lua = class({})
LinkLuaModifier("modifier_bonus_strength_lua", "modifiers/modifier_bonus_strength", LUA_MODIFIER_MOTION_NONE)

function modifier_bonus_strength_lua:DeclareFunctions(keys)
	local funcs = 
	{
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS 
	}
 
	return funcs
end

function modifier_bonus_strength_lua:GetModifierBonusStats_Strength(keys)
	local bonus = self:GetCaster().strength_bonus
	self:SetStackCount(bonus)
	return bonus
end

function modifier_bonus_strength_lua:GetModifierModelScale(keys)
	local bonus = self:GetCaster().strength_bonus
	return bonus * 0.4
end

function modifier_bonus_strength_lua:GetTexture()
	return "fist"
end

function modifier_bonus_strength_lua:RemoveOnDeath()
	return false
end