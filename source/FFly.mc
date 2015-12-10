//!
//! Copyright 2015 by Garmin Ltd. or its subsidiaries.
//! Subject to Garmin SDK License Agreement and Wearables
//! Application Developer Agreement.
//!

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Sensor as Snsr;
using Toybox.Application as App;
using Toybox.Position as GPS;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Position as Position;
using Toybox.ActivityRecording as Record;
using Toybox.Attention as Attention;
using Toybox.Activity as Activity;


var session = null;
var log = "";

var vibrateLogStart = [
                    new Attention.VibeProfile(  25, 100 ),
                    new Attention.VibeProfile(  100, 100 )
                  ];
var vibrateLogEnd = [
                    new Attention.VibeProfile(  25, 100 ),
                    new Attention.VibeProfile(  25, 100 ),
                    new Attention.VibeProfile(  25, 100 )
                  ];
                      
// TODO
// - Waypoints
// 	- Navigate in waypoint list
// 	- Distance to point
// 	- Heading to point
//  - Vertical distance to point / glide to point
// - Auto detect hike mode
// - * Record HR
// - * Wall-clock Time, Flight/Hike duration, Temperature, HR
// - Total distance
// - * Vibration for session start

class BaseInputDelegate extends Ui.InputDelegate
{
    function stopRecording() {
        Attention.vibrate( vibrateLogEnd );
        
        session.stop();
        session.save();
        session = null;
        Ui.requestUpdate();
    }
    
    function startRecording() {
        Attention.vibrate( vibrateLogStart );
    
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
	var targetPosition;
	var targetAltitude;
	var distString = "--";
	var altitudeDiffString = "--";
	var statusIndex = 0;
	var activityStart;
	var currentTemperature;
	
    //! Constructor
    function initialize()
    {
        Snsr.setEnabledSensors([Snsr.SENSOR_TEMPERATURE, Snsr.SENSOR_HEARTRATE]);
        Snsr.enableSensorEvents( method(:onSnsr) );
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        
        altitude = new HistoryDisplay(10, 0, 100, Gfx.COLOR_DK_RED, Gfx.COLOR_WHITE);
        speed = new HistoryDisplay(0, 0, 10, Gfx.COLOR_DK_BLUE, Gfx.COLOR_WHITE);
        
        activityStart = Time.now();
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
    	
    	dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT );
    	dc.drawText(150, 80, Gfx.FONT_LARGE, distString, Gfx.TEXT_JUSTIFY_CENTER);
    	dc.drawText(60, 80, Gfx.FONT_LARGE, altitudeDiffString, Gfx.TEXT_JUSTIFY_CENTER);

		var status;
    	do {
			++statusIndex;
			statusIndex %= 60;
			status = statusString(statusIndex/10);
		} while (status == null);
    	dc.drawText(dc.getWidth()/2, dc.getHeight()-30, Gfx.FONT_SMALL, status, Gfx.TEXT_JUSTIFY_CENTER);
		
		
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
			if (targetAltitude == null) {
				targetAltitude = sensor_info.altitude;
			}
			altitudeDiffString = (targetAltitude - sensor_info.altitude).format("%d");
			currentTemperature = sensor_info.temperature;
		}
        Ui.requestUpdate();
    }    

	function statusString(idx) {
		var info = Activity.getActivityInfo();
		if (idx == 0) {
			var clockTime = Sys.getClockTime();			 
			return clockTime.hour.format("%02d") +":" + clockTime.min.format("%02d");
		} else if (idx == 1) {
			if (currentTemperature != null) {
				return currentTemperature.format("%d") + " `C";
			}
		} else if (idx == 2) {
			var hr = info.currentHeartRate;
			if (hr != null) {
				return hr.format("%d");
			}
		} else if (idx == 3) {
			if (info.elapsedTime != null) {
				var duration = info.elapsedTime / 1000;
				return (duration / 3600).format("%02d") +":"+((duration / 60)%60).format("%02d") + ":" + (duration %60).format("%02d");
			}
		} else if (idx == 4) {
			if (info.elapsedDistance != null) {
				return (info.elapsedDistance / 1000).format("%.1f") + "km";
			}
		} else if (idx == 5) {
			if (info.totalAscent != null) {
				return info.totalAscent.format("%d") + "m D+";
			}
		}
		return null;
	}
	    
    function calcDistance(pos1, pos2) {
    	var pos1A = pos1.toRadians();
    	var pos2A = pos2.toRadians();
    	var dlat = pos1A[0] - pos2A[0]; 
    	var dlon = pos1A[1] - pos2A[1];
    	return 6371*2*Math.asin(Math.sqrt(Math.pow(Math.sin(dlat/2),2)+Math.cos(pos1A[1])*Math.cos(pos2A[1])*Math.pow(Math.sin(dlon/2),2)));
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
			if (targetPosition == null) {
				targetPosition = info.position;
			}
			distString = calcDistance(targetPosition, info.position).format("%.2f");
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
