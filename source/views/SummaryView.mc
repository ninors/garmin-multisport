import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SummaryView extends WatchUi.View {
    private var manager as MultisportManager;
    public var page as Number;
    private var dotsVisibleUntilTick as Number;
    private var sportLegIndices as Array<Number>;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
        page = 0;
        dotsVisibleUntilTick = mgr.tickCount + 3;

        // Collect non-transition sport segments for dedicated section-by-section summary pages!
        sportLegIndices = [] as Array<Number>;
        for (var i = 0; i < mgr.segments.size(); i++) {
            if (!SportDefinitions.isTransition(mgr.segments[i].sportType)) {
                sportLegIndices.add(i);
            }
        }
    }

    public function getTotalPages() as Number {
        // Page 0: Overview, Page 1: Étapes, Page 2: Zones FC, Pages 3+: 1 card per Sport!
        return 3 + sportLegIndices.size();
    }

    public function nextPage() as Void {
        page = (page + 1) % getTotalPages();
        dotsVisibleUntilTick = manager.tickCount + 3;
        WatchUi.requestUpdate();
    }

    public function prevPage() as Void {
        var total = getTotalPages();
        page = (page - 1 + total) % total;
        dotsVisibleUntilTick = manager.tickCount + 3;
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
            var sportIdx = page - 3;
            if (sportIdx >= 0 && sportIdx < sportLegIndices.size()) {
                drawSportSectionPage(dc, sportLegIndices[sportIdx], sportIdx < sportLegIndices.size() - 1);
            }
        }

        // Native Garmin Glowing Cyan START Arc at Top-Right (28 deg) — press START to finish!
        GarminComponents.drawActionGlowArc(dc, 28, 0xAAEEFF, 0x00CCFF, 0x004466);

        if (manager.tickCount <= dotsVisibleUntilTick) {
            GarminComponents.drawPaginationDots(dc, page, getTotalPages());
        }
    }

    // PAGE 0: EXACT Official Garmin Forerunner 965 Multisport Summary
    private function drawOverviewPageFR965(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;

        GarminComponents.drawMultisportRings(dc, cx, 62, 16);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 146, Graphics.FONT_NUMBER_HOT, SportDefinitions.formatTime(manager.totalElapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawMiniRoutePreview(dc, 62, 204, 114, 82);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(202, 224, Graphics.FONT_SMALL, SportDefinitions.formatDistance(manager.totalDistanceMeters, false) + " km", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(202, 266, Graphics.FONT_SMALL, manager.totalCalories.toString() + " kcal", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

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

    // PAGE 1: ÉTAPES (Clean, spacious single-line per leg — zero crowding!)
    private function drawSegmentsPage(dc as Dc) as Void {
        drawTopHeader(dc, "ÉTAPES", 0x00AAFF);

        var count = manager.segments.size();
        if (count > 5) { count = 5; }
        var startY = 104;
        var rowH = 44;

        for (var i = 0; i < count; i++) {
            var seg = manager.segments[i];
            var y = startY + (i * rowH);
            var sColor = SportDefinitions.getSportColor(seg.sportType);

            SportIcons.drawSportIcon(dc, seg.sportType, 68, y, 13, sColor);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(96, y, Graphics.FONT_TINY, SportDefinitions.getSportName(seg.sportType), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(sColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(324, y, Graphics.FONT_TINY, SportDefinitions.formatTime(seg.elapsedMs), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        drawFooterHint(dc, "ZONES FC");
    }

    // PAGE 2: EXACT Official Garmin Forerunner 965 Zones Screen
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

        var avgHr = manager.getGlobalAvgHr();
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(114, 234, Graphics.FONT_NUMBER_MILD, (avgHr > 0) ? avgHr.toString() : "--", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(114, 274, Graphics.FONT_XTINY, "FC MOY.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var rowStartY = 114;
        var rowStep = 38;
        var barCenterX = 266;

        for (var z = 4; z >= 0; z--) {
            var ry = rowStartY + ((4 - z) * rowStep);
            var secs = manager.zoneSeconds[z];
            var pct = ((secs.toFloat() / totalZ.toFloat()) * 100.0f).toNumber();
            var zColor = Theme.getZoneColor(z);

            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barCenterX - 12, ry, Graphics.FONT_XTINY, SportDefinitions.formatTime(secs * 1000), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(zColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barCenterX - 2, ry - 11, 5, 22, 2);

            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(barCenterX + 12, ry, Graphics.FONT_XTINY, pct.toString() + "%", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        var nextHint = (sportLegIndices.size() > 0)
            ? SportDefinitions.getSportShortName(manager.segments[sportLegIndices[0]].sportType)
            : "TERMINER";
        drawFooterHint(dc, nextHint);
    }

    // PAGES 3+: Dedicated Section-by-Section General Summary per Sport (replaces Training Effect!)
    private function drawSportSectionPage(dc as Dc, segIndex as Number, hasNext as Boolean) as Void {
        var w = dc.getWidth();
        var cx = w / 2;
        var seg = manager.segments[segIndex];
        var sport = seg.sportType;
        var sColor = SportDefinitions.getSportColor(sport);

        // Top Header with Sport Icon + Sport Name
        var title = SportDefinitions.getSportName(sport).toUpper();
        var tw = dc.getTextWidthInPixels(title, Graphics.FONT_XTINY);
        var startX = cx - ((32 + tw) / 2);
        SportIcons.drawSportIcon(dc, sport, startX + 12, 48, 14, sColor);
        dc.setColor(sColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + 30, 48, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Large Sport Elapsed Time
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 96, Graphics.FONT_NUMBER_MILD, SportDefinitions.formatTime(seg.elapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Faded Divider
        GarminComponents.drawFadedHorizontalLine(dc, 134, 32, w - 32, sColor, 0x444444, 0x181818);

        // 2x2 General Stats Grid for this Sport
        var lCx = (cx / 2) + 14;
        var rCx = cx + (cx / 2) - 14;

        // Row 1: Distance | Avg Pace or Speed
        var u = SportDefinitions.getDistanceUnit(seg.distanceMeters, SportDefinitions.isSwim(sport));
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 158, Graphics.FONT_XTINY, "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 188, Graphics.FONT_SMALL, SportDefinitions.formatDistance(seg.distanceMeters, SportDefinitions.isSwim(sport)) + " " + u, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var paceLbl = SportDefinitions.isBike(sport) ? "VIT. MOY." : "ALL. MOY.";
        var paceVal = SportDefinitions.isBike(sport)
            ? (seg.getAvgSpeedKmh().format("%.1f") + " km/h")
            : SportDefinitions.formatPaceSecPerUnit(seg.getAvgPaceSec());
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 158, Graphics.FONT_XTINY, paceLbl, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 188, Graphics.FONT_SMALL, paceVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Row 2: Avg/Max HR | Cadence / SWOLF / Calories
        var avgHr = seg.getAvgHeartRate();
        var hrStr = (avgHr > 0) ? (avgHr.toString() + " / " + seg.maxHeartRate.toString()) : "--";
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 232, Graphics.FONT_XTINY, "FC MOY/MAX", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_HEART_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 262, Graphics.FONT_SMALL, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var metricLbl = "CALORIES";
        var metricVal = seg.calories.toString() + " kcal";
        if (SportDefinitions.isSwim(sport)) {
            var sw = seg.getEstimatedSwolf(manager.settings.poolLengthMeters);
            if (sw > 0) {
                metricLbl = "SWOLF";
                metricVal = sw.toString();
            }
        } else if (seg.getAvgCadence() > 0) {
            metricLbl = "CADENCE";
            metricVal = seg.getAvgCadence().toString();
        }
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 232, Graphics.FONT_XTINY, metricLbl, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 262, Graphics.FONT_SMALL, metricVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (hasNext) {
            var nextSeg = manager.segments[sportLegIndices[page - 2]];
            drawFooterHint(dc, SportDefinitions.getSportShortName(nextSeg.sportType));
        } else {
            drawFooterHint(dc, "TERMINER");
        }
    }

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
}

class SummaryDelegate extends WatchUi.InputDelegate {
    private var manager as MultisportManager;
    private var view as SummaryView;

    function initialize(mgr as MultisportManager, v as SummaryView) {
        InputDelegate.initialize();
        manager = mgr;
        view = v;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_DOWN) {
            slideToPage((view.page + 1) % view.getTotalPages(), WatchUi.SLIDE_UP);
            return true;
        } else if (k == WatchUi.KEY_UP) {
            var tot = view.getTotalPages();
            slideToPage((view.page - 1 + tot) % tot, WatchUi.SLIDE_DOWN);
            return true;
        } else if (k == WatchUi.KEY_MENU) {
            MainSettingsMenu.push(manager);
            return true;
        } else if (k == WatchUi.KEY_ENTER || k == WatchUi.KEY_ESC) {
            // Activity is ALREADY saved in all cases: physical START or BACK cleanly returns to Pre-Start
            manager.resetToPreStart();
            var preView = new PreStartView(manager);
            var preDel = new PreStartDelegate(manager);
            WatchUi.switchToView(preView, preDel, WatchUi.SLIDE_RIGHT);
            return true;
        }
        return false;
    }

    private function slideToPage(targetPage as Number, transition as WatchUi.SlideType) as Void {
        var nextV = new SummaryView(manager);
        nextV.page = targetPage;
        WatchUi.switchToView(nextV, new SummaryDelegate(manager, nextV), transition);
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            slideToPage((view.page + 1) % view.getTotalPages(), WatchUi.SLIDE_UP);
        } else if (dir == WatchUi.SWIPE_DOWN) {
            var tot = view.getTotalPages();
            slideToPage((view.page - 1 + tot) % tot, WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}
