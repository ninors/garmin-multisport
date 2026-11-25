import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

class PreStartView extends WatchUi.View {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // 1. Semi-transparent Triathlon Hero SVG backdrop in top half (matching FR965 photo!)
        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        var splitY = 252;
        GarminComponents.ensureGlows();
        if (GarminComponents.bmpBgTri != null) {
            dc.drawBitmap(0, 0, GarminComponents.bmpBgTri);
        }

        // Deep dark-navy bottom rounded cap (matching FR965 Triathlon photo)
        dc.setColor(0x071422, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, splitY, w, h - splitY);

        // 2. Top-center: Exact 3 overlapping Garmin Multisport rings (Red, Blue, Green)
        GarminComponents.drawMultisportRings(dc, cx, 58, 16);

        // 3. Bold White Activity Title ("Triathlon" / "Duathlon" / "Swimrun" / "Multisport")
        var profileName = SportDefinitions.getProfileName(manager.settings.profileId);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 114, Graphics.FONT_MEDIUM, profileName, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 4. Native Garmin GPS Status Text + Horizontal Progress Bar
        var gpsReady = (manager.gpsQuality >= Position.QUALITY_GOOD);
        var gpsUsable = (manager.gpsQuality >= Position.QUALITY_POOR);
        var gpsColor = gpsReady ? Theme.COLOR_GPS_GREEN : (gpsUsable ? Theme.COLOR_GPS_YELLOW : Theme.COLOR_GPS_RED);
        var gpsText = gpsReady ? "GPS prêt" : "Attente du signal GPS";

        dc.setColor(gpsReady ? Theme.COLOR_GPS_GREEN : Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 152, Graphics.FONT_XTINY, gpsText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Horizontal GPS progress bar (exact FR965 style from photo)
        var barX = 56;
        var barW = w - 112;
        var barY = 172;
        dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barX, barY, barW, 5, 2);

        dc.setColor(gpsColor, Graphics.COLOR_TRANSPARENT);
        if (gpsReady) {
            dc.fillRoundedRectangle(barX, barY, barW, 5, 2);
        } else {
            var frac = ((manager.tickCount % 5) + 1).toFloat() / 5.0f;
            var fillW = (barW.toFloat() * frac * 0.45f).toNumber();
            if (gpsUsable) {
                fillW = (barW * 2) / 3;
            }
            if (fillW < 24) { fillW = 24; }
            dc.fillRoundedRectangle(barX, barY, fillW, 5, 2);
        }

        // 5. Sensor & Sport Icons Row (Heart + GPS + Compact Sport Chain)
        var hrColor = (manager.heartRate > 30) ? Theme.COLOR_HEART_RED : Theme.COLOR_WHITE;
        SportIcons.drawHeart(dc, 76, 200, 14, hrColor);
        if (manager.heartRate > 30) {
            dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(94, 200, Graphics.FONT_XTINY, manager.heartRate.toString(), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Compact sport chain on the right side of the sensor row
        var legCount = manager.legs.size();
        var shown = 0;
        var iconX = 210;
        for (var i = 0; i < legCount && shown < 4; i++) {
            var sp = manager.legs[i];
            if (!SportDefinitions.isTransition(sp)) {
                var c = (shown == 0) ? SportDefinitions.getSportColor(sp) : Theme.COLOR_LABEL;
                SportIcons.drawSportIcon(dc, sp, iconX + (shown * 34), 200, 10, c);
                shown++;
            }
        }

        // 6. Left-Edge Garmin Options Indicator (curved white bar + 3 vertical dots, exact photo)
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawArc(cx, cy, cx - 10, Graphics.ARC_COUNTER_CLOCKWISE, 170, 190);
        dc.fillCircle(24, cy - 12, 3);
        dc.fillCircle(22, cy, 3);
        dc.fillCircle(24, cy + 12, 3);

        // 7. Signature Bright Cyan-Blue SVG Gradient Horizontal Divider (exact FR965 Triathlon photo!)
        GarminComponents.drawFadedHorizontalLine(dc, splitY, 12, w - 12, 0x00CCFF, 0x006699, 0x002233);

        // 8. Compact Bottom Cap: Clock + Small Green Battery Icon
        var clock = System.getClockTime();
        var timeStr = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        var stats = System.getSystemStats();
        var battPct = stats.battery.toNumber();

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 16, 278, Graphics.FONT_XTINY, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        SportIcons.drawBatteryIcon(dc, cx + 20, 272, 20, 11, battPct);

        // 9. Smaller sleek White 0:00 with Superscript 00 Hundredths
        var mainZero = "0:00";
        var zeroW = dc.getTextWidthInPixels(mainZero, Graphics.FONT_MEDIUM);
        var zeroLeft = cx - (zeroW / 2) - 8;
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(zeroLeft, 318, Graphics.FONT_MEDIUM, mainZero, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(zeroLeft + zeroW + 3, 309, Graphics.FONT_XTINY, "00", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 10. Bottom Downward White Chevron "v"
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 7, 358, cx, 365);
        dc.drawLine(cx, 365, cx + 7, 358);

        // 11. Native Garmin Glowing Cyan/Green START Bezel Arc on Top-Right
        GarminComponents.drawActionGlowArc(dc, 28, 0xAAFFCC, Theme.COLOR_GREEN_RING, 0x004422);

        // Full-screen Garmin overlay if active (e.g. profile switch)
        GarminComponents.drawGarminOverlay(dc, manager);
    }
}

// Uses WatchUi.InputDelegate directly so physical buttons work 100%
// and screen taps NEVER launch or change anything!
class PreStartDelegate extends WatchUi.InputDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        InputDelegate.initialize();
        manager = mgr;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        var k = evt.getKey();
        if (k == WatchUi.KEY_ENTER) {
            // Physical START/STOP -> Launch Multisport Activity
            manager.startActivity();
            var activeView = new ActiveDataView(manager);
            var activeDelegate = new ActiveDataDelegate(manager, activeView);
            WatchUi.switchToView(activeView, activeDelegate, WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (k == WatchUi.KEY_ESC) {
            // Physical BACK -> Exit Watch App cleanly
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        } else if (k == WatchUi.KEY_UP || k == WatchUi.KEY_MENU) {
            // Physical UP / MENU -> Open Settings Menu
            MainSettingsMenu.push(manager);
            return true;
        } else if (k == WatchUi.KEY_DOWN) {
            // Physical DOWN -> Cycle Multisport Profile
            manager.settings.profileId = (manager.settings.profileId + 1) % 5;
            manager.settings.save();
            manager.rebuildProfile();
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    // Block ALL screen taps & swipes on Pre-Start
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        return true;
    }
}
