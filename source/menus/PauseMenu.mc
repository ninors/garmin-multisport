import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// EXACT Forerunner 965 Native Pause Screen:
// Thick red ring around bezel, CHRONO + 1:18⁹⁸ header, scrollable list with
// Garmin deep-blue highlight row + cyan left accent bar + white vector icons!
module PauseMenu {
    function push(manager as MultisportManager) as Void {
        var view = new PauseMenuView(manager);
        WatchUi.pushView(view, new PauseMenuDelegate(manager, view), WatchUi.SLIDE_IMMEDIATE);
    }
}

class PauseMenuView extends WatchUi.View {
    private var manager as MultisportManager;
    public var items as Array<Symbol>;
    public var labels as Array<String>;
    public var selectedIdx as Number;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
        selectedIdx = 0;
        items = [:resume, :save] as Array<Symbol>;
        labels = ["Reprendre", "Enregistrer"] as Array<String>;
        if (mgr.getNextSport() != null) {
            items.add(:next_sport);
            labels.add("Sport suivant");
        }
        items.add(:rec_hr);
        labels.add("FC récupération");
        items.add(:discard);
        labels.add("Ignorer");
    }

    public function moveDown() as Void {
        if (selectedIdx < items.size() - 1) {
            selectedIdx++;
            WatchUi.requestUpdate();
        }
    }

    public function moveUp() as Void {
        if (selectedIdx > 0) {
            selectedIdx--;
            WatchUi.requestUpdate();
        }
    }

    public function getSelectedId() as Symbol {
        return items[selectedIdx];
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        var rowH = 58;
        var centerRowY = (selectedIdx == 0) ? 196 : cy;

        // Draw scrollable rows cleanly INSIDE the red ring (zero text touching the red ring!)
        for (var i = 0; i < items.size(); i++) {
            var ry = centerRowY + ((i - selectedIdx) * rowH);
            if (ry < 58 || ry > h - 54) {
                continue;
            }
            var isSel = (i == selectedIdx);
            if (isSel) {
                // Signature FR965 navy-blue selection bar + bright cyan left vertical accent
                dc.setColor(0x0B2344, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(38, ry - 26, w - 76, 52);
                dc.setColor(0x00CCFF, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(38, ry - 26, 5, 52);
            }

            drawPauseItemIcon(dc, items[i], 82, ry);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(114, ry, Graphics.FONT_TINY, labels[i], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Top CHRONO + Elapsed Time header when at top of list (exact Photo 8!)
        if (selectedIdx == 0) {
            dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, w, 150);
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 54, Graphics.FONT_XTINY, "CHRONO", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            var tStr = SportDefinitions.formatTime(manager.totalElapsedMs);
            var tw = dc.getTextWidthInPixels(tStr, Graphics.FONT_NUMBER_MEDIUM);
            var leftX = cx - (tw / 2) - 8;
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftX, 104, Graphics.FONT_NUMBER_MEDIUM, tStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            var hundredths = ((manager.totalElapsedMs % 1000) / 10).format("%02d");
            dc.drawText(leftX + tw + 3, 90, Graphics.FONT_XTINY, hundredths, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Clean black outer rim mask + Signature Forerunner 965 Continuous Red Bezel Ring right at the edge!
        dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(12);
        dc.drawCircle(cx, cy, cx - 2);
        dc.setColor(0xFF0022, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(7);
        dc.drawCircle(cx, cy, cx - 10);
    }

    private function drawPauseItemIcon(dc as Dc, id as Symbol, x as Number, y as Number) as Void {
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (id == :resume) {
            // Crisp Play Triangle
            var tri = [[x - 8, y - 12], [x + 12, y], [x - 8, y + 12]] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(tri);
        } else if (id == :save) {
            // Crisp Download / Save arrow
            dc.fillRectangle(x - 3, y - 12, 6, 12);
            var arr = [[x - 10, y - 1], [x + 10, y - 1], [x, y + 9]] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(arr);
            dc.fillRectangle(x - 11, y + 11, 22, 3);
        } else if (id == :next_sport) {
            // Forward skip icon
            var t1 = [[x - 10, y - 10], [x + 4, y], [x - 10, y + 10]] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(t1);
            dc.fillRectangle(x + 6, y - 10, 4, 20);
        } else if (id == :rec_hr) {
            // Crisp White Heart icon (Photo 1!)
            SportIcons.drawHeart(dc, x, y, 18, Theme.COLOR_WHITE);
        } else if (id == :discard) {
            // Crisp White Trash Can icon (Photo 1!)
            dc.fillRectangle(x - 10, y - 10, 20, 3);
            dc.fillRectangle(x - 4, y - 14, 8, 4);
            dc.fillRoundedRectangle(x - 8, y - 5, 16, 18, 2);
        }
    }
}

class PauseMenuDelegate extends WatchUi.InputDelegate {
    private var manager as MultisportManager;
    private var view as PauseMenuView;

    function initialize(mgr as MultisportManager, v as PauseMenuView) {
        InputDelegate.initialize();
        manager = mgr;
        view = v;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_DOWN) {
            view.moveDown();
            return true;
        } else if (k == WatchUi.KEY_UP) {
            view.moveUp();
            return true;
        } else if (k == WatchUi.KEY_ESC) {
            if (manager.state == MultisportManager.STATE_PAUSED) {
                manager.togglePause();
            }
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (k == WatchUi.KEY_ENTER) {
            return handleSelect(view.getSelectedId());
        }
        return false;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            view.moveDown();
        } else if (dir == WatchUi.SWIPE_DOWN) {
            view.moveUp();
        }
        return true;
    }

    private function handleSelect(id as Symbol) as Boolean {
        if (id == :resume) {
            if (manager.state == MultisportManager.STATE_PAUSED) {
                manager.togglePause();
            }
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
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
            var hrText = (manager.heartRate > 30) ? (manager.heartRate.toString() + " bpm") : "-- bpm";
            manager.showAlert("FC RÉCUPÉRATION", hrText, 3);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :discard) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            var confirm = new WatchUi.Confirmation("Ignorer l'activité ?");
            WatchUi.pushView(confirm, new DiscardConfirmDelegate(manager), WatchUi.SLIDE_UP);
        }
        return true;
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
