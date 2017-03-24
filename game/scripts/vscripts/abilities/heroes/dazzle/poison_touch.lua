--[[Author: Pizzalol
	Date: 07.02.2015.
	Checks if the current ability level is supposed to stun, if yes then stun the target]]
function PoisonTouchStun( keys )
	local caster = keys.caster
	local target = keys.target_points[1]
	local direction = caster - target
	local ability = keys.ability

	local ability_level = ability:GetLevel() - 1
	local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)
	local should_stun = ability:GetLevelSpecialValueFor("should_stun", ability_level)

	if should_stun == 1 then
		target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})
	end
end

function ThrowPoisonProjectile(keys)
	local caster = keys.caster
	local target = keys.target_points[1]
	local ability = keys.ability
	local ability_level = ability:GetLevel()
	local projectile_speed = ability:GetLevelSpecialValueFor("projectile_speed", ability_level)
	local projectile_duration = ability:GetSpecialValueFor("projectile_duration")

	local direction = (target - caster:GetAbsOrigin())
	direction.z = 0
	direction = direction:Normalized()

	local unit = CreateUnitByName( "npc_dummy_unit", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
	Physics:Unit(unit)
	unit:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	unit:SetGroundBehavior(PHYSICS_GROUND_LOCK)
	unit:AddPhysicsVelocity(direction * projectile_speed)
	unit:SetPhysicsFriction(0)
	unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})

	local particle = ParticleManager:CreateParticle("particles/heroes/dazzle/hlw_dazzle_poison_touch.vpcf", PATTACH_OVERHEAD_FOLLOW, unit )
	ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_OVERHEAD_FOLLOW, "attach_overhead", unit:GetAbsOrigin(), true)
	-- Creates a new particle effect
	local end_projectile = false

	Timers:CreateTimer(function()

			if end_projectile then
				return nil
			end
			-- Check for units to apply the debuff to
			local enemies = FindUnitsInRadius(caster:GetTeamNumber(), unit:GetAbsOrigin(), nil, 100, 
				DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, 0, false )

			for _, enemy in pairs(enemies) do
				ability:ApplyDataDrivenModifier(caster, enemy, "modifier_poison_touch_slow_1_datadriven", {
					Target = enemy,
					Duration = ability:GetLevelSpecialValueFor("slow_1_duration", ability_level)
				} )
				ability:ApplyDataDrivenModifier(caster, enemy, "modifier_poison_touch_debuff_datadriven", {
					Target = enemy,
					Duration = ability:GetLevelSpecialValueFor("duration_tooltip", ability_level)
				} )

				Timers:CreateTimer(ability:GetLevelSpecialValueFor("set_time", ability_level), function()
						ability:ApplyDataDrivenModifier(caster, enemy, "modifier_poison_touch_damage_datadriven", {
							Target = enemy,
							Duration = ability:GetLevelSpecialValueFor("damage_duration", ability_level)
						} )

					end
				)
			end

			return 0.1
		end
	)

	Timers:CreateTimer(projectile_duration, function()
			end_projectile = true
			unit:RemoveSelf()
			ParticleManager:DestroyParticle(particle, false)
		end
	)
end