import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// EXACT Forerunner 165 / 965 Native Pause Screen (IMG_0472, IMG_0473, IMG_0474):
// - Crisp red bezel ring around edge
// - 3-second cycling top header (DISTANCE -> CHRONO -> FRÉQ. CARD. -> CALORIES)
// - Blue-gradient FR165 selection highlight bar + cyan left accent + white vector icons
// - BACK button stays PAUSED (returns to data screens with red pause border)
// - Native WatchUi.Confirmation("Ignorer ?") for authentic Garmin OK/Cancel corner buttons
// - Authentic FR165 "FC récupération" circular cyan 2:00 countdown screen!
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
            if (ry < 58 || ry > h - 50) {
                continue;
            }
            var isSel = (i == selectedIdx);
            if (isSel) {
                // Authentic FR165 smooth blue-to-black gradient highlight + bright cyan left accent!
                var barX = 32;
                var barW = w - 64;
                var barY = ry - 27;
                var barH = 54;
                dc.setColor(0x030B18, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(barX, barY, barW, barH);
                dc.setColor(0x061936, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(barX, barY, (barW * 3) / 4, barH);
                dc.setColor(0x0A2B5E, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(barX, barY, barW / 2, barH);
                dc.setColor(0x0F3E82, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(barX, barY, barW / 4, barH);
                dc.setColor(0x00CCFF, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(barX, barY, 5, barH);
            }

            drawPauseItemIcon(dc, items[i], 82, ry);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(114, ry, Graphics.FONT_TINY, labels[i], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Top cycling info header every 3 seconds when at top of list (CHRONO -> DISTANCE -> FC -> CALORIES)
        if (selectedIdx == 0) {
            dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, w, 152);

            var slot = (manager.tickCount / 3) % 4;
            if (slot == 0) {
                dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 54, Graphics.FONT_XTINY, "CHRONO", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                var tStr = SportDefinitions.formatTime(manager.totalElapsedMs);
                var tw = dc.getTextWidthInPixels(tStr, Graphics.FONT_NUMBER_MEDIUM);
                var leftX = cx - (tw / 2) - 8;
                dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(leftX, 104, Graphics.FONT_NUMBER_MEDIUM, tStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                var hundredths = ((manager.totalElapsedMs % 1000) / 10).format("%02d");
                dc.drawText(leftX + tw + 3, 90, Graphics.FONT_XTINY, hundredths, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            } else if (slot == 1) {
                dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 54, Graphics.FONT_XTINY, "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 104, Graphics.FONT_NUMBER_MEDIUM, SportDefinitions.formatDistance(manager.totalDistanceMeters, false), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else if (slot == 2) {
                dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 54, Graphics.FONT_XTINY, "FRÉQ. CARD.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                var hrStr = (manager.heartRate > 30) ? manager.heartRate.toString() : "--";
                var hw = dc.getTextWidthInPixels(hrStr, Graphics.FONT_NUMBER_MILD);
                var hx = cx - ((28 + hw) / 2);
                SportIcons.drawHeart(dc, hx + 10, 104, 18, Theme.COLOR_HEART_RED);
                dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(hx + 28, 104, Graphics.FONT_NUMBER_MILD, hrStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 54, Graphics.FONT_XTINY, "CALORIES", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 104, Graphics.FONT_NUMBER_MILD, manager.totalCalories.toString() + " kcal", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Clean black outer rim mask + Authentic FR165 Crisp Red Bezel Ring right at the edge!
        dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(10);
        dc.drawCircle(cx, cy, cx - 1);
        dc.setColor(0xFF0033, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(5);
        dc.drawCircle(cx, cy, cx - 7);
    }

    private function drawPauseItemIcon(dc as Dc, id as Symbol, x as Number, y as Number) as Void {
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (id == :resume) {
            var tri = [[x - 8, y - 12], [x + 12, y], [x - 8, y + 12]] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(tri);
        } else if (id == :save) {
            dc.fillRectangle(x - 3, y - 12, 6, 12);
            var arr = [[x - 10, y - 1], [x + 10, y - 1], [x, y + 9]] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(arr);
            dc.fillRectangle(x - 11, y + 11, 22, 3);
        } else if (id == :next_sport) {
            var t1 = [[x - 10, y - 10], [x + 4, y], [x - 10, y + 10]] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(t1);
            dc.fillRectangle(x + 6, y - 10, 4, 20);
        } else if (id == :rec_hr) {
            SportIcons.drawHeart(dc, x, y, 18, Theme.COLOR_WHITE);
        } else if (id == :discard) {
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
            // BACK button stays PAUSED and shows data screens with red pause border!
            WatchUi.popView(WatchUi.SLIDE_DOWN);
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
            // Native Garmin Confirmation ("Ignorer ?") -> renders authentic FR165 corner X / Trash buttons!
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            var confirm = new WatchUi.Confirmation("Ignorer ?");
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
            // Sets state = STATE_PRE_START & pendingReturnToPreStart = true;
            // Garmin auto-pops Confirmation back to ActiveDataView, whose onShow() switches cleanly to PreStartView!
            manager.discardAll();
        }
        // On CONFIRM_NO, stay PAUSED on data screens (with red pause border)
        return true;
    }
}

// EXACT Forerunner 165 "FC récupération" Screen (IMG_0473):
// Bright cyan-blue circular countdown ring + Red Heart at top + "Mesure en cours..." + Big 2:00 timer + Live BPM!
class RecoveryHRView extends WatchUi.View {
    private var manager as MultisportManager;
    private var startTick as Number;
    private var startHr as Number;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
        startTick = mgr.tickCount;
        startHr = mgr.heartRate;
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        var w = dc.getWidth();
        var cx = w / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        var elapsedSec = manager.tickCount - startTick;
        var remSec = 120 - elapsedSec;
        if (remSec < 0) { remSec = 0; }

        // Subtle dark circular track
        var ringR = cx - 22;
        dc.setColor(0x0A1B2E, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(10);
        dc.drawCircle(cx, cy, ringR);

        // Glowing cyan-blue countdown progress arc (sweeps clockwise from 12 o'clock)
        var frac = remSec.toFloat() / 120.0f;
        if (frac > 0.01f) {
            var sweepDeg = (frac * 358.0f).toNumber();
            var startDeg = 90;
            var endDeg = (90 - sweepDeg + 360) % 360;
            // Soft outer blue glow
            dc.setColor(0x0055AA, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(14);
            dc.drawArc(cx, cy, ringR, Graphics.ARC_CLOCKWISE, startDeg, endDeg);
            // Bright crisp cyan inner ring
            dc.setColor(0x00CCFF, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(6);
            dc.drawArc(cx, cy, ringR, Graphics.ARC_CLOCKWISE, startDeg, endDeg);
        }

        // Top-center bright red Heart icon
        SportIcons.drawHeart(dc, cx, 78, 26, 0xFF1122);

        // Status label
        var statusStr = (remSec > 0) ? "Mesure en cours..." : "Récupération";
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 134, Graphics.FONT_XTINY, statusStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Center HUGE bold countdown timer (or final HR drop once 2:00 finishes)
        if (remSec > 0) {
            var mins = remSec / 60;
            var secs = remSec % 60;
            var timeStr = mins.toString() + ":" + secs.format("%02d");
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 198, Graphics.FONT_NUMBER_HOT, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var drop = (startHr > 30 && manager.heartRate > 30) ? (startHr - manager.heartRate) : 0;
            var dropStr = (drop > 0) ? ("-" + drop.toString()) : "0";
            dc.setColor(0x00E64D, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 198, Graphics.FONT_NUMBER_HOT, dropStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Bottom live BPM
        var hrStr = (manager.heartRate > 30) ? (manager.heartRate.toString() + " bpm") : "-- bpm";
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 268, Graphics.FONT_SMALL, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
