function WillBreak(keys)
	local caster = keys.caster
	local target = keys.target

	local radius = keys.Radius
	local dpc = keys.DamagePerCreep

	local units = FindUnitsInRadius(target:GetOpposingTeamNumber(), target:GetAbsOrigin(), target, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, 0, false)

	local count = 0
	for k, v in pairs(units) do 
		count = count + 1 
	end

	print("dpc: " .. dpc)
	print("count: " .. count)
	print("damage: " .. tonumber(dpc)*count)

	local damageTable = 
	{
		victim = target,
		attacker = caster,
		damage = tonumber(dpc)*count,
		damage_type = DAMAGE_TYPE_MAGICAL
	}
	ApplyDamage(damageTable)
end