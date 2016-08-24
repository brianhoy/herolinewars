function CreateX(keys)
	local caster = keys.caster
	local target = keys.target_points[1]
	local ability = keys.ability

	local particle_name = keys.particle
	local duration = ability:GetSpecialValueFor("duration")
	local radius = ability:GetSpecialValueFor("radius")

	local particle_id = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle_id, 0, target)

	local units = FindUnitsInRadius(ability:GetTeamNumber(), target, nil, radius, ability:GetAbilityTargetTeam(), 
		ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), 0, false)

	for _, unit in pairs(units) do
		-- Disallow the unit to do commands
		unit:AddNewModifier(caster, ability, "modifier_kunkka_x_marks_the_spot_forcemove_debuff", {duration=duration})
		-- Make the unit go toward the target point then stop
		local order = {
			UnitIndex = unit:entindex(), 
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = target, 
			Queue = false
		}
		local stopOrder = {
			UnitIndex = unit:entindex(), 
			OrderType = DOTA_UNIT_ORDER_HOLD_POSITION,
			Queue = true
		}
		ExecuteOrderFromTable(order)
		ExecuteOrderFromTable(stopOrder)
	end

	-- Find the nearest waypoint entity index
	local team = caster:GetTeamNumber()
	local team_waypoints = GameMode.WaypointEnts[team]
	local nearest_waypoint_side
	local nearest_waypoint_index
	local nearest_waypoint_distance = 99999
	for side = 1, 2 do
		for index, waypoint in pairs(team_waypoints[side]) do
			local current_waypoint_distance = (waypoint:GetAbsOrigin() - target):Length2D()
			if current_waypoint_distance < nearest_waypoint_distance then
				nearest_waypoint_distance = current_waypoint_distance
				nearest_waypoint_index = index
				nearest_waypoint_side = side
			end
		end
	end

	Timers:CreateTimer(duration, function()
			-- Remove the particle
			ParticleManager:DestroyParticle(particle_id, false)

			-- Set the unit back on the path toward the ancient
			for _, unit in pairs(units) do
				GameMode:RequeueWaypoints(unit, GameMode.WaypointEnts, team, nearest_waypoint_side, nearest_waypoint_index)
			end
		end
	)
end

