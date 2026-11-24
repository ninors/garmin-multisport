import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class PreStartView extends WatchUi.View {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        View.initialize();
        manager = mgr;
    }

    function onUpdate(dc as Dc) as Void {
        Theme.ensureFonts();
        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        var w = dc.getWidth();
        var cx = w / 2;
        var curSport = manager.getCurrentSport();
        var nextSport = manager.getNextSport();
        var sportColor = SportDefinitions.getSportColor(curSport);

        // 1. Top 5-zone HR arc + red heart + BPM
        var zPos = manager.getHrZonePosition(manager.heartRate);
        var zIdx = manager.getHrZoneIndex(manager.heartRate);
        GarminComponents.drawTopHrArc(dc, manager.heartRate, zPos, zIdx);

        // 2. Active Sport Vector Icon + Large White 0:00 Chrono
        var chronoStr = "0:00";
        var chronoW = dc.getTextWidthInPixels(chronoStr, Theme.fValueBig as Graphics.FontType);
        var groupW = 42 + chronoW;
        var startX = cx - (groupW / 2);
        SportIcons.drawSportIcon(dc, curSport, startX + 16, 102, 16, sportColor);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + 40, 102, Theme.fValueBig as Graphics.FontType, chronoStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. Transition indicator: "SUIVANT : T1" + profile name
        var nextLabel = (nextSport != null)
            ? ("SUIVANT : " + SportDefinitions.getSportShortName(nextSport as Number))
            : SportDefinitions.getProfileName(manager.settings.profileId).toUpper();
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 144, Theme.fLabel as Graphics.FontType, nextLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 4. 3-Column Data Grid: DIST | ALLURE (or VIT.) | TEMPS
        dc.setColor(Theme.COLOR_DARK_LINE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(36, 164, w - 36, 164);
        dc.drawLine(36, 234, w - 36, 234);
        dc.drawLine(134, 170, 134, 228);
        dc.drawLine(256, 170, 256, 228);

        var col1X = 78;
        var col2X = cx;
        var col3X = 312;

        var paceLabel = SportDefinitions.isBike(curSport) ? "VIT." : "ALLURE";
        var distInit = SportDefinitions.isSwim(curSport) ? "0 m" : "0.00";
        var paceInit = SportDefinitions.isBike(curSport) ? "0.0" : "--:--";

        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col1X, 180, Theme.fLabel as Graphics.FontType, "DIST", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(col2X, 180, Theme.fLabel as Graphics.FontType, paceLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(col3X, 180, Theme.fLabel as Graphics.FontType, "TEMPS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(sportColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col1X, 212, Theme.fValueMed as Graphics.FontType, distInit, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(col2X, 212, Theme.fValueMed as Graphics.FontType, paceInit, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(col3X, 212, Theme.fValueMed as Graphics.FontType, "0:00", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 5. Visual chain of chained multisport segments with luminous green active ring
        GarminComponents.drawSportChain(dc, manager.legs, manager.currentLegIndex, 276);

        // 6. Bottom Status Bar: Current Time, GPS icon, Battery gauge & %
        GarminComponents.drawStatusBar(dc, manager.gpsQuality, 342);

        // 7. Right-edge pagination dots
        GarminComponents.drawPaginationDots(dc, 0, 5);

        // Alert banner if profile changed
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
