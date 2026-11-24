import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SummaryView extends WatchUi.View {
    public static const TOTAL_PAGES = 4;
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
            drawOverviewPageFR965(dc);
        } else if (page == 1) {
            drawSegmentsPage(dc);
        } else if (page == 2) {
            drawHeartRateZonesPageFR965(dc);
        } else {
            drawTrainingEffectPage(dc);
        }

        GarminComponents.drawPaginationDots(dc, page, TOTAL_PAGES);
    }

    // PAGE 0: EXACT Official Garmin Forerunner 965 Multisport Summary (Photo 3!)
    // Top: 3 rings | Middle: Huge white Total Time | Lower: Mini multi-color GPS track + km / kcal | Bottom: — ÉTAPES —
    private function drawOverviewPageFR965(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;

        // 1. Top center: 3 overlapping Garmin Multisport rings (Red, Blue, Green)
        GarminComponents.drawMultisportRings(dc, cx, 62, 16);

        // 2. Huge Pure White Total Time across center
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 146, Graphics.FONT_NUMBER_HOT, SportDefinitions.formatTime(manager.totalElapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. Lower-Left: Miniature Multi-Colored GPS Route Preview (Blue/Green/Red)
        drawMiniRoutePreview(dc, 62, 204, 114, 82);

        // 4. Lower-Right: Stacked Distance (km) & Calories (kcal)
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(202, 224, Graphics.FONT_SMALL, SportDefinitions.formatDistance(manager.totalDistanceMeters, false) + " km", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(202, 266, Graphics.FONT_SMALL, manager.totalCalories.toString() + " kcal", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 5. Bottom FR965 Section Hint: — ÉTAPES —
        drawFooterHint(dc, "ÉTAPES");
    }

    private function drawMiniRoutePreview(dc as Dc, rx as Number, ry as Number, rw as Number, rh as Number) as Void {
        var count = manager.trackLats.size();
        if (count >= 2) {
            var minLat = manager.trackLats[0];
            var maxLat = minLat;
            var minLon = manager.trackLons[0];
            var maxLon = minLon;
            for (var i = 1; i < count; i++) {
                var la = manager.trackLats[i];
                var lo = manager.trackLons[i];
                if (la < minLat) { minLat = la; }
                if (la > maxLat) { maxLat = la; }
                if (lo < minLon) { minLon = lo; }
                if (lo > maxLon) { maxLon = lo; }
            }
            var spanLat = maxLat - minLat;
            var spanLon = maxLon - minLon;
            var maxSpan = (spanLat > spanLon) ? spanLat : spanLon;
            if (maxSpan < 0.0004f) { maxSpan = 0.0004f; }
            var midLat = (minLat + maxLat) / 2.0f;
            var midLon = (minLon + maxLon) / 2.0f;
            var scale = (rh.toFloat() * 0.85f) / maxSpan;
            var mcx = rx + (rw / 2);
            var mcy = ry + (rh / 2);

            var prevX = mcx + ((manager.trackLons[0] - midLon) * scale).toNumber();
            var prevY = mcy - ((manager.trackLats[0] - midLat) * scale).toNumber();
            dc.setPenWidth(4);
            for (var j = 1; j < count; j++) {
                var px = mcx + ((manager.trackLons[j] - midLon) * scale).toNumber();
                var py = mcy - ((manager.trackLats[j] - midLat) * scale).toNumber();
                var sp = (j < manager.trackSports.size()) ? manager.trackSports[j] : SportDefinitions.SPORT_RUN;
                var col = SportDefinitions.isSwim(sp) ? 0x00AAFF : (SportDefinitions.isBike(sp) ? 0x00DD55 : (SportDefinitions.isTransition(sp) ? 0xFFCC00 : 0xFF2233));
                dc.setColor(col, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(prevX, prevY, px, py);
                prevX = px;
                prevY = py;
            }
        } else {
            // Clean stylized mini multisport loop silhouette when indoor/no GPS
            var mcx = rx + (rw / 2);
            var mcy = ry + (rh / 2);
            dc.setPenWidth(4);
            dc.setColor(0x00AAFF, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(mcx - 36, mcy - 8, mcx - 10, mcy - 8);
            dc.setColor(0x00DD55, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(mcx + 8, mcy, 24, Graphics.ARC_CLOCKWISE, 140, 260);
            dc.setColor(0xFF2233, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(mcx - 10, mcy + 20, mcx - 34, mcy + 4);
        }
    }

    // PAGE 1: ÉTAPES (Per-Segment Breakdown — clean spacing, zero overlap!)
    private function drawSegmentsPage(dc as Dc) as Void {
        drawTopHeader(dc, "ÉTAPES", 0x00AAFF);

        var count = manager.segments.size();
        if (count > 5) { count = 5; }
        var startY = 98;
        var rowH = 46;

        for (var i = 0; i < count; i++) {
            var seg = manager.segments[i];
            var y = startY + (i * rowH);
            var sColor = SportDefinitions.getSportColor(seg.sportType);

            SportIcons.drawSportIcon(dc, seg.sportType, 58, y, 12, sColor);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(82, y - 9, Graphics.FONT_XTINY, SportDefinitions.getSportName(seg.sportType), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            var sub = "Transition";
            if (!SportDefinitions.isTransition(seg.sportType)) {
                var u = SportDefinitions.getDistanceUnit(seg.distanceMeters, SportDefinitions.isSwim(seg.sportType));
                var hrPart = (seg.getAvgHeartRate() > 0) ? (" • " + seg.getAvgHeartRate().toString()) : "";
                sub = SportDefinitions.formatDistance(seg.distanceMeters, SportDefinitions.isSwim(seg.sportType)) + u + hrPart;
            }
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(82, y + 11, Graphics.FONT_XTINY, sub, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(sColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(334, y, Graphics.FONT_XTINY, SportDefinitions.formatTime(seg.elapsedMs), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        drawFooterHint(dc, "ZONES FC");
    }

    // PAGE 2: EXACT Official Garmin Forerunner 965 Zones Screen (Photo 2!)
    // Left: 5 vertical colored bars + huge Avg HR + FC MOY. | Right: 5 rows (Time | colored tick | %)
    private function drawHeartRateZonesPageFR965(dc as Dc) as Void {
        drawTopHeader(dc, "ZONES FC", 0x00AAFF);

        var totalZ = 0;
        var maxSec = 1;
        for (var i = 0; i < 5; i++) {
            totalZ += manager.zoneSeconds[i];
            if (manager.zoneSeconds[i] > maxSec) {
                maxSec = manager.zoneSeconds[i];
            }
        }
        if (totalZ <= 0) { totalZ = 1; }

        // LEFT SIDE: 5 Vertical Bar Columns (Z1 Gray .. Z5 Red) rising from y = 186
        var baseY = 186;
        var maxBarH = 82;
        var barW = 18;
        var barGap = 6;
        var leftStartX = 56;

        for (var b = 0; b < 5; b++) {
            var bx = leftStartX + (b * (barW + barGap));
            var bh = ((manager.zoneSeconds[b].toFloat() / maxSec.toFloat()) * maxBarH.toFloat()).toNumber();
            if (bh < 8) { bh = 8; }
            dc.setColor(Theme.getZoneColor(b), Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(bx, baseY - bh, barW, bh, 3);
        }

        // Huge Avg HR directly beneath the 5 vertical bars
        var avgHr = manager.getGlobalAvgHr();
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(114, 234, Graphics.FONT_NUMBER_MILD, (avgHr > 0) ? avgHr.toString() : "--", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(114, 274, Graphics.FONT_XTINY, "FC MOY.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // RIGHT SIDE: 5 Stacked Rows (Z5 top -> Z1 bottom): Time | Vertical Colored Bar | %
        var rowStartY = 114;
        var rowStep = 38;
        var barCenterX = 266;

        for (var z = 4; z >= 0; z--) {
            var ry = rowStartY + ((4 - z) * rowStep);
            var secs = manager.zoneSeconds[z];
            var pct = ((secs.toFloat() / totalZ.toFloat()) * 100.0f).toNumber();
            var zColor = Theme.getZoneColor(z);

            // Time right-aligned to the left of the colored bar
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barCenterX - 12, ry, Graphics.FONT_XTINY, SportDefinitions.formatTime(secs * 1000), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

            // Crisp vertical colored zone tick "|"
            dc.setColor(zColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barCenterX - 2, ry - 11, 5, 22, 2);

            // Percentage left-aligned to the right of the colored bar
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barCenterX + 12, ry, Graphics.FONT_XTINY, pct.toString() + "%", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        drawFooterHint(dc, "TRAINING EFFECT");
    }

    // PAGE 3: Dedicated Training Effect & Max HR Screen
    private function drawTrainingEffectPage(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        drawTopHeader(dc, "TRAINING EFFECT", 0x00AAFF);

        var aero = manager.getAerobicTrainingEffect();
        var ana = manager.getAnaerobicTrainingEffect();

        // Aerobic gauge
        dc.setColor(0x0099FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(66, 128, Graphics.FONT_TINY, "Aérobie", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(324, 128, Graphics.FONT_MEDIUM, aero.format("%.1f"), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawProgressBar(dc, 66, 152, 258, 12, aero / 5.0f, 0x0099FF);

        // Anaerobic gauge
        dc.setColor(0xAA44FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(66, 206, Graphics.FONT_TINY, "Anaérobie", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(324, 206, Graphics.FONT_MEDIUM, ana.format("%.1f"), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawProgressBar(dc, 66, 230, 258, 12, ana / 5.0f, 0xAA44FF);

        // Max HR & Ascent summary
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        var maxHrStr = (manager.globalMaxHr > 0) ? (manager.globalMaxHr.toString() + " bpm") : "--";
        dc.drawText(cx, 286, Graphics.FONT_XTINY, "FC Max : " + maxHrStr + "  •  D+ " + manager.totalAscent.toNumber().toString() + "m", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 336, Graphics.FONT_XTINY, "START : Terminer", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Native FR965 Top Header with flanking accent dashes: — TITLE —
    private function drawTopHeader(dc as Dc, title as String, accentColor as Number) as Void {
        var cx = dc.getWidth() / 2;
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 50, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var tw = dc.getTextWidthInPixels(title, Graphics.FONT_XTINY);
        var dashGap = (tw / 2) + 12;
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - dashGap - 22, 50, cx - dashGap, 50);
        dc.drawLine(cx + dashGap, 50, cx + dashGap + 22, 50);
    }

    // Native FR965 Bottom Section Hint: — NEXT —
    private function drawFooterHint(dc as Dc, label as String) as Void {
        var cx = dc.getWidth() / 2;
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 338, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var tw = dc.getTextWidthInPixels(label, Graphics.FONT_XTINY);
        var dashGap = (tw / 2) + 12;
        dc.setColor(Theme.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - dashGap - 18, 338, cx - dashGap, 338);
        dc.drawLine(cx + dashGap, 338, cx + dashGap + 18, 338);
    }

    private function drawProgressBar(dc as Dc, x as Number, y as Number, w as Number, h as Number, ratio as Float, color as Number) as Void {
        if (ratio < 0.0f) { ratio = 0.0f; }
        if (ratio > 1.0f) { ratio = 1.0f; }
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
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
