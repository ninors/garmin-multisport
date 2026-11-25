import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// EXACT 2-Level Forerunner 965 French Settings Hierarchy (Photos 2, 3, 4, 5!)
// Level 1 (Root): Paramètres Triathlon | Profils Multisport | Écrans de données | Navigation
// Level 2 (Paramètres Triathlon): Activité 1..N | Ajouter une activité | Transitions | Changement auto | Verrouiller | Répéter | Alertes | Auto Lap | Auto Pause | Enregistrement FIT | Sons
module MainSettingsMenu {

    // LEVEL 1: Root Options Menu (Photo 3!)
    function push(manager as MultisportManager) as Void {
        var s = manager.settings;
        var stats = System.getSystemStats();
        var estH = ((stats.battery / 100.0f) * 18.0f).toNumber();
        var rootTitle = estH.toString() + " heures";
        var profName = SportDefinitions.getProfileName(s.profileId);

        var menu = new WatchUi.Menu2({:title => rootTitle});
        menu.addItem(new WatchUi.MenuItem("Param. " + profName, "Activités, transitions...", :open_tri_settings, null));
        menu.addItem(new WatchUi.MenuItem("Profils Multisport", profName, :open_profiles, null));
        menu.addItem(new WatchUi.MenuItem("Écrans de données", "Modifier les champs", :open_data_fields, null));
        menu.addItem(new WatchUi.MenuItem("Navigation", s.getGpsModeLabel(), :open_navigation, null));

        WatchUi.pushView(menu, new RootSettingsDelegate(manager), WatchUi.SLIDE_LEFT);
    }

    // LEVEL 2: Exact "Paramètres Triathlon" Submenu (Photos 4, 5, 2!)
    function pushTriathlonSettings(manager as MultisportManager) as Void {
        var s = manager.settings;
        var menu = new WatchUi.Menu2({:title => SportDefinitions.getProfileName(s.profileId)});

        // Activité 1, Activité 2, Activité 3... (exact Photo 4!)
        var actNum = 1;
        for (var i = 0; i < manager.legs.size(); i++) {
            var sp = manager.legs[i];
            if (!SportDefinitions.isTransition(sp)) {
                var sub = SportDefinitions.getSportName(sp);
                if (sp == SportDefinitions.SPORT_SWIM_OPEN) { sub = "Eau libre"; }
                else if (sp == SportDefinitions.SPORT_SWIM_POOL) { sub = "Piscine " + s.poolLengthMeters.toString() + " m"; }
                menu.addItem(new WatchUi.MenuItem("Activité " + actNum.toString(), sub, actNum == 1 ? :act_1 : :open_custom_ed, null));
                actNum++;
            }
        }
        menu.addItem(new WatchUi.MenuItem("Ajouter une activité", "Personnaliser la liste", :add_activity, null));

        // Exact Garmin toggles order (Photos 5 & 2!)
        menu.addItem(new WatchUi.ToggleMenuItem("Transitions", s.transitionsEnabled ? "Activé" : "Désactivé", :transitions, s.transitionsEnabled, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Changement auto", s.autoSportChange ? "Activé" : "Désactivé", :auto_sport, s.autoSportChange, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Verrouiller l'appareil", s.lockDeviceEnabled ? "Activé" : "Désactivé", :lock_dev, s.lockDeviceEnabled, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Répéter", s.repeatEnabled ? "Activé" : "Désactivé", :repeat_mode, s.repeatEnabled, null));

        menu.addItem(new WatchUi.MenuItem("Alertes", "FC, Allure, Nutrition", :alerts, null));
        menu.addItem(new WatchUi.MenuItem("Auto Lap", s.getAutoLapLabel(), :auto_lap, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Auto Pause", s.autoPauseEnabled ? "Activé" : "Désactivé", :auto_pause, s.autoPauseEnabled, null));

        var fitModeSub = s.multiFileMode ? "3 activités séparées" : "1 activité (GitHub)";
        menu.addItem(new WatchUi.MenuItem("Enregistrement FIT", fitModeSub, :fit_mode, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Sons et vibrations", s.tonesEnabled ? "Activé" : "Désactivé", :audio_vibe, s.tonesEnabled, null));

        WatchUi.pushView(menu, new TriSettingsDelegate(manager), WatchUi.SLIDE_LEFT);
    }
}

class RootSettingsDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :open_tri_settings) {
            MainSettingsMenu.pushTriathlonSettings(manager);
        } else if (id == :open_profiles) {
            ProfileBuilderMenu.pushSelector(manager);
        } else if (id == :open_data_fields) {
            AlertAndFieldMenus.pushDataFieldsMenu(manager);
        } else if (id == :open_navigation) {
            manager.settings.gpsMode = (manager.settings.gpsMode + 1) % 3;
            manager.settings.save();
            manager.configureGps();
            item.setSubLabel(manager.settings.getGpsModeLabel());
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class TriSettingsDelegate extends WatchUi.Menu2InputDelegate {
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

        if (id == :act_1) {
            // Toggle Swim Open Water / Pool 25m / Pool 50m on Activity 1
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
        } else if (id == :open_custom_ed) {
            ProfileBuilderMenu.pushCustomEditor(manager);
        } else if (id == :add_activity) {
            ProfileBuilderMenu.pushAddSportPicker(manager);
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
        } else if (id == :alerts) {
            AlertAndFieldMenus.pushAlertsMenu(manager);
        } else if (id == :auto_lap) {
            autoLapItem = item;
            var picker = new GarminPickerView("AUTO LAP", "mètres (0 = OFF)", GarminPickerView.MODE_NUMBER, s.autoLapDistanceMeters, 100, 10000, 100);
            WatchUi.pushView(picker, new GarminPickerDelegate(picker, method(:onAutoLapPicked)), WatchUi.SLIDE_LEFT);
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
