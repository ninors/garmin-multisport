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

        // 1. Pure black top half + deep Garmin dark-navy bottom half (matching native FR965 photo)
        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        var splitY = 216;
        // Subtle stylized dark background lines in top half
        dc.setColor(0x141414, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(40, 144, w - 40, 144);
        dc.drawLine(30, 160, w - 30, 160);
        dc.drawLine(25, 186, w - 25, 186);

        // Deep dark-navy tint for bottom half (like native FR965 pre-start screen)
        dc.setColor(0x0A1622, Graphics.COLOR_TRANSPARENT);
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

        // 7. Signature Bright Magenta/Red Smooth Faded Horizontal Divider Line
        GarminComponents.drawFadedHorizontalLine(dc, splitY, 16, w - 16, 0xFF0055, 0x88002B, 0x2A000E);

        // 8. Bottom Half: Current Clock + Green Battery Icon (clean breathing room above 0:00)
        var clock = System.getClockTime();
        var timeStr = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        var stats = System.getSystemStats();
        var battPct = stats.battery.toNumber();

        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 18, 244, Graphics.FONT_TINY, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        SportIcons.drawBatteryIcon(dc, cx + 26, 237, 26, 14, battPct);

        // 9. Crisp White 0:00 with Superscript 00 Hundredths (well-spaced above chevron)
        var mainZero = "0:00";
        var zeroW = dc.getTextWidthInPixels(mainZero, Graphics.FONT_NUMBER_MEDIUM);
        var zeroLeft = cx - (zeroW / 2) - 10;
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(zeroLeft, 304, Graphics.FONT_NUMBER_MEDIUM, mainZero, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(zeroLeft + zeroW + 4, 290, Graphics.FONT_XTINY, "00", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 10. Bottom Downward White Chevron "v"
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(cx - 9, 356, cx, 365);
        dc.drawLine(cx, 365, cx + 9, 356);

        // 11. Native Garmin Glowing Cyan/Green START Bezel Arc on Top-Right
        GarminComponents.drawActionGlowArc(dc, 28, 0xAAFFCC, Theme.COLOR_GREEN_RING, 0x004422);

        // Full-screen Garmin overlay if active (e.g. profile switch)
        GarminComponents.drawGarminOverlay(dc, manager);
    }
}

class PreStartDelegate extends WatchUi.BehaviorDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        BehaviorDelegate.initialize();
        manager = mgr;
    }

    // START/STOP -> Launch Multisport Activity with native Garmin Big Green Triangle
    function onSelect() as Boolean {
        manager.startActivity();
        var activeView = new ActiveDataView(manager);
        var activeDelegate = new ActiveDataDelegate(manager, activeView);
        WatchUi.switchToView(activeView, activeDelegate, WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    // Long press UP (MENU) -> Open Full Settings Menu
    function onMenu() as Boolean {
        MainSettingsMenu.push(manager);
        return true;
    }

    // UP -> Open Settings Menu
    function onPreviousPage() as Boolean {
        MainSettingsMenu.push(manager);
        return true;
    }

    // DOWN -> Quick cycle Multisport Profile (Triathlon / Duathlon / Swimrun / Aquathlon / Perso)
    function onNextPage() as Boolean {
        manager.settings.profileId = (manager.settings.profileId + 1) % 5;
        manager.settings.save();
        manager.rebuildProfile();
        WatchUi.requestUpdate();
        return true;
    }

    // Touch swipe support
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            return onNextPage();
        } else if (dir == WatchUi.SWIPE_DOWN) {
            return onPreviousPage();
        } else if (dir == WatchUi.SWIPE_RIGHT) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        return false;
    }
}
