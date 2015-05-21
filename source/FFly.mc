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
    var altitude;
	var speed;
	
    //! Constructor
    function initialize()
    {
        Snsr.enableSensorEvents( method(:onSnsr) );
        
        altitude = new HistoryDisplay(10, 100, 100, Gfx.COLOR_RED);
        speed = new HistoryDisplay(0, 100, 10, Gfx.COLOR_BLUE);
    }

    //! Handle the update event
    function onUpdate(dc)
    {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        
    	altitude.draw(dc, 60, 30, 50, 130);
    	speed.draw(dc, 150, 30, -1, -1);
    }

    function onSnsr(sensor_info)
    {
		if (sensor_info.altitude != null) {
			altitude.addItem(sensor_info.altitude);
			speed.addItem(sensor_info.speed * 3600 / 1000);    	
        }
        
        Ui.requestUpdate();
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
