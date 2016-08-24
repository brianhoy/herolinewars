function DoAbilityHealthCost(keys)
    local caster = keys.caster
    local ability = keys.ability
    local health_cost = ability:GetSpecialValueFor("buff_health_cost")

	Timers:CreateTimer(0.1, function()
			local max_health = caster:GetMaxHealth()
			local health = caster:GetHealth()
			local total_tics = 60
			local desired_health = max_health * (1 - (health_cost/100))
			local interval = (caster:GetHealth() - desired_health) / total_tics
			local current_tic = 1

			Timers:CreateTimer(function()
					caster:ModifyHealth(caster:GetHealth() - interval, ability, false, 0)
					if current_tic >= total_tics then
						return
					end
					current_tic = current_tic + 1
					return 0.003
				end
			)
		end
	)
end

--[[
    Author: Bude
    Date: 30.09.2015
    Removes HP for using Burning Spear
    This is called everytime the ability is used (manual left-click or via auto-cast right-click)
]]
function DoHealthCost( keys )
    -- Variables
    local caster = keys.caster
    local ability = keys.ability
    local health_cost = ability:GetLevelSpecialValueFor( "spear_health_cost" , ability:GetLevel() - 1  )
    local health = caster:GetHealth()
    local new_health = (health - health_cost)

    -- "do damage"
    -- aka set the casters HP to the new value
    -- ModifyHealth's third parameter lets us decide if the healthcost should be lethal
    caster:ModifyHealth(new_health, ability, false, 0)
end

--[[
    Author: Bude
    Date: 30.09.2015
    Increases stack count on the visual modifier
    This is called everytime an enemy is hit by burning_spear
]]
function IncreaseStackCount( keys )
    -- Variables
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local modifier_name = keys.modifier_counter_name
    local dur = ability:GetSpecialValueFor("spear_duration")

    local modifier = target:FindModifierByName(modifier_name)
    local count = target:GetModifierStackCount(modifier_name, caster)

    -- if the unit does not already have the counter modifier we apply it with a stackcount of 1
    -- else we increase the stack and refresh the counters duration
    if not modifier then
        ability:ApplyDataDrivenModifier(caster, target, modifier_name, {duration=dur})
        target:SetModifierStackCount(modifier_name, caster, 1) 
    else
        target:SetModifierStackCount(modifier_name, caster, count+1)
        modifier:SetDuration(dur, true)
    end
end

--[[
    Author: Bude
    Date: 30.09.2015
    Decreases stack count on the visual modifier 
    This is called whenever the debuff modifier runs out
]]
function DecreaseStackCount(keys)
    --Variables
    local caster = keys.caster
    local target = keys.target
    local modifier_name = keys.modifier_counter_name
    local modifier = target:FindModifierByName(modifier_name)
    local count = target:GetModifierStackCount(modifier_name, caster)

    -- just some saftey checks -just in case
    if modifier then

        -- if there is something to reduce reduce
        -- else just remove the modifier
        if count and count > 1 then
            target:SetModifierStackCount(modifier_name, caster, count-1)
        else
            target:RemoveModifierByName(modifier_name)
        end
    end
end
