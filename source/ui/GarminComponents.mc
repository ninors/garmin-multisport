import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

module GarminComponents {

    var bmpGlowTR as WatchUi.BitmapResource?;
    var bmpGlowBR as WatchUi.BitmapResource?;
    var glowsLoaded as Boolean = false;

    function ensureGlows() as Void {
        if (glowsLoaded) {
            return;
        }
        glowsLoaded = true;
        bmpGlowTR = WatchUi.loadResource(Rez.Drawables.GlowTopRight) as WatchUi.BitmapResource;
        bmpGlowBR = WatchUi.loadResource(Rez.Drawables.GlowBotRight) as WatchUi.BitmapResource;
    }

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

    // Signature FR965 Smooth 7-Step Faded Horizontal Divider Line (used on ALL red/yellow lines!)
    function drawFadedHorizontalLine(dc as Dc, y as Number, x1 as Number, x2 as Number, brightColor as Number, midColor as Number, dimColor as Number) as Void {
        var span = x2 - x1;
        var s1 = span / 16;
        var s2 = span / 8;
        var s3 = (span * 3) / 16;
        var s4 = span / 4;

        dc.setPenWidth(3);
        // Very dark outer tips
        var darkTip = ((dimColor >> 1) & 0x7F7F7F);
        dc.setColor(darkTip, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x1, y, x1 + s1, y);
        dc.drawLine(x2 - s1, y, x2, y);

        // Dim step
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x1 + s1, y, x1 + s2, y);
        dc.drawLine(x2 - s2, y, x2 - s1, y);

        // Mid step
        dc.setColor(midColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x1 + s2, y, x1 + s3, y);
        dc.drawLine(x2 - s3, y, x2 - s2, y);

        // Semi-bright step
        var semiBright = (((brightColor & 0xFEFEFE) >> 1) + ((midColor & 0xFEFEFE) >> 1));
        dc.setColor(semiBright, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x1 + s3, y, x1 + s4, y);
        dc.drawLine(x2 - s4, y, x2 - s3, y);

        // Bright crisp center
        dc.setColor(brightColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x1 + s4, y, x2 - s4, y);
    }

    // Bottom 5-zone HR arc — EXACT Forerunner 965 style (thin inactive zones, THICK active zone + white vertical tick!)
    function drawBottomHrArc(dc as Dc, hr as Number, zonePos as Float, zoneIdx as Number) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var radius = (cx - 14);
        var startDeg = 216.0f;
        var totalSpan = 108.0f;
        var segSpan = totalSpan / 5.0f;
        var gap = 2.2f;
        var hasHr = (hr > 30);

        for (var i = 0; i < 5; i++) {
            var a1 = (startDeg + (i * segSpan)).toNumber();
            var a2 = (startDeg + ((i + 1) * segSpan) - gap).toNumber();
            dc.setColor(Theme.ZONE_COLORS[i], Graphics.COLOR_TRANSPARENT);
            if (hasHr && i == zoneIdx) {
                // Active zone pops out THICK exactly like Forerunner 965!
                dc.setPenWidth(18);
                dc.drawArc(cx, cy, radius - 2, Graphics.ARC_COUNTER_CLOCKWISE, a1, a2);
            } else {
                dc.setPenWidth(6);
                dc.drawArc(cx, cy, radius, Graphics.ARC_COUNTER_CLOCKWISE, a1, a2);
            }
        }

        // Crisp vertical white tick marker through the active thick zone
        if (hasHr) {
            var cursorAngleDeg = startDeg + ((zonePos / 5.0f) * totalSpan);
            var rad = cursorAngleDeg * Math.PI / 180.0d;
            var cosA = Math.cos(rad);
            var sinA = Math.sin(rad);
            var xIn = cx + (cosA * (radius - 13)).toNumber();
            var yIn = cy - (sinA * (radius - 13)).toNumber();
            var xOut = cx + (cosA * (radius + 9)).toNumber();
            var yOut = cy - (sinA * (radius + 9)).toNumber();
            dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(7);
            dc.drawLine(xIn, yIn, xOut, yOut);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(4);
            dc.drawLine(xIn, yIn, xOut, yOut);
        }

        // Colored heart (zone color) + large crisp BPM value
        Theme.ensureFonts();
        var hrText = hasHr ? hr.toString() : "--";
        var heartColor = hasHr ? Theme.getZoneColor(zoneIdx) : Theme.COLOR_HEART_RED;
        var textW = dc.getTextWidthInPixels(hrText, Theme.fValueBig as Graphics.FontType);
        var totalW = 32 + textW;
        var startX = cx - (totalW / 2);

        SportIcons.drawHeart(dc, startX + 11, 308, 20, heartColor);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + 30, 308, Theme.fValueBig as Graphics.FontType, hrText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
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

    // Vertical pagination dots on the LEFT curved edge (solid white = active, hollow white ring = inactive)
    function drawPaginationDots(dc as Dc, currentPage as Number, totalPages as Number) as Void {
        if (totalPages <= 1) {
            return;
        }
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var r = cx - 10;
        var stepDeg = 6.5f;
        var halfSpan = ((totalPages - 1).toFloat() * stepDeg) / 2.0f;

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < totalPages; i++) {
            // Left side (180 deg): top dot at (180 - halfSpan), bottom dot at (180 + halfSpan)
            var deg = 180.0f - halfSpan + (i.toFloat() * stepDeg);
            var rad = deg * Math.PI / 180.0d;
            var dx = cx + (Math.cos(rad) * r).toNumber();
            var dy = cy - (Math.sin(rad) * r).toNumber();
            if (i == currentPage) {
                dc.fillCircle(dx, dy, 4);
            } else {
                dc.drawCircle(dx, dy, 3);
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

    // Exact 3 horizontal overlapping Garmin Multisport rings (Red, Blue, Green)
    function drawMultisportRings(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        var offset = (r * 1.2f).toNumber();
        dc.setPenWidth(5);
        dc.setColor(0xFF2B2B, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx - offset, cy, r);
        dc.setColor(0x0066B3, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
        dc.setColor(0x22CC33, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx + offset, cy, r);
    }

    // Authentic Full-Screen Garmin Forerunner Action Overlays (NO clunky boxes!)
    function drawGarminOverlay(dc as Dc, manager as MultisportManager) as Void {
        var oType = manager.overlayType;
        if (oType == MultisportManager.OVERLAY_NONE) {
            return;
        }
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        if (oType == MultisportManager.OVERLAY_START) {
            // Full-screen black backdrop + thick green bezel ring + HUGE green Play Triangle
            dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
            dc.fillCircle(cx, cy, cx);
            dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(12);
            dc.drawCircle(cx, cy, cx - 6);
            var tri = [
                [cx - 38, cy - 52],
                [cx + 56, cy],
                [cx - 38, cy + 52]
            ] as Array<[Numeric, Numeric]>;
            dc.fillPolygon(tri);
        } else if (oType == MultisportManager.OVERLAY_PAUSE) {
            // Full-screen black backdrop + thick red bezel ring + HUGE red Stop Square
            dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
            dc.fillCircle(cx, cy, cx);
            dc.setColor(Theme.COLOR_GPS_RED, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(12);
            dc.drawCircle(cx, cy, cx - 6);
            dc.fillRoundedRectangle(cx - 44, cy - 44, 88, 88, 10);
        } else if (oType == MultisportManager.OVERLAY_TRANSITION) {
            // Native Garmin Multisport Transition Full-Screen Flash
            dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
            dc.fillCircle(cx, cy, cx);
            dc.setColor(manager.overlayColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(10);
            dc.drawCircle(cx, cy, cx - 6);
            SportIcons.drawSportIcon(dc, manager.overlaySport, cx, cy - 54, 28, manager.overlayColor);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            if (manager.alertMessage != null) {
                dc.drawText(cx, cy + 16, Graphics.FONT_LARGE, manager.alertMessage as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            if (manager.alertSubMessage != null) {
                dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, cy + 68, Graphics.FONT_MEDIUM, manager.alertSubMessage as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else if (oType == MultisportManager.OVERLAY_LAP) {
            // Native Garmin Lap Screen
            dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
            dc.fillCircle(cx, cy, cx);
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(8);
            dc.drawCircle(cx, cy, cx - 5);
            if (manager.alertMessage != null) {
                dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, cy - 42, Graphics.FONT_MEDIUM, manager.alertMessage as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            if (manager.alertSubMessage != null) {
                dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, cy + 20, Graphics.FONT_NUMBER_HOT, manager.alertSubMessage as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else {
            // Clean Circular Garmin Alert (Nutrition / HR / Profile switch)
            dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
            dc.fillCircle(cx, cy, cx);
            dc.setColor(manager.overlayColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(8);
            dc.drawCircle(cx, cy, cx - 5);
            if (manager.alertMessage != null) {
                dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, cy - 16, Graphics.FONT_MEDIUM, manager.alertMessage as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            if (manager.alertSubMessage != null) {
                dc.setColor(manager.overlayColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, cy + 32, Graphics.FONT_SMALL, manager.alertSubMessage as String, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }

    // Native Garmin Glowing Cyan-Blue Curved Action Arc (SVG bitmap with smooth gradient halo!)
    // centerDeg < 90 => Top-Right (START/STOP), centerDeg > 270 => Bottom-Right (BACK/LAP)
    function drawActionGlowArc(dc as Dc, centerDeg as Number, coreColor as Number, midColor as Number, dimColor as Number) as Void {
        ensureGlows();
        var w = dc.getWidth();
        var h = dc.getHeight();
        if (centerDeg < 90) {
            if (bmpGlowTR != null) {
                dc.drawBitmap(w - bmpGlowTR.getWidth() - 4, 48, bmpGlowTR);
            }
        } else {
            if (bmpGlowBR != null) {
                dc.drawBitmap(w - bmpGlowBR.getWidth() - 4, h - bmpGlowBR.getHeight() - 48, bmpGlowBR);
            }
        }
    }

    // Paused Red Ring Indicator
    function drawPausedOverlay(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawCircle(cx, cy, cx - 3);
    }
}
