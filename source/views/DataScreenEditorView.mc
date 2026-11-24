import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Authentic Garmin Forerunner 965 Interactive Visual Data Screen Customizer
class DataScreenEditorView extends WatchUi.View {
    private var manager as MultisportManager;
    public var sportCategory as Number; // 0 = Swim, 1 = Bike, 2 = Run
    public var selectedSlot as Number;  // 0 = Top, 1 = Middle-Left, 2 = Middle-Right

    function initialize(mgr as MultisportManager, category as Number) {
        View.initialize();
        manager = mgr;
        sportCategory = category;
        selectedSlot = 0;
    }

    public function nextSlot() as Void {
        selectedSlot = (selectedSlot + 1) % 3;
        WatchUi.requestUpdate();
    }

    public function prevSlot() as Void {
        selectedSlot = (selectedSlot + 2) % 3;
        WatchUi.requestUpdate();
    }

    public function getSportType() as Number {
        if (sportCategory == 0) { return SportDefinitions.SPORT_SWIM_OPEN; }
        if (sportCategory == 1) { return SportDefinitions.SPORT_BIKE; }
        return SportDefinitions.SPORT_RUN;
    }

    function onUpdate(dc as Dc) as Void {
        Theme.enableAA(dc);
        var w = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Theme.COLOR_BG, Theme.COLOR_BG);
        dc.clear();

        var s = manager.settings;
        var fTop = (sportCategory == 0) ? s.swimFieldTop : ((sportCategory == 1) ? s.bikeFieldTop : s.runFieldTop);
        var fLeft = (sportCategory == 0) ? s.swimFieldLeft : ((sportCategory == 1) ? s.bikeFieldLeft : s.runFieldLeft);
        var fRight = (sportCategory == 0) ? s.swimFieldRight : ((sportCategory == 1) ? s.bikeFieldRight : s.runFieldRight);

        // Red FR965 dividers
        dc.setColor(Theme.COLOR_RED_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(14, 130, w - 14, 130);
        dc.drawLine(14, 256, w - 14, 256);
        dc.drawLine(cx, 130, cx, 256);

        // Highlight selected slot with authentic Garmin Blue selection border!
        var selColor = 0x00AAFF;
        dc.setPenWidth(4);
        if (selectedSlot == 0) {
            dc.setColor(selColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(58, 22, w - 116, 102, 14);
        } else if (selectedSlot == 1) {
            dc.setColor(selColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(14, 134, cx - 18, 118, 12);
        } else {
            dc.setColor(selColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(cx + 4, 134, cx - 18, 118, 12);
        }

        // Slot 0: Top
        dc.setColor(selectedSlot == 0 ? selColor : Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 44, Graphics.FONT_XTINY, SportDefinitions.getFieldLabel(fTop), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 88, Graphics.FONT_MEDIUM, getSampleValue(fTop), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Slot 1: Middle-Left
        var lCx = (cx / 2) + 8;
        dc.setColor(selectedSlot == 1 ? selColor : Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 160, Graphics.FONT_XTINY, SportDefinitions.getFieldLabel(fLeft), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(lCx, 206, Graphics.FONT_MEDIUM, getSampleValue(fLeft), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Slot 2: Middle-Right
        var rCx = cx + (cx / 2) - 8;
        dc.setColor(selectedSlot == 2 ? selColor : Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 160, Graphics.FONT_XTINY, SportDefinitions.getFieldLabel(fRight), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rCx, 206, Graphics.FONT_MEDIUM, getSampleValue(fRight), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom: Fixed HR gauge preview + instructions
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        var sportName = (sportCategory == 0) ? "NATATION" : ((sportCategory == 1) ? "VÉLO" : "COURSE");
        dc.drawText(cx, 286, Graphics.FONT_XTINY, sportName, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(selColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 318, Graphics.FONT_XTINY, "START : Modifier", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 344, Graphics.FONT_XTINY, "UP/DOWN : Champ", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function getSampleValue(fieldId as Number) as String {
        switch (fieldId) {
            case SportDefinitions.FIELD_CHRONO: return "12:34";
            case SportDefinitions.FIELD_DISTANCE: return "1.50";
            case SportDefinitions.FIELD_PACE: return "4:15";
            case SportDefinitions.FIELD_SPEED: return "34.2";
            case SportDefinitions.FIELD_POWER: return "245";
            case SportDefinitions.FIELD_CADENCE: return "178";
            case SportDefinitions.FIELD_AVG_PACE: return "4:20";
            case SportDefinitions.FIELD_AVG_SPEED: return "32.5";
            case SportDefinitions.FIELD_CALORIES: return "320";
            case SportDefinitions.FIELD_ELEVATION: return "125m";
            case SportDefinitions.FIELD_LAP_TIME: return "3:45";
            case SportDefinitions.FIELD_LAP_DIST: return "1.00";
            case SportDefinitions.FIELD_TOTAL_TIME: return "48:12";
            case SportDefinitions.FIELD_SWOLF: return "34";
            default: return "--";
        }
    }
}

class DataScreenEditorDelegate extends WatchUi.BehaviorDelegate {
    private var manager as MultisportManager;
    private var view as DataScreenEditorView;

    function initialize(mgr as MultisportManager, v as DataScreenEditorView) {
        BehaviorDelegate.initialize();
        manager = mgr;
        view = v;
    }

    function onNextPage() as Boolean {
        view.nextSlot();
        return true;
    }

    function onPreviousPage() as Boolean {
        view.prevSlot();
        return true;
    }

    function onSelect() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Choisir champ"});
        menu.addItem(new WatchUi.MenuItem("Chrono", "Temps du segment", SportDefinitions.FIELD_CHRONO, null));
        menu.addItem(new WatchUi.MenuItem("Distance", "Distance du segment", SportDefinitions.FIELD_DISTANCE, null));
        menu.addItem(new WatchUi.MenuItem("Allure", "Allure instantanée", SportDefinitions.FIELD_PACE, null));
        menu.addItem(new WatchUi.MenuItem("Vitesse", "km/h instantané", SportDefinitions.FIELD_SPEED, null));
        menu.addItem(new WatchUi.MenuItem("Allure moy.", "Moyenne du segment", SportDefinitions.FIELD_AVG_PACE, null));
        menu.addItem(new WatchUi.MenuItem("Vitesse moy.", "Moyenne km/h", SportDefinitions.FIELD_AVG_SPEED, null));
        menu.addItem(new WatchUi.MenuItem("Cadence", "Pas / tours par min", SportDefinitions.FIELD_CADENCE, null));
        menu.addItem(new WatchUi.MenuItem("Temps total", "Chrono global", SportDefinitions.FIELD_TOTAL_TIME, null));
        menu.addItem(new WatchUi.MenuItem("Temps tour", "Chrono du tour", SportDefinitions.FIELD_LAP_TIME, null));
        menu.addItem(new WatchUi.MenuItem("Dist. tour", "Distance du tour", SportDefinitions.FIELD_LAP_DIST, null));
        menu.addItem(new WatchUi.MenuItem("Calories", "kcal dépensées", SportDefinitions.FIELD_CALORIES, null));
        menu.addItem(new WatchUi.MenuItem("Altitude", "Élévation en m", SportDefinitions.FIELD_ELEVATION, null));
        menu.addItem(new WatchUi.MenuItem("SWOLF", "Efficacité natation", SportDefinitions.FIELD_SWOLF, null));
        menu.addItem(new WatchUi.MenuItem("Puissance", "Watts (si capteur)", SportDefinitions.FIELD_POWER, null));

        WatchUi.pushView(menu, new FieldValuePickerDelegate(manager, view.sportCategory, view.selectedSlot), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

class FieldValuePickerDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;
    private var sportCategory as Number;
    private var slot as Number;

    function initialize(mgr as MultisportManager, cat as Number, sl as Number) {
        Menu2InputDelegate.initialize();
        manager = mgr;
        sportCategory = cat;
        slot = sl;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof Number) {
            var fieldVal = id as Number;
            var s = manager.settings;
            if (sportCategory == 0) {
                if (slot == 0) { s.swimFieldTop = fieldVal; }
                else if (slot == 1) { s.swimFieldLeft = fieldVal; }
                else { s.swimFieldRight = fieldVal; }
            } else if (sportCategory == 1) {
                if (slot == 0) { s.bikeFieldTop = fieldVal; }
                else if (slot == 1) { s.bikeFieldLeft = fieldVal; }
                else { s.bikeFieldRight = fieldVal; }
            } else {
                if (slot == 0) { s.runFieldTop = fieldVal; }
                else if (slot == 1) { s.runFieldLeft = fieldVal; }
                else { s.runFieldRight = fieldVal; }
            }
            s.save();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
