using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.SensorHistory;

class MainView extends WatchUi.View {

    private var viewType;
    private var viewName;
    private var screenMidX;

    function initialize() {
        View.initialize();
    }

    function setType(type, name) {
        viewType = type;
        viewName = name;
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        screenMidX = dc.getWidth() / 2;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        View.onUpdate(dc);

        draw(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    private function draw(dc) {
        var iterator = getHistory(viewType);
        drawGraph(dc, 20, 175, 200, 115, iterator);
    }

    // [baseX, baseY] : left bottom point
    private function drawGraph(dc, baseX, baseY, width, height, iterator) {
        var ySpace = 15;
        var min = iterator.getMin();
        var max = iterator.getMax();
        System.println("max=" + max + ", min=" + min);
        if (max == min) {
            if (min < 0) {
                max = 0;
            } else if (max > 0) {
                min = 0;
            } else {
                max = 1;
                min = 0;
            }
        }
        var yRatio = (height - ySpace*2.0) / (max - min);
        System.println("yRatio=" + yRatio);

        var fromTime = iterator.getOldestSampleTime().value();
        var toTime = iterator.getNewestSampleTime().value();

        var secPerPixel = (toTime - fromTime) / width;

        System.println("from=" + fromTime + ", to=" + toTime);
        System.println("secPerPixel="+secPerPixel);

        var sample = iterator.next();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(screenMidX, 2, Graphics.FONT_XTINY, viewName, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(screenMidX, 20, Graphics.FONT_MEDIUM, 
            Lang.format("$1$", [sample.data ? sample.data.format("%.1f") : "--"]), Graphics.TEXT_JUSTIFY_CENTER);

        var lastTime = Gregorian.info(iterator.getNewestSampleTime(), Time.FORMAT_SHORT);
        var hour = lastTime.hour;
        var seconds = lastTime.min * 60 + lastTime.sec;
        var x = baseX + width - seconds / secPerPixel;
        System.println("x=" + x);
        while (x > baseX) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
            dc.drawLine(x, baseY+2, x, baseY-height);
            dc.drawText(x, baseY+2, Graphics.FONT_XTINY, Lang.format("$1$", [hour]), Graphics.TEXT_JUSTIFY_CENTER);

            x = x - 3600 / secPerPixel;
            hour = hour - 1;
            if (hour < 0) {
                hour = 23;
            }
        }

        var stepSec = secPerPixel * 3; // adjustable
        var nextTime = toTime - stepSec;
        var prevX = baseX + width - 1;
        var prevY = null;
        var minPoint = { :value => max };
        var maxPoint = { :value => min };
        var sum = 0;
        var num = 0;

        for (; sample != null; sample = iterator.next() ) {
            var data = sample.data ? sample.data : min;
            // System.println(data);

            if (prevY == null) {
                prevY = baseY - ySpace - (data - min) * yRatio;
            }

            var t = sample.when.value();
            var x = baseX + width - 1 - Math.round((toTime - t) / secPerPixel);
            var y = baseY - ySpace - (data - min) * yRatio;
            
            if (sample.data != null) {
                sum += data;
                num++;
                if (data < minPoint[:value]) {
                    minPoint = { :x => x, :y => y, :value => data };
                } 
                if (data > maxPoint[:value]) {
                    maxPoint = { :x => x, :y => y, :value => data };
                } 
            }

            if (t > nextTime) {
                continue;
            }

            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            dc.fillPolygon([[x, y], [prevX, prevY], [prevX, baseY], [x, baseY]]);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawLine(prevX, prevY, x, y);

            prevX = x;
            prevY = y;
            nextTime = nextTime - stepSec;
        }

        var avg = sum/num;
        System.println("avg=" + avg);
        var avgY = baseY - ySpace - (avg - min) * yRatio; 
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(baseX, avgY, baseX + width, avgY);
        dc.drawText(screenMidX, baseY + dc.getFontHeight(Graphics.FONT_XTINY), Graphics.FONT_XTINY, "avg: " + avg.format("%.1f"), 
                Graphics.TEXT_JUSTIFY_CENTER);

        drawMarker(dc, minPoint, -1);
        drawMarker(dc, maxPoint, 1);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawLine(baseX, baseY, baseX, baseY-height);
        dc.drawLine(baseX+width, baseY, baseX+width, baseY-height);
    }

    private function drawMarker(dc, point, sign) {
        var x = point[:x];
        var y = point[:y];
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x, y-sign], [x+4, y-8*sign], [x-4, y-8*sign]]);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_YELLOW);
        var text = " " + point[:value].format("%.1f") + " ";
        if (x > screenMidX) {
            dc.drawText(x-10, y-8*sign, Graphics.FONT_XTINY, text, 
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(x+10, y-8*sign, Graphics.FONT_XTINY, text, 
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function getHistory(type) {
        if (Toybox has :SensorHistory && Toybox.SensorHistory has type) {
            switch (type) {
                case :getTemperatureHistory:
                    return Toybox.SensorHistory.getTemperatureHistory({});
                case :getPressureHistory:
                    return Toybox.SensorHistory.getPressureHistory({});
                case :getElevationHistory:
                    return Toybox.SensorHistory.getElevationHistory({});
                case :getHeartRateHistory:
                    return Toybox.SensorHistory.getHeartRateHistory({});
            }
        }        
        return null;
    }
}
