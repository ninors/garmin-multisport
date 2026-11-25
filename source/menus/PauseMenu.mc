import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Native Garmin Menu2 Pause Screen (exact same native selection highlight & smooth scrolling as Settings!)
// Includes cycling Pause Header Drawable (CHRONO -> DISTANCE -> FC -> CALORIES every 3 seconds)
module PauseMenu {
    function push(manager as MultisportManager) as Void {
        var menu = new WatchUi.Menu2({:title => new PauseHeaderDrawable(manager)});
        menu.addItem(new WatchUi.MenuItem("Reprendre", SportDefinitions.getSportName(manager.getCurrentSport()), :resume, null));
        menu.addItem(new WatchUi.MenuItem("Enregistrer", SportDefinitions.formatTime(manager.totalElapsedMs), :save, null));
        if (manager.getNextSport() != null) {
            menu.addItem(new WatchUi.MenuItem("Sport suivant", SportDefinitions.getSportName(manager.getNextSport() as Number), :next_sport, null));
        }
        menu.addItem(new WatchUi.MenuItem("FC récupération", (manager.heartRate > 30) ? (manager.heartRate.toString() + " bpm") : "--", :rec_hr, null));
        menu.addItem(new WatchUi.MenuItem("Ignorer", "Supprimer l'activité", :discard, null));

        WatchUi.pushView(menu, new PauseMenuDelegate(manager), WatchUi.SLIDE_UP);
    }
}

// Native Menu2 Header that cycles every 3 seconds: CHRONO -> DISTANCE -> FC -> CALORIES
class PauseHeaderDrawable extends WatchUi.Drawable {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        Drawable.initialize({});
        manager = mgr;
    }

    function draw(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var h = dc.getHeight();
        var slot = (manager.tickCount / 3) % 4;

        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        if (slot == 0) {
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h / 3, Graphics.FONT_XTINY, "CHRONO", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 3) / 4, Graphics.FONT_MEDIUM, SportDefinitions.formatTime(manager.totalElapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (slot == 1) {
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h / 3, Graphics.FONT_XTINY, "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 3) / 4, Graphics.FONT_MEDIUM, SportDefinitions.formatDistance(manager.totalDistanceMeters, false) + " km", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (slot == 2) {
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h / 3, Graphics.FONT_XTINY, "FRÉQ. CARD.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Theme.COLOR_HEART_RED, Graphics.COLOR_TRANSPARENT);
            var hrStr = (manager.heartRate > 30) ? (manager.heartRate.toString() + " bpm") : "--";
            dc.drawText(cx, (h * 3) / 4, Graphics.FONT_MEDIUM, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h / 3, Graphics.FONT_XTINY, "CALORIES", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 3) / 4, Graphics.FONT_MEDIUM, manager.totalCalories.toString() + " kcal", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class PauseMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :resume) {
            if (manager.state == MultisportManager.STATE_PAUSED) {
                manager.togglePause();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :next_sport) {
            var finished = manager.nextSegment();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            if (finished) {
                var evalView = new FeelEvalView(manager);
                WatchUi.switchToView(evalView, new FeelEvalDelegate(manager, evalView), WatchUi.SLIDE_LEFT);
            }
        } else if (id == :save) {
            manager.saveAndFinish();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            var evalView = new FeelEvalView(manager);
            WatchUi.switchToView(evalView, new FeelEvalDelegate(manager, evalView), WatchUi.SLIDE_LEFT);
        } else if (id == :rec_hr) {
            var recView = new RecoveryHRView(manager);
            WatchUi.pushView(recView, new RecoveryHRDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :discard) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            // Native Garmin Confirmation dialog (native red cross X / green check V!)
            var confirm = new WatchUi.Confirmation("Ignorer l'activité ?");
            WatchUi.pushView(confirm, new DiscardConfirmDelegate(manager), WatchUi.SLIDE_UP);
        }
    }

    function onBack() as Void {
        if (manager.state == MultisportManager.STATE_PAUSED) {
            manager.togglePause();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class DiscardConfirmDelegate extends WatchUi.ConfirmationDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        ConfirmationDelegate.initialize();
        manager = mgr;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            // Sets state = STATE_PRE_START; Garmin auto-pops Confirmation back to ActiveDataView,
            // whose onShow() immediately switches cleanly to PreStartView!
            manager.discardAll();
        } else {
            if (manager.state == MultisportManager.STATE_PAUSED) {
                manager.togglePause();
            }
        }
        return true;
    }
}

// Ultra-clean Minimalist Recovery HR Page: ONLY live Heart + BPM + Bottom 5-zone colored semi-circle arc!
class RecoveryHRView extends WatchUi.View {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        var zPos = manager.getHrZonePosition(manager.heartRate);
        var zIdx = manager.getHrZoneIndex(manager.heartRate);
        GarminComponents.drawBottomHrArc(dc, manager.heartRate, zPos, zIdx);
    }
}

class RecoveryHRDelegate extends WatchUi.InputDelegate {
    function initialize() {
        InputDelegate.initialize();
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_ESC || k == WatchUi.KEY_ENTER) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        return false;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return true;
    }
}
