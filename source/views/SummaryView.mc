import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SummaryView extends WatchUi.View {
    public static const TOTAL_PAGES = 3;
    private var manager as MultisportManager;
    public var page as Number;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
        page = 0;
    }

    public function nextPage() as Void {
        page = (page + 1) % TOTAL_PAGES;
        WatchUi.requestUpdate();
    }

    public function prevPage() as Void {
        page = (page - 1 + TOTAL_PAGES) % TOTAL_PAGES;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        if (page == 0) {
            drawOverviewPage(dc);
        } else if (page == 1) {
            drawSegmentsPage(dc);
        } else {
            drawHeartRateZonesPage(dc);
        }

        GarminComponents.drawPaginationDots(dc, page, TOTAL_PAGES);
    }

    // Page 0: Global Totals + Training Effect (compact header, zero clipping!)
    private function drawOverviewPage(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        // Clean green saved header well inside circular chord
        dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 44, Graphics.FONT_XTINY, "ENREGISTRÉ", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 88, Graphics.FONT_NUMBER_MILD, SportDefinitions.formatTime(manager.totalElapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(36, 126, w - 36, 126);

        // Distance & Calories
        var lCx = cx / 2 + 12;
        var rCx = cx + (cx / 2) - 12;

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 148, Graphics.FONT_XTINY, "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(rCx, 148, Graphics.FONT_XTINY, "CALORIES", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 180, Graphics.FONT_SMALL, SportDefinitions.formatDistance(manager.totalDistanceMeters, false) + " km", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(rCx, 180, Graphics.FONT_SMALL, manager.totalCalories.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Training Effect (Aerobic & Anaerobic)
        var aero = manager.getAerobicTrainingEffect();
        var ana = manager.getAnaerobicTrainingEffect();

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 222, Graphics.FONT_XTINY, "TRAINING EFFECT", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x0099FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(68, 252, Graphics.FONT_XTINY, "Aérobie", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(322, 252, Graphics.FONT_TINY, aero.format("%.1f"), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawProgressBar(dc, 68, 268, 254, 8, aero / 5.0f, 0x0099FF);

        dc.setColor(0xAA44FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(68, 296, Graphics.FONT_XTINY, "Anaérobie", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(322, 296, Graphics.FONT_TINY, ana.format("%.1f"), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawProgressBar(dc, 68, 312, 254, 8, ana / 5.0f, 0xAA44FF);

        dc.setColor(Theme.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 350, Graphics.FONT_XTINY, "START : Terminer", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Page 1: Per-Segment Breakdown (compact header, zero clipping!)
    private function drawSegmentsPage(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 44, Graphics.FONT_XTINY, "SEGMENTS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(46, 66, w - 46, 66);

        var count = manager.segments.size();
        if (count > 5) { count = 5; }
        var startY = 98;
        var rowH = 50;

        for (var i = 0; i < count; i++) {
            var seg = manager.segments[i];
            var y = startY + (i * rowH);
            var sColor = SportDefinitions.getSportColor(seg.sportType);

            SportIcons.drawSportIcon(dc, seg.sportType, 62, y, 12, sColor);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(86, y - 10, Graphics.FONT_XTINY, SportDefinitions.getSportName(seg.sportType), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            var sub = "Transition";
            if (!SportDefinitions.isTransition(seg.sportType)) {
                var u = SportDefinitions.getDistanceUnit(seg.distanceMeters, SportDefinitions.isSwim(seg.sportType));
                sub = SportDefinitions.formatDistance(seg.distanceMeters, SportDefinitions.isSwim(seg.sportType)) + " " + u + " • FC " + seg.getAvgHeartRate().toString();
            }
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(86, y + 12, Graphics.FONT_XTINY, sub, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(sColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(330, y, Graphics.FONT_TINY, SportDefinitions.formatTime(seg.elapsedMs), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Page 2: Authentic Garmin Forerunner 965 "Temps dans les zones" HR Zones Screen
    private function drawHeartRateZonesPage(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;

        // Compact non-clipped header
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 40, Graphics.FONT_XTINY, "ZONES FC", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var avgHr = manager.getGlobalAvgHr();
        var maxHr = manager.globalMaxHr;
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 68, Graphics.FONT_XTINY,
            "Moy " + ((avgHr > 0) ? avgHr.toString() : "--") + "  •  Max " + ((maxHr > 0) ? maxHr.toString() : "--"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var totalZ = 0;
        for (var i = 0; i < 5; i++) {
            totalZ += manager.zoneSeconds[i];
        }
        if (totalZ <= 0) { totalZ = 1; }

        // Native Garmin FR965 thick horizontal zone bars (Zone # | Thick Bar | Time & %)
        var startY = 112;
        var rowH = 48;
        for (var z = 4; z >= 0; z--) {
            var y = startY + ((4 - z) * rowH);
            var secs = manager.zoneSeconds[z];
            var ratio = secs.toFloat() / totalZ.toFloat();
            var zColor = Theme.getZoneColor(z);

            // Colored zone number badge on the left
            dc.setColor(zColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(44, y - 13, 28, 26, 6);
            dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
            dc.drawText(58, y, Graphics.FONT_XTINY, (z + 1).toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Thick Garmin native horizontal bar track + colored fill
            var barX = 80;
            var barW = 164;
            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, y - 12, barW, 24, 6);
            var fillW = (barW.toFloat() * ratio).toNumber();
            if (fillW > 0) {
                if (fillW < 10) { fillW = 10; }
                dc.setColor(zColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(barX, y - 12, fillW, 24, 6);
            }

            // Time in zone + percentage on the right
            var pct = (ratio * 100.0f).toNumber();
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(336, y - 8, Graphics.FONT_XTINY, SportDefinitions.formatTime(secs * 1000), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(336, y + 11, Graphics.FONT_XTINY, pct.toString() + "%", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function drawProgressBar(dc as Dc, x as Number, y as Number, w as Number, h as Number, ratio as Float, color as Number) as Void {
        if (ratio < 0.0f) { ratio = 0.0f; }
        if (ratio > 1.0f) { ratio = 1.0f; }
        dc.setColor(Theme.COLOR_DARK_LINE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, h / 2);
        var fillW = (w.toFloat() * ratio).toNumber();
        if (fillW > 0) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, fillW, h, h / 2);
        }
    }
}

class SummaryDelegate extends WatchUi.BehaviorDelegate {
    private var manager as MultisportManager;
    private var view as SummaryView;

    function initialize(mgr as MultisportManager, v as SummaryView) {
        BehaviorDelegate.initialize();
        manager = mgr;
        view = v;
    }

    function onNextPage() as Boolean {
        view.nextPage();
        return true;
    }

    function onPreviousPage() as Boolean {
        view.prevPage();
        return true;
    }

    function onSelect() as Boolean {
        return exitToPreStart();
    }

    function onBack() as Boolean {
        return exitToPreStart();
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            view.nextPage();
            return true;
        } else if (dir == WatchUi.SWIPE_DOWN) {
            view.prevPage();
            return true;
        }
        return false;
    }

    private function exitToPreStart() as Boolean {
        manager.resetToPreStart();
        var preView = new PreStartView(manager);
        var preDel = new PreStartDelegate(manager);
        WatchUi.switchToView(preView, preDel, WatchUi.SLIDE_RIGHT);
        return true;
    }
}
