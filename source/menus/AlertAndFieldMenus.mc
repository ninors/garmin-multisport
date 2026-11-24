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
    private var activeItem as WatchUi.MenuItem?;
    private var activeId as Symbol?;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
        activeItem = null;
        activeId = null;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var s = manager.settings;
        activeItem = item;
        activeId = id as Symbol;

        var picker = null as GarminPickerView?;
        if (id == :hr_max) {
            picker = new GarminPickerView("ALERTE FC MAX", "bpm (0 = OFF)", GarminPickerView.MODE_NUMBER, s.hrAlertMax, 110, 210, 1);
        } else if (id == :pace_slow) {
            var initP = (s.paceAlertSlowSec > 0) ? s.paceAlertSlowSec : 300;
            picker = new GarminPickerView("ALLURE LENTE", "min:sec / km (0:00 = OFF)", GarminPickerView.MODE_TIME_MMSS, initP, 0, 3599, 1);
        } else if (id == :dist_alert) {
            picker = new GarminPickerView("ALERTE DISTANCE", "mètres (0 = OFF)", GarminPickerView.MODE_NUMBER, s.distAlertMeters, 500, 42000, 500);
        } else if (id == :time_alert) {
            picker = new GarminPickerView("ALERTE TEMPS", "minutes (0 = OFF)", GarminPickerView.MODE_NUMBER, s.timeAlertMin, 1, 180, 1);
        } else if (id == :nutrition) {
            picker = new GarminPickerView("HYDRATATION", "toutes les X min", GarminPickerView.MODE_NUMBER, s.nutritionAlertMin, 5, 90, 1);
        }

        if (picker != null) {
            WatchUi.pushView(picker, new GarminPickerDelegate(picker, method(:onPicked)), WatchUi.SLIDE_LEFT);
        }
    }

    public function onPicked(val as Number) as Void {
        var s = manager.settings;
        if (activeId == :hr_max) {
            s.hrAlertMax = val;
            if (activeItem != null) { (activeItem as WatchUi.MenuItem).setSubLabel((val > 0) ? (val.toString() + " bpm") : "Désactivée"); }
        } else if (activeId == :pace_slow) {
            s.paceAlertSlowSec = val;
            if (activeItem != null) { (activeItem as WatchUi.MenuItem).setSubLabel((val > 0) ? (SportDefinitions.formatPaceSecPerUnit(val.toFloat()) + " /km") : "Désactivée"); }
        } else if (activeId == :dist_alert) {
            s.distAlertMeters = val;
            if (activeItem != null) { (activeItem as WatchUi.MenuItem).setSubLabel((val > 0) ? ((val / 1000.0f).format("%.1f") + " km") : "Désactivée"); }
        } else if (activeId == :time_alert) {
            s.timeAlertMin = val;
            if (activeItem != null) { (activeItem as WatchUi.MenuItem).setSubLabel((val > 0) ? (val.toString() + " min") : "Désactivée"); }
        } else if (activeId == :nutrition) {
            s.nutritionAlertMin = val;
            if (activeItem != null) { (activeItem as WatchUi.MenuItem).setSubLabel((val > 0) ? ("Toutes les " + val.toString() + " min") : "Désactivée"); }
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
