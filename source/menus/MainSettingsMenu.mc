import Toybox.Lang;
import Toybox.WatchUi;

// Official Garmin Forerunner 965 French Settings Hierarchy (matching Photos 3, 4, 5, 6!)
module MainSettingsMenu {

    function push(manager as MultisportManager) as Void {
        var s = manager.settings;
        var title = "Param. " + SportDefinitions.getProfileName(s.profileId);
        var menu = new WatchUi.Menu2({:title => title});

        // 1. Activities / Profile order (Activité 1, Activité 2, Activité 3...)
        menu.addItem(new WatchUi.MenuItem("Activités", SportDefinitions.getProfileName(s.profileId), :profile, null));

        // 2. Native FR965 Multisport Toggles in exact Garmin order
        menu.addItem(new WatchUi.ToggleMenuItem("Transitions", s.transitionsEnabled ? "Activé" : "Désactivé", :transitions, s.transitionsEnabled, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Changement auto", s.autoSportChange ? "Activé" : "Désactivé", :auto_sport, s.autoSportChange, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Verrouiller l'appareil", s.lockDeviceEnabled ? "Activé" : "Désactivé", :lock_dev, s.lockDeviceEnabled, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Répéter", s.repeatEnabled ? "Activé" : "Désactivé", :repeat_mode, s.repeatEnabled, null));

        // 3. Data screens, Alerts, Auto Lap, Auto Pause
        menu.addItem(new WatchUi.MenuItem("Écrans de données", "Modifier les champs", :data_fields, null));
        menu.addItem(new WatchUi.MenuItem("Alertes", "FC, Allure, Nutrition", :alerts, null));
        menu.addItem(new WatchUi.MenuItem("Auto Lap", s.getAutoLapLabel(), :auto_lap, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Auto Pause", s.autoPauseEnabled ? "Activé" : "Désactivé", :auto_pause, s.autoPauseEnabled, null));

        // 4. Satellites & Recording mode (1 continuous Running session for GitHub vs 3 separate FIT files!)
        menu.addItem(new WatchUi.MenuItem("Satellites", s.getGpsModeLabel(), :gps_mode, null));
        var fitModeSub = s.multiFileMode ? "3 activités séparées" : "1 activité (GitHub)";
        menu.addItem(new WatchUi.MenuItem("Enregistrement FIT", fitModeSub, :fit_mode, null));

        // 5. Swim & Audio
        var swimLabel = s.swimPoolMode ? ("Piscine " + s.poolLengthMeters.toString() + " m") : "Eau libre";
        menu.addItem(new WatchUi.MenuItem("Natation", swimLabel, :swim_mode, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Sons et vibrations", s.tonesEnabled ? "Activé" : "Désactivé", :audio_vibe, s.tonesEnabled, null));

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
                item.setSubLabel(s.transitionsEnabled ? "Activé" : "Désactivé");
                s.save();
                manager.rebuildProfile();
            }
        } else if (id == :auto_sport) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                s.autoSportChange = (item as WatchUi.ToggleMenuItem).isEnabled();
                item.setSubLabel(s.autoSportChange ? "Activé" : "Désactivé");
                s.save();
            }
        } else if (id == :lock_dev) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                s.lockDeviceEnabled = (item as WatchUi.ToggleMenuItem).isEnabled();
                item.setSubLabel(s.lockDeviceEnabled ? "Activé" : "Désactivé");
                s.save();
            }
        } else if (id == :repeat_mode) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                s.repeatEnabled = (item as WatchUi.ToggleMenuItem).isEnabled();
                item.setSubLabel(s.repeatEnabled ? "Activé" : "Désactivé");
                s.save();
            }
        } else if (id == :auto_pause) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                s.autoPauseEnabled = (item as WatchUi.ToggleMenuItem).isEnabled();
                item.setSubLabel(s.autoPauseEnabled ? "Activé" : "Désactivé");
                s.save();
            }
        } else if (id == :swim_mode) {
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
            item.setSubLabel(s.swimPoolMode ? ("Piscine " + s.poolLengthMeters.toString() + " m") : "Eau libre");
        } else if (id == :data_fields) {
            AlertAndFieldMenus.pushDataFieldsMenu(manager);
        } else if (id == :alerts) {
            AlertAndFieldMenus.pushAlertsMenu(manager);
        } else if (id == :auto_lap) {
            autoLapItem = item;
            var picker = new GarminPickerView("AUTO LAP", "mètres (0 = OFF)", GarminPickerView.MODE_NUMBER, s.autoLapDistanceMeters, 100, 10000, 100);
            WatchUi.pushView(picker, new GarminPickerDelegate(picker, method(:onAutoLapPicked)), WatchUi.SLIDE_LEFT);
        } else if (id == :gps_mode) {
            s.gpsMode = (s.gpsMode + 1) % 3;
            s.save();
            manager.configureGps();
            item.setSubLabel(s.getGpsModeLabel());
        } else if (id == :fit_mode) {
            s.multiFileMode = !s.multiFileMode;
            s.save();
            item.setSubLabel(s.multiFileMode ? "3 activités séparées" : "1 activité (GitHub)");
        } else if (id == :audio_vibe) {
            if (item instanceof WatchUi.ToggleMenuItem) {
                var en = (item as WatchUi.ToggleMenuItem).isEnabled();
                s.tonesEnabled = en;
                s.vibesEnabled = en;
                item.setSubLabel(en ? "Activé" : "Désactivé");
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
