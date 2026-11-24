import Toybox.Lang;
import Toybox.WatchUi;

module PauseMenu {

    function push(manager as MultisportManager) as Void {
        var menu = new WatchUi.Menu2({:title => "PAUSE"});
        menu.addItem(new WatchUi.MenuItem("Reprendre", SportDefinitions.getSportName(manager.getCurrentSport()), :resume, null));
        menu.addItem(new WatchUi.MenuItem("Enregistrer", SportDefinitions.formatTime(manager.totalElapsedMs), :save, null));

        var nextSport = manager.getNextSport();
        if (nextSport != null) {
            menu.addItem(new WatchUi.MenuItem("Sport suivant", SportDefinitions.getSportName(nextSport as Number), :next_sport, null));
        }
        menu.addItem(new WatchUi.MenuItem("Ignorer", "Supprimer l'activité", :discard, null));

        WatchUi.pushView(menu, new PauseMenuDelegate(manager), WatchUi.SLIDE_LEFT);
    }
}

class PauseMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        Menu2InputDelegate.initialize();
        manager = mgr;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :resume) {
            if (manager.state == MultisportManager.STATE_PAUSED) {
                manager.togglePause();
            }
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (id == :next_sport) {
            var finished = manager.nextSegment();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            if (finished) {
                var evalView = new FeelEvalView(manager);
                WatchUi.switchToView(evalView, new FeelEvalDelegate(manager, evalView), WatchUi.SLIDE_LEFT);
            }
        } else if (id == :save) {
            manager.saveAndFinish();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            var evalView = new FeelEvalView(manager);
            WatchUi.switchToView(evalView, new FeelEvalDelegate(manager, evalView), WatchUi.SLIDE_LEFT);
        } else if (id == :lap) {
            if (manager.state == MultisportManager.STATE_PAUSED) {
                manager.togglePause();
            }
            manager.addManualLap();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (id == :settings) {
            MainSettingsMenu.push(manager);
        } else if (id == :discard) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            var confirm = new WatchUi.Confirmation("Ignorer l'activité ?");
            WatchUi.pushView(confirm, new DiscardConfirmDelegate(manager), WatchUi.SLIDE_UP);
        }
    }

    function onBack() as Void {
        if (manager.state == MultisportManager.STATE_PAUSED) {
            manager.togglePause();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class DiscardConfirmDelegate extends WatchUi.ConfirmationDelegate {
    private var manager as MultisportManager;

    function initialize(mgr as MultisportManager) {
        ConfirmationDelegate.initialize();
        manager = mgr;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            manager.discardAll();
            var preView = new PreStartView(manager);
            var preDel = new PreStartDelegate(manager);
            WatchUi.switchToView(preView, preDel, WatchUi.SLIDE_RIGHT);
        } else {
            if (manager.state == MultisportManager.STATE_PAUSED) {
                manager.togglePause();
            }
        }
        return true;
    }
}
