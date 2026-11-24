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
        var menu = new WatchUi.Menu2({:title => "Écrans de données"});
        menu.addItem(new WatchUi.MenuItem("Natation", "Éditeur visuel 3 champs", :edit_swim, null));
        menu.addItem(new WatchUi.MenuItem("Vélo", "Éditeur visuel 3 champs", :edit_bike, null));
        menu.addItem(new WatchUi.MenuItem("Course à pied", "Éditeur visuel 3 champs", :edit_run, null));

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

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var cat = 2;
        if (id == :edit_swim) { cat = 0; }
        else if (id == :edit_bike) { cat = 1; }
        var edView = new DataScreenEditorView(manager, cat);
        WatchUi.pushView(edView, new DataScreenEditorDelegate(manager, edView), WatchUi.SLIDE_LEFT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
