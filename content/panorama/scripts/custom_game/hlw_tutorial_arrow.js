var m_pnlArrow;
var m_timeID;

(function() 
{
	GameEvents.Subscribe("ShowArrow", ShowArrow);
	m_pnlArrow = $("#Arrow");
})();

function ShowArrow(keys)
{
	var duration = keys.duration;
	m_timeID = Game.GetGameTime();
	var localTimeID = m_timeID;
	if(m_pnlArrow.BHasClass("Hide"))
	{
		m_pnlArrow.RemoveClass("Hide");
	}
	$.Schedule(duration, function()
	{
		if(localTimeID == m_timeID)
		{
			if(!m_pnlArrow.BHasClass("Hide"))
			{
				m_pnlArrow.AddClass("Hide");
			}
		}
	}); 
}