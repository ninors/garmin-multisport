import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class ActiveDataView extends WatchUi.View {
    public static const TOTAL_PAGES = 6;
    private var manager as MultisportManager;
    public var currentPage as Number;
    private var dotsVisibleUntilTick as Number;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
        currentPage = 0;
        dotsVisibleUntilTick = mgr.tickCount + 3;
    }

    // Safely transition back to PreStartView AFTER Confirmation dialog pops on Discard!
    function onShow() as Void {
        if (manager.state == MultisportManager.STATE_PRE_START) {
            var preView = new PreStartView(manager);
            var preDel = new PreStartDelegate(manager);
            WatchUi.switchToView(preView, preDel, WatchUi.SLIDE_RIGHT);
        }
    }

    public function nextPage() as Void {
        currentPage = (currentPage + 1) % TOTAL_PAGES;
        dotsVisibleUntilTick = manager.tickCount + 3;
        WatchUi.requestUpdate();
    }

    public function prevPage() as Void {
        currentPage = (currentPage - 1 + TOTAL_PAGES) % TOTAL_PAGES;
        dotsVisibleUntilTick = manager.tickCount + 3;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        if (currentPage == 0) {
            if (SportDefinitions.isTransition(manager.getCurrentSport())) {
                drawTransitionScreen(dc);
            } else {
                drawPage0MainFR965(dc);
            }
        } else if (currentPage == 1) {
            drawPage1SegmentDetail(dc);
        } else if (currentPage == 2) {
            drawPage2MultisportRecap(dc);
        } else if (currentPage == 3) {
            drawPage3GpsTrack(dc);
        } else if (currentPage == 4) {
            drawPage4ElevationProfile(dc);
        } else {
            drawPage5ClockBattery(dc);
        }

        // Left-edge pagination dots (auto-hide after 3 seconds until page changes)
        if (manager.tickCount <= dotsVisibleUntilTick) {
            GarminComponents.drawPaginationDots(dc, currentPage, TOTAL_PAGES);
        }

        // Lock icon indicator if locked
        if (manager.isLocked) {
            SportIcons.drawLockIcon(dc, 34, 195, Theme.COLOR_GPS_YELLOW);
        }

        // Pause red border
        if (manager.state == MultisportManager.STATE_PAUSED) {
            GarminComponents.drawPausedOverlay(dc);
        }

        // Native Garmin Full-Screen Action Overlays (Big Green Triangle, Red Square, Transitions, Laps)
        GarminComponents.drawGarminOverlay(dc, manager);
    }

    // SPECIAL NATIVE GARMIN TRANSITION SCREEN (Yellow theme + dynamic alignment + glowing LAP hint!)
    private function drawTransitionScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;
        var seg = manager.getCurrentSegment();
        var sport = seg.sportType;
        var transYellow = 0xFFCC00;

        // Top yellow transition header dynamically centered (ZERO icon overlap!)
        var tTitle = (sport == SportDefinitions.SPORT_TRANSITION_1) ? "TRANSITION 1" : "TRANSITION 2";
        var tW = dc.getTextWidthInPixels(tTitle, Graphics.FONT_XTINY);
        var tStartX = cx - ((32 + tW) / 2);
        SportIcons.drawSportIcon(dc, sport, tStartX + 12, 40, 14, transYellow);
        dc.setColor(transYellow, Graphics.COLOR_TRANSPARENT);
        dc.drawText(tStartX + 30, 40, Graphics.FONT_XTINY, tTitle, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Large crisp transition chrono
        GarminComponents.drawSuperscriptChrono(dc, seg.elapsedMs, cx, 88, Theme.COLOR_WHITE);

        // Signature Garmin Faded Yellow Dividers for Transitions
        GarminComponents.drawFadedHorizontalLine(dc, 132, 16, w - 16, 0xFFCC00, 0x886600, 0x332200);
        GarminComponents.drawFadedHorizontalLine(dc, 256, 16, w - 16, 0xFFCC00, 0x886600, 0x332200);
        dc.setColor(transYellow, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(cx, 132, cx, 256);

        var leftCx = (cx / 2) + 16;
        var rightCx = cx + (cx / 2) - 16;

        // Middle-Left: Cumulative Multisport Time since start (compact "TOTAL", zero clipping!)
        dc.setColor(transYellow, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, 156, Graphics.FONT_XTINY, "TOTAL", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, 206, Graphics.FONT_MEDIUM, SportDefinitions.formatTime(manager.totalElapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Middle-Right: Previous Completed Leg Recap
        var prevLabel = "PRÉCÉDENT";
        var prevVal = "--:--";
        if (manager.currentLegIndex > 0) {
            var prevSeg = manager.segments[manager.currentLegIndex - 1];
            prevLabel = SportDefinitions.getSportShortName(prevSeg.sportType);
            prevVal = SportDefinitions.formatTime(prevSeg.elapsedMs);
        }
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightCx, 156, Graphics.FONT_XTINY, prevLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightCx, 206, Graphics.FONT_MEDIUM, prevVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom: Next Sport preview dynamically centered (ZERO icon overlap!)
        var nextSp = manager.getNextSport();
        if (nextSp != null) {
            var nColor = SportDefinitions.getSportColor(nextSp as Number);
            var nName = SportDefinitions.getSportName(nextSp as Number).toUpper();
            var nW = dc.getTextWidthInPixels(nName, Graphics.FONT_SMALL);
            var nStartX = cx - ((34 + nW) / 2);
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 278, Graphics.FONT_XTINY, "SUIVANT", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            SportIcons.drawSportIcon(dc, nextSp as Number, nStartX + 12, 314, 14, nColor);
            dc.setColor(nColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(nStartX + 32, 314, Graphics.FONT_SMALL, nName, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Live HR at bottom
        var hrStr = (manager.heartRate > 30) ? (manager.heartRate.toString() + " bpm") : "--";
        dc.setColor(transYellow, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 354, Graphics.FONT_XTINY, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Native Garmin Glowing Blue/Cyan Bottom-Right Arc (332 deg = BACK/LAP button hint!)
        GarminComponents.drawActionGlowArc(dc, 332, 0xAAEEFF, 0x00CCFF, 0x004466);
    }

    // PAGE 0: Signature Forerunner 965 Main Screen (4 fields + Red T/Cross dividers + Bottom 5-zone HR arc)
    private function drawPage0MainFR965(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;
        var seg = manager.getCurrentSegment();
        var sport = seg.sportType;
        var sportColor = SportDefinitions.getSportColor(sport);

        // Top: Material SVG sport icon dynamically positioned to NEVER overlap text!
        var topField = manager.settings.getFieldTopForSport(sport);
        var topLabel = getDynamicFieldLabel(topField, seg);
        var topLblW = dc.getTextWidthInPixels(topLabel, Graphics.FONT_XTINY);
        var topGroupW = 32 + topLblW;
        var topStartX = cx - (topGroupW / 2);
        SportIcons.drawSportIcon(dc, sport, topStartX + 12, 36, 14, sportColor);
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(topStartX + 30, 36, Graphics.FONT_XTINY, topLabel, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        if (topField == SportDefinitions.FIELD_CHRONO) {
            GarminComponents.drawSuperscriptChrono(dc, seg.elapsedMs, cx, 84, Theme.COLOR_WHITE);
        } else {
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 84, Graphics.FONT_NUMBER_MEDIUM, manager.getFormattedFieldValue(topField), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Signature FR965 Faded Red Dividers (thick bright center fading to edges — exact Photo 4!)
        GarminComponents.drawFadedHorizontalLine(dc, 130, 14, w - 14, 0xFF0033, 0x88001A, 0x2A0008);
        GarminComponents.drawFadedHorizontalLine(dc, 256, 14, w - 14, 0xFF0033, 0x88001A, 0x2A0008);
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(cx, 130, cx, 256);

        // Middle 2 Columns: Dynamic unit in label so big numbers NEVER overflow!
        var leftField = manager.settings.getFieldLeftForSport(sport);
        var rightField = manager.settings.getFieldRightForSport(sport);

        var leftLabel = getDynamicFieldLabel(leftField, seg);
        var rightLabel = getDynamicFieldLabel(rightField, seg);
        var leftVal = manager.getFormattedFieldValue(leftField);
        var rightVal = manager.getFormattedFieldValue(rightField);

        var leftCx = (cx / 2) + 8;
        var rightCx = cx + (cx / 2) - 8;

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, 152, Graphics.FONT_XTINY, leftLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(rightCx, 152, Graphics.FONT_XTINY, rightLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, 206, Graphics.FONT_NUMBER_MILD, leftVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(rightCx, 206, Graphics.FONT_NUMBER_MILD, rightVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom: Zone-colored Heart + Big HR Value + 5-Zone HR Arc with live white pointer
        var zPos = manager.getHrZonePosition(manager.heartRate);
        var zIdx = manager.getHrZoneIndex(manager.heartRate);
        GarminComponents.drawBottomHrArc(dc, manager.heartRate, zPos, zIdx);
    }

    private function getDynamicFieldLabel(fieldId as Number, seg as SegmentData) as String {
        if (fieldId == SportDefinitions.FIELD_DISTANCE) {
            var unit = SportDefinitions.getDistanceUnit(seg.distanceMeters, SportDefinitions.isSwim(seg.sportType));
            return "DIST. " + unit;
        } else if (fieldId == SportDefinitions.FIELD_SPEED) {
            return "VIT. km/h";
        } else if (fieldId == SportDefinitions.FIELD_PACE) {
            return SportDefinitions.isSwim(seg.sportType) ? "ALL. /100" : "ALLURE";
        }
        return SportDefinitions.getFieldLabel(fieldId);
    }

    // PAGE 1: Detailed Current Segment / Lap Data (smooth faded lines + zero icon/text overlap!)
    private function drawPage1SegmentDetail(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;
        var seg = manager.getCurrentSegment();
        var sport = seg.sportType;
        var sportColor = SportDefinitions.getSportColor(sport);
        var isTrans = SportDefinitions.isTransition(sport);

        // Dynamically centered header (icon NEVER overlaps sport name!)
        var hdrText = SportDefinitions.getSportShortName(sport) + " T" + seg.lapCount.toString();
        var hdrW = dc.getTextWidthInPixels(hdrText, Graphics.FONT_TINY);
        var hdrGroupW = 34 + hdrW;
        var hdrStartX = cx - (hdrGroupW / 2);
        SportIcons.drawSportIcon(dc, sport, hdrStartX + 12, 48, 14, sportColor);
        dc.setColor(sportColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hdrStartX + 32, 48, Graphics.FONT_TINY, hdrText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Smooth Faded FR965 Dividers on ALL lines!
        if (isTrans) {
            GarminComponents.drawFadedHorizontalLine(dc, 82, 24, w - 24, 0xFFCC00, 0x886600, 0x332200);
            GarminComponents.drawFadedHorizontalLine(dc, 195, 14, w - 14, 0xFFCC00, 0x886600, 0x332200);
            GarminComponents.drawFadedHorizontalLine(dc, 308, 24, w - 24, 0xFFCC00, 0x886600, 0x332200);
            dc.setColor(0xFFCC00, Graphics.COLOR_TRANSPARENT);
        } else {
            GarminComponents.drawFadedHorizontalLine(dc, 82, 24, w - 24, 0xFF0033, 0x88001A, 0x2A0008);
            GarminComponents.drawFadedHorizontalLine(dc, 195, 14, w - 14, 0xFF0033, 0x88001A, 0x2A0008);
            GarminComponents.drawFadedHorizontalLine(dc, 308, 24, w - 24, 0xFF0033, 0x88001A, 0x2A0008);
            dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        }
        dc.setPenWidth(3);
        dc.drawLine(cx, 82, cx, 308);

        var lCx = (cx / 2) + 14;
        var rCx = cx + (cx / 2) - 14;

        // Top-Left: Segment Time
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 108, Graphics.FONT_XTINY, "TPS SEG.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 150, Graphics.FONT_MEDIUM, SportDefinitions.formatTime(seg.elapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Top-Right: Segment Distance (compact label, never clipped!)
        var distUnit = SportDefinitions.getDistanceUnit(seg.distanceMeters, SportDefinitions.isSwim(sport));
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 108, Graphics.FONT_XTINY, "DIST. " + distUnit, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 150, Graphics.FONT_MEDIUM, SportDefinitions.formatDistance(seg.distanceMeters, SportDefinitions.isSwim(sport)), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom-Left: Avg Pace / Avg Speed
        var avgLbl = SportDefinitions.isBike(sport) ? "VIT. MOY." : "ALL. MOY.";
        var avgVal = SportDefinitions.isBike(sport)
            ? (seg.getAvgSpeedKmh().format("%.1f"))
            : SportDefinitions.formatPaceSecPerUnit(seg.getAvgPaceSec());
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 222, Graphics.FONT_XTINY, avgLbl, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 266, Graphics.FONT_MEDIUM, avgVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom-Right: SWOLF (Swim) / Cadence
        var fourthLbl = "CADENCE";
        var fourthVal = (manager.cadence > 0) ? manager.cadence.toString() : "--";
        if (SportDefinitions.isSwim(sport)) {
            fourthLbl = "SWOLF";
            var sw = seg.getEstimatedSwolf(manager.settings.poolLengthMeters);
            fourthVal = (sw > 0) ? sw.toString() : "--";
        }
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 222, Graphics.FONT_XTINY, fourthLbl, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 266, Graphics.FONT_MEDIUM, fourthVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Footer: Current Lap Time
        var lapTime = SportDefinitions.formatTime(seg.elapsedMs - manager.lapStartElapsedMs);
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 338, Graphics.FONT_XTINY, "TOUR : " + lapTime, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // PAGE 2: Clean Native Garmin Multisport Total Recap (safe circular margins, zero clipping!)
    private function drawPage2MultisportRecap(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        // Compact header well inside the circular bezel
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 44, Graphics.FONT_XTINY, "TOTAL", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 78, Graphics.FONT_MEDIUM, SportDefinitions.formatTime(manager.totalElapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 108, Graphics.FONT_XTINY,
            SportDefinitions.formatDistance(manager.totalDistanceMeters, false) + " km",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        GarminComponents.drawFadedHorizontalLine(dc, 126, 36, w - 36, 0xFF0033, 0x88001A, 0x2A0008);

        // Clean leg rows centered inside circular safe zone (y = 148..324) — ZERO overlap!
        var maxRows = (manager.segments.size() > 5) ? 5 : manager.segments.size();
        var startY = 148;
        var rowH = 42;
        for (var i = 0; i < maxRows; i++) {
            var s = manager.segments[i];
            var y = startY + (i * rowH);
            var isCur = (i == manager.currentLegIndex);
            var sColor = SportDefinitions.getSportColor(s.sportType);
            var textColor = isCur ? sColor : (s.completed ? Theme.COLOR_WHITE : Theme.COLOR_DIM);

            // Crisp Material SVG icon
            SportIcons.drawSportIcon(dc, s.sportType, 62, y, 12, sColor);

            // Compact sport label (max 4 chars so time & dist never collide!)
            var shortLbl = getCompactLegLabel(s.sportType);
            dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(84, y, Graphics.FONT_XTINY, shortLbl, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            // Leg elapsed time (right-aligned at x = 228)
            var tStr = (s.completed || isCur) ? SportDefinitions.formatTime(s.elapsedMs) : "--:--";
            dc.drawText(228, y, Graphics.FONT_XTINY, tStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

            // Leg distance (right-aligned at x = 328, plenty of breathing room!)
            if (!SportDefinitions.isTransition(s.sportType)) {
                var u = SportDefinitions.getDistanceUnit(s.distanceMeters, SportDefinitions.isSwim(s.sportType));
                var dStr = SportDefinitions.formatDistance(s.distanceMeters, SportDefinitions.isSwim(s.sportType)) + (u.equals("m") ? "m" : "");
                dc.setColor(isCur ? Theme.COLOR_WHITE : Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
                dc.drawText(328, y, Graphics.FONT_XTINY, dStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }

    private function getCompactLegLabel(sport as Number) as String {
        switch (sport) {
            case SportDefinitions.SPORT_SWIM_OPEN:
            case SportDefinitions.SPORT_SWIM_POOL: return "Nage";
            case SportDefinitions.SPORT_TRANSITION_1: return "T1";
            case SportDefinitions.SPORT_BIKE: return "Vélo";
            case SportDefinitions.SPORT_TRANSITION_2: return "T2";
            case SportDefinitions.SPORT_RUN: return "Run";
            case SportDefinitions.SPORT_TRAIL: return "Trail";
            case SportDefinitions.SPORT_WALK: return "Marc.";
            default: return "Card.";
        }
    }

    // PAGE 3: Multi-Colored Live GPS Track Map (Blue=Swim, Yellow=Trans, Green=Bike, Red=Run)
    private function drawPage3GpsTrack(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // Subtle Garmin compass ring
        dc.setColor(Theme.COLOR_DARK_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, 134);
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 38, Graphics.FONT_XTINY, "N", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

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
            if (maxSpan < 0.0005f) {
                maxSpan = 0.0005f;
            }
            var midLat = (minLat + maxLat) / 2.0f;
            var midLon = (minLon + maxLon) / 2.0f;
            var scale = 196.0f / maxSpan;

            var prevX = cx + ((manager.trackLons[0] - midLon) * scale).toNumber();
            var prevY = cy - ((manager.trackLats[0] - midLat) * scale).toNumber();
            dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(prevX, prevY, 5);

            dc.setPenWidth(4);
            for (var j = 1; j < count; j++) {
                var px = cx + ((manager.trackLons[j] - midLon) * scale).toNumber();
                var py = cy - ((manager.trackLats[j] - midLat) * scale).toNumber();
                var ptSport = (j < manager.trackSports.size()) ? manager.trackSports[j] : manager.getCurrentSport();
                dc.setColor(getTrackColorForSport(ptSport), Graphics.COLOR_TRANSPARENT);
                dc.drawLine(prevX, prevY, px, py);
                prevX = px;
                prevY = py;
            }
            drawHeadingArrow(dc, prevX, prevY, manager.heading);

            // Dynamic scale bar (clean, NO legend)
            var metersPerPx = (maxSpan * 111000.0f) / 196.0f;
            var barMeters = (metersPerPx * 52.0f).toNumber();
            if (barMeters < 10) { barMeters = 10; }
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawLine(cx - 26, 344, cx + 26, 344);
            dc.drawLine(cx - 26, 339, cx - 26, 349);
            dc.drawLine(cx + 26, 339, cx + 26, 349);
            dc.drawText(cx, 326, Graphics.FONT_XTINY, barMeters.toString() + " m", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            drawHeadingArrow(dc, cx, cy, manager.heading);
        }
    }

    private function getTrackColorForSport(sport as Number) as Number {
        if (SportDefinitions.isSwim(sport)) {
            return 0x00AAFF; // Blue for Swim
        } else if (SportDefinitions.isBike(sport)) {
            return 0x00DD55; // Green for Bike
        } else if (SportDefinitions.isTransition(sport)) {
            return 0xFFCC00; // Yellow for Transition
        }
        return 0xFF2233; // Red for Run
    }

    private function drawHeadingArrow(dc as Dc, x as Number, y as Number, headingRad as Float) as Void {
        var sinH = Math.sin(headingRad);
        var cosH = Math.cos(headingRad);
        var tipX = x + (sinH * 14.0d).toNumber();
        var tipY = y - (cosH * 14.0d).toNumber();
        var leftX = x + (Math.sin(headingRad - 2.4d) * 10.0d).toNumber();
        var leftY = y - (Math.cos(headingRad - 2.4d) * 10.0d).toNumber();
        var rightX = x + (Math.sin(headingRad + 2.4d) * 10.0d).toNumber();
        var rightY = y - (Math.cos(headingRad + 2.4d) * 10.0d).toNumber();
        var pts = [[tipX, tipY], [leftX, leftY], [x, y], [rightX, rightY]] as Array<[Numeric, Numeric]>;
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(pts);
    }

    // PAGE 4: Native Garmin Elevation Profile Screen
    // Progressive left-to-right growth, NO right Y-axis, clean compact top altitude
    private function drawPage4ElevationProfile(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        // 1. Top center: Crisp green twin-mountain peak icon
        dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
        var mtn1 = [[cx - 14, 54], [cx - 3, 38], [cx + 8, 54]] as Array<[Numeric, Numeric]>;
        var mtn2 = [[cx - 1, 54], [cx + 8, 43], [cx + 16, 54]] as Array<[Numeric, Numeric]>;
        dc.fillPolygon(mtn1);
        dc.fillPolygon(mtn2);

        // 2. Clean medium-sized white Altitude value (e.g. "204")
        var altNum = manager.altitude.toNumber();
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 96, Graphics.FONT_NUMBER_MILD, altNum.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. Centered Elevation Graph box (NO right Y-axis, clean full width x: 56..334, y: 152..282)
        var gx = 56;
        var gw = w - 112;
        var gyTop = 152;
        var gyBot = 282;
        var gh = gyBot - gyTop;

        // Subtle horizontal reference grid lines
        dc.setColor(0x202020, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(gx, gyTop, gx + gw, gyTop);
        dc.drawLine(gx, gyTop + (gh / 2), gx + gw, gyTop + (gh / 2));

        var count = manager.altHistory.size();
        if (count >= 1) {
            var minA = manager.altHistory[0];
            var maxA = minA;
            var minIdx = 0;
            var maxIdx = 0;
            for (var i = 1; i < count; i++) {
                var a = manager.altHistory[i];
                if (a < minA) { minA = a; minIdx = i; }
                if (a > maxA) { maxA = a; maxIdx = i; }
            }
            var span = maxA - minA;
            if (span < 10.0f) { span = 10.0f; }

            // Progressive left-to-right growth: starts from left edge point-by-point
            // instead of stretching 2 points across the whole screen!
            var denom = (count < 24) ? 23.0f : (count - 1).toFloat();

            var prevX = gx;
            var prevY = gyBot - (((manager.altHistory[0] - minA) / span) * gh.toFloat()).toNumber();
            var maxPx = prevX;
            var maxPy = prevY;
            var minPx = prevX;
            var minPy = prevY;

            for (var j = 1; j < count; j++) {
                var px = gx + ((j.toFloat() / denom) * gw.toFloat()).toNumber();
                var py = gyBot - (((manager.altHistory[j] - minA) / span) * gh.toFloat()).toNumber();
                if (j == maxIdx) { maxPx = px; maxPy = py; }
                if (j == minIdx) { minPx = px; minPy = py; }

                var quad = [
                    [prevX, prevY],
                    [px, py],
                    [px, gyBot],
                    [prevX, gyBot]
                ] as Array<[Numeric, Numeric]>;
                dc.setColor(0x002E12, Graphics.COLOR_TRANSPARENT);
                dc.fillPolygon(quad);

                dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(3);
                dc.drawLine(prevX, prevY, px, py);
                prevX = px;
                prevY = py;
            }

            // Bright white dot at the latest point
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(prevX, prevY, 4);

            // Show high/low labels once curve has meaningful vertical spread
            if (count >= 3 && (maxA - minA) >= 3.0f) {
                dc.drawText(maxPx, maxPy + 14, Graphics.FONT_XTINY, maxA.toNumber().toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.drawText(minPx, minPy - 14, Graphics.FONT_XTINY, minA.toNumber().toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // 4. Horizontal bottom axis line with 4 tick marks
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(gx, gyBot, gx + gw, gyBot);
        for (var tk = 0; tk <= 4; tk++) {
            var tx = gx + ((gw * tk) / 4);
            dc.drawLine(tx, gyBot - 4, tx, gyBot + 4);
        }

        // 5. Bottom center: Elapsed time (e.g. "1:21:13")
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 320, Graphics.FONT_SMALL, SportDefinitions.formatTime(manager.totalElapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // PAGE 5: Pure Minimalist Native Garmin Clock & Battery on Pure Black
    private function drawPage5ClockBattery(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;

        var clock = System.getClockTime();
        var timeStr = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        var secStr = clock.sec.format("%02d");

        // Huge centered clock on pure black
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 178, Graphics.FONT_NUMBER_THAI_HOT, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Crisp seconds cleanly below clock (zero overlap!)
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 240, Graphics.FONT_SMALL, secStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Clean Battery Gauge + Percentage
        var stats = System.getSystemStats();
        var batt = stats.battery.toNumber();
        var battStr = batt.toString() + "%";
        var textW = dc.getTextWidthInPixels(battStr, Graphics.FONT_SMALL);
        var totalW = 36 + 10 + textW;
        var startX = cx - (totalW / 2);

        SportIcons.drawBatteryIcon(dc, startX, 294, 34, 18, batt);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + 44, 303, Graphics.FONT_SMALL, battStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// Uses WatchUi.InputDelegate directly so screen taps NEVER pause/start/change sport!
// Touch is ONLY allowed for vertical swipe to scroll data screens.
class ActiveDataDelegate extends WatchUi.InputDelegate {
    private var manager as MultisportManager;
    private var view as ActiveDataView;

    function initialize(mgr as MultisportManager, v as ActiveDataView) {
        InputDelegate.initialize();
        manager = mgr;
        view = v;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_LIGHT) {
            manager.isLocked = !manager.isLocked;
            manager.showAlert(manager.isLocked ? "VERROUILLÉ" : "DÉVERROUILLÉ", "", 2);
            WatchUi.requestUpdate();
            return true;
        }
        if (k == WatchUi.KEY_ENTER) {
            // Physical START/STOP -> Pause & Open PauseMenu
            if (manager.isLocked) {
                manager.showAlert("VERROUILLÉ", "Appui LIGHT", 2);
                WatchUi.requestUpdate();
                return true;
            }
            if (manager.state == MultisportManager.STATE_ACTIVE) {
                manager.togglePause();
            }
            PauseMenu.push(manager);
            return true;
        } else if (k == WatchUi.KEY_ESC) {
            // Physical BACK/LAP -> Next segment / transition
            if (manager.isLocked) {
                manager.showAlert("VERROUILLÉ", "Appui LIGHT", 2);
                WatchUi.requestUpdate();
                return true;
            }
            var finished = manager.nextSegment();
            if (finished) {
                var evalView = new FeelEvalView(manager);
                WatchUi.switchToView(evalView, new FeelEvalDelegate(manager, evalView), WatchUi.SLIDE_LEFT);
            } else {
                WatchUi.requestUpdate();
            }
            return true;
        } else if (k == WatchUi.KEY_DOWN) {
            view.nextPage();
            return true;
        } else if (k == WatchUi.KEY_UP) {
            view.prevPage();
            return true;
        } else if (k == WatchUi.KEY_MENU) {
            if (!manager.isLocked) {
                MainSettingsMenu.push(manager);
            }
            return true;
        }
        return false;
    }

    // Long-press UP (HOLD on KEY_UP) opens Settings on devices that fire onHold/KEY_MENU
    function onHold(evt as WatchUi.ClickEvent) as Boolean {
        return true;
    }

    // Block ALL screen taps (never pauses, starts, or changes sport on touch!)
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return true;
    }

    // Touch swipe: ONLY vertical swipe allowed to scroll data screens
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        if (manager.isLocked) {
            return true;
        }
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            view.nextPage();
        } else if (dir == WatchUi.SWIPE_DOWN) {
            view.prevPage();
        }
        return true;
    }
}
