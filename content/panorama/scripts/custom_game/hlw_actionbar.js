/*
    This is a snippet of code found in Valve's RPG example. I thought about using it but I'd have to fix the map a bit

var g_yaw = 0;
var g_targetYaw = 0;
(function smoothCameraYaw()
{
	$.Schedule( 1.0/60.0, smoothCameraYaw );
	while ( g_targetYaw > 360 && g_yaw > 360 )
	{
		g_targetYaw -= 360;
		g_yaw -= 360;
	}
	while ( g_targetYaw < 0 && g_yaw < 0 )
	{
		g_targetYaw += 360;
		g_yaw += 360;
	}

	var minStep = 1;
	var delta = ( g_targetYaw - g_yaw );
	if ( Math.abs( delta ) < minStep )
	{
		g_yaw = g_targetYaw;
	}
	else
	{
		var step = delta * 0.3;
		if ( Math.abs( step ) < minStep )
		{
			if ( delta > 0 )
				step = minStep;
			else
				step = -minStep;
		}
		g_yaw += step;
	}
	GameUI.SetCameraYaw( g_yaw );
	return;
})();


// Main mouse event callback
GameUI.SetMouseCallback( 
    function( eventName, arg ) 
    {
        var nMouseButton = arg
        var CONSUME_EVENT = true;
        var CONTINUE_PROCESSING_EVENT = false;
        if ( GameUI.GetClickBehaviors() !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE )
            return CONTINUE_PROCESSING_EVENT;

        if ( eventName === "pressed" )
        {
            // Middle-click is reset yaw.
            if ( arg === 2 )
            {
                g_targetYaw = 0;
                g_yaw = g_targetYaw;
                return CONSUME_EVENT;
            }
        }

        if ( eventName === "wheeled" )
        {
            g_targetYaw += arg * 10;
            return CONSUME_EVENT;
        }

        return CONTINUE_PROCESSING_EVENT;
    } 
);

GameUI.SetCameraPitchMax( 55 );
*/