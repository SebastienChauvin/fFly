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
using Toybox.Position as Position;
using Toybox.ActivityRecording as Record;


var session = null;
var log = "";

class BaseInputDelegate extends Ui.InputDelegate
{
    function stopRecording() {
        session.stop();
        session.save();
        session = null;
        Ui.requestUpdate();
    }
    
    function startRecording() {
        session = Record.createSession({:name=>"FFly", :sport=>Record.SPORT_GENERIC});
        session.start();
        Ui.requestUpdate();
	}
	
    function onKey(key) {
        if(key.getKey() == Ui.KEY_ENTER) {
    		toggleRecording();	
        }
        else {
    	    Sys.println(key.getKey().toString());
    	}    	
    }
    
    function toggleRecording() {
        if( Toybox has :ActivityRecording ) {
            if( ( session == null ) || ( session.isRecording() == false ) ) {
            	startRecording();
            }
            else if( ( session != null ) && session.isRecording() ) {
            	stopRecording();
            }
        }
    }
}

class AltSpeed extends Ui.View
{
    var altitude;
	var speed;
	var heading = Math.PI;
	var glideRatioString = "--";
	
    //! Constructor
    function initialize()
    {
        Snsr.enableSensorEvents( method(:onSnsr) );
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        
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
    	
    	if (session != null) {
    		dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW);
    		dc.fillRectangle(dc.getWidth()/2 - 10, 0, 20, 20);
    	}
    	
    	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
    	dc.drawText(150, 130, Gfx.FONT_LARGE, glideRatioString, Gfx.TEXT_JUSTIFY_CENTER);

    	dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
		drawHand(dc, -heading, 20, 30);
    }

    function drawHand(dc, angle, length, width)
    {
    	var radius = dc.getWidth() / 2;
        // Map out the coordinates of the watch hand
        var coords = [ [-(width/2), length - radius], [-(width/2), -radius], [width/2, -radius], [width/2, length - radius] ];
        var result = new [4];
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ centerX+x, centerY+y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
        dc.fillPolygon(result);
    }
    
    function onSnsr(sensor_info)
    {
		if (sensor_info.altitude != null) {
			altitude.addItem(sensor_info.altitude);
			heading = sensor_info.heading;
		}
        Ui.requestUpdate();
    }
    
    
    function onPosition(info) {
    	if (info.speed != null) {
			speed.addItem(info.speed * 3600 / 1000);
			var altVario = altitude.getVarioValue();
			if (altVario == 0) {
				glideRatioString = "oo";
			} else {
				glideRatioString = (-info.speed / altVario).format("%.1f");
			}
//            heading = info.heading;
        }
        
        Ui.requestUpdate();
    }
    
    function onHide() {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function onShow() {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
		Snsr.enableSensorEvents( method(:onSnsr) );
    }
}

//! main is the primary start point for a Monkeybrains application
class FFly extends App.AppBase
{
	var inputDelegate;
	
    function onStart()
    {
        return false;
    }

    function getInitialView()
    {
    	inputDelegate = new BaseInputDelegate();
        return [new AltSpeed(), inputDelegate];
    }

    function onStop()
    {
        inputDelegate.stopRecording();
        return false;
    }
}
