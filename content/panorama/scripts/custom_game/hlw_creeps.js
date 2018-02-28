"use strict";

var m_CreepPanels = [];
var m_PlayerID = Players.GetLocalPlayer();
var m_UpgradePanel;
var m_Level;
var Hud = $.GetContextPanel().GetParent().GetParent().GetParent();

function UpdateButtonStatuses(data)
{
    var PlayerGold = data.PlayerGold;
    var PlayerCharges = data.PlayerCharges;

	if(m_Level == 3)
	{
		for(var i = 1; i <= 10; i++)
		{
			m_CreepPanels[i - 1].Update(PlayerGold, PlayerCharges[i]);
		}
	}
	else
	{
		for(var i = 0; i <= 10; i++)
		{
			m_CreepPanels[i].Update(PlayerGold, PlayerCharges[i]);
		}
	}
}

function SetButtonConfig(data)
{
	var playeraa = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer( "OnRecievedCreepPanorama", { PlayerID: playeraa });

	m_UpgradePanel = null;
    m_Level = data.level;
    var CreepCosts = data.CreepCosts;
	var CreepCharges = data.CreepCharges
    var CreepImagePaths = data.CreepImagePaths;

    var i = 0;
    var contextPanel = $.GetContextPanel();
	var childCount = contextPanel.GetChildCount();
	var length = m_CreepPanels.length

	for(var j = 0; j < length; j++)
	{
		var panel = m_CreepPanels.pop();
		panel.RemoveAndDeleteChildren();
		panel.DeleteAsync(0);
	}

	if(m_Level == 3)
	{
		i = 1;
	}

    for(i; i <= 10; i++)
    {
		var panel = $.CreatePanel("Panel", contextPanel, "creep_" + i);
		panel.BLoadLayout("file://{resources}/layout/custom_game/hlw_creep.xml", false, false);
		m_CreepPanels.push(panel);
		panel.BuildCreepButton(CreepImagePaths[i], CreepCharges, CreepCosts[i], i - 1);
		if(i == 0)
		{
			m_UpgradePanel = panel;
			continue;
		}
		if(m_UpgradePanel != null)
		{
			contextPanel.MoveChildBefore(panel, m_UpgradePanel);
		}
    }
	if(m_UpgradePanel != null)
	{
		contextPanel.MoveChildAfter($("#base_panel_changeside"), m_UpgradePanel);	
	}
	else
	{
		$.Schedule(0.1, function()
			{
				contextPanel.MoveChildAfter($("#base_panel_changeside"), $("#creep_10"));	
			});
	}
}

// Listen to game events
(function () {
    GameEvents.Subscribe( "UpdateButtonStatuses", UpdateButtonStatuses);
    GameEvents.Subscribe( "SetButtonConfig", SetButtonConfig);

	$.GetContextPanel().SetParent(Hud);
	m_PlayerID = Players.GetLocalPlayer();
})();

var flowdown = false;

function SwitchButtonSide()
{
    if(flowdown == false)
    { 
        flowdown = true;
		var panel = $.GetContextPanel();
		if(panel.BHasClass("ButtonRowHorizontal") == true)
		{
			panel.RemoveClass("ButtonRowHorizontal");
		}
        panel.AddClass("ButtonRowVertical");
        $("#base_panel_changeside_image").SetImage("file://{images}/custom_game/hlw_creeps/switch2.png");
    }
    else
    {
        flowdown = false;
		var panel = $.GetContextPanel();
		if(panel.BHasClass("ButtonRowVertical") == true)
		{
			panel.RemoveClass("ButtonRowVertical");
		}
		panel.AddClass("ButtonRowHorizontal");
        $("#base_panel_changeside_image").SetImage("file://{images}/custom_game/hlw_creeps/switch.png");
    }
}