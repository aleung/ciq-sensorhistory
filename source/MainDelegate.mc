using Toybox.WatchUi;
using Toybox.System;

class MainDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        return false;
    }

}
