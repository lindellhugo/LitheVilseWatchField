using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;

var partialUpdatesAllowed = false;


class VilseClockView extends Ui.WatchFace {
	
	var mVilseLogo;
	var mScreenCenterPoint;
	var mOffscreenBuffer;
	var mFullScreenRefresh;
	var mDigitFont;
	var mIsAwake;
	
    function initialize() {
        WatchFace.initialize();
        mFullScreenRefresh = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
        
        // Load the logo
        mVilseLogo = Ui.loadResource(Rez.Drawables.VilseLogga);
		
		// mDigitFont to use (standard mDigitFont so nothing special)
        mDigitFont = Gfx.FONT_MEDIUM;
		
		
		 // If this device supports BufferedBitmap, allocate the buffers we use for drawing
        if(Toybox.Graphics has :BufferedBitmap) {
            mOffscreenBuffer = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>dc.getHeight(),
                :palette=> [
                	Graphics.COLOR_WHITE
                ]
            });
        } else {
            mOffscreenBuffer = null;
        }
        
        // Save the center point for future use to reduce calculations
        mScreenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];

    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }
    
    
         
    // This function is used to generate the coordinates of the 4 corners of the polygon
    // used to draw a watch hand. The coordinates are generated with specified length,
    // tail length, and width and rotated around the center point at the provided angle.
    // 0 degrees is at the 12 o'clock position, and increases in the clockwise direction.
    function generateHandCoordinates(centerPoint, angle, handLength, tailLength, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2), tailLength], [-(width / 2), -handLength], [width / 2, -handLength], [width / 2, tailLength]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }
    
    // Generate the tip coordinates, ie. the tip (the little triangle) of the hands
    function generateTipCoordinates(centerPoint, angle, handLength, tipLength, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2), -handLength], [width / 2, -handLength], [0, -handLength - tipLength]];
        var result = new [3];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 3; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }
    

    // Update the view
    function onUpdate(dc) {
    
    	
		var width;
        var height;
        var screenWidth = dc.getWidth();
        var clockTime = System.getClockTime();
        var minuteHandAngle;
        var hourHandAngle;
        var secondHand;
        var targetDc = null;
        var handWidth = 10;

        // We always want to refresh the full screen when we get a regular onUpdate call.
        mFullScreenRefresh = true;

        if(null != mOffscreenBuffer) {
            dc.clearClip();
            curClip = null;
            // If we have an offscreen buffer that we are using to draw the background,
            // set the draw context of that buffer as our target.
            targetDc = mOffscreenBuffer.getDc();
        } else {
            targetDc = dc;
        }
		
		// Save width and height for future use
        width = targetDc.getWidth();
        height = targetDc.getHeight();

        // Fill the entire background with white.
        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        
        // Draw the Vilse logo
        if (null != mVilseLogo) {
            targetDc.drawBitmap(mScreenCenterPoint[0] - 105, mScreenCenterPoint[1] - 105, mVilseLogo);
            System.println(mScreenCenterPoint[0]);
            System.println(mScreenCenterPoint[1]);
        }

        //Use white to draw the hour hand
        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		
        // Draw the hour hand. Convert it to minutes and compute the angle.
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;
		targetDc.fillPolygon(generateHandCoordinates(mScreenCenterPoint, hourHandAngle, 70, 0, handWidth));
		targetDc.fillPolygon(generateTipCoordinates(mScreenCenterPoint, hourHandAngle, 70, 10, handWidth));
		
		//Use red to draw the minute hand
        targetDc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
		
        // Draw the minute hand.
        minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        targetDc.fillPolygon(generateHandCoordinates(mScreenCenterPoint, minuteHandAngle, 70, 0, handWidth));
        targetDc.fillPolygon(generateTipCoordinates(mScreenCenterPoint, minuteHandAngle, 70, 10, handWidth));

        // Draw the circle in the center of the screen.
        targetDc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        targetDc.fillCircle(mScreenCenterPoint[0], mScreenCenterPoint[1], 9);

        // Draw the 3, 6, 9, and 12 hour labels.
        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        targetDc.drawText(mScreenCenterPoint[0], 1, mDigitFont, "12", Graphics.TEXT_JUSTIFY_CENTER);
        targetDc.drawText(width - 6, mScreenCenterPoint[1] - 14, mDigitFont, "3", Graphics.TEXT_JUSTIFY_RIGHT);
        targetDc.drawText(mScreenCenterPoint[0], height - 26, mDigitFont, "6", Graphics.TEXT_JUSTIFY_CENTER);
        targetDc.drawText(2, mScreenCenterPoint[1] - 15, mDigitFont, "9", Graphics.TEXT_JUSTIFY_LEFT);

        // Output the offscreen buffers to the main display if required.
        drawBackground(dc);

        if( partialUpdatesAllowed ) {
            // If this device supports partial updates and they are currently
            // allowed run the onPartialUpdate method to draw the second hand.
            onPartialUpdate( dc );
        } else if ( mIsAwake ) {
            // Otherwise, if we are out of sleep mode, draw the second hand
            // directly in the full update method.
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            secondHand = (clockTime.sec / 60.0) * Math.PI * 2;

            dc.fillPolygon(generateHandCoordinates(mScreenCenterPoint, secondHand, 80, 0, 2));
        }

        mFullScreenRefresh = false;
    }
	
	// Handle the partial update event
    function onPartialUpdate( dc ) {
        // If we're not doing a full screen refresh we need to re-draw the background
        // before drawing the updated second hand position. Note this will only re-draw
        // the background in the area specified by the previously computed clipping region.
        if(!mFullScreenRefresh) {
            drawBackground(dc);
        }

        var clockTime = System.getClockTime();
        var secondHand = (clockTime.sec / 60.0) * Math.PI * 2;
        var secondHandPoints = generateHandCoordinates(mScreenCenterPoint, secondHand, 80, 0, 2);

        // Update the cliping rectangle to the new location of the second hand.
        curClip = getBoundingBox( secondHandPoints );
        var bboxWidth = curClip[1][0] - curClip[0][0] + 1;
        var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
        dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);

        // Draw the second hand to the screen.
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(secondHandPoints);
    }
	
	// Draw the watch face background
    // onUpdate uses this method to transfer newly rendered Buffered Bitmaps
    // to the main display.
    // onPartialUpdate uses this to blank the second hand from the previous
    // second before outputing the new one.
    function drawBackground(dc) {
                
        //If we have an offscreen buffer that has been written to
        //draw it to the screen.
        if( null != mOffscreenBuffer ) {
            dc.drawBitmap(0, 0, mOffscreenBuffer);
        }

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	mIsAwake = true;
        
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	mIsAwake = false;
    	WatchUi.requestUpdate();
    }
    
    

}

class VilseClockDelegate extends Ui.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }
}