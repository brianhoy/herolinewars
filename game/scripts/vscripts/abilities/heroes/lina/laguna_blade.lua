local easingFunctions = require("libraries/easing")

function StartChanneling(keys)
	local caster = keys.caster
	local ability = keys.ability
	local prep_time = ability:GetSpecialValueFor("prep_time")
	local pulses_per_second = ability:GetSpecialValueFor("pulses_per_second")
	local radius = ability:GetSpecialValueFor("radius")
	local max_jump_targets = ability:GetSpecialValueFor("max_jump_targets")
	local laguna_particle_name = 'particles/units/heroes/hero_lina/lina_spell_laguna_blade.vpcf';
	local mana_to_damage_conversion_rate = ability:GetSpecialValueFor("mana_to_damage_conversion_rate")
	local percent_mana_drain_per_second = ability:GetSpecialValueFor("percent_mana_drain_per_second")

	-- Ground particle
	local caster_location = caster:GetAbsOrigin()
	local ground_particle_location = caster_location
	ground_particle_location.z = GetGroundHeight(ground_particle_location, caster)

	local ground_particle = 'particles/heroes/earthshaker/earthshaker_totem_ti6_cast.vpcf'
	local ground_particle_id = ParticleManager:CreateParticle(ground_particle, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(ground_particle_id, 0, ground_particle_location)
	
	ability.ground_particle_id = ground_particle_id
	ability.completed = false
	ability.initialHeight = caster_location.z

	-- Raise Lina
	local t = 0 -- elapsed time
	local b = 0 -- initial value
	local c = 200 -- change
	local d = prep_time -- duration
	local interval = 1.0/60.0
	Timers:CreateTimer(0, function()
		if ability.completed == false and t <= d then
			local height = easingFunctions.inQuart(t, b, c, d)
			caster:SetAbsOrigin(Vector(caster_location.x, caster_location.y, caster_location.z + height))
			t = t + interval
			return interval
		end
	end)

	-- Apply periodic damage
	Timers:CreateTimer(0, function()
		print("applying periodic damage")

		local targets = {}
		local current_target = caster

		local mana_requirement = caster:GetMaxMana() * (percent_mana_drain_per_second/100) * (1/pulses_per_second)

		if caster:GetMana() < mana_requirement then
			ChannelCompleted(keys)
			return nil;
		end
		print("mana requirement", mana_requirement)

		caster:SpendMana(mana_requirement, ability)

		local fired_bolt = false

		for i = 1, max_jump_targets do
			local possible_targets = FindUnitsInRadius(caster:GetTeam(), current_target:GetAbsOrigin(), nil, radius, ability:GetAbilityTargetTeam(), 
				ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), 0, false)

			local count = 0
			for _, __ in pairs(possible_targets) do count = count + 1 end
			print("#possible targets", count)

			local found_target = nil

			for _, unit in pairs(possible_targets) do
				if not targets[unit:entindex()] then
					found_target = unit
					break;
				end
			end

			if found_target then
				fired_bolt = true

				targets[found_target:entindex()] = found_target
				
				local particle_id = ParticleManager:CreateParticle(laguna_particle_name, PATTACH_CUSTOMORIGIN, caster)
				if current_target == caster then
					ParticleManager:SetParticleControlEnt(particle_id, 0, current_target, PATTACH_POINT_FOLLOW, "attach_attack1", current_target:GetAbsOrigin(), false)
				else
					ParticleManager:SetParticleControlEnt(particle_id, 0, current_target, PATTACH_POINT_FOLLOW, "attach_hitloc", current_target:GetAbsOrigin(), false)
				end
				ParticleManager:SetParticleControlEnt(particle_id, 1, found_target, PATTACH_POINT_FOLLOW, "attach_hitloc", current_target:GetAbsOrigin(), false)

				current_target = found_target

				local damageTable = {
					victim = current_target,
					attacker = caster,
					damage = mana_requirement * mana_to_damage_conversion_rate,
					damage_type = ability:GetAbilityDamageType(),
					ability = ability
				}
				ApplyDamage(damageTable)
			else
				print("FOUND NO TARGET")
				break
			end
		end

		if fired_bolt then StartSoundEvent("Ability.LagunaBlade", caster) end

		if not ability.completed then
			return (1/pulses_per_second)
		end
	end)

end

function StartAbilityPhase(keys)
end

function ChannelCompleted(keys)
	print("Channel Completed")
	local caster = keys.caster
	local ability = keys.ability
	local caster_location = caster:GetAbsOrigin()

	ability.completed = true

	caster:AddNewModifier(caster, ability, "modifier_lina_laguna_immobile", {duration = 0.3})
	-- Add a modifier to this unit.

	--lower Lina
	local t = 0 -- elapsed time
	local b = 0 -- initial value
	local c = GetGroundHeight(caster_location, caster) - caster_location.z -- change
	local d = 0.3 -- duration
	local interval = 1.0/60.0
	Timers:CreateTimer(0, function()
		if ability.completed == true and t <= d then
			local height = easingFunctions.inQuart(t, b, c, d)
			caster:SetAbsOrigin(Vector(caster_location.x, caster_location.y, caster_location.z + height))
			t = t + interval
			return interval
		end
	end) 
	ParticleManager:DestroyParticle(keys.ability.ground_particle_id, false)
end

function FinishChannelling(keys)
	ChannelCompleted(keys)
end