using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.SensorHistory;

class MainView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));      
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
        drawGraph(dc, 20, 180, 200, 120, getTemperatureHistory());
    }

    // [baseX, baseY] : left bottom point
    private function drawGraph(dc, baseX, baseY, width, height, iterator) {
        var ySpace = 15;
        var min = iterator.getMin();
        var max = iterator.getMax();
        var yRatio = (height - ySpace*2) / (max - min);

        System.println("max=" + max + ", min=" + min);
        System.println("yRatio="+yRatio);

        var fromTime = iterator.getOldestSampleTime().value();
        var toTime = iterator.getNewestSampleTime().value();

        var secPerPixel = (toTime - fromTime) / width;

        System.println("from=" + fromTime + ", to=" + toTime);
        System.println("secPerPixel="+secPerPixel);

        var sample = iterator.next();
        // TODO: move it outside of this function
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(120, 20, Graphics.FONT_MEDIUM, Lang.format("$1$", [sample.data]), Graphics.TEXT_JUSTIFY_CENTER);

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
                hour = 24;
            }
        }

        var stepSec = secPerPixel * 5; // x step: 5 pixels
        var nextTime = toTime - stepSec;
        var prevX = baseX + width - 1;
        var prevY = null;
        for (; sample != null; sample = iterator.next() ) {

            if (prevY == null) {
                prevY = baseY - ySpace - (sample.data - min) * yRatio;
            }

            var t = sample.when.value();
            if (t > nextTime) {
                continue;
            }

            var x = baseX + width - 1 - Math.round((toTime - t) / secPerPixel);
            // System.println("x="+x);

            var y = baseY - ySpace - (sample.data - min) * yRatio;
            
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            dc.fillPolygon([[x, y], [prevX, prevY], [prevX, baseY], [x, baseY]]);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawLine(prevX, prevY, x, y);

            prevX = x;
            prevY = y;
            nextTime = nextTime - stepSec;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawLine(baseX, baseY, baseX, baseY-height);
        dc.drawLine(baseX+width, baseY, baseX+width, baseY-height);
    }

    private function getTemperatureHistory() {
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getTemperatureHistory)) {
            return Toybox.SensorHistory.getTemperatureHistory({});
        }        
        return null;
    }
}
