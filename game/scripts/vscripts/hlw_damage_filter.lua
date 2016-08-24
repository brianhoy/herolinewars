function GameMode:DamageFilter(filterTable)
    local victim_index = filterTable["entindex_victim_const"]
    local attacker_index = filterTable["entindex_attacker_const"]
    if not victim_index or not attacker_index then
        return true
    end

	local victim = EntIndexToHScript( victim_index )
    local attacker = EntIndexToHScript( attacker_index )
    local damagetype = filterTable["damagetype_const"]
    local inflictor = filterTable["entindex_inflictor_const"]

	if inflictor and attacker:IsHero() then
		-- For every 2 intellect, the damage is amplified by an extra percent
		local amp = (attacker:GetIntellect()/2)/100

        filterTable["damage"] = filterTable["damage"] * (1 + amp)
    end

	return true
end