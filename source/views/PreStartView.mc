import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

class PreStartView extends WatchUi.View {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        var w = dc.getWidth();
        var cx = w / 2;
        var cy = dc.getHeight() / 2;
        var curSport = manager.getCurrentSport();
        var nextSport = manager.getNextSport();
        var sportColor = SportDefinitions.getSportColor(curSport);

        // 1. Native Garmin GPS Acquisition Arc at the very top edge
        var gpsReady = (manager.gpsQuality >= Position.QUALITY_GOOD);
        var gpsUsable = (manager.gpsQuality >= Position.QUALITY_POOR);
        var gpsColor = gpsReady ? Theme.COLOR_GPS_GREEN : (gpsUsable ? Theme.COLOR_GPS_YELLOW : Theme.COLOR_GPS_RED);

        // Background track for GPS arc
        dc.setPenWidth(8);
        dc.setColor(Theme.COLOR_DARK_LINE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, cx - 8, Graphics.ARC_CLOCKWISE, 138, 42);

        // Animated progress when searching GPS, full green arc when locked
        dc.setColor(gpsColor, Graphics.COLOR_TRANSPARENT);
        if (gpsReady) {
            dc.drawArc(cx, cy, cx - 8, Graphics.ARC_CLOCKWISE, 138, 42);
        } else {
            var pulseStep = (manager.tickCount % 4) + 1; // 1..4
            var endDeg = 138 - (pulseStep * 22);
            if (endDeg < 42) { endDeg = 42; }
            dc.drawArc(cx, cy, cx - 8, Graphics.ARC_CLOCKWISE, 138, endDeg);
        }

        // GPS Status Pill + Live HR right underneath
        var gpsText = gpsReady ? "GPS PRÊT" : (gpsUsable ? "GPS FAIBLE" : "ATTENTE GPS...");
        dc.setColor(gpsColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 38, Theme.fLabel, gpsText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Live Heart Rate badge (heart + BPM)
        var hrText = (manager.heartRate > 30) ? manager.heartRate.toString() : "--";
        SportIcons.drawHeart(dc, cx - 28, 66, 12, Theme.COLOR_HEART_RED);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 14, 66, Theme.fSmall, hrText + " bpm", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 2. Native Garmin Profile Title & Active Sport Icon + 0:00 Chrono
        dc.setColor(sportColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 98, Theme.fMedium,
            SportDefinitions.getProfileName(manager.settings.profileId).toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        SportIcons.drawSportIcon(dc, curSport, cx - 78, 140, 16, sportColor);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + 12, 140, Theme.fValueBig, "0:00", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. Transition indicator: "SUIVANT : T1"
        var nextLabel = (nextSport != null)
            ? ("SUIVANT : " + SportDefinitions.getSportShortName(nextSport as Number))
            : "PRÊT AU DÉPART";
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 178, Theme.fLabel, nextLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 4. 3-Column Data Preview (DIST | ALLURE | TEMPS)
        dc.setColor(Theme.COLOR_DARK_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(34, 196, w - 34, 196);
        dc.drawLine(34, 250, w - 34, 250);
        dc.drawLine(134, 200, 134, 246);
        dc.drawLine(256, 200, 256, 246);

        var paceLabel = SportDefinitions.isBike(curSport) ? "VIT." : "ALLURE";
        var distInit = SportDefinitions.isSwim(curSport) ? "0 m" : "0.00";
        var paceInit = SportDefinitions.isBike(curSport) ? "0.0" : "--:--";

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(78, 210, Theme.fLabel, "DIST", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, 210, Theme.fLabel, paceLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(312, 210, Theme.fLabel, "TEMPS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(sportColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(78, 234, Theme.fSmall, distInit, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, 234, Theme.fSmall, paceInit, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(312, 234, Theme.fSmall, "0:00", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 5. Visual chain of chained multisport segments with luminous green active ring
        GarminComponents.drawSportChain(dc, manager.legs, manager.currentLegIndex, 286);

        // 6. Bottom Status Bar: Current Time, GPS icon, Battery gauge & %
        GarminComponents.drawStatusBar(dc, manager.gpsQuality, 344);

        // 7. Native Garmin Green START Arc Accent near top-right START button (~28 deg)
        dc.setColor(Theme.COLOR_GREEN_RING, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawArc(cx, cy, cx - 5, Graphics.ARC_CLOCKWISE, 36, 16);

        // 8. Right-edge pagination dots
        GarminComponents.drawPaginationDots(dc, 0, 5);

        // Alert banner if profile changed or GPS locked
        if (manager.alertMessage != null) {
            GarminComponents.drawAlertBanner(dc, manager.alertMessage as String, manager.alertSubMessage);
        }
    }
}

class PreStartDelegate extends WatchUi.BehaviorDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        BehaviorDelegate.initialize();
        manager = mgr;
    }

    // START/STOP -> Launch Multisport Activity
    function onSelect() as Boolean {
        manager.startActivity();
        var activeView = new ActiveDataView(manager);
        var activeDelegate = new ActiveDataDelegate(manager, activeView);
        WatchUi.switchToView(activeView, activeDelegate, WatchUi.SLIDE_LEFT);
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

    // DOWN -> Quick cycle Multisport Profile (Triathlon / Duathlon / Swimrun / Perso)
    function onNextPage() as Boolean {
        manager.settings.profileId = (manager.settings.profileId + 1) % 4;
        manager.settings.save();
        manager.rebuildProfile();
        manager.showAlert(
            SportDefinitions.getProfileName(manager.settings.profileId),
            manager.legs.size().toString() + " étapes",
            2
        );
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
