import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.UserProfile;
import Toybox.WatchUi;

class MultisportManager {
    // App states
    public static const STATE_PRE_START = 0;
    public static const STATE_ACTIVE = 1;
    public static const STATE_PAUSED = 2;
    public static const STATE_SUMMARY = 3;

    public var settings as SettingsModel;
    public var state as Number;
    public var legs as Array<Number>;
    public var segments as Array<SegmentData>;
    public var currentLegIndex as Number;
    public var msGroupId as String;

    // Live sensor telemetry
    public var heartRate as Number;
    public var speedMps as Float;
    public var cadence as Number;
    public var power as Number;
    public var altitude as Float;
    public var heading as Float;
    public var gpsQuality as Number;
    public var hasPosition as Boolean;

    // Current lap tracking
    public var lapStartElapsedMs as Number;
    public var lapStartDistMeters as Float;
    public var lastAutoLapDistMeters as Float;

    // Global summary accumulators
    public var totalElapsedMs as Number;
    public var totalDistanceMeters as Float;
    public var totalCalories as Number;
    public var globalMaxHr as Number;
    public var globalHrSum as Number;
    public var globalHrSamples as Number;
    public var hrZones as Array<Number>; // 6 bounds: [z1min, z1max, z2max, z3max, z4max, z5max]
    public var zoneSeconds as Array<Number>; // 5 buckets

    // Native Garmin full-screen overlay types (no ugly rectangle popups!)
    public static const OVERLAY_NONE = 0;
    public static const OVERLAY_START = 1;       // Big green triangle + green bezel ring
    public static const OVERLAY_PAUSE = 2;       // Big red square + red bezel ring
    public static const OVERLAY_TRANSITION = 3;  // Big sport icon + colored ring + split
    public static const OVERLAY_LAP = 4;         // Native Garmin lap banner
    public static const OVERLAY_ALERT = 5;       // Clean Garmin alert (GPS / HR / Nutrition)

    // Overlay state
    public var overlayType as Number;
    public var overlayColor as Number;
    public var overlaySport as Number;
    public var alertMessage as String?;
    public var alertSubMessage as String?;
    public var alertExpiresTick as Number;
    public var tickCount as Number;
    public var lastNutritionAlertSec as Number;
    public var lastDistAlertMeters as Float;
    public var lastTimeAlertSec as Number;
    public var lastHrAlertTick as Number;
    public var lastPaceAlertTick as Number;

    // Auto-sport & Auto-pause heuristic counters
    private var autoSportMatchTicks as Number;
    public var autoPaused as Boolean;
    private var autoPauseStopTicks as Number;
    private var autoPauseMoveTicks as Number;

    // Post-activity self-evaluation feel rating (0..4)
    public var feelRating as Number;

    // Lock state (LIGHT button long/toggle)
    public var isLocked as Boolean;

    // GPS track ring buffer (max 160 points for low RAM, tagged with sport for multi-color map!)
    public static const MAX_TRACK_POINTS = 160;
    public var trackLats as Array<Float>;
    public var trackLons as Array<Float>;
    public var trackSports as Array<Number>;
    private var lastTrackLat as Double;
    private var lastTrackLon as Double;
    private var hasLastTrack as Boolean;

    // Elevation profile ring buffer (max 80 points, low RAM & low battery) + D+/D-
    public static const MAX_ALT_POINTS = 80;
    public var altHistory as Array<Float>;
    public var totalAscent as Float;
    public var totalDescent as Float;
    private var lastAltSample as Float;
    private var hasLastAlt as Boolean;

    // Active continuous FIT recording session (keeps LiveTrack & audio 100% seamless!)
    private var session as ActivityRecording.Session?;
    private var sportLapField as FitContributor.Field?;
    private var feelSessionField as FitContributor.Field?;
    private var timer as Timer.Timer;
    private var segmentStartMs as Number;
    private var segmentStartDistMeters as Float;
    private var segmentStartCalories as Number;
    private var pauseStartMs as Number;
    private var accumulatedPauseMs as Number;
    private var lastSessionDist as Float;

    function initialize(settingsModel as SettingsModel) {
        settings = settingsModel;
        state = STATE_PRE_START;
        legs = [] as Array<Number>;
        segments = [] as Array<SegmentData>;
        currentLegIndex = 0;
        msGroupId = "";

        heartRate = 0;
        speedMps = 0.0f;
        cadence = 0;
        power = 0;
        altitude = 0.0f;
        heading = 0.0f;
        gpsQuality = Position.QUALITY_NOT_AVAILABLE;
        hasPosition = false;

        lapStartElapsedMs = 0;
        lapStartDistMeters = 0.0f;
        lastAutoLapDistMeters = 0.0f;

        totalElapsedMs = 0;
        totalDistanceMeters = 0.0f;
        totalCalories = 0;
        globalMaxHr = 0;
        globalHrSum = 0;
        globalHrSamples = 0;
        zoneSeconds = [0, 0, 0, 0, 0] as Array<Number>;

        overlayType = OVERLAY_NONE;
        overlayColor = 0x00E64D;
        overlaySport = SportDefinitions.SPORT_SWIM_OPEN;
        alertMessage = null;
        alertSubMessage = null;
        alertExpiresTick = 0;
        tickCount = 0;
        lastNutritionAlertSec = 0;
        lastDistAlertMeters = 0.0f;
        lastTimeAlertSec = 0;
        lastHrAlertTick = -30;
        lastPaceAlertTick = -30;
        autoSportMatchTicks = 0;
        autoPaused = false;
        autoPauseStopTicks = 0;
        autoPauseMoveTicks = 0;
        feelRating = 3;
        isLocked = false;

        trackLats = [] as Array<Float>;
        trackLons = [] as Array<Float>;
        trackSports = [] as Array<Number>;
        lastTrackLat = 0.0d;
        lastTrackLon = 0.0d;
        hasLastTrack = false;

        altHistory = [] as Array<Float>;
        totalAscent = 0.0f;
        totalDescent = 0.0f;
        lastAltSample = 0.0f;
        hasLastAlt = false;

        session = null;
        sportLapField = null;
        feelSessionField = null;
        segmentStartMs = 0;
        segmentStartDistMeters = 0.0f;
        segmentStartCalories = 0;
        pauseStartMs = 0;
        accumulatedPauseMs = 0;
        lastSessionDist = 0.0f;

        hrZones = loadHrZonesForSport(getCurrentSport());
        rebuildProfile();

        timer = new Timer.Timer();
        timer.start(method(:onTick), 1000, true);
    }

    public function startSensors() as Void {
        // Safely enable supported sensors on fr165m (avoid crash on unsupported BIKEPOWER)
        try {
            Sensor.setEnabledSensors([
                Sensor.SENSOR_HEARTRATE,
                Sensor.SENSOR_BIKECADENCE,
                Sensor.SENSOR_BIKESPEED,
                Sensor.SENSOR_FOOTPOD
            ]);
        } catch (ex) {
            try {
                Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            } catch (ex2) {
                // Ignore if simulator has restricted sensors
            }
        }
        try {
            Sensor.enableSensorEvents(method(:onSensor));
        } catch (ex3) {
        }
        configureGps();
    }

    public function stopSensors() as Void {
        try {
            Sensor.enableSensorEvents(null);
        } catch (ex) {
        }
        try {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        } catch (ex2) {
        }
        timer.stop();
    }

    public function configureGps() as Void {
        try {
            var options = {
                :acquisitionType => Position.LOCATION_CONTINUOUS
            };
            if (Position has :hasConfigurationSupport) {
                if (settings.gpsMode == 0 && Position has :CONFIGURATION_GPS && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS)) {
                    options[:configuration] = Position.CONFIGURATION_GPS;
                } else if (settings.gpsMode == 2 && Position has :CONFIGURATION_SAT_IQ && Position.hasConfigurationSupport(Position.CONFIGURATION_SAT_IQ)) {
                    options[:configuration] = Position.CONFIGURATION_SAT_IQ;
                } else if (Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1 && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1)) {
                    options[:configuration] = Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1;
                }
            }
            Position.enableLocationEvents(options, method(:onPosition));
        } catch (ex) {
            try {
                Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
            } catch (ex2) {
            }
        }
    }

    public function rebuildProfile() as Void {
        if (state != STATE_PRE_START) {
            return;
        }
        legs = SportDefinitions.buildLegs(
            settings.profileId,
            settings.transitionsEnabled,
            settings.swimPoolMode,
            settings.customSports
        );
        segments = [] as Array<SegmentData>;
        for (var i = 0; i < legs.size(); i++) {
            segments.add(new SegmentData(legs[i]));
        }
        currentLegIndex = 0;
    }

    public function getCurrentSport() as Number {
        if (legs.size() == 0) {
            return SportDefinitions.SPORT_RUN;
        }
        if (currentLegIndex < 0 || currentLegIndex >= legs.size()) {
            return legs[legs.size() - 1];
        }
        return legs[currentLegIndex];
    }

    public function getNextSport() as Number? {
        if (currentLegIndex + 1 < legs.size()) {
            return legs[currentLegIndex + 1];
        }
        return null;
    }

    public function getCurrentSegment() as SegmentData {
        if (segments.size() == 0) {
            segments.add(new SegmentData(SportDefinitions.SPORT_RUN));
        }
        if (currentLegIndex < 0 || currentLegIndex >= segments.size()) {
            return segments[segments.size() - 1];
        }
        return segments[currentLegIndex];
    }

    // Start the multisport activity from Pre-Start
    public function startActivity() as Void {
        if (state != STATE_PRE_START) {
            return;
        }
        rebuildProfile();
        var nowInfo = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var yrStr = (nowInfo.year as Number).format("%04d").substring(2, 4);
        var moStr = (nowInfo.month as Number).format("%02d");
        var dyStr = (nowInfo.day as Number).format("%02d");
        msGroupId = (yrStr != null ? yrStr : "26") +
            moStr +
            dyStr + "_" +
            nowInfo.hour.format("%02d") +
            nowInfo.min.format("%02d");

        totalElapsedMs = 0;
        totalDistanceMeters = 0.0f;
        totalCalories = 0;
        globalMaxHr = 0;
        globalHrSum = 0;
        globalHrSamples = 0;
        zoneSeconds = [0, 0, 0, 0, 0] as Array<Number>;
        trackLats = [] as Array<Float>;
        trackLons = [] as Array<Float>;
        trackSports = [] as Array<Number>;
        hasLastTrack = false;
        altHistory = [] as Array<Float>;
        totalAscent = 0.0f;
        totalDescent = 0.0f;
        hasLastAlt = false;
        lastNutritionAlertSec = 0;
        lastDistAlertMeters = 0.0f;
        lastTimeAlertSec = 0;

        currentLegIndex = 0;
        state = STATE_ACTIVE;
        hrZones = loadHrZonesForSport(getCurrentSport());
        startContinuousSession();
        // Vibrate only (Garmin firmware already plays the native Start tone when session.start() runs)
        triggerVibeOnly(100);
        showOverlay(OVERLAY_START, 0x00E64D, getCurrentSport(), "", "", 2);
    }

    // Move to the next leg/transition (BACK/LAP button)
    // Uses session.addLap() on the single continuous session -> ZERO stop/start voice prompts,
    // ZERO double-beeps, and 100% continuous LiveTrack!
    public function nextSegment() as Boolean {
        if (state != STATE_ACTIVE && state != STATE_PAUSED) {
            return false;
        }

        var curSeg = getCurrentSegment();
        curSeg.completed = true;
        var prevTime = SportDefinitions.formatTime(curSeg.elapsedMs);

        // Tag the completed lap with its exact SportType ID for the GitHub Multisport FIT converter
        if (sportLapField != null) {
            sportLapField.setData(curSeg.sportType);
        }

        if (currentLegIndex + 1 >= legs.size()) {
            // Stop recording now; commitSaveWithFeel() will write the chosen smiley & save the FIT!
            if (session != null && session.isRecording()) {
                session.stop();
            }
            state = STATE_SUMMARY;
            triggerVibeOnly(150);
            overlayType = OVERLAY_NONE;
            return true;
        }

        // Seamless lap marker inside the single continuous session!
        if (session != null && session.isRecording()) {
            session.addLap();
        }

        currentLegIndex++;
        state = STATE_ACTIVE;
        autoSportMatchTicks = 0;
        hrZones = loadHrZonesForSport(getCurrentSport());

        // Reset per-segment baseline offsets from the continuous session
        segmentStartMs = System.getTimer();
        accumulatedPauseMs = 0;
        segmentStartDistMeters = lastSessionDist;
        segmentStartCalories = totalCalories;
        lapStartElapsedMs = 0;
        lapStartDistMeters = 0.0f;
        lastAutoLapDistMeters = 0.0f;

        // Pre-tag the new lap with the new sport
        if (sportLapField != null) {
            sportLapField.setData(getCurrentSport());
        }

        // Single clean lap feedback (no Stop/Start double tone!)
        triggerFeedback(Attention.TONE_LAP, 100);

        var nextSport = getCurrentSport();
        var title = SportDefinitions.isTransition(nextSport)
            ? SportDefinitions.getSportShortName(nextSport)
            : SportDefinitions.getSportName(nextSport);
        showOverlay(OVERLAY_TRANSITION, SportDefinitions.getSportColor(nextSport), nextSport, title, prevTime, 2);
        return false;
    }

    public function togglePause() as Void {
        if (state == STATE_ACTIVE) {
            state = STATE_PAUSED;
            pauseStartMs = System.getTimer();
            if (session != null && session.isRecording()) {
                session.stop();
            }
            triggerFeedback(Attention.TONE_STOP, 80);
            showOverlay(OVERLAY_PAUSE, 0xFF1133, getCurrentSport(), "", "", 2);
        } else if (state == STATE_PAUSED) {
            state = STATE_ACTIVE;
            accumulatedPauseMs += (System.getTimer() - pauseStartMs);
            if (session != null && !session.isRecording()) {
                session.start();
            }
            triggerFeedback(Attention.TONE_START, 80);
            showOverlay(OVERLAY_START, 0x00E64D, getCurrentSport(), "", "", 2);
        }
    }

    public function addManualLap() as Void {
        if (state != STATE_ACTIVE) {
            return;
        }
        var seg = getCurrentSegment();
        if (session != null && session.isRecording()) {
            session.addLap();
        }
        var lapMs = seg.elapsedMs - lapStartElapsedMs;
        seg.lapCount++;
        lapStartElapsedMs = seg.elapsedMs;
        lapStartDistMeters = seg.distanceMeters;
        triggerFeedback(Attention.TONE_LAP, 75);
        showOverlay(OVERLAY_LAP, 0xFFFFFF, seg.sportType, "TOUR " + seg.lapCount.toString(), SportDefinitions.formatTime(lapMs), 3);
    }

    public function saveAndFinish() as Void {
        if (state == STATE_ACTIVE || state == STATE_PAUSED) {
            if (sportLapField != null) {
                sportLapField.setData(getCurrentSport());
            }
            if (session != null && session.isRecording()) {
                session.stop();
            }
            getCurrentSegment().completed = true;
            state = STATE_SUMMARY;
            triggerVibeOnly(150);
        }
    }

    // Called from FeelEvalView right after the user picks their smiley (or skips)
    public function commitSaveWithFeel(rating as Number) as Void {
        feelRating = rating;
        if (feelSessionField != null) {
            feelSessionField.setData(rating);
        }
        finalizeContinuousSession(true);
    }

    public function discardAll() as Void {
        finalizeContinuousSession(false);
        state = STATE_PRE_START;
        totalElapsedMs = 0;
        totalDistanceMeters = 0.0f;
        totalCalories = 0;
        rebuildProfile();
        triggerVibeOnly(100);
    }

    public function resetToPreStart() as Void {
        state = STATE_PRE_START;
        totalElapsedMs = 0;
        totalDistanceMeters = 0.0f;
        totalCalories = 0;
        rebuildProfile();
    }

    private function startContinuousSession() as Void {
        var sport = getCurrentSport();
        segmentStartMs = System.getTimer();
        accumulatedPauseMs = 0;
        segmentStartDistMeters = 0.0f;
        segmentStartCalories = 0;
        lapStartElapsedMs = 0;
        lapStartDistMeters = 0.0f;
        lastAutoLapDistMeters = 0.0f;
        lastSessionDist = 0.0f;

        var sessionName = "MS " + msGroupId + " " + SportDefinitions.getProfileName(settings.profileId);
        // Record the single continuous session as SPORT_RUNNING (100% supported on fr165m with full GPS/HR/LiveTrack;
        // Garmin firmware rejects SPORT_MULTISPORT on fr165m, and our GitHub script splits laps via ms_sport into native multi_sport).
        var opts = {
            :name => sessionName,
            :sport => Activity.SPORT_RUNNING,
            :subSport => Activity.SUB_SPORT_GENERIC
        };

        try {
            session = ActivityRecording.createSession(opts);
            if (session != null) {
                // Attach FitContributor LAP field (id=0) to record each leg's exact SportType
                if (session has :createField) {
                    sportLapField = session.createField(
                        "ms_sport",
                        0,
                        FitContributor.DATA_TYPE_UINT8,
                        {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "id"}
                    );
                    if (sportLapField != null) {
                        sportLapField.setData(sport);
                    }
                    feelSessionField = session.createField(
                        "ms_feel",
                        1,
                        FitContributor.DATA_TYPE_UINT8,
                        {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "lvl"}
                    );
                    if (feelSessionField != null) {
                        feelSessionField.setData(feelRating);
                    }
                }
                session.start();
            }
        } catch (ex) {
            session = null;
            sportLapField = null;
            feelSessionField = null;
        }
    }

    private function finalizeContinuousSession(saveFile as Boolean) as Void {
        if (session != null) {
            try {
                if (session.isRecording()) {
                    session.stop();
                }
                if (saveFile) {
                    session.save();
                } else {
                    session.discard();
                }
            } catch (ex) {
            }
            session = null;
            sportLapField = null;
            feelSessionField = null;
        }
    }

    // Sensor callback (guarded with `has` checks for fr165m safety!)
    public function onSensor(sensorInfo as Sensor.Info) as Void {
        if (sensorInfo has :heartRate && sensorInfo.heartRate != null) {
            heartRate = sensorInfo.heartRate as Number;
        }
        if (sensorInfo has :cadence && sensorInfo.cadence != null) {
            cadence = sensorInfo.cadence as Number;
        }
        if (sensorInfo has :power && sensorInfo.power != null) {
            power = sensorInfo.power as Number;
        }
        if (sensorInfo has :speed && sensorInfo.speed != null) {
            speedMps = sensorInfo.speed as Float;
        }
        if (sensorInfo has :altitude && sensorInfo.altitude != null) {
            altitude = sensorInfo.altitude as Float;
        }
    }

    // GPS Position callback
    public function onPosition(info as Position.Info) as Void {
        var prevQuality = gpsQuality;
        if (info has :accuracy && info.accuracy != null) {
            gpsQuality = info.accuracy as Number;
        }
        // Native Garmin GPS-lock beep on Pre-Start screen
        if (state == STATE_PRE_START && prevQuality < Position.QUALITY_GOOD && gpsQuality >= Position.QUALITY_GOOD) {
            triggerFeedback(Attention.TONE_KEY, 80);
        }
        if (info has :speed && info.speed != null && (info.speed as Float) >= 0.0f) {
            speedMps = info.speed as Float;
        }
        if (info has :altitude && info.altitude != null) {
            altitude = info.altitude as Float;
        }
        if (info has :heading && info.heading != null) {
            heading = info.heading as Float;
        }
        if (info has :position && info.position != null && gpsQuality >= Position.QUALITY_POOR) {
            hasPosition = true;
            var deg = (info.position as Position.Location).toDegrees();
            var lat = deg[0] as Double;
            var lon = deg[1] as Double;
            if (state == STATE_ACTIVE) {
                recordTrackPoint(lat, lon);
            }
        }
    }

    private function recordTrackPoint(lat as Double, lon as Double) as Void {
        if (hasLastTrack) {
            var dLat = lat - lastTrackLat;
            var dLon = lon - lastTrackLon;
            // Record point only if moved at least ~5 meters
            if ((dLat * dLat + dLon * dLon) < 0.000000002d) {
                return;
            }
        }
        lastTrackLat = lat;
        lastTrackLon = lon;
        hasLastTrack = true;

        if (trackLats.size() >= MAX_TRACK_POINTS) {
            // Downsample by keeping every 2nd point to preserve entire route shape & colors
            var newLats = [] as Array<Float>;
            var newLons = [] as Array<Float>;
            var newSports = [] as Array<Number>;
            for (var i = 0; i < trackLats.size(); i += 2) {
                newLats.add(trackLats[i]);
                newLons.add(trackLons[i]);
                newSports.add(trackSports[i]);
            }
            trackLats = newLats;
            trackLons = newLons;
            trackSports = newSports;
        }
        trackLats.add(lat.toFloat());
        trackLons.add(lon.toFloat());
        trackSports.add(getCurrentSport());
    }

    // 1 Hz main heartbeat
    public function onTick() as Void {
        tickCount++;
        if (overlayType != OVERLAY_NONE && tickCount >= alertExpiresTick) {
            overlayType = OVERLAY_NONE;
            alertMessage = null;
            alertSubMessage = null;
        }

        if (state == STATE_ACTIVE) {
            checkAutoPause();
            if (!autoPaused) {
                updateActiveMetrics();
                checkAlerts();
                checkAutoSportChange();
            }
        }
        WatchUi.requestUpdate();
    }

    // Smart hysteresis Auto-Pause (disabled during Swimming & Transitions)
    private function checkAutoPause() as Void {
        if (!settings.autoPauseEnabled) {
            if (autoPaused) {
                autoPaused = false;
                if (session != null && !session.isRecording()) {
                    session.start();
                }
            }
            return;
        }
        var sp = getCurrentSport();
        if (SportDefinitions.isSwim(sp) || SportDefinitions.isTransition(sp)) {
            return;
        }
        if (!autoPaused) {
            if (speedMps < 0.55f) {
                autoPauseStopTicks++;
                if (autoPauseStopTicks >= 4) {
                    autoPaused = true;
                    autoPauseStopTicks = 0;
                    autoPauseMoveTicks = 0;
                    pauseStartMs = System.getTimer();
                    if (session != null && session.isRecording()) {
                        session.stop();
                    }
                    triggerFeedback(Attention.TONE_STOP, 60);
                    showOverlay(OVERLAY_PAUSE, 0xFF1133, sp, "", "", 2);
                }
            } else {
                autoPauseStopTicks = 0;
            }
        } else {
            if (speedMps >= 1.1f) {
                autoPauseMoveTicks++;
                if (autoPauseMoveTicks >= 2) {
                    autoPaused = false;
                    autoPauseMoveTicks = 0;
                    accumulatedPauseMs += (System.getTimer() - pauseStartMs);
                    if (session != null && !session.isRecording()) {
                        session.start();
                    }
                    triggerFeedback(Attention.TONE_START, 60);
                    showOverlay(OVERLAY_START, 0x00E64D, sp, "", "", 2);
                }
            } else {
                autoPauseMoveTicks = 0;
            }
        }
    }

    private function updateActiveMetrics() as Void {
        var seg = getCurrentSegment();
        var actInfo = Activity.getActivityInfo();

        // Elapsed time for current segment (independent of continuous session total)
        seg.elapsedMs = System.getTimer() - segmentStartMs - accumulatedPauseMs;

        // Distance for current segment = delta from continuous session distance
        if (actInfo != null && actInfo has :elapsedDistance && actInfo.elapsedDistance != null) {
            var d = actInfo.elapsedDistance as Float;
            if (d >= lastSessionDist) {
                lastSessionDist = d;
            }
            var segD = lastSessionDist - segmentStartDistMeters;
            if (segD < 0.0f) { segD = 0.0f; }
            if (!SportDefinitions.isTransition(seg.sportType)) {
                seg.distanceMeters = segD;
            }
        } else if (speedMps > 0.2f && !SportDefinitions.isTransition(seg.sportType)) {
            seg.distanceMeters += speedMps;
        }

        // HR / Cadence / Power fallback from ActivityInfo (all safely guarded with `has`)
        if (actInfo != null) {
            if (actInfo has :currentHeartRate && actInfo.currentHeartRate != null) {
                heartRate = actInfo.currentHeartRate as Number;
            }
            if (actInfo has :currentSpeed && actInfo.currentSpeed != null && (actInfo.currentSpeed as Float) >= 0.0f) {
                speedMps = actInfo.currentSpeed as Float;
            }
            if (actInfo has :currentCadence && actInfo.currentCadence != null) {
                cadence = actInfo.currentCadence as Number;
            }
            if (actInfo has :currentPower && actInfo.currentPower != null) {
                power = actInfo.currentPower as Number;
            }
            if (actInfo has :calories && actInfo.calories != null) {
                var totalCal = actInfo.calories as Number;
                var segCal = totalCal - segmentStartCalories;
                if (segCal < 0) { segCal = 0; }
                seg.calories = segCal;
            }
        }

        seg.addSample(heartRate, cadence, power);

        // Update global totals
        var sumElapsed = 0;
        var sumDist = 0.0f;
        var sumCal = 0;
        for (var i = 0; i <= currentLegIndex && i < segments.size(); i++) {
            sumElapsed += segments[i].elapsedMs;
            sumDist += segments[i].distanceMeters;
            sumCal += segments[i].calories;
        }
        totalElapsedMs = sumElapsed;
        totalDistanceMeters = sumDist;
        totalCalories = sumCal;

        if (heartRate > 30) {
            globalHrSum += heartRate;
            globalHrSamples++;
            if (heartRate > globalMaxHr) {
                globalMaxHr = heartRate;
            }
            var z = getHrZoneIndex(heartRate); // 0..4
            zoneSeconds[z] = zoneSeconds[z] + 1;
        }

        // Low-power elevation profile sampling (every 5 seconds)
        if ((tickCount % 5) == 0 && altitude > -500.0f && altitude < 9000.0f) {
            if (hasLastAlt) {
                var dAlt = altitude - lastAltSample;
                if (dAlt > 1.5f) {
                    totalAscent += dAlt;
                } else if (dAlt < -1.5f) {
                    totalDescent += (-dAlt);
                }
            }
            lastAltSample = altitude;
            hasLastAlt = true;
            if (altHistory.size() >= MAX_ALT_POINTS) {
                var compacted = [] as Array<Float>;
                for (var k = 0; k < altHistory.size(); k += 2) {
                    compacted.add(altHistory[k]);
                }
                altHistory = compacted;
            }
            altHistory.add(altitude);
        }
    }

    private function checkAlerts() as Void {
        var seg = getCurrentSegment();
        var totalSec = totalElapsedMs / 1000;

        // 1. Auto-Lap
        if (settings.autoLapDistanceMeters > 0 && !SportDefinitions.isTransition(seg.sportType)) {
            var nextAutoLap = lastAutoLapDistMeters + settings.autoLapDistanceMeters.toFloat();
            if (seg.distanceMeters >= nextAutoLap) {
                lastAutoLapDistMeters = nextAutoLap;
                if (session != null && session.isRecording()) {
                    session.addLap();
                }
                seg.lapCount++;
                lapStartElapsedMs = seg.elapsedMs;
                lapStartDistMeters = seg.distanceMeters;
                triggerFeedback(Attention.TONE_LAP, 80);
                showAlert("AUTO LAP " + seg.lapCount.toString(), SportDefinitions.formatDistance(seg.distanceMeters, SportDefinitions.isSwim(seg.sportType)), 3);
            }
        }

        // 2. Nutrition / Hydration reminder
        if (settings.nutritionAlertMin > 0) {
            var intervalSec = settings.nutritionAlertMin * 60;
            if (totalSec >= lastNutritionAlertSec + intervalSec) {
                lastNutritionAlertSec = totalSec;
                triggerFeedback(Attention.TONE_ALERT_HI, 120);
                showAlert("HYDRATATION", "Boire / Nutrition", 4);
            }
        }

        // 3. HR Max alert
        if (settings.hrAlertMax > 0 && heartRate > settings.hrAlertMax && (tickCount - lastHrAlertTick) >= 20) {
            lastHrAlertTick = tickCount;
            triggerFeedback(Attention.TONE_ALERT_HI, 100);
            showAlert("ALERTE FC", heartRate.toString() + " bpm > " + settings.hrAlertMax.toString(), 3);
        }

        // 4. Slow Pace alert
        if (settings.paceAlertSlowSec > 0 && speedMps > 0.4f && !SportDefinitions.isTransition(seg.sportType) && !SportDefinitions.isBike(seg.sportType)) {
            var curPace = 1000.0f / speedMps;
            if (curPace > settings.paceAlertSlowSec.toFloat() && (tickCount - lastPaceAlertTick) >= 25) {
                lastPaceAlertTick = tickCount;
                triggerFeedback(Attention.TONE_ALERT_LO, 100);
                showAlert("ALLURE LENTE", SportDefinitions.formatPaceSecPerUnit(curPace) + " /km", 3);
            }
        }

        // 5. Distance milestone alert
        if (settings.distAlertMeters > 0) {
            if (totalDistanceMeters >= lastDistAlertMeters + settings.distAlertMeters.toFloat()) {
                lastDistAlertMeters += settings.distAlertMeters.toFloat();
                triggerFeedback(Attention.TONE_ALERT_HI, 90);
                showAlert("DISTANCE", SportDefinitions.formatDistance(totalDistanceMeters, false) + " km", 3);
            }
        }

        // 6. Time milestone alert
        if (settings.timeAlertMin > 0) {
            var tInterval = settings.timeAlertMin * 60;
            if (totalSec >= lastTimeAlertSec + tInterval) {
                lastTimeAlertSec = totalSec;
                triggerFeedback(Attention.TONE_ALERT_HI, 90);
                showAlert("TEMPS", SportDefinitions.formatTime(totalElapsedMs), 3);
            }
        }
    }

    private function checkAutoSportChange() as Void {
        if (!settings.autoSportChange) {
            return;
        }
        var curSport = getCurrentSport();
        var nextSport = getNextSport();
        if (nextSport == null) {
            return;
        }
        var curSeg = getCurrentSegment();
        var matched = false;
        // 1. Swim -> T1: running cadence detected after swimming >= 100m
        if (SportDefinitions.isSwim(curSport) && SportDefinitions.isTransition(nextSport as Number)) {
            if (curSeg.distanceMeters >= 100.0f && cadence >= 110 && speedMps > 1.5f) {
                matched = true;
            }
        // 2. T1 -> Bike: cycling speed > 15 km/h (4.2 m/s)
        } else if (SportDefinitions.isTransition(curSport) && SportDefinitions.isBike(nextSport as Number)) {
            if (speedMps > 4.2f) {
                matched = true;
            }
        // 3. Bike -> T2: dismount (speed < 1.8 m/s & zero bike cadence after >= 200m)
        } else if (SportDefinitions.isBike(curSport) && SportDefinitions.isTransition(nextSport as Number)) {
            if (curSeg.distanceMeters >= 200.0f && speedMps < 1.8f && cadence == 0) {
                matched = true;
            }
        // 4. T2 -> Run/Trail: running cadence >= 135 spm & speed 6-20 km/h
        } else if (SportDefinitions.isTransition(curSport) && (nextSport == SportDefinitions.SPORT_RUN || nextSport == SportDefinitions.SPORT_TRAIL)) {
            if (cadence >= 135 && speedMps > 1.8f && speedMps < 5.8f) {
                matched = true;
            }
        }
        if (matched) {
            autoSportMatchTicks++;
            if (autoSportMatchTicks >= 6) {
                autoSportMatchTicks = 0;
                nextSegment();
            }
        } else {
            autoSportMatchTicks = 0;
        }
    }

    public function showOverlay(oType as Number, color as Number, sport as Number, title as String, subtitle as String, durationSec as Number) as Void {
        overlayType = oType;
        overlayColor = color;
        overlaySport = sport;
        alertMessage = title;
        alertSubMessage = subtitle;
        alertExpiresTick = tickCount + durationSec;
    }

    public function showAlert(title as String, subtitle as String, durationSec as Number) as Void {
        showOverlay(OVERLAY_ALERT, 0x00E64D, getCurrentSport(), title, subtitle, durationSec);
    }

    public function triggerFeedback(tone as Attention.Tone, vibeMs as Number) as Void {
        if (settings.tonesEnabled && Attention has :playTone) {
            Attention.playTone(tone);
        }
        if (settings.vibesEnabled && Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(75, vibeMs)]);
        }
    }

    public function triggerVibeOnly(vibeMs as Number) as Void {
        if (settings.vibesEnabled && Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(75, vibeMs)]);
        }
    }

    // Load user's REAL synced Garmin Connect HR zones per sport (Running, Cycling, Generic)
    private function loadHrZonesForSport(sport as Number) as Array<Number> {
        try {
            var sportZoneType = UserProfile.HR_ZONE_SPORT_GENERIC;
            if (SportDefinitions.isBike(sport) && UserProfile has :HR_ZONE_SPORT_BIKING) {
                sportZoneType = UserProfile.HR_ZONE_SPORT_BIKING;
            } else if ((sport == SportDefinitions.SPORT_RUN || sport == SportDefinitions.SPORT_TRAIL) && UserProfile has :HR_ZONE_SPORT_RUNNING) {
                sportZoneType = UserProfile.HR_ZONE_SPORT_RUNNING;
            } else if (SportDefinitions.isSwim(sport) && UserProfile has :HR_ZONE_SPORT_SWIMMING) {
                sportZoneType = UserProfile.HR_ZONE_SPORT_SWIMMING;
            }
            var profileZones = UserProfile.getHeartRateZones(sportZoneType);
            if (profileZones != null && profileZones.size() >= 6) {
                return profileZones;
            }
            var genericZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
            if (genericZones != null && genericZones.size() >= 6) {
                return genericZones;
            }
        } catch (ex) {
        }
        return [102, 122, 142, 162, 182, 200] as Array<Number>;
    }

    public function getHrZoneIndex(hr as Number) as Number {
        if (hr < hrZones[1]) {
            return 0; // Z1 Gray
        } else if (hr < hrZones[2]) {
            return 1; // Z2 Blue
        } else if (hr < hrZones[3]) {
            return 2; // Z3 Green
        } else if (hr < hrZones[4]) {
            return 3; // Z4 Orange
        }
        return 4; // Z5 Red
    }

    // Continuous position along the 5-zone arc: 0.0 to 5.0
    public function getHrZonePosition(hr as Number) as Float {
        if (hr <= hrZones[0]) {
            return 0.0f;
        }
        if (hr >= hrZones[5]) {
            return 5.0f;
        }
        for (var i = 0; i < 5; i++) {
            var low = hrZones[i];
            var high = hrZones[i + 1];
            if (hr <= high) {
                var span = (high - low);
                if (span <= 0) {
                    return i.toFloat();
                }
                return i.toFloat() + ((hr - low).toFloat() / span.toFloat());
            }
        }
        return 5.0f;
    }

    // Current field formatted value for the customizable FR965 data screens
    public function getFormattedFieldValue(fieldId as Number) as String {
        var seg = getCurrentSegment();
        var sport = seg.sportType;
        var isSwim = SportDefinitions.isSwim(sport);

        switch (fieldId) {
            case SportDefinitions.FIELD_DISTANCE:
                return SportDefinitions.formatDistance(seg.distanceMeters, isSwim);
            case SportDefinitions.FIELD_PACE:
                if (speedMps <= 0.1f) {
                    return "--:--";
                }
                var paceSec = isSwim ? (100.0f / speedMps) : (1000.0f / speedMps);
                return SportDefinitions.formatPaceSecPerUnit(paceSec);
            case SportDefinitions.FIELD_SPEED:
                return (speedMps * 3.6f).format("%.1f");
            case SportDefinitions.FIELD_POWER:
                return (power > 0) ? (power.toString() + " W") : "-- W";
            case SportDefinitions.FIELD_CADENCE:
                return (cadence > 0) ? cadence.toString() : "--";
            case SportDefinitions.FIELD_AVG_PACE:
                return SportDefinitions.formatPaceSecPerUnit(seg.getAvgPaceSec());
            case SportDefinitions.FIELD_AVG_SPEED:
                return seg.getAvgSpeedKmh().format("%.1f");
            case SportDefinitions.FIELD_CALORIES:
                return seg.calories.toString();
            case SportDefinitions.FIELD_ELEVATION:
                return altitude.toNumber().toString() + " m";
            case SportDefinitions.FIELD_LAP_TIME:
                return SportDefinitions.formatTime(seg.elapsedMs - lapStartElapsedMs);
            case SportDefinitions.FIELD_LAP_DIST:
                return SportDefinitions.formatDistance(seg.distanceMeters - lapStartDistMeters, isSwim);
            case SportDefinitions.FIELD_TOTAL_TIME:
                return SportDefinitions.formatTime(totalElapsedMs);
            case SportDefinitions.FIELD_SWOLF:
                var sw = seg.getEstimatedSwolf(settings.poolLengthMeters);
                return (sw > 0) ? sw.toString() : "--";
            case SportDefinitions.FIELD_CHRONO:
                return SportDefinitions.formatTime(seg.elapsedMs);
            default:
                return "--";
        }
    }

    public function getGlobalAvgHr() as Number {
        if (globalHrSamples <= 0) {
            return 0;
        }
        return globalHrSum / globalHrSamples;
    }

    // Estimated Aerobic Training Effect (1.0 - 5.0)
    public function getAerobicTrainingEffect() as Float {
        var aerobicMin = (zoneSeconds[1] + zoneSeconds[2] * 1.4f + zoneSeconds[3] * 1.8f + zoneSeconds[4] * 2.0f) / 60.0f;
        var te = 1.0f + (aerobicMin / 22.0f);
        if (te > 5.0f) {
            te = 5.0f;
        }
        return te;
    }

    // Estimated Anaerobic Training Effect (0.0 - 5.0)
    public function getAnaerobicTrainingEffect() as Float {
        var anaMin = (zoneSeconds[3] * 0.5f + zoneSeconds[4] * 1.8f) / 60.0f;
        var te = anaMin / 6.0f;
        if (te > 5.0f) {
            te = 5.0f;
        }
        return te;
    }
}
