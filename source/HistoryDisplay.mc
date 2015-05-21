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

class HistoryDisplay
{
    var history_size;
    var value_string = "--";
    var vario_string = "--";
    var graph;
	var value_history;
	var time_history;
	var history_pointer = 0;
	
    //! Constructor
    function initialize(varioHistorySize, graphHistorySize, minRange, color)
    {
        graph = new LineGraph(graphHistorySize, minRange, color);
        history_size = varioHistorySize;
        value_history = new [history_size];
		time_history = new [history_size];
    }

    //! Handle the update event
    function draw(dc, valueX, valueY, varioX, varioY)
    {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );

		if (valueX >= 0) {
        	dc.drawText( valueX, valueY, Gfx.FONT_LARGE, value_string, Gfx.TEXT_JUSTIFY_CENTER);
        }
        if (varioX >= 0) {
        	dc.drawText( varioX, varioY, Gfx.FONT_LARGE, vario_string, Gfx.TEXT_JUSTIFY_CENTER);
       	}

        graph.draw( dc, [0,0], [dc.getWidth(),dc.getHeight()] );
    }

    function addItem(value)
    {
        computeString(value);
        graph.addItem(value);
    }
    
    function computeString(value)
    {
        value_string = value.format("%d");
        if (history_size > 0) {
	        history_pointer++;
	        history_pointer %= history_size;
	
	        var now = Time.now();
	        if (time_history[history_pointer] != null) {
		        var updatePeriod = now.subtract(time_history[history_pointer]).value().toFloat();
		        var difference = value - value_history[history_pointer];
		        value_history[history_pointer] = value;
		        
		        vario_string = (difference / updatePeriod).format("%.2f");
	        } else {
				for(var i = 0; i < history_size; i++) {
					value_history[i] = value;
					time_history[i] = now;
				}
			}
	        time_history[history_pointer] = now;
        }
    }
}