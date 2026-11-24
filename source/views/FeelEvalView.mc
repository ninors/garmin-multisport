import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Authentic Garmin Post-Activity Self-Evaluation ("Ressenti") with 5 Curved Smileys on Right Edge
class FeelEvalView extends WatchUi.View {
    public var selected as Number; // 0 = Très faible .. 4 = Très bon

    private static const FEEL_LABELS = [
        "Très faible",
        "Faible",
        "Normal",
        "Bon",
        "Très bon"
    ] as Array<String>;

    private static const FEEL_COLORS = [
        0xFF2233, // Red
        0xFF8800, // Orange
        0xFFCC00, // Yellow
        0x88DD22, // Light Green
        0x00E64D  // Bright Green
    ] as Array<Number>;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        selected = mgr.feelRating;
    }

    public function moveUp() as Void {
        if (selected < 4) {
            selected++;
            WatchUi.requestUpdate();
        }
    }

    public function moveDown() as Void {
        if (selected > 0) {
            selected--;
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        // Top title
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 12, 56, Graphics.FONT_XTINY, "RESSENTI", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Large active smiley centered slightly left of the right-edge curved wheel
        var mainColor = FEEL_COLORS[selected];
        drawSmiley(dc, cx - 22, cy - 10, 44, selected, mainColor, true);

        // Active feel label underneath
        dc.setColor(mainColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 22, cy + 72, Graphics.FONT_SMALL, FEEL_LABELS[selected], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 5 Miniature Smileys along the curved RIGHT edge (index 4 at top -> 0 at bottom)
        var wheelR = cx - 34;
        var angles = [-38.0f, -19.0f, 0.0f, 19.0f, 38.0f] as Array<Float>;
        for (var i = 0; i < 5; i++) {
            var rad = angles[i] * Math.PI / 180.0d;
            var sx = cx + (Math.cos(rad) * wheelR).toNumber();
            var sy = cy - (Math.sin(rad) * wheelR).toNumber();
            var isSel = (i == selected);
            if (isSel) {
                dc.setColor(0x00CCFF, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(3);
                dc.drawCircle(sx, sy, 17);
            }
            drawSmiley(dc, sx, sy, isSel ? 13 : 10, i, FEEL_COLORS[i], isSel);
        }

        // Native Garmin Glowing Cyan START Arc at Top-Right (28 deg)
        GarminComponents.drawActionGlowArc(dc, 28, 0xAAEEFF, 0x00CCFF, 0x004466);
    }

    private function drawSmiley(dc as Dc, x as Number, y as Number, r as Number, level as Number, color as Number, filled as Boolean) as Void {
        if (filled) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, r);
            dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawCircle(x, y, r);
        }

        // Eyes
        var eyeOffX = (r * 35) / 100;
        var eyeOffY = (r * 22) / 100;
        var eyeR = (r >= 25) ? 4 : 1;
        dc.fillCircle(x - eyeOffX, y - eyeOffY, eyeR);
        dc.fillCircle(x + eyeOffX, y - eyeOffY, eyeR);

        // Mouth expression according to level (0 = very sad, 1 = sad, 2 = flat, 3 = smile, 4 = big smile)
        var mw = (r * 45) / 100;
        var my = y + ((r * 22) / 100);
        dc.setPenWidth((r >= 25) ? 4 : 2);
        if (level == 0) {
            dc.drawArc(x, y + (r / 2) + 2, mw, Graphics.ARC_COUNTER_CLOCKWISE, 25, 155);
        } else if (level == 1) {
            dc.drawArc(x, y + (r / 2) + 6, mw, Graphics.ARC_COUNTER_CLOCKWISE, 35, 145);
        } else if (level == 2) {
            dc.drawLine(x - mw, my, x + mw, my);
        } else if (level == 3) {
            dc.drawArc(x, y + (r / 10), mw, Graphics.ARC_COUNTER_CLOCKWISE, 210, 330);
        } else {
            dc.drawArc(x, y, mw, Graphics.ARC_COUNTER_CLOCKWISE, 195, 345);
        }
    }
}

class FeelEvalDelegate extends WatchUi.BehaviorDelegate {
    private var manager as MultisportManager;
    private var view as FeelEvalView;

    function initialize(mgr as MultisportManager, v as FeelEvalView) {
        BehaviorDelegate.initialize();
        manager = mgr;
        view = v;
    }

    function onPreviousPage() as Boolean {
        view.moveUp();
        return true;
    }

    function onNextPage() as Boolean {
        view.moveDown();
        return true;
    }

    function onSelect() as Boolean {
        manager.commitSaveWithFeel(view.selected);
        var sumView = new SummaryView(manager);
        WatchUi.switchToView(sumView, new SummaryDelegate(manager, sumView), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onBack() as Boolean {
        manager.commitSaveWithFeel(view.selected);
        var sumView = new SummaryView(manager);
        WatchUi.switchToView(sumView, new SummaryDelegate(manager, sumView), WatchUi.SLIDE_LEFT);
        return true;
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
}
