import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class MultisportApp extends Application.AppBase {
    private var settings as SettingsModel?;
    private var manager as MultisportManager?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        settings = new SettingsModel();
        manager = new MultisportManager(settings as SettingsModel);
        (manager as MultisportManager).startSensors();
    }

    function onStop(state as Dictionary?) as Void {
        if (manager != null) {
            (manager as MultisportManager).stopSensors();
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var mgr = manager as MultisportManager;
        return [new PreStartView(mgr), new PreStartDelegate(mgr)];
    }
}
