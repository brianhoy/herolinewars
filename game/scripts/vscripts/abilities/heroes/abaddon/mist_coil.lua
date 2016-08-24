function DeathCoil( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local damage_percent = ability:GetLevelSpecialValueFor( "target_damage_percent" , ability:GetLevel() - 1  )
	local self_damage_percent = ability:GetLevelSpecialValueFor( "self_damage_percent" , ability:GetLevel() - 1  )
	local heal_amount = ability:GetLevelSpecialValueFor( "heal_amount" , ability:GetLevel() - 1 )
	local projectile_speed = ability:GetSpecialValueFor( "projectile_speed" )
	local particle_name = "particles/units/heroes/hero_abaddon/abaddon_death_coil.vpcf"

	-- Play the ability sound
	caster:EmitSound("Hero_Abaddon.DeathCoil.Cast")
	target:EmitSound("Hero_Abaddon.DeathCoil.Target")

	-- If the target and caster are on a different team, do Damage. Heal otherwise
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		local enemy_current_health_percent = target:GetHealth() / target:GetMaxHealth()

		local damage_amount = (damage_percent/100) * (target:GetMaxHealth() - target:GetHealth())
		ApplyDamage({ victim = target, attacker = caster, damage = damage_amount,	damage_type = DAMAGE_TYPE_MAGICAL })

		local self_damage_amount = (self_damage_percent/100) * (caster:GetMaxHealth() - (enemy_current_health_percent * caster:GetMaxHealth()))
		ApplyDamage({ victim = caster, attacker = caster, damage = self_damage_amount,	damage_type = DAMAGE_TYPE_MAGICAL })
	else
		target:Heal(heal_amount, caster)
		ApplyDamage({ victim = caster, attacker = caster, damage = heal_amount,	damage_type = DAMAGE_TYPE_PURE })
	end

	-- Self Damage

	-- Create the projectile
	local info = {
		Target = target,
		Source = caster,
		Ability = ability,
		EffectName = particle_name,
		bDodgeable = false,
			bProvidesVision = true,
			iMoveSpeed = projectile_speed,
        iVisionRadius = 0,
        iVisionTeamNumber = caster:GetTeamNumber(),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	}
	ProjectileManager:CreateTrackingProjectile( info )

end
