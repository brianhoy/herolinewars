modifier_cleavable_lua = class({})
LinkLuaModifier("modifier_cleavable_lua", "modifiers/modifier_cleavable", LUA_MODIFIER_MOTION_NONE)
print("[HLW] cleave modifier is LINKED")

function modifier_cleavable_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,	
	}
 
	return funcs
end

function modifier_cleavable_lua:GetTexture()
	print("Modifier cleavify added.")
	return "beastmaster_wild_axes"
end

function modifier_cleavable_lua:OnAttackLanded(keys)
	local target = keys.target
	local attacker = keys.attacker
	local caster = self:GetCaster()	

	if keys.attacker:IsRealHero() ~= true or 
	   keys.target:HasModifier("modifier_cleavable_lua") ~= true then 
		return
	end


	local ability = caster:FindAbilityByName("hlw_antimage_cleavify")
	local radius = ability:GetSpecialValueFor("cleave_radius")
	local attDamage = ability:GetSpecialValueFor("cleave_percent")
	local location = ( -(attacker:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * radius) + target:GetAbsOrigin()

	local particle = ParticleManager:CreateParticle("particles/antimage_cleave_ring/dazzle_weave_circle_ray.vpcf", PATTACH_ABSORIGIN, attacker)
	ParticleManager:SetParticleControl(particle, 0, location)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))

	local units = FindUnitsInRadius(attacker:GetTeamNumber(), location, nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), 0, false)
	for _, unit in pairs(units) do
		if unit:HasModifier("modifier_cleavable_lua") ~= true then
			return
		end

		local damageTable = 
		{
			victim = unit,
			attacker = caster,
			damage = attDamage,
			damage_type = DAMAGE_TYPE_PHYSICAL
		}

		ApplyDamage(damageTable)
	end
end