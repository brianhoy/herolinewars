require("libraries/timers")

function start_field(keys)
	local caster = keys.caster
	local target = keys.target_points[1]
	local ability = keys.ability
	
	local shard_hit_radius = ability:GetSpecialValueFor("shard_hit_radius")
	local area_of_effect = ability:GetSpecialValueFor("area_of_effect")
	local ice_shard_wave_count = ability:GetSpecialValueFor("ice_shard_wave_count")
	local damage = ability:GetSpecialValueFor("damage")

	local ID = GameRules:GetGameTime()
	lastID = ID	

	local changetime = true
	if TimeOfDayReset == nil then
		TimeOfDayReset = GameRules:GetTimeOfDay()
	else
		changetime = false
	end

		GameRules:SetTimeOfDay(0)

	
	local dummy = CreateUnitByName( "npc_dummy_unit", target, false, caster, caster, caster:GetTeamNumber() )
	dummy:AddNewModifier(caster, nil, "modifier_invulnerable", {duration=999999})

	local particleName1 = "particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_explosion_arcana1.vpcf"
	local particleName2 = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf"
	local particleName3 = "particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_casterribbons_glow2_arcana1.vpcf"
	local particleName4 = "particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_casterribbons_arcana1.vpcf"
	local particleName5 = "particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_darkcore_arcana1.vpcf"
	local particleName6 = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"

	local particle2 = ParticleManager:CreateParticle(particleName2, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle2, 0, target)

	local particle3 = ParticleManager:CreateParticle(particleName3, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle3, 0, target)

	local particle4 = ParticleManager:CreateParticle(particleName4, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle4, 0, target)

	StartSoundEvent("hero_Crystal.freezingField.wind", dummy)

	local i = 0
	Timers:CreateTimer(0, function()
		if i >= ice_shard_wave_count then
				local particle5 = ParticleManager:CreateParticle(particleName5, PATTACH_CUSTOMORIGIN, caster)
				ParticleManager:SetParticleControl(particle5, 0, target)

				ParticleManager:DestroyParticle(particle2, true)
				ParticleManager:DestroyParticle(particle3, true)
				ParticleManager:DestroyParticle(particle4, true)
				
				StopSoundEvent("hero_Crystal.freezingField.wind", dummy)
				dummy:RemoveSelf()		

				if lastID == ID then
					GameRules:SetTimeOfDay(TimeOfDayReset)
					TimeOfDayReset = nil			
				end

				Timers:CreateTimer(3, function()
					ParticleManager:DestroyParticle(particle5, true)
					return nil
				end)
			return nil
		end
		
		local random = RandomInt(1, 2)
		if random == 1 then
			pName = particleName1
		else
			pName = particleName6
		end
		local particle1 = ParticleManager:CreateParticle(pName, PATTACH_CUSTOMORIGIN, caster)
		local vec = RandomVector(RandomInt(0, area_of_effect))
		ParticleManager:SetParticleControl(particle1, 0, target + vec)
		
		if i % 2 == 0 then
			StartSoundEventFromPositionUnreliable("hero_Crystal.freezingField.explosion", target)
		end

		local units = FindUnitsInRadius(ability:GetTeamNumber(), target, nil, shard_hit_radius, ability:GetAbilityTargetTeam(), 
					ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), 0, false)

		for _, ent in pairs(units) do
			if ent:GetTeamNumber() ~= caster:GetTeamNumber() then
				local damageTable = 
				{
					victim = ent,
					attacker = caster,
					damage = damage,
					damage_type = ability:GetAbilityDamageType(),
					ability = ability
				}
				ApplyDamage(damageTable)
			end
		end

		i = i + 1
		return 0.07
	end)
end