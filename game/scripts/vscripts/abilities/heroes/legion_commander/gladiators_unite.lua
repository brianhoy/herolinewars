LinkLuaModifier("modifier_legion_commander_gladiators_unite_lua", "abilities/heroes/legion_commander/modifiers/modifier_legion_commander_gladiators_unite_lua.lua", LUA_MODIFIER_MOTION_NONE )

function StartRing(keys)
	local caster = keys.caster
	local ability = keys.ability
	local particle = keys.particle

	ability.heroes_in_ring = {}

	ability.target = caster:GetAbsOrigin()

	local radius = ability:GetSpecialValueFor("radius")
	local duration = ability:GetSpecialValueFor("duration")

	local particle_id = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle_id, 0, ability.target)

	local elapsed_time = 0

	Timers:CreateTimer(function()
			local units = FindUnitsInRadius(ability:GetTeamNumber(), ability.target, nil, radius, ability:GetAbilityTargetTeam(), 
				ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), 0, false)

			for _, unit in pairs(units) do
				-- If the hero is not in the ring table, add the hero to the table
				if ability.heroes_in_ring[unit:entindex()] == nil then
					print("adding hero to ring")
					local hero = unit
					ability.heroes_in_ring[unit:entindex()] = unit
					hero:AddNewModifier(caster, ability, "modifier_gladiator_visual", {duration = duration - elapsed_time})
					hero:AddNewModifier(caster, ability, "modifier_legion_commander_gladiators_unite_lua", 
						{
							duration = duration - elapsed_time, 
							ability = ability
						})
				end
			end

			for ent_index, hero in pairs(ability.heroes_in_ring) do
				local found = false
				for _, unit in pairs(units) do
					if ent_index == unit:entindex() then
						found = true
						break
					end
				end

				-- If the hero is in the ring table, but is no longer in the radius, remove the hero from the table
				if found == false then
					print("removing hero from ring")

					local hero = ability.heroes_in_ring[ent_index]
					if hero:HasModifier("modifier_legion_commander_gladiators_unite_lua") then
						hero:RemoveModifierByName("modifier_legion_commander_gladiators_unite_lua")
					end

					ability.heroes_in_ring[ent_index] = nil
				end
			end
			
			if elapsed_time > duration then
				ParticleManager:DestroyParticle(particle_id, false)
				return
			end

			elapsed_time = elapsed_time + 0.2
			return 0.2
		end
	)
end

function AddLuaModifier(keys)
	local target = keys.target
	local ability = keys.ability

	print("yo")

	target:AddNewModifier(caster, ability, "modifier_legion_commander_gladiators_unite_lua", {duration=-1})
end

function RemoveLuaModifier(keys)
	local target = keys.target
	local ability = keys.ability
	local modifier = target:FindModifierByName("modifier_legion_commander_gladiators_unite_lua")

	print("bye")

	if modifier then
		target:RemoveModifierByName("modifier_legion_commander_gladiators_unite_lua")
	end
end


