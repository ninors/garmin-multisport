import Toybox.Activity;
import Toybox.Lang;

module SportDefinitions {

    // Sport type identifiers
    const SPORT_SWIM_OPEN = 0;
    const SPORT_SWIM_POOL = 1;
    const SPORT_TRANSITION_1 = 2;
    const SPORT_BIKE = 3;
    const SPORT_TRANSITION_2 = 4;
    const SPORT_RUN = 5;
    const SPORT_TRAIL = 6;
    const SPORT_WALK = 7;
    const SPORT_CARDIO = 8;

    // Multisport profile identifiers
    const PROFILE_TRIATHLON = 0;
    const PROFILE_DUATHLON = 1;
    const PROFILE_SWIMRUN = 2;
    const PROFILE_CUSTOM = 3;

    // Customizable data field identifiers
    const FIELD_DISTANCE = 0;
    const FIELD_PACE = 1;
    const FIELD_SPEED = 2;
    const FIELD_POWER = 3;
    const FIELD_CADENCE = 4;
    const FIELD_AVG_PACE = 5;
    const FIELD_AVG_SPEED = 6;
    const FIELD_CALORIES = 7;
    const FIELD_ELEVATION = 8;
    const FIELD_LAP_TIME = 9;
    const FIELD_LAP_DIST = 10;
    const FIELD_TOTAL_TIME = 11;
    const FIELD_SWOLF = 12;
    const FIELD_CHRONO = 13;

    function getSportName(sport as Number) as String {
        switch (sport) {
            case SPORT_SWIM_OPEN: return "Natation";
            case SPORT_SWIM_POOL: return "Nage Pisc.";
            case SPORT_TRANSITION_1: return "T1";
            case SPORT_BIKE: return "Vélo";
            case SPORT_TRANSITION_2: return "T2";
            case SPORT_RUN: return "Course";
            case SPORT_TRAIL: return "Trail";
            case SPORT_WALK: return "Marche";
            case SPORT_CARDIO: return "Cardio";
            default: return "Sport";
        }
    }

    function getSportShortName(sport as Number) as String {
        switch (sport) {
            case SPORT_SWIM_OPEN: return "NAGE";
            case SPORT_SWIM_POOL: return "PISCINE";
            case SPORT_TRANSITION_1: return "T1";
            case SPORT_BIKE: return "VÉLO";
            case SPORT_TRANSITION_2: return "T2";
            case SPORT_RUN: return "COURSE";
            case SPORT_TRAIL: return "TRAIL";
            case SPORT_WALK: return "MARCHE";
            case SPORT_CARDIO: return "CARDIO";
            default: return "SPORT";
        }
    }

    function getSportColor(sport as Number) as Number {
        switch (sport) {
            case SPORT_SWIM_OPEN:
            case SPORT_SWIM_POOL:
                return 0x00AAFF; // Cyan natation FR965
            case SPORT_TRANSITION_1:
            case SPORT_TRANSITION_2:
                return 0xFFCC00; // Jaune Garmin transition
            case SPORT_BIKE:
                return 0x00DD55; // Vert vif vélo
            case SPORT_RUN:
                return 0xFF8800; // Orange course
            case SPORT_TRAIL:
                return 0x66CC00; // Vert trail
            case SPORT_WALK:
                return 0x00DDBB; // Turquoise marche
            case SPORT_CARDIO:
                return 0xFF0055; // Magenta cardio
            default:
                return 0xFFFFFF;
        }
    }

    function getFitSafeTag(sport as Number) as String {
        switch (sport) {
            case SPORT_SWIM_OPEN: return "SWIM";
            case SPORT_SWIM_POOL: return "POOL";
            case SPORT_TRANSITION_1: return "T1";
            case SPORT_BIKE: return "BIKE";
            case SPORT_TRANSITION_2: return "T2";
            case SPORT_RUN: return "RUN";
            case SPORT_TRAIL: return "TRAIL";
            case SPORT_WALK: return "WALK";
            case SPORT_CARDIO: return "CARDIO";
            default: return "SPORT";
        }
    }

    function getFitSport(sport as Number) as Activity.Sport {
        switch (sport) {
            case SPORT_SWIM_OPEN:
            case SPORT_SWIM_POOL:
                return Activity.SPORT_SWIMMING;
            case SPORT_TRANSITION_1:
            case SPORT_TRANSITION_2:
                return Activity.SPORT_GENERIC;
            case SPORT_BIKE:
                return Activity.SPORT_CYCLING;
            case SPORT_RUN:
            case SPORT_TRAIL:
                return Activity.SPORT_RUNNING;
            case SPORT_WALK:
                return Activity.SPORT_WALKING;
            case SPORT_CARDIO:
                return Activity.SPORT_TRAINING;
            default:
                return Activity.SPORT_GENERIC;
        }
    }

    function getFitSubSport(sport as Number) as Activity.SubSport {
        switch (sport) {
            case SPORT_SWIM_OPEN:
                return Activity.SUB_SPORT_OPEN_WATER;
            case SPORT_SWIM_POOL:
                return Activity.SUB_SPORT_LAP_SWIMMING;
            case SPORT_TRAIL:
                return Activity.SUB_SPORT_TRAIL;
            case SPORT_CARDIO:
                return Activity.SUB_SPORT_CARDIO_TRAINING;
            default:
                // SUB_SPORT_GENERIC is 100% supported across Cycling, Running, Walking, Transition on fr165m
                return Activity.SUB_SPORT_GENERIC;
        }
    }

    function isTransition(sport as Number) as Boolean {
        return (sport == SPORT_TRANSITION_1 || sport == SPORT_TRANSITION_2);
    }

    function isSwim(sport as Number) as Boolean {
        return (sport == SPORT_SWIM_OPEN || sport == SPORT_SWIM_POOL);
    }

    function isBike(sport as Number) as Boolean {
        return (sport == SPORT_BIKE);
    }

    function getProfileName(profileId as Number) as String {
        switch (profileId) {
            case PROFILE_TRIATHLON: return "Triathlon";
            case PROFILE_DUATHLON: return "Duathlon";
            case PROFILE_SWIMRUN: return "Swimrun";
            case PROFILE_CUSTOM: return "Multisport Perso";
            default: return "Triathlon";
        }
    }

    function getFieldLabel(fieldId as Number) as String {
        switch (fieldId) {
            case FIELD_DISTANCE: return "DISTANCE";
            case FIELD_PACE: return "ALLURE";
            case FIELD_SPEED: return "VITESSE";
            case FIELD_POWER: return "PUISSANCE";
            case FIELD_CADENCE: return "CADENCE";
            case FIELD_AVG_PACE: return "ALL. MOY.";
            case FIELD_AVG_SPEED: return "VIT. MOY.";
            case FIELD_CALORIES: return "CALORIES";
            case FIELD_ELEVATION: return "ALTITUDE";
            case FIELD_LAP_TIME: return "TPS TOUR";
            case FIELD_LAP_DIST: return "DIST TOUR";
            case FIELD_TOTAL_TIME: return "TPS TOTAL";
            case FIELD_SWOLF: return "SWOLF";
            case FIELD_CHRONO: return "CHRONO";
            default: return "DONNÉE";
        }
    }

    function getFieldShortLabel(fieldId as Number) as String {
        switch (fieldId) {
            case FIELD_DISTANCE: return "DIST";
            case FIELD_PACE: return "ALLURE";
            case FIELD_SPEED: return "VIT.";
            case FIELD_POWER: return "PUISS.";
            case FIELD_CADENCE: return "CAD.";
            case FIELD_AVG_PACE: return "ALL.M";
            case FIELD_AVG_SPEED: return "VIT.M";
            case FIELD_CALORIES: return "KCAL";
            case FIELD_ELEVATION: return "ALT.";
            case FIELD_LAP_TIME: return "TOUR";
            case FIELD_LAP_DIST: return "D.TOUR";
            case FIELD_TOTAL_TIME: return "TOTAL";
            case FIELD_SWOLF: return "SWOLF";
            default: return "---";
        }
    }

    function buildLegs(profileId as Number, transitionsEnabled as Boolean, swimPoolMode as Boolean, customSports as Array<Number>) as Array<Number> {
        var swimType = swimPoolMode ? SPORT_SWIM_POOL : SPORT_SWIM_OPEN;
        var baseSports = [] as Array<Number>;

        if (profileId == PROFILE_TRIATHLON) {
            baseSports = [swimType, SPORT_BIKE, SPORT_RUN] as Array<Number>;
        } else if (profileId == PROFILE_DUATHLON) {
            baseSports = [SPORT_RUN, SPORT_BIKE, SPORT_RUN] as Array<Number>;
        } else if (profileId == PROFILE_SWIMRUN) {
            baseSports = [swimType, SPORT_RUN, swimType, SPORT_RUN] as Array<Number>;
        } else {
            if (customSports.size() >= 2) {
                for (var i = 0; i < customSports.size(); i++) {
                    var s = customSports[i];
                    if (s == SPORT_SWIM_OPEN || s == SPORT_SWIM_POOL) {
                        baseSports.add(swimType);
                    } else {
                        baseSports.add(s);
                    }
                }
            } else {
                baseSports = [swimType, SPORT_BIKE, SPORT_RUN] as Array<Number>;
            }
        }

        if (!transitionsEnabled) {
            return baseSports;
        }

        var result = [] as Array<Number>;
        var transIdx = 0;
        for (var j = 0; j < baseSports.size(); j++) {
            result.add(baseSports[j]);
            if (j < baseSports.size() - 1) {
                var tType = (transIdx % 2 == 0) ? SPORT_TRANSITION_1 : SPORT_TRANSITION_2;
                result.add(tType);
                transIdx++;
            }
        }
        return result;
    }

    function formatTime(ms as Number) as String {
        if (ms < 0) {
            ms = 0;
        }
        var totalSec = ms / 1000;
        var hrs = totalSec / 3600;
        var mins = (totalSec % 3600) / 60;
        var secs = totalSec % 60;
        if (hrs > 0) {
            return hrs.toString() + ":" + mins.format("%02d") + ":" + secs.format("%02d");
        }
        return mins.toString() + ":" + secs.format("%02d");
    }

    function formatPaceSecPerUnit(secPerUnit as Float) as String {
        if (secPerUnit <= 0.0f || secPerUnit > 3599.0f) {
            return "--:--";
        }
        var totalSec = secPerUnit.toNumber();
        var mins = totalSec / 60;
        var secs = totalSec % 60;
        return mins.toString() + ":" + secs.format("%02d");
    }

    function formatDistance(meters as Float, isSwimSport as Boolean) as String {
        if (meters <= 0.0f) {
            return isSwimSport ? "0" : "0.00";
        }
        if (isSwimSport && meters < 1000.0f) {
            return meters.toNumber().toString();
        }
        var km = meters / 1000.0f;
        if (km >= 100.0f) {
            return km.format("%.1f");
        }
        return km.format("%.2f");
    }

    function getDistanceUnit(meters as Float, isSwimSport as Boolean) as String {
        if (isSwimSport && meters < 1000.0f) {
            return "m";
        }
        return "km";
    }
}
