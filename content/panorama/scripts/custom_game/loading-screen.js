var SettingListener;
var IsHost = false;
var panels = [$("#DifficultyRow"), $("#MaxCreepPerTeamRow"), $("#MaxChargesPerCreepRow")];
var settings = ["DifficultyRow", "MaxCreepPerTeamRow", "MaxChargesPerCreepRow"];
var m_MenuMusic;

(function() 
{
	GameEvents.Subscribe("SetHost", SetHost);
	SettingListener = GameEvents.Subscribe("SetSettingFromServer", SetSettingFromServer);
	
	$.Schedule(7, function() { 
		m_MenuMusic = Game.EmitSound("HLW.MenuMusic"); 
		IsGameStarted();
	});
})();

function IsGameStarted()
{
	$.Schedule(1, function()
	{
		if(Game.GetState() == DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)
		{
			Game.StopSound(m_MenuMusic);
		}
		else
		{
			IsGameStarted();
		}
	})
}

function SetHost(keys)
{
	if(IsHost == true)
	{
		return;
	} 
	
//	$.Msg("Recieved Set Host.");
	IsHost = true;
	GameEvents.Unsubscribe(SettingListener);
	GameEvents.SendCustomGameEventToServer( "RecievedSetHost", { uselessVar: 42 });
	
	// Set defaults
	SetSetting(settings[0], 2);
	SetSetting(settings[1], 2);
	SetSetting(settings[2], 2);
}

function SetSettingFromServer(keys)
{
	ChangeSetting(panels[keys.panel - 1], keys.choice);
}

function SetSetting(setting, choice)
{
	// Only hosts can change settings
	if(!IsHost){return;}
	GameEvents.SendCustomGameEventToServer( "SetSetting", {setting: setting, value: choice});
	ChangeSetting($("#" + setting), choice);
}

function ChangeSetting(panel, choice)
{
	Game.EmitSound("HLW.Option");
	for (var i = 1; i <= panel.GetChildCount(); i++) 
	{
		var child = panel.GetChild(i - 1);
		if(i == choice)
		{
			child.AddClass("SettingBoxSelected");
		}
		else if(child.BHasClass("SettingBoxSelected"))
		{
			child.RemoveClass("SettingBoxSelected");
		}
	};
}