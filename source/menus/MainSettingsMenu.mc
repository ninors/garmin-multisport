import Toybox.Lang;
import Toybox.WatchUi;

module MainSettingsMenu {

    function push(manager as MultisportManager) as Void {
        var s = manager.settings;
        var menu = new WatchUi.Menu2({:title => "Paramètres"});

        menu.addItem(new WatchUi.MenuItem("Profil Multisport", SportDefinitions.getProfileName(s.profileId), :profile, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Transitions", "Inclure T1 / T2", :transitions, s.transitionsEnabled, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Changement auto", "Détection sport auto", :auto_sport, s.autoSportChange, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Pause auto", "Arrêt automatique", :auto_pause, s.autoPauseEnabled, null));

        var swimLabel = s.swimPoolMode ? ("Piscine " + s.poolLengthMeters.toString() + "m") : "Eau libre (GPS)";
        menu.addItem(new WatchUi.MenuItem("Natation", swimLabel, :swim_mode, null));

        menu.addItem(new WatchUi.MenuItem("Écrans de données", "Champs par sport", :data_fields, null));
        menu.addItem(new WatchUi.MenuItem("Alertes", "FC, Allure, Nutrition", :alerts, null));
        menu.addItem(new WatchUi.MenuItem("Tours auto", s.getAutoLapLabel(), :auto_lap, null));
        menu.addItem(new WatchUi.MenuItem("GPS & Satellites", s.getGpsModeLabel(), :gps_mode, null));
        menu.addItem(new WatchUi.MenuItem("Enregistrement", s.getRecordingModeLabel(), :rec_mode, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Sons & Vibrations", "Bips et retours", :audio_vibe, s.tonesEnabled, null));

        WatchUi.pushView(menu, new MainSettingsMenuDelegate(manager), WatchUi.SLIDE_LEFT);
    }
}

class MainSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;
    private var autoLapItem as WatchUi.MenuItem?;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
        autoLapItem = null;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var s = manager.settings;

        if (id == :profile) {
            ProfileBuilderMenu.pushSelector(manager);
        } else if (id == :transitions) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                s.transitionsEnabled = (item as WatchUi.ToggleMenuItem).isEnabled();
                s.save();
                manager.rebuildProfile();
            }
        } else if (id == :auto_sport) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                s.autoSportChange = (item as WatchUi.ToggleMenuItem).isEnabled();
                s.save();
            }
        } else if (id == :auto_pause) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                s.autoPauseEnabled = (item as WatchUi.ToggleMenuItem).isEnabled();
                s.save();
            }
        } else if (id == :swim_mode) {
            // Cycle: Eau libre -> Piscine 25m -> Piscine 50m -> Eau libre
            if (!s.swimPoolMode) {
                s.swimPoolMode = true;
                s.poolLengthMeters = 25;
            } else if (s.poolLengthMeters == 25) {
                s.poolLengthMeters = 50;
            } else {
                s.swimPoolMode = false;
            }
            s.save();
            manager.rebuildProfile();
            item.setSubLabel(s.swimPoolMode ? ("Piscine " + s.poolLengthMeters.toString() + "m") : "Eau libre (GPS)");
        } else if (id == :data_fields) {
            AlertAndFieldMenus.pushDataFieldsMenu(manager);
        } else if (id == :alerts) {
            AlertAndFieldMenus.pushAlertsMenu(manager);
        } else if (id == :auto_lap) {
            autoLapItem = item;
            var picker = new GarminPickerView("TOURS AUTO", "mètres (0 = OFF)", GarminPickerView.MODE_NUMBER, s.autoLapDistanceMeters, 100, 10000, 100);
            WatchUi.pushView(picker, new GarminPickerDelegate(picker, method(:onAutoLapPicked)), WatchUi.SLIDE_LEFT);
        } else if (id == :gps_mode) {
            s.gpsMode = (s.gpsMode + 1) % 3;
            s.save();
            manager.configureGps();
            item.setSubLabel(s.getGpsModeLabel());
        } else if (id == :rec_mode) {
            s.recordingMode = (s.recordingMode + 1) % 2;
            s.save();
            item.setSubLabel(s.getRecordingModeLabel());
        } else if (id == :audio_vibe) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                var en = (item as WatchUi.ToggleMenuItem).isEnabled();
                s.tonesEnabled = en;
                s.vibesEnabled = en;
                s.save();
            }
        }
    }

    public function onAutoLapPicked(val as Number) as Void {
        manager.settings.autoLapDistanceMeters = val;
        manager.settings.save();
        if (autoLapItem != null) {
            (autoLapItem as WatchUi.MenuItem).setSubLabel(manager.settings.getAutoLapLabel());
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
