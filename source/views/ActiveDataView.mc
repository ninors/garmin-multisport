import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class ActiveDataView extends WatchUi.View {
    public static const TOTAL_PAGES = 5;
    private var manager as MultisportManager;
    public var currentPage as Number;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
        currentPage = 0;
    }

    public function nextPage() as Void {
        currentPage = (currentPage + 1) % TOTAL_PAGES;
        WatchUi.requestUpdate();
    }

    public function prevPage() as Void {
        currentPage = (currentPage - 1 + TOTAL_PAGES) % TOTAL_PAGES;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        if (currentPage == 0) {
            drawPage0MainFR965(dc);
        } else if (currentPage == 1) {
            drawPage1SegmentDetail(dc);
        } else if (currentPage == 2) {
            drawPage2MultisportRecap(dc);
        } else if (currentPage == 3) {
            drawPage3GpsTrack(dc);
        } else {
            drawPage4ClockBattery(dc);
        }

        // Right-edge pagination dots
        GarminComponents.drawPaginationDots(dc, currentPage, TOTAL_PAGES);

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

    // PAGE 0: Signature Forerunner 965 Main Screen (4 fields + Red T/Cross dividers + Bottom 5-zone HR arc)
    private function drawPage0MainFR965(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;
        var seg = manager.getCurrentSegment();
        var sport = seg.sportType;
        var sportColor = SportDefinitions.getSportColor(sport);

        // Top: Label "CHRONO" (or Transition badge) + Superscript Hours Chrono
        var topLabel = SportDefinitions.isTransition(sport)
            ? ("TRANSITION " + SportDefinitions.getSportShortName(sport))
            : "CHRONO";
        dc.setColor(SportDefinitions.isTransition(sport) ? Theme.COLOR_GREEN_RING : Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 34, Theme.fLabel as Graphics.FontType, topLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Small sport dot next to label
        SportIcons.drawSportIcon(dc, sport, cx - 72, 34, 10, sportColor);

        // Huge Chrono with superscript hours (e.g. ¹08:20)
        GarminComponents.drawSuperscriptChrono(dc, seg.elapsedMs, cx, 84, Theme.COLOR_WHITE);

        // Signature FR965 Thin Red Dividers (#FF0033) in T + Cross shape
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(14, 130, w - 14, 130);
        dc.drawLine(14, 258, w - 14, 258);
        dc.drawLine(cx, 130, cx, 258);

        // Middle 2 Columns: Customizable per sport (Left: DISTANCE, Right: ALLURE / VITESSE / PUISSANCE)
        var leftField = manager.settings.getFieldLeftForSport(sport);
        var rightField = manager.settings.getFieldRightForSport(sport);
        if (SportDefinitions.isTransition(sport)) {
            leftField = SportDefinitions.FIELD_TOTAL_TIME;
            rightField = SportDefinitions.FIELD_DISTANCE;
        }

        var leftLabel = SportDefinitions.getFieldLabel(leftField);
        var rightLabel = SportDefinitions.getFieldLabel(rightField);
        var leftVal = manager.getFormattedFieldValue(leftField);
        var rightVal = manager.getFormattedFieldValue(rightField);

        var leftCx = cx / 2 + 4;
        var rightCx = cx + (cx / 2) - 4;

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, 154, Theme.fLabel as Graphics.FontType, leftLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(rightCx, 154, Theme.fLabel as Graphics.FontType, rightLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCx, 208, Theme.fValueBig as Graphics.FontType, leftVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(rightCx, 208, Theme.fValueBig as Graphics.FontType, rightVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom: Zone-colored Heart + Big HR Value + 5-Zone HR Arc with live white pointer
        var zPos = manager.getHrZonePosition(manager.heartRate);
        var zIdx = manager.getHrZoneIndex(manager.heartRate);
        GarminComponents.drawBottomHrArc(dc, manager.heartRate, zPos, zIdx);
    }

    // PAGE 1: Detailed Current Segment / Lap Data
    private function drawPage1SegmentDetail(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;
        var seg = manager.getCurrentSegment();
        var sport = seg.sportType;
        var sportColor = SportDefinitions.getSportColor(sport);

        // Header: Sport Icon + Name + Lap #
        SportIcons.drawSportIcon(dc, sport, cx - 64, 48, 13, sportColor);
        dc.setColor(sportColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 12, 48, Theme.fMedium as Graphics.FontType,
            SportDefinitions.getSportShortName(sport) + " T" + seg.lapCount.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Red Cross Grid
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(24, 82, w - 24, 82);
        dc.drawLine(14, 195, w - 14, 195);
        dc.drawLine(24, 308, w - 24, 308);
        dc.drawLine(cx, 82, cx, 308);

        var lCx = cx / 2 + 6;
        var rCx = cx + (cx / 2) - 6;

        // Top-Left: Segment Time
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 106, Theme.fLabel as Graphics.FontType, "TPS SEG.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 148, Theme.fValueMed as Graphics.FontType, SportDefinitions.formatTime(seg.elapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Top-Right: Segment Distance
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 106, Theme.fLabel as Graphics.FontType, "DIST SEG.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 148, Theme.fValueMed as Graphics.FontType, SportDefinitions.formatDistance(seg.distanceMeters, SportDefinitions.isSwim(sport)), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom-Left: Avg Pace / Avg Speed
        var avgLbl = SportDefinitions.isBike(sport) ? "VIT. MOY." : "ALL. MOY.";
        var avgVal = SportDefinitions.isBike(sport)
            ? (seg.getAvgSpeedKmh().format("%.1f"))
            : SportDefinitions.formatPaceSecPerUnit(seg.getAvgPaceSec());
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 220, Theme.fLabel as Graphics.FontType, avgLbl, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 264, Theme.fValueMed as Graphics.FontType, avgVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom-Right: SWOLF (Swim) / Power (Bike if >0) / Cadence
        var fourthLbl = "CADENCE";
        var fourthVal = (manager.cadence > 0) ? manager.cadence.toString() : "--";
        if (SportDefinitions.isSwim(sport)) {
            fourthLbl = "SWOLF";
            var sw = seg.getEstimatedSwolf(manager.settings.poolLengthMeters);
            fourthVal = (sw > 0) ? sw.toString() : "--";
        } else if (SportDefinitions.isBike(sport) && manager.power > 0) {
            fourthLbl = "PUISSANCE";
            fourthVal = manager.power.toString() + "W";
        }
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 220, Theme.fLabel as Graphics.FontType, fourthLbl, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 264, Theme.fValueMed as Graphics.FontType, fourthVal, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Footer: Current Lap Time
        var lapTime = SportDefinitions.formatTime(seg.elapsedMs - manager.lapStartElapsedMs);
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 336, Theme.fSmall as Graphics.FontType, "TOUR : " + lapTime, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // PAGE 2: Cumulative Multisport Summary
    private function drawPage2MultisportRecap(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        // Global Total Header
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 36, Theme.fLabel as Graphics.FontType, "MULTISPORT TOTAL", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 74, Theme.fValueMed as Graphics.FontType, SportDefinitions.formatTime(manager.totalElapsedMs), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 108, Theme.fSmall as Graphics.FontType,
            SportDefinitions.formatDistance(manager.totalDistanceMeters, false) + " km  •  " + manager.totalCalories.toString() + " kcal",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(34, 128, w - 34, 128);

        // Segment breakdown rows (up to 5 legs)
        var maxRows = (manager.segments.size() > 5) ? 5 : manager.segments.size();
        var startY = 152;
        var rowH = 40;
        for (var i = 0; i < maxRows; i++) {
            var s = manager.segments[i];
            var y = startY + (i * rowH);
            var isCur = (i == manager.currentLegIndex);
            var color = isCur ? Theme.COLOR_GREEN_RING : (s.completed ? Theme.COLOR_WHITE : Theme.COLOR_DIM);

            SportIcons.drawSportIcon(dc, s.sportType, 66, y, 10, SportDefinitions.getSportColor(s.sportType));
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(90, y, Theme.fSmall as Graphics.FontType, SportDefinitions.getSportShortName(s.sportType), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            var tStr = (s.completed || isCur) ? SportDefinitions.formatTime(s.elapsedMs) : "--:--";
            dc.drawText(235, y, Theme.fSmall as Graphics.FontType, tStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

            var dStr = SportDefinitions.isTransition(s.sportType)
                ? ""
                : SportDefinitions.formatDistance(s.distanceMeters, SportDefinitions.isSwim(s.sportType));
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            dc.drawText(334, y, Theme.fLabel as Graphics.FontType, dStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // PAGE 3: Live Vector GPS Track on Pure Black
    private function drawPage3GpsTrack(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // Subtle compass ring
        dc.setColor(Theme.COLOR_DARK_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, 148);
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 30, Theme.fLabel as Graphics.FontType, "N", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

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
            var scale = 220.0f / maxSpan;

            dc.setColor(SportDefinitions.getSportColor(manager.getCurrentSport()), Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(4);
            var prevX = cx + ((manager.trackLons[0] - midLon) * scale).toNumber();
            var prevY = cy - ((manager.trackLats[0] - midLat) * scale).toNumber();
            // Start dot
            dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(prevX, prevY, 5);

            dc.setColor(SportDefinitions.getSportColor(manager.getCurrentSport()), Graphics.COLOR_TRANSPARENT);
            for (var j = 1; j < count; j++) {
                var px = cx + ((manager.trackLons[j] - midLon) * scale).toNumber();
                var py = cy - ((manager.trackLats[j] - midLat) * scale).toNumber();
                dc.drawLine(prevX, prevY, px, py);
                prevX = px;
                prevY = py;
            }
            // Current position arrow
            drawHeadingArrow(dc, prevX, prevY, manager.heading);

            // Dynamic scale bar (1 deg lat ~ 111,000 m)
            var metersPerPx = (maxSpan * 111000.0f) / 220.0f;
            var barMeters = (metersPerPx * 60.0f).toNumber();
            if (barMeters < 10) { barMeters = 10; }
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawLine(cx - 30, 344, cx + 30, 344);
            dc.drawLine(cx - 30, 339, cx - 30, 349);
            dc.drawLine(cx + 30, 339, cx + 30, 349);
            dc.drawText(cx, 326, Theme.fLabel as Graphics.FontType, barMeters.toString() + " m", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            drawHeadingArrow(dc, cx, cy, manager.heading);
            dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
            var gpsText = (manager.gpsQuality >= Position.QUALITY_POOR) ? "TRACÉ EN COURS..." : "RECHERCHE GPS...";
            dc.drawText(cx, cy + 48, Theme.fSmall as Graphics.FontType, gpsText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Top distance readout
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 62, Theme.fSmall as Graphics.FontType,
            SportDefinitions.formatDistance(manager.totalDistanceMeters, false) + " km",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawHeadingArrow(dc as Dc, x as Number, y as Number, headingRad as Float) as Void {
        var sinH = Math.sin(headingRad);
        var cosH = Math.cos(headingRad);
        var tipX = x + (sinH * 12.0d).toNumber();
        var tipY = y - (cosH * 12.0d).toNumber();
        var leftX = x + (Math.sin(headingRad - 2.4d) * 9.0d).toNumber();
        var leftY = y - (Math.cos(headingRad - 2.4d) * 9.0d).toNumber();
        var rightX = x + (Math.sin(headingRad + 2.4d) * 9.0d).toNumber();
        var rightY = y - (Math.cos(headingRad + 2.4d) * 9.0d).toNumber();
        var pts = [[tipX, tipY], [leftX, leftY], [x, y], [rightX, rightY]] as Array<[Numeric, Numeric]>;
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(pts);
    }

    // PAGE 4: Time of Day, Sunset, Battery Remaining
    private function drawPage4ClockBattery(dc as Dc) as Void {
        var w = dc.getWidth();
        var cx = w / 2;

        var clock = System.getClockTime();
        var timeStr = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        var secStr = clock.sec.format("%02d");

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 62, Theme.fLabel as Graphics.FontType, "HEURE DU JOUR", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 18, 122, Theme.fChronoHuge as Graphics.FontType, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 88, 132, Theme.fMedium as Graphics.FontType, secStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(36, 178, w - 36, 178);

        // Approximate Sunset based on month (Northern hemisphere Europe)
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var sunsetTable = ["17:15", "18:05", "18:55", "20:40", "21:25", "21:55", "21:45", "20:55", "19:55", "18:50", "17:10", "16:55"] as Array<String>;
        var mIdx = (now.month as Number) - 1;
        if (mIdx < 0 || mIdx > 11) { mIdx = 0; }

        dc.setColor(Theme.COLOR_GPS_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 212, Theme.fLabel as Graphics.FontType, "COUCHER SOLEIL", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 246, Theme.fValueMed as Graphics.FontType, sunsetTable[mIdx], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Battery Gauge + Estimated GPS hours left (~17h max on FR165)
        var stats = System.getSystemStats();
        var batt = stats.battery.toNumber();
        var estHours = ((batt.toFloat() / 100.0f) * 17.0f).toNumber();
        SportIcons.drawBatteryIcon(dc, cx - 58, 296, 32, 16, batt);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 16, 304, Theme.fMedium as Graphics.FontType, batt.toString() + "%", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 338, Theme.fLabel as Graphics.FontType, "~" + estHours.toString() + "h GPS restantes", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class ActiveDataDelegate extends WatchUi.BehaviorDelegate {
    private var manager as MultisportManager;
    private var view as ActiveDataView;

    function initialize(mgr as MultisportManager, v as ActiveDataView) {
        BehaviorDelegate.initialize();
        manager = mgr;
        view = v;
    }

    // START/STOP -> Pause & Open FR965 Pause Menu
    function onSelect() as Boolean {
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
    }

    // BACK/LAP -> Directly advance to next segment/transition (FR965 native multisport behavior)
    function onBack() as Boolean {
        if (manager.isLocked) {
            manager.showAlert("VERROUILLÉ", "Appui LIGHT", 2);
            WatchUi.requestUpdate();
            return true;
        }
        var finished = manager.nextSegment();
        if (finished) {
            var sumView = new SummaryView(manager);
            var sumDel = new SummaryDelegate(manager, sumView);
            WatchUi.switchToView(sumView, sumDel, WatchUi.SLIDE_LEFT);
        } else {
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onNextPage() as Boolean {
        view.nextPage();
        return true;
    }

    function onPreviousPage() as Boolean {
        view.prevPage();
        return true;
    }

    function onMenu() as Boolean {
        if (manager.isLocked) {
            return true;
        }
        MainSettingsMenu.push(manager);
        return true;
    }

    // LIGHT key toggles screen lock
    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        if (evt.getKey() == WatchUi.KEY_LIGHT) {
            manager.isLocked = !manager.isLocked;
            manager.showAlert(manager.isLocked ? "ÉCRAN VERROUILLÉ" : "DÉVERROUILLÉ", "", 2);
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    // Touch swipe: vertical = change data page, right = next segment (when unlocked)
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        if (manager.isLocked) {
            return true;
        }
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
}
