"use strict";

var Collapsed = false;
var Hud = $.GetContextPanel().GetParent().GetParent().GetParent();

function Collapse()
{
	if(Collapsed == true)
	{
		Collapsed = false;
		$("#CollapseLabel").text = "Collapse";
		$("#IncomesHighestParent").RemoveClass("TranslateUpPermenant");
		$("#IncomesHighestParent").AddClass("TranslateDown");
		$.Schedule(0.1, function()
        {
			$("#IncomesHighestParent").RemoveClass("TranslateDown");
        }); 
	}
	else
	{
		Collapsed = true;
		$("#CollapseLabel").text = "Expand";
		$("#IncomesHighestParent").AddClass("TranslateUp");
		$.Schedule(0.1, function()
        {
			$("#IncomesHighestParent").RemoveClass("TranslateUp");
            $("#IncomesHighestParent").AddClass("TranslateUpPermenant");
        }); 
	}	
}

function OnTableChanged(table_name, key, data)
{
//	$.Msg(CustomNetTables.GetAllTableValues("income"));
	if(table_name != "income")
	{
		return;
	}
	var panel = $("#Player_" + key + "_" + "Gold");
	
//	$.Msg("panel = " + panel)
	
	if(panel === null)
	{
		AddPlayer({PlayerID: parseInt(key)});
		panel = $("#Player_" + key + "_" + "Gold");
	}
	panel.text = (Math.round(data.gold * 100) / 100);
}

function contains(a, obj) {
    for (var i = 0; i < a.length; i++) {
        if (a[i] === obj) {
            return true;
        }
    }
    return false;
}

function AddPlayer(data)
{
    var playerID = parseInt(data.PlayerID);

	var teamNumb = 3;
	if(contains(Game.GetPlayerIDsOnTeam(2), playerID))
	{
		teamNumb = 2;
	}
	
	var steamName = Players.GetPlayerName(playerID);
	var ParentPanel = $("#Team_" + teamNumb.toString() + "_Players");
	var PlayerPanel = $.CreatePanel("Label", ParentPanel, "Player_" + playerID);
	var PlayerName = $.CreatePanel("Label", PlayerPanel, "Player_" + playerID + "_Name");
	var PlayerGold = $.CreatePanel("Label", PlayerPanel, "Player_" + playerID + "_Gold");
	
	PlayerPanel.hittest = false;
	PlayerName.hittest = false;
	PlayerGold.hittest = false;
	PlayerName.text = steamName;
	PlayerPanel.AddClass("Player", true);
	PlayerName.AddClass("PlayerName", true);
	PlayerGold.AddClass("PlayerGold", true);
}

var hasAnimClass = false;

function StartIncomeBar(keys)
{
    if(hasAnimClass == true)
    {
        // This restarts the animation
        $("#GoldBar").ToggleClass("GoldBarAnimation");
        $("#GoldBar").ToggleClass("GoldBarAnimation");
    }
    else
    {
        hasAnimClass = true;
        $("#GoldBar").AddClass("GoldBarAnimation");
    }
}

(function () {
    GameEvents.Subscribe( "StartIncomeBar", StartIncomeBar);
	CustomNetTables.SubscribeNetTableListener("income", OnTableChanged);

	$.GetContextPanel().SetParent(Hud);

	// Update all nettable values
	$.Schedule(5, ReadAllNettableValues);
})();

function ReadAllNettableValues()
{
	var NettableValues = CustomNetTables.GetAllTableValues("income");
	for (var prop in NettableValues) 
	{
		if (!NettableValues.hasOwnProperty(prop)) 
		{
			continue;
		}
		OnTableChanged("income", prop, NettableValues[prop]["value"]);
	}	
}