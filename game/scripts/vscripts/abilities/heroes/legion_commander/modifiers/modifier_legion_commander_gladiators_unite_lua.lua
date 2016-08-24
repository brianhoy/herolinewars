print("gladiator buff modifier loaded")

modifier_legion_commander_gladiators_unite_lua = class({})

function modifier_legion_commander_gladiators_unite_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
 
	return funcs
end

function modifier_legion_commander_gladiators_unite_lua:OnAttackLanded( params )
	if not IsServer() then return 0 end

	if params.attacker == self:GetParent() and ( not self:GetParent():IsIllusion() ) then
		if self:GetParent():PassivesDisabled() then
			return 0
		end

		local target = params.target
		-- If you're actually hitting an enemy creep or hero...
		if target ~= nil and (target:IsCreep() or target:IsHero()) and target:GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
			local new_health = self:GetParent():GetHealth() + (params.damage * (self.lifesteal_per_hero * self.number_of_heroes_in_ring))
			self:GetParent():ModifyHealth(new_health, nil, false, 0)
		end
	end
 
	return 0
end

function modifier_legion_commander_gladiators_unite_lua:OnCreated(keys)
	if not IsServer() then return end

	self:StartIntervalThink(0.1)

	print("Ability name: ", self:GetAbility():GetAbilityName())

	self.bonus_armor_per_hero = self:GetAbility():GetSpecialValueFor("bonus_armor_per_hero") or 1
	self.bonus_damage_per_hero = self:GetAbility():GetSpecialValueFor("bonus_damage_per_hero") or 1
	self.bonus_evasion = self:GetAbility():GetSpecialValueFor("bonus_evasion") or 1
	self.lifesteal_per_hero = self:GetAbility():GetSpecialValueFor("lifesteal_per_hero") or 1

	self.number_of_heroes_in_ring = 1
end

function modifier_legion_commander_gladiators_unite_lua:GetModifierPreAttack_BonusDamage( params )
	local table = CustomNetTables:GetTableValue("gladiatorduelmodifiers", tostring(self:GetParent():entindex()))
	if table then return table.bonus_damage or 1 end
	return 1
end

function modifier_legion_commander_gladiators_unite_lua:GetModifierPhysicalArmorBonus( params )
	local table = CustomNetTables:GetTableValue("gladiatorduelmodifiers", tostring(self:GetParent():entindex()))
	if table then return table.bonus_armor or 1 end
	return 1
end

function modifier_legion_commander_gladiators_unite_lua:GetModifierEvasion_Constant( params )
	return self.bonus_evasion
end

function modifier_legion_commander_gladiators_unite_lua:OnIntervalThink()
	if not IsServer() then return end

	local hero_count = 0

	local table = self:GetAbility().heroes_in_ring or {}

	for _, hero in pairs(table) do
		hero_count = hero_count + 1
	end

	-- update nettable
	CustomNetTables:SetTableValue("gladiatorduelmodifiers", tostring(self:GetParent():entindex()), {
		bonus_armor = self.bonus_armor_per_hero * self.number_of_heroes_in_ring,
		bonus_damage = self.bonus_damage_per_hero * self.number_of_heroes_in_ring,
		hero_count = hero_count
	})

	self:SetStackCount(hero_count)

	self.number_of_heroes_in_ring = hero_count or 1
end
