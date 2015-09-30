function StartTeleport(keys)
	if not HLWTP_mostRecentTP then
		HLWTP_mostRecentTP = {}
	end
	local caster = keys.caster
	local target = keys.target_points[1]
	local sound = keys.Sound
	local particleName1 = "particles/econ/events/pw_compendium_2014/teleport_end_pw2014.vpcf"

	local particle1 = ParticleManager:CreateParticle(particleName1, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle1, 0, target)

	caster.tpDummyUnit = CreateUnitByName("npc_dummy_unit", target, false, caster, caster, DOTA_TEAM_NEUTRALS)
	caster.tpDummyUnit:AddNewModifier(caster.tpDummyUnit, nil, "modifier_invisible", {duration=-1})
	caster.tpDummyUnit:AddNewModifier(caster.tpDummyUnit, nil, "modifier_phased", {duration=-1})
	caster.tpDummyUnit:AddNewModifier(caster.tpDummyUnit, nil, "modifier_invulnerable", {duration=-1})

	caster.HLWTP_mostRecentTP = particle1
	caster.HLWTP_mostRecentTPLoc = target

	StartSoundEvent(sound, caster)
	StartSoundEvent(sound, caster.tpDummyUnit)
end

function StopSound(keys)
	local item = keys.ability
	local charges = item:GetCurrentCharges()
	local caster = keys.caster
	local sound = keys.Sound
	local particle1 = caster.HLWTP_mostRecentTP
	ParticleManager:DestroyParticle(particle1, true)

	if charges > 1 then
		item:SetCurrentCharges(charges - 1)
	else
		item:RemoveSelf()
	end

	StopSoundEvent(sound, caster)
	StopSoundEvent(sound, caster.tpDummyUnit)

	caster.tpDummyUnit:RemoveSelf()

	
end

function FinishTeleport(keys)
	local caster = keys.caster
	local targetLoc = caster.HLWTP_mostRecentTPLoc
	local casterLoc = caster:GetAbsOrigin()	

	local soundNameDisappear = keys.SoundLeave
	local soundNameAppear = keys.SoundAppear

	StartSoundEventFromPosition(soundNameDisappear, casterLoc)
	StartSoundEventFromPosition(soundNameAppear, targetLoc)

	FindClearSpaceForUnit(caster, targetLoc, true)
end