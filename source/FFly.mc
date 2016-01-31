//!
//! Copyright 2015 by Garmin Ltd. or its subsidiaries.
//! Subject to Garmin SDK License Agreement and Wearables
//! Application Developer Agreement.
//!

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Position as GPS;
using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Position as Position;
using Toybox.Activity as Activity;


var log = "";
                      
// TODO
// - Waypoints
// 	- Navigate in waypoint list
// 	- Distance to point
// 	- Heading to point
//  - Vertical distance to point / glide to point
// - Auto detect hike mode
// - * Record HR
// - * Wall-clock Time, Flight/Hike duration, Temperature, HR
// - * Total distance
// - * Vibration for session start

class AltSpeed extends Ui.DataField
{
    var altitude;
	var speed;
	var heading = Math.PI;
	var glideRatioString = "--";
	var targetPosition;
	var targetAltitude;
	var bearing2Pt;
	var glide2PtString = "--";
	var dist2PtString = "--";
	var altitude2PtString = "--";
	var statusIndex = 0;
	var activityStart;
	var currentTemperature;
	var helpCounter;
	
    //! Constructor
    function initialize()
    {
        altitude = new HistoryDisplay(10, 0, 0, Gfx.COLOR_DK_RED, Gfx.COLOR_WHITE);
        speed = new HistoryDisplay(0, 0, 0, Gfx.COLOR_DK_BLUE, Gfx.COLOR_WHITE);
        
        activityStart = Time.now();
        showHelp();
    }

	function showHelp() {
		helpCounter = 2;
	}
	
    //! Handle the update event
    function onUpdate(dc)
    {
    	if (helpCounter > 0) {
    		drawHelpScreen(dc);
    		--helpCounter;
    	} else {
    		drawMainScreen(dc);
    	}
    }

	function drawMainScreen(dc)
	{
		var hw = dc.getWidth()/2;
		
	    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        
    	altitude.draw(dc, 60, 30, 50, 130);
    	speed.draw(dc, 150, 30, -1, -1);
    	
    	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
    	dc.drawText(150, 130, Gfx.FONT_LARGE, glideRatioString, Gfx.TEXT_JUSTIFY_CENTER);
    	
    	dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT );
    	dc.drawText(40, 80, Gfx.FONT_MEDIUM, altitude2PtString, Gfx.TEXT_JUSTIFY_CENTER);
    	dc.drawText(hw, 80, Gfx.FONT_MEDIUM, dist2PtString, Gfx.TEXT_JUSTIFY_CENTER);
    	dc.drawText(175, 80, Gfx.FONT_MEDIUM, glide2PtString, Gfx.TEXT_JUSTIFY_CENTER);

		var status;
    	do {
			++statusIndex;
			statusIndex %= 60;
			status = statusString(statusIndex/10);
		} while (status == null);
    	dc.drawText(hw, dc.getHeight()-30, Gfx.FONT_SMALL, status, Gfx.TEXT_JUSTIFY_CENTER);
		
    	if (heading != null) {
    		dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
			drawHand(dc, -heading, 20, 30);
		}
		if (bearing2Pt != null) {
    		dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);
			drawHand(dc, bearing2Pt, 20, 30);
		}
	}
	
	function drawHelpScreen(dc)
	{
        var hw = dc.getWidth()/2;
		
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        
    	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT );
 
    	dc.drawText(60, 30, Gfx.FONT_SMALL, "Altitude", Gfx.TEXT_JUSTIFY_CENTER);
    	dc.drawText(50, 130, Gfx.FONT_SMALL, "Vario", Gfx.TEXT_JUSTIFY_CENTER);
    	dc.drawText(150, 30, Gfx.FONT_SMALL, "Speed", Gfx.TEXT_JUSTIFY_CENTER);
    	
    	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT );
    	dc.drawText(150, 130, Gfx.FONT_SMALL, "GlideRatio", Gfx.TEXT_JUSTIFY_CENTER);
    	
    	dc.drawText(40, 80, Gfx.FONT_SMALL, "Alt2Point", Gfx.TEXT_JUSTIFY_CENTER);
    	dc.drawText(hw, 80, Gfx.FONT_SMALL, "Dist2Point", Gfx.TEXT_JUSTIFY_CENTER);
    	dc.drawText(180, 80, Gfx.FONT_SMALL, "Glide2Point", Gfx.TEXT_JUSTIFY_CENTER);

    	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_GREEN);
    	dc.drawText(hw - 10, 15, Gfx.FONT_SMALL, "North", Gfx.TEXT_JUSTIFY_CENTER);

    	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT );
    	dc.drawText(hw, dc.getHeight()-40, Gfx.FONT_XTINY, "clock/temp/HR/time/", Gfx.TEXT_JUSTIFY_CENTER);
    	dc.drawText(hw, dc.getHeight()-30, Gfx.FONT_XTINY, "totalDist/totalD+", Gfx.TEXT_JUSTIFY_CENTER);		
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
    
    function calcBearing(pos1, pos2) {
	   	var pos1A = pos1.toRadians();
	   	var pos2A = pos2.toRadians();
	   	var la1 = pos1A[0];
	   	var la2 = pos2A[0];
	   	var lo1 = pos1A[1];
	   	var lo2 = pos2A[1];
	    var y = Math.sin(lo2-lo1) * Math.cos(la2);
		var x = Math.cos(la1)*Math.sin(la2) -
	    	    Math.sin(la1)*Math.cos(la2)*Math.cos(lo2-lo1);
		return atan2(y, x);
    }
    
    function atan2(y, x)
    {
    	if (x == 0) {
    		return 0;
    	} else {
    		return Math.atan(y/x) + (x < 0 ? Math.PI : 0);
    	}
    }
    
    function compute(info) {
    	var altitude2Pt = 0;
    	var alt = info.altitude;
		if (alt != null) {
			altitude.addItem(alt);
			if (targetAltitude == null) {
				targetAltitude = info.altitude;
			}
			altitude2Pt = alt - targetAltitude;
			altitude2PtString = altitude2Pt.format("%d");
		}
   	    var s = info.currentSpeed;
    	if (s != null) {
			speed.addItem(s * 3600 / 1000);
			var altVario = altitude.getVarioValue();
			if (altVario == 0) {
				glideRatioString = "oo";
			} else {
				glideRatioString = (-s / altVario).format("%.1f");
			}
			if (targetPosition == null) {
				targetPosition = info.currentLocation;
			}
			var dist2Pt = calcDistance(targetPosition, info.currentLocation);
			if (altitude2Pt == 0) {
				glide2PtString = "--";
			} else {
				glide2PtString = (dist2Pt * 1000 / altitude2Pt).format("%.1f");
			}
			dist2PtString = dist2Pt.format("%.2f"); 
			bearing2Pt = calcBearing(targetPosition, info.currentLocation);
        }        
		heading = info.currentHeading;
    }
}

class FFly extends App.AppBase
{
    function initialize() {
        AppBase.initialize();
    }
    
    function onStart(state)
    {
    }

    function onStop()
    {    	
    }
    
    function getInitialView()
    {
    	var mainView = new AltSpeed();
        return [mainView];
    }
}
