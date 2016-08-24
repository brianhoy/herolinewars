require('libraries/timers')

function send_wave(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	print('[HLW] sending wave at ', point)
	point.z = 256
	point.x = 3500	

	local particles = {}

	for i = 1, 5 do
		particles[i] = ParticleManager:CreateParticle("particles/units/heroes/hero_morphling/morphling_waveform_splash_f.vpcf", 3, caster)
	end

	local z = 0
	Timers:CreateTimer(0.1, function()
		if point.x < -700 then
			point.z = 384
		end
		if point.x < -4750 then	
			for i = 1, 5 do
				ParticleManager:DestroyParticle(particles[i], true)
			end
			StartSoundEventFromPosition("Ability.Ghostship.crash", point)
			return nil
		else
			local mult
			local ef = z % 8
			if ef <= 3 then
				mult = 100 * (ef - 4)
			else
				mult = -100 * (ef - 4)
			end
			mult = mult + 250
			for i = 1, 5 do
				local npy = point.y + ((i - 3) * 100)


				ParticleManager:SetParticleControl(particles[i], 3, Vector(point.x, npy, point.z + mult ))
			end
			
			for _, ent in pairs(Entities:FindAllByClassnameWithin("npc_dota_creature", point, 300)) do
				if not ent:HasModifier("dummy_modifier") then
					if ent:IsCreep() and ent:GetTeamNumber() ~= caster:GetTeamNumber() then
						local damageTable = {
							victim = ent,
							attacker = caster,
							damage = keys.Damage,
							damage_type = DAMAGE_TYPE_PURE,
							ability = keys.ability
						}
						ApplyDamage(damageTable)
						keys.ability:ApplyDataDrivenModifier(caster, ent, "dummy_modifier", {duration=2})
					end
				end
			end
			if z % 8 == 0 then
				StartSoundEventFromPosition("Hero_Morphling.Waveform", point)
			end
			z = z + 1
			point.x = point.x - 200
			return 0.1
		end
	end)
	
	Timers:CreateTimer(10, function()
		for i = 1, 5 do
			ParticleManager:DestroyParticle(particles[i], true)
		end
		return nil
	end)	
end