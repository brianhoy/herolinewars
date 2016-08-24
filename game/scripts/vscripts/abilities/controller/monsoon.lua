require('libraries/timers')

function start_storm(keys)
	local caster = keys.caster
	local target = keys.target_points[1]

	local ID = GameRules:GetGameTime()
	lastID = ID	
	local changetime = true
	if TimeOfDayReset == nil then
		TimeOfDayReset = GameRules:GetTimeOfDay()
	else
		changetime = false
	end
	GameRules:SetTimeOfDay(0)

	local damage_ = keys.Damage
	local duration = keys.Duration
	local aoe = keys.AreaOfEffect
	local boltspersecond = keys.BoltsPerSecond

	local aoefactor = 1 + ((aoe - 400) / 500)

	local particleName1 = "particles/razor_static_storm/razor_rain_storm.vpcf"
	local particleName2 = "particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf"
	local particleName3 = "particles/units/heroes/hero_phoenix/phoenix_supernova_death.vpcf"

	local soundName1 = {}
	soundName1[1] = "Hero_Zuus.LightningBolt.Righteous"
	soundName1[2] = "Hero_Zuus.LightningBolt.Cast.Righteous"
	local soundName2 = "Hero_Pheonix.SuperNova.Explode"

	local particleLocations = 
	{
		Vector(200, 100, 0) * aoefactor,
		Vector(100, 200, 0) * aoefactor,

		Vector(-200, 100, 0) * aoefactor,
		Vector(-100, 200, 0) * aoefactor,

		Vector(-200, -100, 0) * aoefactor,
		Vector(-100, -200, 0) * aoefactor,

		Vector(200, -100, 0) * aoefactor,
		Vector(100, -200, 0) * aoefactor,

		Vector(0, 0, 0),
	}
	local particle1 = {}
	for i = 9, 9 do
		particle1[i] = ParticleManager:CreateParticle(particleName1, PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(particle1[i], 0, target + particleLocations[i])
	end

	local runs = boltspersecond * duration
	local z = 0
	Timers:CreateTimer(0, function()
		if z >= runs then
			particle3 = ParticleManager:CreateParticle(particleName3, PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(particle3, 1, target)
			StartSoundEventFromPosition(soundName2, target)
			for i = 9, 9 do
				ParticleManager:DestroyParticle(particle1[i], true)
			end
			if lastID == ID then
				GameRules:SetTimeOfDay(TimeOfDayReset)
				TimeOfDayReset = nil			
			end
			return nil
		end

		local vec = RandomVector(RandomInt(0, aoe))

		local doRandomBolt = true
		local entcount = 0
		local entsa = {}
		for _, ent in pairs(Entities:FindAllInSphere(target, aoe)) do
			if ent:GetClassname() == "npc_dota_creature" or string.sub(ent:GetClassname(), 1, 13) == "npc_dota_hero" then
				if ent:IsAlive() ~= false then
					if ent:GetTeamNumber() ~= caster:GetTeamNumber() then
						entcount = entcount + 1
						entsa[entcount] = ent
						doRandomBolt = false
					end
				end
			end
		end
	
		if doRandomBolt == false then
			local vic = entsa[RandomInt(1, entcount)]
			local damageTable = {
				victim = vic,
				attacker = caster,
				damage = damage_,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = keys.ability
			}
			ApplyDamage(damageTable)

			local particle2 = ParticleManager:CreateParticle(particleName2, PATTACH_CUSTOMORIGIN, caster)
			local vicorigin = vic:GetAbsOrigin()
			ParticleManager:SetParticleControl(particle2, 0, vicorigin)
			vicorigin.z = vicorigin.z + 400
			ParticleManager:SetParticleControl(particle2, 1, vicorigin)

			StartSoundEventFromPosition(soundName1[1], vic:GetAbsOrigin())
		else
			local particle2 = ParticleManager:CreateParticle(particleName2, PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(particle2, 0, target + vec)
			vec.z = vec.z + 400
			ParticleManager:SetParticleControl(particle2, 1, target + vec)
			if z % 2 == 0 then
				StartSoundEventFromPosition(soundName1[2], vec + target)
			end
		end
		
		
		



		

		z = z + 1
		return 1 / boltspersecond 
	end)
end