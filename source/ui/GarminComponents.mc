import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;

module GarminComponents {

    // Top 5-zone HR arc (Pre-Start screen)
    // Spans 142 deg (top-left) clockwise to 38 deg (top-right) = 104 deg total
    function drawTopHrArc(dc as Dc, hr as Number, zonePos as Float, zoneIdx as Number) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var radius = (cx - 10);
        var startDeg = 142.0f;
        var totalSpan = 104.0f;
        var segSpan = totalSpan / 5.0f; // ~20.8 deg per zone
        var gap = 2.0f;

        dc.setPenWidth(9);
        for (var i = 0; i < 5; i++) {
            var a1 = (startDeg - (i * segSpan)).toNumber();
            var a2 = (startDeg - ((i + 1) * segSpan) + gap).toNumber();
            dc.setColor(Theme.ZONE_COLORS[i], Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, a1, a2);
        }

        // White live cursor on top arc when HR valid
        if (hr > 30) {
            var cursorAngleDeg = startDeg - ((zonePos / 5.0f) * totalSpan);
            drawArcCursor(dc, cx, cy, radius, cursorAngleDeg, true);
        }

        // Heart icon + BPM directly below top arc
        Theme.ensureFonts();
        var hrText = (hr > 30) ? hr.toString() : "--";
        var hrColor = (hr > 30) ? Theme.COLOR_WHITE : Theme.COLOR_LABEL;
        var textW = dc.getTextWidthInPixels(hrText, Theme.fMedium as Graphics.FontType);
        var totalW = 20 + textW;
        var startX = cx - (totalW / 2);
        SportIcons.drawHeart(dc, startX + 8, 44, 14, Theme.COLOR_HEART_RED);
        dc.setColor(hrColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + 22, 44, Theme.fMedium as Graphics.FontType, hrText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Bottom 5-zone HR arc (Active Main screen — signature FR965)
    // Spans 218 deg (bottom-left) counter-clockwise to 322 deg (bottom-right) = 104 deg total
    function drawBottomHrArc(dc as Dc, hr as Number, zonePos as Float, zoneIdx as Number) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var radius = (cx - 10);
        var startDeg = 218.0f;
        var totalSpan = 104.0f;
        var segSpan = totalSpan / 5.0f;
        var gap = 2.0f;

        dc.setPenWidth(10);
        for (var i = 0; i < 5; i++) {
            var a1 = (startDeg + (i * segSpan)).toNumber();
            var a2 = (startDeg + ((i + 1) * segSpan) - gap).toNumber();
            dc.setColor(Theme.ZONE_COLORS[i], Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, radius, Graphics.ARC_COUNTER_CLOCKWISE, a1, a2);
        }

        // White movable pointer on bottom arc
        if (hr > 30) {
            var cursorAngleDeg = startDeg + ((zonePos / 5.0f) * totalSpan);
            drawArcCursor(dc, cx, cy, radius, cursorAngleDeg, false);
        }

        // Colored heart (zone color) + large BPM value
        Theme.ensureFonts();
        var hrText = (hr > 30) ? hr.toString() : "--";
        var heartColor = (hr > 30) ? Theme.getZoneColor(zoneIdx) : Theme.COLOR_HEART_RED;
        var textW = dc.getTextWidthInPixels(hrText, Theme.fValueBig as Graphics.FontType);
        var totalW = 30 + textW;
        var startX = cx - (totalW / 2);

        SportIcons.drawHeart(dc, startX + 11, 314, 20, heartColor);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + 28, 314, Theme.fValueBig as Graphics.FontType, hrText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Crisp white pointer triangle on an arc
    function drawArcCursor(dc as Dc, cx as Number, cy as Number, radius as Number, angleDeg as Float, isTop as Boolean) as Void {
        var rad = angleDeg * Math.PI / 180.0d;
        var cosA = Math.cos(rad);
        var sinA = Math.sin(rad);

        var rOuter = radius + 6;
        var rInner = radius - 8;
        var perpRad = (angleDeg + 90.0f) * Math.PI / 180.0d;
        var px = Math.cos(perpRad) * 5.0d;
        var py = -Math.sin(perpRad) * 5.0d;

        var tipX = cx + (cosA * rInner).toNumber();
        var tipY = cy - (sinA * rInner).toNumber();
        var baseX = cx + (cosA * rOuter).toNumber();
        var baseY = cy - (sinA * rOuter).toNumber();

        if (!isTop) {
            // Point inward toward center
            var pts = [
                [tipX, tipY],
                [baseX + px.toNumber(), baseY + py.toNumber()],
                [baseX - px.toNumber(), baseY - py.toNumber()]
            ] as Array<[Numeric, Numeric]>;
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(pts);
        } else {
            var ptsTop = [
                [tipX, tipY],
                [baseX + px.toNumber(), baseY + py.toNumber()],
                [baseX - px.toNumber(), baseY - py.toNumber()]
            ] as Array<[Numeric, Numeric]>;
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(ptsTop);
        }
    }

    // Visual chain of chained multisport segments with luminous green active ring
    function drawSportChain(dc as Dc, legs as Array<Number>, currentIdx as Number, yCenter as Number) as Void {
        var count = legs.size();
        if (count == 0) {
            return;
        }
        var maxShow = (count > 5) ? 5 : count;
        var startIdx = 0;
        if (count > 5) {
            startIdx = currentIdx - 2;
            if (startIdx < 0) { startIdx = 0; }
            if (startIdx + 5 > count) { startIdx = count - 5; }
        }

        var cx = dc.getWidth() / 2;
        var spacing = 56;
        var totalW = (maxShow - 1) * spacing;
        var x0 = cx - (totalW / 2);

        for (var i = 0; i < maxShow; i++) {
            var legIdx = startIdx + i;
            var x = x0 + (i * spacing);
            var sport = legs[legIdx];
            var isActive = (legIdx == currentIdx);
            var isDone = (legIdx < currentIdx);

            // Connecting subtle chevron between icons
            if (i < maxShow - 1) {
                var midX = x + (spacing / 2);
                dc.setColor(Theme.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(2);
                dc.drawLine(midX - 3, yCenter - 4, midX + 2, yCenter);
                dc.drawLine(midX + 2, yCenter, midX - 3, yCenter + 4);
            }

            if (isActive) {
                // Luminous green glow + bright green ring
                dc.setColor(Theme.COLOR_GREEN_GLOW, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(6);
                dc.drawCircle(x, yCenter, 21);
                dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(3);
                dc.drawCircle(x, yCenter, 20);
                SportIcons.drawSportIcon(dc, sport, x, yCenter, 13, Theme.COLOR_WHITE);
            } else if (isDone) {
                dc.setColor(Theme.COLOR_DARK_LINE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(2);
                dc.drawCircle(x, yCenter, 16);
                SportIcons.drawSportIcon(dc, sport, x, yCenter, 11, Theme.COLOR_DIM);
                // Small green completed dot
                dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x + 12, yCenter - 12, 4);
            } else {
                SportIcons.drawSportIcon(dc, sport, x, yCenter, 12, Theme.COLOR_LABEL);
            }
        }
    }

    // Vertical pagination dots on the right curved edge
    function drawPaginationDots(dc as Dc, currentPage as Number, totalPages as Number) as Void {
        if (totalPages <= 1) {
            return;
        }
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var r = cx - 9;
        var stepDeg = 6.5f;
        var startDeg = ((totalPages - 1).toFloat() * stepDeg) / 2.0f;

        for (var i = 0; i < totalPages; i++) {
            var deg = startDeg - (i.toFloat() * stepDeg);
            var rad = deg * Math.PI / 180.0d;
            var dx = cx + (Math.cos(rad) * r).toNumber();
            var dy = cy - (Math.sin(rad) * r).toNumber();
            if (i == currentPage) {
                dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx, dy, 4);
            } else {
                dc.setColor(Theme.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dx, dy, 2);
            }
        }
    }

    // Signature FR965 Chrono with superscript hours (e.g. ¹08:20)
    function drawSuperscriptChrono(dc as Dc, elapsedMs as Number, cx as Number, yCenter as Number, color as Number) as Void {
        Theme.ensureFonts();
        if (elapsedMs < 0) {
            elapsedMs = 0;
        }
        var totalSec = elapsedMs / 1000;
        var hrs = totalSec / 3600;
        var mins = (totalSec % 3600) / 60;
        var secs = totalSec % 60;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (hrs > 0) {
            var mainStr = mins.format("%02d") + ":" + secs.format("%02d");
            var hrStr = hrs.toString();
            var mainW = dc.getTextWidthInPixels(mainStr, Theme.fChronoHuge as Graphics.FontType);
            var hrW = dc.getTextWidthInPixels(hrStr, Theme.fChronoSup as Graphics.FontType);
            var totalW = hrW + 4 + mainW;
            var leftX = cx - (totalW / 2);

            dc.drawText(leftX, yCenter - 14, Theme.fChronoSup as Graphics.FontType, hrStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(leftX + hrW + 4, yCenter, Theme.fChronoHuge as Graphics.FontType, mainStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var str = mins.toString() + ":" + secs.format("%02d");
            dc.drawText(cx, yCenter, Theme.fChronoHuge as Graphics.FontType, str, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Pre-Start Bottom Status Bar: Clock Time | GPS Icon | Battery Gauge + %
    function drawStatusBar(dc as Dc, gpsQuality as Number, yCenter as Number) as Void {
        Theme.ensureFonts();
        var cx = dc.getWidth() / 2;

        // Current clock time
        var clock = System.getClockTime();
        var timeStr = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 58, yCenter, Theme.fSmall as Graphics.FontType, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // GPS icon (Red = searching, Yellow = usable, Green = good)
        var gpsColor = Theme.COLOR_GPS_RED;
        if (gpsQuality >= Position.QUALITY_GOOD) {
            gpsColor = Theme.COLOR_GPS_GREEN;
        } else if (gpsQuality >= Position.QUALITY_POOR) {
            gpsColor = Theme.COLOR_GPS_YELLOW;
        }
        SportIcons.drawGpsIcon(dc, cx, yCenter, gpsColor);

        // Battery gauge + percentage
        var stats = System.getSystemStats();
        var battPct = stats.battery.toNumber();
        SportIcons.drawBatteryIcon(dc, cx + 26, yCenter - 7, 24, 14, battPct);
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 56, yCenter, Theme.fLabel as Graphics.FontType, battPct.toString() + "%", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // High-contrast FR965 Alert Banner Overlay
    function drawAlertBanner(dc as Dc, title as String, subtitle as String?) as Void {
        Theme.ensureFonts();
        var w = dc.getWidth();
        var cx = w / 2;
        var boxW = 310;
        var boxH = 82;
        var x = cx - (boxW / 2);
        var y = (dc.getHeight() / 2) - (boxH / 2);

        dc.setColor(Theme.COLOR_BANNER_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, boxW, boxH, 16);
        dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawRoundedRectangle(x, y, boxW, boxH, 16);

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y + 28, Theme.fMedium as Graphics.FontType, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (subtitle != null) {
            dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y + 58, Theme.fSmall as Graphics.FontType, subtitle, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Paused Red Ring Indicator
    function drawPausedOverlay(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(5);
        dc.drawCircle(cx, cy, cx - 3);
    }
}
