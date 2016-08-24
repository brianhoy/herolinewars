function CreateMissile(keys)
	local caster = keys.caster
	local target = keys.target_points[1]
	local ability = keys.ability
	local starting_distance = ability:GetLevelSpecialValueFor( "starting_distance", ability:GetLevel() - 1 )
	local direction = (caster:GetAbsOrigin() - target):Normalized()
	
	if ability.missile and ability.missile:IsNull() ~= true then
		ability.missile:ForceKill(false)
		ability.missile:RemoveSelf()
	end

	local position = caster:GetAbsOrigin() + starting_distance * direction
	ability.target = target
	-- The initial position of the missile, to be used later in damage calculations
	ability.starting_position = position
	ability.level = ability:GetLevel() - 1
	-- Number of hits to kill the missile, to be decremented upon attacks
	ability.hits_to_kill = ability:GetLevelSpecialValueFor( "hits_to_kill_tooltip", ability:GetLevel() - 1 )
	-- A boolean telling us whether the missile has hit its target (ensures no repeated missile hit actions)
	ability.hit = false
	
	-- Creates the missile
	ability.missile = CreateUnitByName("npc_dota_gyrocopter_homing_missile", position, true, caster, nil, caster:GetTeam())
	-- Applies the modifer that moves the missile
	ability:ApplyDataDrivenModifier(caster, ability.missile, "modifier_homing_missile_datadriven", {})
	ability.missile:SetOwner(caster)
	-- We need to keep track of passing time, so we know when to fire the missile after the delay
	ability.time_passed = 0
	-- Attaches the fuse particle to the missile
	local particle = ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN_FOLLOW, ability.missile) 
	ParticleManager:SetParticleControlEnt(particle, 1, ability.missile, PATTACH_POINT_FOLLOW, "attach_hitloc", ability.missile:GetAbsOrigin(), true)
end

--[[Author: YOLOSPAGHETTI
	Date: March 28, 2016
	Moves the missile and senses when it hits the target]]
function MoveMissile(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = ability.target
	-- The interval on which this function is called (every 0.02 seconds)
	local interval = 0.02


	-- Checks whether the missile has hit the target already
	if ability.hit == false then
		local pre_flight_time = ability:GetLevelSpecialValueFor( "pre_flight_time", ability.level )
		local stun_duration = ability:GetLevelSpecialValueFor( "stun_duration", ability.level )
		local min_damage = ability:GetLevelSpecialValueFor( "min_damage", ability.level )
		local max_damage = ability:GetLevelSpecialValueFor( "max_damage", ability.level )
		local starting_speed = ability:GetLevelSpecialValueFor("starting_speed", ability.level) * interval
		local max_speed = ability:GetLevelSpecialValueFor("max_speed", ability.level) * interval
		local acceleration = ability:GetLevelSpecialValueFor( "acceleration", ability.level )*interval


		-- Location and distance variables
		local vector_distance = target - ability.missile:GetAbsOrigin()
		local distance = (vector_distance):Length2D()
		local direction = (vector_distance):Normalized()
		
		-- Adds the interval length to the passed time
		ability.time_passed = ability.time_passed + interval
		
		-- Checks if the missile has passed its pre-launch phase
		if ability.time_passed >= pre_flight_time then
			local speed = starting_speed + (ability.time_passed * acceleration)
				if speed > max_speed then
					speed = max_speed
				end

			-- On the missile launch, we play the launch sound
			if ability.time_passed == pre_flight_time then
				EmitSoundOn(keys.sound2, ability.missile)
			end
			-- Checks if the missile is close enough to hit the target (melee range)
			if distance < 128 then
				ability.hit = true
				local radius = ability:GetLevelSpecialValueFor( "radius", ability.level )
				local knockback_duration = ability:GetLevelSpecialValueFor( "knockback_duration", ability.level )
				local knockback_distance = ability:GetLevelSpecialValueFor( "knockback_distance", ability.level )

				local particle = ParticleManager:CreateParticle("particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_guided_missile_explosion.vpcf", 
					PATTACH_ABSORIGIN, ability.missile)

				ParticleManager:SetParticleControl(particle, 0, ability.missile:GetAbsOrigin())

				local particle = ParticleManager:CreateParticle("particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_guided_missile_explosion.vpcf", 
					PATTACH_ABSORIGIN_FOLLOW, ability.missile) 
				ParticleManager:SetParticleControlEnt(particle, 1, ability.missile, PATTACH_POINT_FOLLOW, "attach_hitloc", ability.missile:GetAbsOrigin(), true)

				local units = FindUnitsInRadius(ability:GetTeamNumber(), ability.target, nil, radius, ability:GetAbilityTargetTeam(), 
					ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), 0, false)
				for _, unit in pairs(units) do
					local distance = (unit:GetAbsOrigin() - ability.target):Length2D()
					local damage = rescale(distance, 0, radius, min_damage, max_damage)

					ApplyDamage({
						victim = unit,
						attacker = caster,
						damage = damage,
						damage_type = ability:GetAbilityDamageType()
					})

					unit:AddNewModifier(caster, ability, "modifier_knockback", {
						duration = knockback_duration, 
						should_stun = 1, 
						knockback_distance = knockback_distance, 
						knockback_height = 200, 
						center_x = ability.target.x, 
						center_y = ability.target.y, 
						center_z = ability.target.z, 
						knockback_duration = knockback_duration
					})
				end

				-- Kills the missile, which triggers the OnMissileAttacked block
				ability.missile:SetModelScale(0.01)
				ability.missile:AddNewModifier(caster, nil, "modifier_invulnerable", {duration = 1})

				Timers:CreateTimer(0.1, function()
					ability.missile:ForceKill(false)
				end)
			else
				-- Turns the missile so it's facing the target
				ability.missile:SetForwardVector(Vector(direction.x/2, direction.y/2, -100))
				-- Calculates the time after launch so we can solve for the new speed (after acceleration)
				local move_duration = math.modf(ability.time_passed - pre_flight_time)
				speed = speed + acceleration * move_duration
				-- Moves the missile
				local vec = ability.missile:GetAbsOrigin() + direction * speed
				ability.missile:SetAbsOrigin(Vector(vec.x, vec.y, GetGroundHeight(ability.missile:GetAbsOrigin(), ability.missile) + 200))
				-- ))
			end
		end
	end
end

function rescale(value, min_old, max_old, min_new, max_new)
	local frac = (max_new - min_new) / (max_old - min_old)
	return frac * (value - max_old) + max_new
end

--[[Author: YOLOSPAGHETTI
	Date: March 28, 2016
	Keeps track of attacks on the missile and applies all death particles and sfx]]
function MissileAttacked(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local ability = keys.ability
	local target = ability.target
	local total_hits = ability:GetLevelSpecialValueFor( "hits_to_kill_tooltip", ability.level )
	
	if ability.missile:IsNull() then
		return
	end

	-- The missile attacks itself in ForceKill calls (so the missile is already dead if this runs)
	if attacker == ability.missile then
		ability.hits_to_kill = 0
	-- If the attacker is not a tower, we decrement a full hit, and give the missile the appropriate health bar
	else
		ability.hits_to_kill = ability.hits_to_kill - 1
		ability.missile:SetHealth(ability.missile:GetMaxHealth()*(ability.hits_to_kill/total_hits))
	end
	
	-- If the missile is out of hits, we kill it
	if ability.hits_to_kill <= 0 then
		ability.missile:ForceKill(false)
	end
	-- Checks if the missile is dead
	if ability.missile:IsAlive() == false then
		-- If the missile did not hit the target, we play the appropriate effects
		if ability.hit == false then
			local particle = ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN_FOLLOW, ability.missile) 
			ParticleManager:SetParticleControlEnt(particle, 1, ability.missile, PATTACH_POINT_FOLLOW, "attach_hitloc", ability.missile:GetAbsOrigin(), true)
		else
			EmitSoundOn(keys.sound3, ability.missile)
		end
		-- Removes the missile's model, so there is no death animation
		ability.missile:AddNoDraw()
		-- Stops both missile sounds
		StopSoundEvent(keys.sound, ability.missile)
		StopSoundEvent(keys.sound2, ability.missile)
		-- Plays the missile death sound
		EmitSoundOn(keys.sound4, ability.missile)
	end
end