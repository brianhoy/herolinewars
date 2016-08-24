AI_THINK_INTERVAL = 0.25
AI_STATE_IDLE = 0
AI_STATE_AGGRESSIVE = 1

NeutralAI = {}
NeutralAI.__index = NeutralAI

-- NOT USED - CREATES TOO MUCH LAG

function NeutralAI:Start( unit, params )
	local ai = {}
	setmetatable( ai, NeutralAI )

	print("neutralAI created")

	unit.ai = ai
	ai.unit = unit 
	ai.state = AI_STATE_IDLE
	ai.stateThinks = {
		[AI_STATE_IDLE] = 'IdleThink',
		[AI_STATE_AGGRESSIVE] = 'AggressiveThink',
		[AI_STATE_FORCE_MOVE_TO_POINT] = 'MoveToPointThink'
	}

	ai.spawnPos = params.spawnPos
	ai.aggroRange = params.aggroRange
	ai.leashRange = params.leashRange
	ai.waypoints = params.waypoints
	ai.curWpLoc = nil
	ai.curWpIndx = nil
	ai.nextWpLoc = nil
	ai:MoveToWaypoint()
	ai.team = unit:GetTeamNumber()
	ai.forcedWaypoint = nil

	Timers:CreateTimer(function()
		return ai:GlobalThink()
	end)

	return ai
end

function NeutralAI:GlobalThink()
	local unit = self.unit
	
	if not IsValidEntity(unit) then
		self = nil
		return nil
	end

	if not unit:IsAlive() then
		return nil
	end

	if self.team ~= unit:GetTeamNumber() then
		return nil
	end



	Dynamic_Wrap(NeutralAI, self.stateThinks[ self.state ])( self )

	return AI_THINK_INTERVAL
end

function NeutralAI:IdleThink()
	local unit = self.unit

	local units = FindUnitsInRadius( unit:GetTeam(), unit:GetAbsOrigin(), nil,
		self.aggroRange, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, 
		FIND_CLOSEST, false )

	local attackableUnit = false

	for _, unit_ in pairs(units) do
		if unit_:HasModifier("modifier_disarmed") == false then
			units[1] = unit_
			attackableUnit = true
			break
		end
	end

	if #units > 0 and attackableUnit == true then
		unit:MoveToTargetToAttack( units[1] )
		self.aggroTarget = units[1]
		self.state = AI_STATE_AGGRESSIVE 
		return true
	end
	
	self:MoveToWaypoint()
end

function NeutralAI:AggressiveThink()
	local unit = self.unit
	local length = ( self.aggroTarget:GetAbsOrigin() - unit:GetAbsOrigin() ):Length2D()

	if length > self.leashRange then
		self:MoveToWaypoint()
		self.state = AI_STATE_IDLE 
		return true 
	end

	if not self.aggroTarget:IsAlive() then
		self:MoveToWaypoint()
		self.state = AI_STATE_IDLE 
		return true 
	end
end

function NeutralAI:MoveToPointThink()
	local order = {
 		UnitIndex = self.unit:entindex(), 
 		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
 		Position = self.forcedWaypoint, 
 		Queue = false
	}
	ExecuteOrderFromTable(order)
end

function NeutralAI:MoveToPoint(duration, point)
	self.state = AI_STATE_FORCE_MOVE_TO_POINT
	ai.forcedWaypoint = point
	self:MoveToPointThink()
	Timers:CreateTimer(duration, function()
		self.state = AI_STATE_IDLE
		self:MoveToWaypoint()
	end)
end

function NeutralAI:MoveToWaypoint()
	local bIsLastWaypoint = false

	if self.curWpLoc == nil then
		self.curWpLoc = self.waypoints[1]:GetAbsOrigin()
		self.nextWpLoc = self.waypoints[2]:GetAbsOrigin()
		self.curWpIndx = 1
	end

	--DebugDrawSphere(self.curWpLoc, Vector(0, 255, 0), 255, 20, false, 0.5)
	--DebugDrawSphere(self.nextWpLoc, Vector(255, 0, 0), 255, 20, false, 0.5)

	if (self.unit:GetAbsOrigin() - self.curWpLoc):Length2D() < 100 then
		if self.waypoints[self.curWpIndx + 1] ~= nil then
			self.curWpIndx = self.curWpIndx + 1
			self.curWpLoc = self.waypoints[self.curWpIndx]:GetAbsOrigin()
			if self.waypoints[self.curWpIndx + 1] ~= nil then
				self.nextWpLoc = self.waypoints[self.curWpIndx + 1]:GetAbsOrigin()
			else
				bIsLastWaypoint = true
				self.nextWpLoc = self.curWpLoc
			end
		end
	end

	local order = {
 		UnitIndex = self.unit:entindex(), 
 		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
 		Position = self.curWpLoc, 
 		Queue = false
	}
	ExecuteOrderFromTable(order)

	if bIsLastWaypoint == false then
		local order2 = {
	 		UnitIndex = self.unit:entindex(), 
	 		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
	 		Position = self.nextWpLoc, 
	 		Queue = true
		}
		ExecuteOrderFromTable(order2)
	end
end