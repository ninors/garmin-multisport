import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Native Garmin Menu2 Pause Screen with native Garmin IconMenuItems + 3s cycling header
// BACK button stays PAUSED (returns to data screens with red pause ring instead of resuming!)
module PauseMenu {
    function push(manager as MultisportManager) as Void {
        var menu = new WatchUi.Menu2({:title => new PauseHeaderDrawable(manager)});
        menu.addItem(new WatchUi.IconMenuItem("Reprendre", SportDefinitions.getSportName(manager.getCurrentSport()), :resume, new PauseIconDrawable(:resume), null));
        menu.addItem(new WatchUi.IconMenuItem("Enregistrer", SportDefinitions.formatTime(manager.totalElapsedMs), :save, new PauseIconDrawable(:save), null));
        if (manager.getNextSport() != null) {
            menu.addItem(new WatchUi.IconMenuItem("Sport suivant", SportDefinitions.getSportName(manager.getNextSport() as Number), :next_sport, new PauseIconDrawable(:next_sport), null));
        }
        menu.addItem(new WatchUi.IconMenuItem("FC récupération", (manager.heartRate > 30) ? (manager.heartRate.toString() + " bpm") : "--", :rec_hr, new PauseIconDrawable(:rec_hr), null));
        menu.addItem(new WatchUi.IconMenuItem("Ignorer", "Supprimer l'activité", :discard, new PauseIconDrawable(:discard), null));

        WatchUi.pushView(menu, new PauseMenuDelegate(manager), WatchUi.SLIDE_UP);
    }
}

// Crisp white Garmin icons inside native Menu2 IconMenuItem
class PauseIconDrawable extends WatchUi.Drawable {
    private var iconId as Symbol;

    function initialize(id as Symbol) {
        Drawable.initialize({:width => 34, :height => 34});
        iconId = id;
    }

    function draw(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        if (iconId == :resume) {
            var tri = [[cx - 7, cy - 11], [cx + 11, cy], [cx - 7, cy + 11]] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(tri);
        } else if (iconId == :save) {
            dc.fillRectangle(cx - 3, cy - 11, 6, 11);
            var arr = [[cx - 9, cy - 1], [cx + 9, cy - 1], [cx, cy + 8]] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(arr);
            dc.fillRectangle(cx - 10, cy + 10, 20, 3);
        } else if (iconId == :next_sport) {
            var t1 = [[cx - 9, cy - 9], [cx + 3, cy], [cx - 9, cy + 9]] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(t1);
            dc.fillRectangle(cx + 5, cy - 9, 4, 18);
        } else if (iconId == :rec_hr) {
            SportIcons.drawHeart(dc, cx, cy, 16, Theme.COLOR_WHITE);
        } else if (iconId == :discard) {
            dc.fillRectangle(cx - 9, cy - 9, 18, 3);
            dc.fillRectangle(cx - 4, cy - 13, 8, 4);
            dc.fillRoundedRectangle(cx - 7, cy - 4, 14, 16, 2);
        }
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

        // Subtle red top accent bar to signal Pause state
        dc.setColor(0xFF0022, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 40, 4, 80, 4);

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
            var confView = new DiscardConfirmView();
            WatchUi.pushView(confView, new DiscardConfirmDelegate(manager, confView), WatchUi.SLIDE_LEFT);
        }
    }

    // BACK button from PauseMenu -> stays PAUSED and shows data screens with red pause border!
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// Authentic Garmin Confirmation Screen with Red Cross (X) and Green Checkmark (V)!
class DiscardConfirmView extends WatchUi.View {
    public var confirmYes as Boolean;

    function initialize() {
        View.initialize();
        confirmYes = false; // Default safe on Red Cross (Cancel)
    }

    public function toggleChoice() as Void {
        confirmYes = !confirmYes;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        var cx = dc.getWidth() / 2;

        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        // Title
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 126, Graphics.FONT_SMALL, "Ignorer l'activité ?", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var leftX = 114;
        var rightX = 276;
        var btnY = 248;
        var r = 42;

        // Selection ring around active button
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        if (!confirmYes) {
            dc.drawCircle(leftX, btnY, r + 8);
        } else {
            dc.drawCircle(rightX, btnY, r + 8);
        }

        // Left: Red Circle with crisp White Cross (X)
        dc.setColor(0xFF2233, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(leftX, btnY, r);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawLine(leftX - 15, btnY - 15, leftX + 15, btnY + 15);
        dc.drawLine(leftX + 15, btnY - 15, leftX - 15, btnY + 15);

        // Right: Green Circle with crisp White Checkmark (V)
        dc.setColor(0x00E64D, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(rightX, btnY, r);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawLine(rightX - 16, btnY + 2, rightX - 4, btnY + 14);
        dc.drawLine(rightX - 4, btnY + 14, rightX + 18, btnY - 14);

        // Glowing blue START hint on top-right
        GarminComponents.drawActionGlowArc(dc, 28, 0xAAEEFF, 0x00CCFF, 0x004466);
    }
}

class DiscardConfirmDelegate extends WatchUi.InputDelegate {
    private var manager as MultisportManager;
    private var view as DiscardConfirmView;

    function initialize(mgr as MultisportManager, v as DiscardConfirmView) {
        InputDelegate.initialize();
        manager = mgr;
        view = v;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_UP || k == WatchUi.KEY_DOWN) {
            view.toggleChoice();
            return true;
        } else if (k == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        } else if (k == WatchUi.KEY_ENTER) {
            if (view.confirmYes) {
                manager.discardAll();
                // Pop DiscardConfirmView + PauseMenu -> ActiveDataView.onShow() switches cleanly to PreStartView!
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            } else {
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            }
            return true;
        }
        return false;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
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
