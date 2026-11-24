import Toybox.Lang;
import Toybox.WatchUi;

module ProfileBuilderMenu {

    function pushSelector(manager as MultisportManager) as Void {
        var menu = new WatchUi.Menu2({:title => "Profil Multisport"});
        menu.addItem(new WatchUi.MenuItem("Triathlon", "Nage • Vélo • Course", :triathlon, null));
        menu.addItem(new WatchUi.MenuItem("Duathlon", "Course • Vélo • Course", :duathlon, null));
        menu.addItem(new WatchUi.MenuItem("Swimrun", "Nage • Course • Nage • Course", :swimrun, null));
        menu.addItem(new WatchUi.MenuItem("Multisport Perso", manager.settings.customSports.size().toString() + " sports", :custom, null));
        menu.addItem(new WatchUi.MenuItem("Éditer Perso...", "Ajouter / Retirer", :edit_custom, null));

        WatchUi.pushView(menu, new ProfileSelectorDelegate(manager), WatchUi.SLIDE_LEFT);
    }

    function pushCustomEditor(manager as MultisportManager) as Void {
        var menu = new WatchUi.Menu2({:title => "Éditer Perso"});
        var sports = manager.settings.customSports;
        for (var i = 0; i < sports.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(
                (i + 1).toString() + ". " + SportDefinitions.getSportName(sports[i]),
                "Appuyer pour retirer",
                i,
                null
            ));
        }
        menu.addItem(new WatchUi.MenuItem("+ Ajouter un sport", "Natation, Vélo, Course...", :add_sport, null));
        menu.addItem(new WatchUi.MenuItem("Réinitialiser", "Triathlon par défaut", :reset_custom, null));

        WatchUi.pushView(menu, new CustomEditorDelegate(manager), WatchUi.SLIDE_LEFT);
    }

    function pushAddSportPicker(manager as MultisportManager) as Void {
        var menu = new WatchUi.Menu2({:title => "Ajouter Sport"});
        menu.addItem(new WatchUi.MenuItem("Natation", "Eau libre / Piscine", SportDefinitions.SPORT_SWIM_OPEN, null));
        menu.addItem(new WatchUi.MenuItem("Vélo", "Route / Triathlon", SportDefinitions.SPORT_BIKE, null));
        menu.addItem(new WatchUi.MenuItem("Course", "Course à pied", SportDefinitions.SPORT_RUN, null));
        menu.addItem(new WatchUi.MenuItem("Trail", "Sentier", SportDefinitions.SPORT_TRAIL, null));
        menu.addItem(new WatchUi.MenuItem("Marche", "Randonnée / Marche", SportDefinitions.SPORT_WALK, null));
        menu.addItem(new WatchUi.MenuItem("Cardio", "Fitness / Renfo", SportDefinitions.SPORT_CARDIO, null));

        WatchUi.pushView(menu, new AddSportPickerDelegate(manager), WatchUi.SLIDE_LEFT);
    }
}

class ProfileSelectorDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :triathlon) {
            manager.settings.profileId = SportDefinitions.PROFILE_TRIATHLON;
        } else if (id == :duathlon) {
            manager.settings.profileId = SportDefinitions.PROFILE_DUATHLON;
        } else if (id == :swimrun) {
            manager.settings.profileId = SportDefinitions.PROFILE_SWIMRUN;
        } else if (id == :custom) {
            manager.settings.profileId = SportDefinitions.PROFILE_CUSTOM;
        } else if (id == :edit_custom) {
            ProfileBuilderMenu.pushCustomEditor(manager);
            return;
        }
        manager.settings.save();
        manager.rebuildProfile();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class CustomEditorDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :add_sport) {
            ProfileBuilderMenu.pushAddSportPicker(manager);
        } else if (id == :reset_custom) {
            manager.settings.customSports = [
                SportDefinitions.SPORT_SWIM_OPEN,
                SportDefinitions.SPORT_BIKE,
                SportDefinitions.SPORT_RUN
            ] as Array<Number>;
            manager.settings.profileId = SportDefinitions.PROFILE_CUSTOM;
            manager.settings.save();
            manager.rebuildProfile();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (id instanceof Number) {
            var idx = id as Number;
            if (manager.settings.customSports.size() > 2 && idx >= 0 && idx < manager.settings.customSports.size()) {
                var newList = [] as Array<Number>;
                for (var i = 0; i < manager.settings.customSports.size(); i++) {
                    if (i != idx) {
                        newList.add(manager.settings.customSports[i]);
                    }
                }
                manager.settings.customSports = newList;
                manager.settings.profileId = SportDefinitions.PROFILE_CUSTOM;
                manager.settings.save();
                manager.rebuildProfile();
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                ProfileBuilderMenu.pushCustomEditor(manager);
            }
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class AddSportPickerDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof Number) {
            manager.settings.customSports.add(id as Number);
            manager.settings.profileId = SportDefinitions.PROFILE_CUSTOM;
            manager.settings.save();
            manager.rebuildProfile();
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        ProfileBuilderMenu.pushCustomEditor(manager);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
