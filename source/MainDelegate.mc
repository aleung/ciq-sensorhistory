using Toybox.WatchUi;
using Toybox.System;

class MainDelegate extends WatchUi.BehaviorDelegate {

    var view;
    var viewTypes = [:getTemperatureHistory, :getElevationHistory, :getPressureHistory, :getHeartRateHistory];
    var typeNames = ["Temp", "Elev", "Pres", "HR"];
    var viewTypeIdx = 0;

    function initialize(refView) {
        BehaviorDelegate.initialize();
        view = refView;
        setNextViewType();
    }

    function onSelect() {
        setNextViewType();
        WatchUi.switchToView(view, self, WatchUi.SLIDE_UP);
        return true;
    }

    private function setNextViewType() {
        System.println("set view type to " + viewTypes[viewTypeIdx].toString());
        view.setType(viewTypes[viewTypeIdx], typeNames[viewTypeIdx]);
        viewTypeIdx++;
        if (viewTypeIdx >= viewTypes.size()) {
            viewTypeIdx = 0;
        }
    }

}
