modifier_unattackable_lua = class({})
LinkLuaModifier("modifier_unattackable_lua", "modifiers/modifier_unattackable", LUA_MODIFIER_MOTION_NONE)

function modifier_unattackable_lua:IsHidden()
	return true
end

function modifier_unattackable_lua:CheckState()
	local state = {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
 
	return state
end