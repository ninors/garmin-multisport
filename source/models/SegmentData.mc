import Toybox.Lang;

class SegmentData {
    public var sportType as Number;
    public var elapsedMs as Number;
    public var distanceMeters as Float;
    public var maxHeartRate as Number;
    public var calories as Number;
    public var lapCount as Number;
    public var completed as Boolean;

    // Running averages accumulators
    private var hrSum as Number;
    private var hrSamples as Number;
    private var cadenceSum as Number;
    private var cadenceSamples as Number;
    private var powerSum as Number;
    private var powerSamples as Number;

    function initialize(sport as Number) {
        sportType = sport;
        elapsedMs = 0;
        distanceMeters = 0.0f;
        maxHeartRate = 0;
        calories = 0;
        lapCount = 1;
        completed = false;
        hrSum = 0;
        hrSamples = 0;
        cadenceSum = 0;
        cadenceSamples = 0;
        powerSum = 0;
        powerSamples = 0;
    }

    public function addSample(hr as Number, cadence as Number, power as Number) as Void {
        if (hr > 30) {
            hrSum += hr;
            hrSamples++;
            if (hr > maxHeartRate) {
                maxHeartRate = hr;
            }
        }
        if (cadence > 0) {
            cadenceSum += cadence;
            cadenceSamples++;
        }
        if (power > 0) {
            powerSum += power;
            powerSamples++;
        }
    }

    public function getAvgHeartRate() as Number {
        if (hrSamples <= 0) {
            return 0;
        }
        return hrSum / hrSamples;
    }

    public function getAvgCadence() as Number {
        if (cadenceSamples <= 0) {
            return 0;
        }
        return cadenceSum / cadenceSamples;
    }

    public function getAvgPower() as Number {
        if (powerSamples <= 0) {
            return 0;
        }
        return powerSum / powerSamples;
    }

    public function getAvgSpeedMps() as Float {
        if (elapsedMs <= 0 || distanceMeters <= 0.0f) {
            return 0.0f;
        }
        return distanceMeters / (elapsedMs.toFloat() / 1000.0f);
    }

    public function getAvgSpeedKmh() as Float {
        return getAvgSpeedMps() * 3.6f;
    }

    // Pace in seconds per km (or per 100m for swimming)
    public function getAvgPaceSec() as Float {
        var speed = getAvgSpeedMps();
        if (speed <= 0.05f) {
            return 0.0f;
        }
        if (SportDefinitions.isSwim(sportType)) {
            return 100.0f / speed;
        }
        return 1000.0f / speed;
    }

    // Approximate SWOLF for swimming (sec per 25m + strokes per 25m)
    public function getEstimatedSwolf(poolLen as Number) as Number {
        if (!SportDefinitions.isSwim(sportType) || distanceMeters < 25.0f || elapsedMs <= 0) {
            return 0;
        }
        var len = (poolLen > 0) ? poolLen.toFloat() : 25.0f;
        var secPerLen = (elapsedMs.toFloat() / 1000.0f) / (distanceMeters / len);
        var avgCad = getAvgCadence();
        var strokesPerLen = (avgCad > 0) ? ((avgCad.toFloat() / 60.0f) * secPerLen) : (secPerLen * 0.65f);
        return (secPerLen + strokesPerLen).toNumber();
    }
}
