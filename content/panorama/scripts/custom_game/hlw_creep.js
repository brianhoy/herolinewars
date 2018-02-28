var m_CreepNumber;
var m_PlayerID;
var m_CreepCost;
var m_bIsTintedBlue;
var m_bIsTintedRed;
var m_Charges;

// Panels
var m_pnlCreepTint;
var m_pnlCreepCharges;
var m_pnlCreepCost;

function BuildCreepButton(imagePath, creepCharges, creepCost, creepNumber)
{
	m_CreepNumber = creepNumber + 1;
	$("#creepImage").SetImage(imagePath);
	m_CreepCost = creepCost;
	m_pnlCreepCost.text = creepCost;
	if(m_CreepNumber == 0) 
	{
		m_pnlCreepCharges.DeleteAsync(0);
		return;
	}
	m_pnlCreepCharges.text = creepCharges;
}

function UpdateCreepButton(playerGold, charges)
{
	if(m_CreepNumber != 0 && m_Charges != charges) 
	{
		m_Charges = charges;
		m_pnlCreepCharges.text = charges; 
	}
	if(playerGold < m_CreepCost) 
	{
		if(m_bIsTintedBlue) 
		{ 
			m_pnlCreepTint.RemoveClass("BlueTint");
			m_bIsTintedBlue = false;
		}
		if(!m_bIsTintedRed)
		{
			m_pnlCreepTint.AddClass("RedTint");
			m_bIsTintedRed = true;
		}
	}
	else if(charges == 0) 
	{
		if(!m_bIsTintedBlue)
		{
			m_pnlCreepTint.AddClass("BlueTint");
			m_bIsTintedBlue = true;
		}
	}
	else
	{
		if(m_bIsTintedRed) 
		{ 
			m_pnlCreepTint.RemoveClass("RedTint");
			m_bIsTintedRed = false;
		}
		if(m_bIsTintedBlue) 
		{ 
			m_pnlCreepTint.RemoveClass("BlueTint");
			m_bIsTintedBlue = false;
		}
	}
}

function BuyCreep()
{
	if(m_CreepNumber == 0)
	{
		GameEvents.SendCustomGameEventToServer( "OnPlayerUpgrade", {PlayerID: m_PlayerID});
		return;
	}
	GameEvents.SendCustomGameEventToServer( "OnPlayerBuyCreep", {PlayerID: m_PlayerID, CreepID: m_CreepNumber});		
}

function BuyAllCreeps()
{
	if(m_CreepNumber == 0)
	{
		GameEvents.SendCustomGameEventToServer( "OnPlayerUpgrade", {PlayerID: m_PlayerID});
		return;
	}
	GameEvents.SendCustomGameEventToServer( "OnPlayerBuyAllCreeps", {PlayerID: m_PlayerID, CreepID: m_CreepNumber});
}

(function() 
{
	m_pnlCreepCost = $("#creepCost");
	m_pnlCreepCharges = $("#creepCharges");
	m_pnlCreepTint = $("#creepTint");
	$.GetContextPanel().BuildCreepButton = BuildCreepButton;
	$.GetContextPanel().Update = UpdateCreepButton;
	m_PlayerID = Players.GetLocalPlayer();
})();
