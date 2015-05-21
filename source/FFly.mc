//!
//! Copyright 2015 by Garmin Ltd. or its subsidiaries.
//! Subject to Garmin SDK License Agreement and Wearables
//! Application Developer Agreement.
//!

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Sensor as Snsr;
using Toybox.Application as App;
using Toybox.Position as GPS;
using Toybox.Math as Math;
using Toybox.Time as Time;

class AltSpeed extends Ui.View
{
    var history_size = 30;
    var altitude_string = "no alt";
    var vario_string = "no vario";
    var altitude_graph;
	var altitude_value_history = new [history_size];
	var altitude_time_history = new [history_size];
	var history_pointer = 0;
	
    //! Constructor
    function initialize()
    {
        Snsr.enableSensorEvents( method(:onSnsr) );
        
        altitude_graph = new LineGraph( 20, 100, Gfx.COLOR_RED );
    }

    //! Handle the update event
    function onUpdate(dc)
    {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );

        dc.drawText( 100, 30, Gfx.FONT_LARGE, altitude_string, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText( 100, 130, Gfx.FONT_LARGE, vario_string, Gfx.TEXT_JUSTIFY_CENTER);

        altitude_graph.draw( dc, [0,0], [dc.getWidth(),dc.getHeight()] );
    }

    function onSnsr(sensor_info)
    {
		if (sensor_info.altitude != null) {    	
        	computeString(sensor_info.altitude);
        	altitude_graph.addItem(sensor_info.altitude);
        }
        
        Ui.requestUpdate();
    }
    
    function computeString(altitude)
    {
        altitude_string = altitude.format("%d");
        
        history_pointer++;
        history_pointer %= history_size;

        var now = Time.now();
        if (altitude_time_history[history_pointer] != null) {
	        var updatePeriod = now.subtract(altitude_time_history[history_pointer]).value().toFloat();
	        var altitude_difference = altitude - altitude_value_history[history_pointer];
	        altitude_value_history[history_pointer] = altitude;
	        
	        vario_string = (altitude_difference / updatePeriod).format("%.2f");
        } else {
			for(var i = 0; i < history_size; i++) {
				altitude_value_history[i] = altitude;
				altitude_time_history[i] = now;
			}
		}
        altitude_time_history[history_pointer] = now;
    }
}

//! main is the primary start point for a Monkeybrains application
class FFly extends App.AppBase
{
    function onStart()
    {
        return false;
    }

    function getInitialView()
    {
        return [new AltSpeed()];
    }

    function onStop()
    {
        return false;
    }
}
