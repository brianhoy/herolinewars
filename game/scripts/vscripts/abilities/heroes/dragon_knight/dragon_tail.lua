function ApplyKnockback(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")
	local knockback_time = ability:GetSpecialValueFor("knockback_time")
	local knockback_distance = ability:GetSpecialValueFor("knockback_duration")
	local stun_duration = ability:GetSpecialValueFor("stun_duration")
	local caster_location = caster:GetAbsOrigin()

	local units = FindUnitsInRadius(caster:GetTeam(), caster_location, nil, radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), 0, 0, false)

	for _, unit in pairs(units) do
		unit:AddNewModifier(caster, ability, "modifier_knockback", {
			duration = knockback_time, 
			should_stun = 0, 
			knockback_distance = knockback_distance, 
			knockback_height = 200, 
			center_x = caster_location.x, 
			center_y = caster_location.y, 
			center_z = caster_location.z, 
			knockback_duration = knockback_time
		})

		unit:AddNewModifier(caster, ability, "modifier_stunned", { duration = stun_duration })
	end
end