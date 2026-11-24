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

    // Page 0: Global Totals + Training Effect
    private function drawOverviewPage(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        // Green saved badge
        dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 38, Theme.fLabel as Graphics.FontType, "ACTIVITÉ ENREGISTRÉE (.FIT)", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 84, Theme.fValueBig as Graphics.FontType, SportDefinitions.formatTime(manager.totalElapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(32, 122, w - 32, 122);

        // Distance & Calories
        var lCx = cx / 2 + 10;
        var rCx = cx + (cx / 2) - 10;

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 144, Theme.fLabel as Graphics.FontType, "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(rCx, 144, Theme.fLabel as Graphics.FontType, "CALORIES", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 178, Theme.fValueMed as Graphics.FontType, SportDefinitions.formatDistance(manager.totalDistanceMeters, false) + " km", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(rCx, 178, Theme.fValueMed as Graphics.FontType, manager.totalCalories.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Training Effect (Aerobic & Anaerobic)
        var aero = manager.getAerobicTrainingEffect();
        var ana = manager.getAnaerobicTrainingEffect();

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 222, Theme.fLabel as Graphics.FontType, "TRAINING EFFECT", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Aerobic bar
        dc.setColor(0x0099FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(66, 254, Theme.fSmall as Graphics.FontType, "Aérobie", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(324, 254, Theme.fMedium as Graphics.FontType, aero.format("%.1f"), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawProgressBar(dc, 66, 272, 258, 8, aero / 5.0f, 0x0099FF);

        // Anaerobic bar
        dc.setColor(0xAA44FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(66, 300, Theme.fSmall as Graphics.FontType, "Anaérobie", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(324, 300, Theme.fMedium as Graphics.FontType, ana.format("%.1f"), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawProgressBar(dc, 66, 318, 258, 8, ana / 5.0f, 0xAA44FF);

        dc.setColor(Theme.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 354, Theme.fLabel as Graphics.FontType, "START : Terminer", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Page 1: Per-Segment Breakdown
    private function drawSegmentsPage(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 40, Theme.fLabel as Graphics.FontType, "DÉTAIL PAR SEGMENT", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(40, 62, w - 40, 62);

        var count = manager.segments.size();
        if (count > 5) { count = 5; }
        var startY = 96;
        var rowH = 50;

        for (var i = 0; i < count; i++) {
            var seg = manager.segments[i];
            var y = startY + (i * rowH);
            var sColor = SportDefinitions.getSportColor(seg.sportType);

            SportIcons.drawSportIcon(dc, seg.sportType, 62, y, 11, sColor);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(86, y - 8, Theme.fSmall as Graphics.FontType, SportDefinitions.getSportName(seg.sportType), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            var sub = SportDefinitions.isTransition(seg.sportType)
                ? "Transition"
                : (SportDefinitions.formatDistance(seg.distanceMeters, SportDefinitions.isSwim(seg.sportType)) + " • FC " + seg.getAvgHeartRate().toString());
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(86, y + 12, Theme.fLabel as Graphics.FontType, sub, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(sColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(334, y, Theme.fMedium as Graphics.FontType, SportDefinitions.formatTime(seg.elapsedMs), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Page 2: Heart Rate Avg/Max & 5-Zone Distribution
    private function drawHeartRateZonesPage(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 40, Theme.fLabel as Graphics.FontType, "FRÉQUENCE CARDIAQUE", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var avgHr = manager.getGlobalAvgHr();
        var maxHr = manager.globalMaxHr;

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 65, 82, Theme.fValueMed as Graphics.FontType, (avgHr > 0) ? avgHr.toString() : "--", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_HEART_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 65, 82, Theme.fValueMed as Graphics.FontType, (maxHr > 0) ? maxHr.toString() : "--", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 65, 110, Theme.fLabel as Graphics.FontType, "MOY.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx + 65, 110, Theme.fLabel as Graphics.FontType, "MAX.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var totalZ = 0;
        for (var i = 0; i < 5; i++) {
            totalZ += manager.zoneSeconds[i];
        }
        if (totalZ <= 0) { totalZ = 1; }

        var startY = 148;
        var rowH = 38;
        for (var z = 4; z >= 0; z--) {
            var y = startY + ((4 - z) * rowH);
            var ratio = manager.zoneSeconds[z].toFloat() / totalZ.toFloat();
            var zColor = Theme.getZoneColor(z);

            dc.setColor(zColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(58, y, Theme.fSmall as Graphics.FontType, "Z" + (z + 1).toString(), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            drawProgressBar(dc, 94, y - 6, 172, 12, ratio, zColor);

            var pct = (ratio * 100.0f).toNumber();
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(334, y, Theme.fLabel as Graphics.FontType, pct.toString() + "%", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
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
