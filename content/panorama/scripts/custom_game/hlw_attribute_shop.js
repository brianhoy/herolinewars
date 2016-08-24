var m_AttributeCosts = [100, 100, 100];
var ATTRIBUTES = ["strength", "agility", "intelligence"];

function BuyAttribute(attribute_)
{
	GameEvents.SendCustomGameEventToServer( 
		"OnPlayerBuyAttribute", {PlayerID: Players.GetLocalPlayer(), Attribute: attribute_});
}

function BuyAllAttributes(attribute_)
{
	GameEvents.SendCustomGameEventToServer( 
		"OnPlayerBuyAllAttributes", {PlayerID: Players.GetLocalPlayer(), Attribute: attribute_});
}

(function() 
{
	m_PlayerID = Players.GetLocalPlayer();
	CustomNetTables.SubscribeNetTableListener("attributecost", OnTableChanged);
	UpdateTint();
})();

function UpdateTint()
{
	for(var i = 0; i <= 2; i++)
	{
		var cost = m_AttributeCosts[i];
		var panel = $("#" + ATTRIBUTES[i] + "AttributeTint");
		var gold = Players.GetGold(m_PlayerID);
		if(gold < cost)
		{
			if(!panel.BHasClass("RedTint"))
			{
				panel.AddClass("RedTint");
			}
		}
		else
		{
			if(panel.BHasClass("RedTint"))
			{
				panel.RemoveClass("RedTint");
			}
		}
	}
	$.Schedule(0.5, UpdateTint);
}

function OnTableChanged(table_name, key, data)
{	
	if(table_name != "attributecost")
	{
		return;
	}
	
	if(parseInt(key) != m_PlayerID)
	{
		return;
	}
	
	for(var i = 0; i <= 2; i++)
	{
		var cost = parseInt(data[ATTRIBUTES[i]]);
		$("#" + ATTRIBUTES[i] + "AttributeCost").text = cost;
		m_AttributeCosts[i] = cost;
	}
}