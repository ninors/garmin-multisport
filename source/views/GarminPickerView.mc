import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Native Garmin-style Step-by-Step Drum Wheel Picker
// Supports:
//   MODE_TIME_MMSS (step 0 = minutes, step 1 = exact seconds 00..59!)
//   MODE_NUMBER    (exact step-by-step integer value with unit, 0 = Désactivé)
class GarminPickerView extends WatchUi.View {
    public static const MODE_TIME_MMSS = 0;
    public static const MODE_NUMBER = 1;

    public var title as String;
    public var unit as String;
    public var mode as Number;
    public var minVal as Number;
    public var maxVal as Number;
    public var stepVal as Number;

    // For MODE_NUMBER
    public var currentVal as Number;
    // For MODE_TIME_MMSS
    public var minutes as Number;
    public var seconds as Number;
    public var activeColumn as Number; // 0 = min, 1 = sec

    function initialize(t as String, u as String, m as Number, initVal as Number, minV as Number, maxV as Number, stp as Number) {
        View.initialize();
        title = t;
        unit = u;
        mode = m;
        minVal = minV;
        maxVal = maxV;
        stepVal = stp;
        currentVal = initVal;
        minutes = initVal / 60;
        seconds = initVal % 60;
        activeColumn = 0;
    }

    public function increment() as Void {
        if (mode == MODE_TIME_MMSS) {
            if (activeColumn == 0) {
                minutes = (minutes + 1) % 60;
            } else {
                seconds = (seconds + 1) % 60;
            }
        } else {
            if (currentVal == 0 && minVal > 0) {
                currentVal = minVal;
            } else {
                currentVal += stepVal;
                if (currentVal > maxVal) {
                    currentVal = 0; // Wrap to OFF
                }
            }
        }
        WatchUi.requestUpdate();
    }

    public function decrement() as Void {
        if (mode == MODE_TIME_MMSS) {
            if (activeColumn == 0) {
                minutes = (minutes + 59) % 60;
            } else {
                seconds = (seconds + 59) % 60;
            }
        } else {
            if (currentVal == 0) {
                currentVal = maxVal;
            } else {
                currentVal -= stepVal;
                if (currentVal < minVal) {
                    currentVal = 0; // OFF
                }
            }
        }
        WatchUi.requestUpdate();
    }

    public function getResultValue() as Number {
        if (mode == MODE_TIME_MMSS) {
            return (minutes * 60) + seconds;
        }
        return currentVal;
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        var w = dc.getWidth();
        var cx = w / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        // Title at top
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 54, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Garmin selection rails (horizontal cyan/blue lines)
        dc.setColor(0x00AAFF, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(56, cy - 40, w - 56, cy - 40);
        dc.drawLine(56, cy + 40, w - 56, cy + 40);

        if (mode == MODE_TIME_MMSS) {
            drawTimeDrum(dc, cx, cy);
        } else {
            drawNumberDrum(dc, cx, cy);
        }

        // Bottom unit & step hint
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 316, Graphics.FONT_XTINY, unit, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var hint = (mode == MODE_TIME_MMSS && activeColumn == 0) ? "START : Secondes" : "START : Valider";
        dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 346, Graphics.FONT_XTINY, hint, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawTimeDrum(dc as Dc, cx as Number, cy as Number) as Void {
        var minX = cx - 56;
        var secX = cx + 56;

        // Previous & Next dimmed values above/below active column
        var prevM = (minutes + 59) % 60;
        var nextM = (minutes + 1) % 60;
        var prevS = (seconds + 59) % 60;
        var nextS = (seconds + 1) % 60;

        dc.setColor(Theme.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        if (activeColumn == 0) {
            dc.drawText(minX, cy - 68, Graphics.FONT_SMALL, prevM.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(minX, cy + 68, Graphics.FONT_SMALL, nextM.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(secX, cy - 68, Graphics.FONT_SMALL, prevS.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(secX, cy + 68, Graphics.FONT_SMALL, nextS.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Colon separator
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 4, Graphics.FONT_NUMBER_MEDIUM, ":", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Active column bright cyan/white, inactive column gray
        dc.setColor(activeColumn == 0 ? 0x00AAFF : Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(minX, cy, Graphics.FONT_NUMBER_MEDIUM, minutes.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(activeColumn == 1 ? 0x00AAFF : Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(secX, cy, Graphics.FONT_NUMBER_MEDIUM, seconds.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawNumberDrum(dc as Dc, cx as Number, cy as Number) as Void {
        var curStr = (currentVal <= 0) ? "OFF" : currentVal.toString();
        var prevVal = (currentVal <= minVal) ? 0 : (currentVal - stepVal);
        var nextVal = (currentVal == 0) ? minVal : (currentVal + stepVal);
        var prevStr = (prevVal <= 0) ? "OFF" : prevVal.toString();
        var nextStr = (nextVal > maxVal) ? "OFF" : nextVal.toString();

        dc.setColor(Theme.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 68, Graphics.FONT_SMALL, prevStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + 68, Graphics.FONT_SMALL, nextStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_NUMBER_MEDIUM, curStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class GarminPickerDelegate extends WatchUi.BehaviorDelegate {
    private var view as GarminPickerView;
    private var callback as Method(val as Number) as Void;

    function initialize(v as GarminPickerView, cb as Method(val as Number) as Void) {
        BehaviorDelegate.initialize();
        view = v;
        callback = cb;
    }

    function onPreviousPage() as Boolean {
        view.increment();
        return true;
    }

    function onNextPage() as Boolean {
        view.decrement();
        return true;
    }

    function onSelect() as Boolean {
        if (view.mode == GarminPickerView.MODE_TIME_MMSS && view.activeColumn == 0) {
            view.activeColumn = 1;
            WatchUi.requestUpdate();
            return true;
        }
        callback.invoke(view.getResultValue());
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onBack() as Boolean {
        if (view.mode == GarminPickerView.MODE_TIME_MMSS && view.activeColumn == 1) {
            view.activeColumn = 0;
            WatchUi.requestUpdate();
            return true;
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            view.increment();
            return true;
        } else if (dir == WatchUi.SWIPE_DOWN) {
            view.decrement();
            return true;
        }
        return false;
    }
}
