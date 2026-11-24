import Toybox.Application.Storage;
import Toybox.Lang;

class SettingsModel {
    public var profileId as Number;
    public var transitionsEnabled as Boolean;
    public var autoSportChange as Boolean;
    public var autoPauseEnabled as Boolean;
    public var swimPoolMode as Boolean;
    public var poolLengthMeters as Number;
    public var autoLapDistanceMeters as Number;
    public var gpsMode as Number; // 0 = GPS seul, 1 = Tous les systèmes, 2 = Auto Select
    public var recordingMode as Number; // 0 = Intelligent, 1 = Chaque seconde

    // Alerts
    public var hrAlertMax as Number;        // 0 = OFF, else BPM
    public var paceAlertSlowSec as Number;  // 0 = OFF, else sec/km
    public var distAlertMeters as Number;   // 0 = OFF, else meters
    public var timeAlertMin as Number;      // 0 = OFF, else minutes
    public var nutritionAlertMin as Number; // 0 = OFF, else minutes

    // Custom multisport profile legs
    public var customSports as Array<Number>;

    // Customizable main screen fields (Top / Left / Right) per discipline
    public var swimFieldTop as Number;
    public var swimFieldLeft as Number;
    public var swimFieldRight as Number;
    public var bikeFieldTop as Number;
    public var bikeFieldLeft as Number;
    public var bikeFieldRight as Number;
    public var runFieldTop as Number;
    public var runFieldLeft as Number;
    public var runFieldRight as Number;

    // Audio & haptics
    public var tonesEnabled as Boolean;
    public var vibesEnabled as Boolean;

    function initialize() {
        profileId = loadNumber("profileId", SportDefinitions.PROFILE_TRIATHLON);
        transitionsEnabled = loadBool("transitionsEnabled", true);
        autoSportChange = loadBool("autoSportChange", false);
        autoPauseEnabled = loadBool("autoPauseEnabled", false);
        swimPoolMode = loadBool("swimPoolMode", false);
        poolLengthMeters = loadNumber("poolLengthMeters", 25);
        autoLapDistanceMeters = loadNumber("autoLapDistanceMeters", 1000);
        gpsMode = loadNumber("gpsMode", 1);
        recordingMode = loadNumber("recordingMode", 1);

        hrAlertMax = loadNumber("hrAlertMax", 0);
        paceAlertSlowSec = loadNumber("paceAlertSlowSec", 0);
        distAlertMeters = loadNumber("distAlertMeters", 0);
        timeAlertMin = loadNumber("timeAlertMin", 0);
        nutritionAlertMin = loadNumber("nutritionAlertMin", 20);

        swimFieldTop = loadNumber("swimFieldTop", SportDefinitions.FIELD_CHRONO);
        swimFieldLeft = loadNumber("swimFieldLeft", SportDefinitions.FIELD_DISTANCE);
        swimFieldRight = loadNumber("swimFieldRight", SportDefinitions.FIELD_PACE);
        bikeFieldTop = loadNumber("bikeFieldTop", SportDefinitions.FIELD_CHRONO);
        bikeFieldLeft = loadNumber("bikeFieldLeft", SportDefinitions.FIELD_DISTANCE);
        bikeFieldRight = loadNumber("bikeFieldRight", SportDefinitions.FIELD_SPEED);
        runFieldTop = loadNumber("runFieldTop", SportDefinitions.FIELD_CHRONO);
        runFieldLeft = loadNumber("runFieldLeft", SportDefinitions.FIELD_DISTANCE);
        runFieldRight = loadNumber("runFieldRight", SportDefinitions.FIELD_PACE);

        tonesEnabled = loadBool("tonesEnabled", true);
        vibesEnabled = loadBool("vibesEnabled", true);

        var storedCustom = Storage.getValue("customSports");
        if (storedCustom instanceof Array) {
            customSports = storedCustom as Array<Number>;
        } else {
            customSports = [
                SportDefinitions.SPORT_SWIM_OPEN,
                SportDefinitions.SPORT_BIKE,
                SportDefinitions.SPORT_RUN
            ] as Array<Number>;
        }
    }

    public function save() as Void {
        Storage.setValue("profileId", profileId);
        Storage.setValue("transitionsEnabled", transitionsEnabled);
        Storage.setValue("autoSportChange", autoSportChange);
        Storage.setValue("autoPauseEnabled", autoPauseEnabled);
        Storage.setValue("swimPoolMode", swimPoolMode);
        Storage.setValue("poolLengthMeters", poolLengthMeters);
        Storage.setValue("autoLapDistanceMeters", autoLapDistanceMeters);
        Storage.setValue("gpsMode", gpsMode);
        Storage.setValue("recordingMode", recordingMode);

        Storage.setValue("hrAlertMax", hrAlertMax);
        Storage.setValue("paceAlertSlowSec", paceAlertSlowSec);
        Storage.setValue("distAlertMeters", distAlertMeters);
        Storage.setValue("timeAlertMin", timeAlertMin);
        Storage.setValue("nutritionAlertMin", nutritionAlertMin);

        Storage.setValue("swimFieldTop", swimFieldTop);
        Storage.setValue("swimFieldLeft", swimFieldLeft);
        Storage.setValue("swimFieldRight", swimFieldRight);
        Storage.setValue("bikeFieldTop", bikeFieldTop);
        Storage.setValue("bikeFieldLeft", bikeFieldLeft);
        Storage.setValue("bikeFieldRight", bikeFieldRight);
        Storage.setValue("runFieldTop", runFieldTop);
        Storage.setValue("runFieldLeft", runFieldLeft);
        Storage.setValue("runFieldRight", runFieldRight);

        Storage.setValue("tonesEnabled", tonesEnabled);
        Storage.setValue("vibesEnabled", vibesEnabled);
        var storedList = [] as Array<Storage.ValueType>;
        for (var i = 0; i < customSports.size(); i++) {
            storedList.add(customSports[i]);
        }
        Storage.setValue("customSports", storedList);
    }

    public function getFieldTopForSport(sport as Number) as Number {
        if (SportDefinitions.isSwim(sport)) {
            return swimFieldTop;
        } else if (SportDefinitions.isBike(sport)) {
            return bikeFieldTop;
        }
        return runFieldTop;
    }

    public function getFieldLeftForSport(sport as Number) as Number {
        if (SportDefinitions.isSwim(sport)) {
            return swimFieldLeft;
        } else if (SportDefinitions.isBike(sport)) {
            return bikeFieldLeft;
        }
        return runFieldLeft;
    }

    public function getFieldRightForSport(sport as Number) as Number {
        if (SportDefinitions.isSwim(sport)) {
            return swimFieldRight;
        } else if (SportDefinitions.isBike(sport)) {
            return bikeFieldRight;
        }
        return runFieldRight;
    }

    public function getGpsModeLabel() as String {
        if (gpsMode == 0) {
            return "GPS seul";
        } else if (gpsMode == 2) {
            return "Auto Select";
        }
        return "Tous systèmes";
    }

    public function getRecordingModeLabel() as String {
        return (recordingMode == 0) ? "Intelligent" : "Chaque sec.";
    }

    public function getAutoLapLabel() as String {
        if (autoLapDistanceMeters <= 0) {
            return "Désactivé";
        } else if (autoLapDistanceMeters >= 1000) {
            return (autoLapDistanceMeters / 1000).toString() + " km";
        }
        return autoLapDistanceMeters.toString() + " m";
    }

    private function loadNumber(key as String, defVal as Number) as Number {
        var val = Storage.getValue(key);
        if (val instanceof Number) {
            return val as Number;
        }
        return defVal;
    }

    private function loadBool(key as String, defVal as Boolean) as Boolean {
        var val = Storage.getValue(key);
        if (val instanceof Boolean) {
            return val as Boolean;
        }
        return defVal;
    }
}
