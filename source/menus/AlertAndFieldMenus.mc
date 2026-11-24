import Toybox.Lang;
import Toybox.WatchUi;

module AlertAndFieldMenus {

    function pushAlertsMenu(manager as MultisportManager) as Void {
        var s = manager.settings;
        var menu = new WatchUi.Menu2({:title => "Alertes"});

        menu.addItem(new WatchUi.MenuItem("FC Max", (s.hrAlertMax > 0) ? (s.hrAlertMax.toString() + " bpm") : "Désactivée", :hr_max, null));
        menu.addItem(new WatchUi.MenuItem("Allure lente", (s.paceAlertSlowSec > 0) ? (SportDefinitions.formatPaceSecPerUnit(s.paceAlertSlowSec.toFloat()) + " /km") : "Désactivée", :pace_slow, null));
        menu.addItem(new WatchUi.MenuItem("Distance", (s.distAlertMeters > 0) ? ((s.distAlertMeters / 1000).toString() + " km") : "Désactivée", :dist_alert, null));
        menu.addItem(new WatchUi.MenuItem("Temps", (s.timeAlertMin > 0) ? (s.timeAlertMin.toString() + " min") : "Désactivée", :time_alert, null));
        menu.addItem(new WatchUi.MenuItem("Nutrition / Hydrat.", (s.nutritionAlertMin > 0) ? ("Toutes les " + s.nutritionAlertMin.toString() + " min") : "Désactivée", :nutrition, null));

        WatchUi.pushView(menu, new AlertsMenuDelegate(manager), WatchUi.SLIDE_LEFT);
    }

    function pushDataFieldsMenu(manager as MultisportManager) as Void {
        var s = manager.settings;
        var menu = new WatchUi.Menu2({:title => "Écrans de données"});

        menu.addItem(new WatchUi.MenuItem("Nage : Gauche", SportDefinitions.getFieldLabel(s.swimFieldLeft), :swim_l, null));
        menu.addItem(new WatchUi.MenuItem("Nage : Droite", SportDefinitions.getFieldLabel(s.swimFieldRight), :swim_r, null));
        menu.addItem(new WatchUi.MenuItem("Vélo : Gauche", SportDefinitions.getFieldLabel(s.bikeFieldLeft), :bike_l, null));
        menu.addItem(new WatchUi.MenuItem("Vélo : Droite", SportDefinitions.getFieldLabel(s.bikeFieldRight), :bike_r, null));
        menu.addItem(new WatchUi.MenuItem("Course : Gauche", SportDefinitions.getFieldLabel(s.runFieldLeft), :run_l, null));
        menu.addItem(new WatchUi.MenuItem("Course : Droite", SportDefinitions.getFieldLabel(s.runFieldRight), :run_r, null));

        WatchUi.pushView(menu, new DataFieldsMenuDelegate(manager), WatchUi.SLIDE_LEFT);
    }
}

class AlertsMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var s = manager.settings;

        if (id == :hr_max) {
            if (s.hrAlertMax == 0) { s.hrAlertMax = 160; }
            else if (s.hrAlertMax == 160) { s.hrAlertMax = 175; }
            else if (s.hrAlertMax == 175) { s.hrAlertMax = 185; }
            else { s.hrAlertMax = 0; }
            item.setSubLabel((s.hrAlertMax > 0) ? (s.hrAlertMax.toString() + " bpm") : "Désactivée");
        } else if (id == :pace_slow) {
            if (s.paceAlertSlowSec == 0) { s.paceAlertSlowSec = 300; }
            else if (s.paceAlertSlowSec == 300) { s.paceAlertSlowSec = 330; }
            else if (s.paceAlertSlowSec == 330) { s.paceAlertSlowSec = 360; }
            else { s.paceAlertSlowSec = 0; }
            item.setSubLabel((s.paceAlertSlowSec > 0) ? (SportDefinitions.formatPaceSecPerUnit(s.paceAlertSlowSec.toFloat()) + " /km") : "Désactivée");
        } else if (id == :dist_alert) {
            if (s.distAlertMeters == 0) { s.distAlertMeters = 1000; }
            else if (s.distAlertMeters == 1000) { s.distAlertMeters = 5000; }
            else if (s.distAlertMeters == 5000) { s.distAlertMeters = 10000; }
            else { s.distAlertMeters = 0; }
            item.setSubLabel((s.distAlertMeters > 0) ? ((s.distAlertMeters / 1000).toString() + " km") : "Désactivée");
        } else if (id == :time_alert) {
            if (s.timeAlertMin == 0) { s.timeAlertMin = 15; }
            else if (s.timeAlertMin == 15) { s.timeAlertMin = 30; }
            else if (s.timeAlertMin == 30) { s.timeAlertMin = 60; }
            else { s.timeAlertMin = 0; }
            item.setSubLabel((s.timeAlertMin > 0) ? (s.timeAlertMin.toString() + " min") : "Désactivée");
        } else if (id == :nutrition) {
            if (s.nutritionAlertMin == 0) { s.nutritionAlertMin = 15; }
            else if (s.nutritionAlertMin == 15) { s.nutritionAlertMin = 20; }
            else if (s.nutritionAlertMin == 20) { s.nutritionAlertMin = 30; }
            else if (s.nutritionAlertMin == 30) { s.nutritionAlertMin = 45; }
            else { s.nutritionAlertMin = 0; }
            item.setSubLabel((s.nutritionAlertMin > 0) ? ("Toutes les " + s.nutritionAlertMin.toString() + " min") : "Désactivée");
        }
        s.save();
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class DataFieldsMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;
    private static const FIELD_COUNT = 13;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var s = manager.settings;
        var nextField = 0;

        if (id == :swim_l) {
            s.swimFieldLeft = (s.swimFieldLeft + 1) % FIELD_COUNT;
            nextField = s.swimFieldLeft;
        } else if (id == :swim_r) {
            s.swimFieldRight = (s.swimFieldRight + 1) % FIELD_COUNT;
            nextField = s.swimFieldRight;
        } else if (id == :bike_l) {
            s.bikeFieldLeft = (s.bikeFieldLeft + 1) % FIELD_COUNT;
            nextField = s.bikeFieldLeft;
        } else if (id == :bike_r) {
            s.bikeFieldRight = (s.bikeFieldRight + 1) % FIELD_COUNT;
            nextField = s.bikeFieldRight;
        } else if (id == :run_l) {
            s.runFieldLeft = (s.runFieldLeft + 1) % FIELD_COUNT;
            nextField = s.runFieldLeft;
        } else if (id == :run_r) {
            s.runFieldRight = (s.runFieldRight + 1) % FIELD_COUNT;
            nextField = s.runFieldRight;
        }
        s.save();
        item.setSubLabel(SportDefinitions.getFieldLabel(nextField));
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
