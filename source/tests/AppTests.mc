import Toybox.Lang;
import Toybox.Test;

module AppTests {

    (:test)
    function testFullMultisportLifecycle(logger as Test.Logger) as Boolean {
        var settings = new SettingsModel();
        var mgr = new MultisportManager(settings);
        mgr.startSensors();

        // 1. Pre-Start state check
        Test.assertEqual(mgr.state, MultisportManager.STATE_PRE_START);
        Test.assert(mgr.legs.size() >= 3);

        // 2. Start activity -> Big Green Triangle overlay + ACTIVE state
        mgr.startActivity();
        Test.assertEqual(mgr.state, MultisportManager.STATE_ACTIVE);
        Test.assertEqual(mgr.overlayType, MultisportManager.OVERLAY_START);

        // 3. Simulate ticks (tests updateActiveMetrics, checkAlerts, checkAutoSportChange on fr165m!)
        mgr.heartRate = 148;
        mgr.speedMps = 3.2f;
        mgr.cadence = 172;
        for (var i = 0; i < 4; i++) {
            mgr.onTick();
        }
        // After 2+ ticks, START overlay auto-clears
        Test.assertEqual(mgr.overlayType, MultisportManager.OVERLAY_NONE);

        // 4. Pause & Resume -> Big Red Square then Big Green Triangle
        mgr.togglePause();
        Test.assertEqual(mgr.state, MultisportManager.STATE_PAUSED);
        Test.assertEqual(mgr.overlayType, MultisportManager.OVERLAY_PAUSE);

        mgr.togglePause();
        Test.assertEqual(mgr.state, MultisportManager.STATE_ACTIVE);
        Test.assertEqual(mgr.overlayType, MultisportManager.OVERLAY_START);

        // 5. Manual Lap
        mgr.addManualLap();
        Test.assertEqual(mgr.overlayType, MultisportManager.OVERLAY_LAP);

        // 6. Advance through all segments (Swim -> T1 -> Bike -> T2 -> Run -> Summary)
        // Run 3 ticks per leg so pendingSessionDelay=2 ACTUALLY triggers createSession for EVERY leg!
        var finished = false;
        var guard = 0;
        while (!finished && guard < 10) {
            finished = mgr.nextSegment();
            for (var t = 0; t < 3; t++) {
                mgr.onTick();
            }
            guard++;
        }
        Test.assert(finished);
        Test.assertEqual(mgr.state, MultisportManager.STATE_SUMMARY);

        // 7. Reset back to Pre-Start
        mgr.resetToPreStart();
        Test.assertEqual(mgr.state, MultisportManager.STATE_PRE_START);

        mgr.stopSensors();
        logger.debug("Full fr165m multisport lifecycle passed cleanly!");
        return true;
    }
}
