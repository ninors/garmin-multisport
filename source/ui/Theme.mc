import Toybox.Graphics;
import Toybox.Lang;

module Theme {
    // Pure AMOLED Forerunner 965 / 165 Native Palette
    const COLOR_BG = 0x000000;
    const COLOR_WHITE = 0xFFFFFF;
    const COLOR_LABEL = 0xAAAAAA;
    const COLOR_DIM = 0x555555;
    const COLOR_DARK_LINE = 0x333333;
    const COLOR_RED_DIVIDER = 0xFF0033;   // Signature FR965 red data grid lines
    const COLOR_GREEN_RING = 0x00E64D;    // Active sport & GPS ready green
    const COLOR_GREEN_GLOW = 0x005522;
    const COLOR_GPS_RED = 0xFF2233;
    const COLOR_GPS_YELLOW = 0xFFAA00;
    const COLOR_GPS_GREEN = 0x00E64D;
    const COLOR_HEART_RED = 0xFF1133;
    const COLOR_BANNER_BG = 0x161616;

    // 5 Heart Rate Zone Colors (Z1..Z5)
    const ZONE_COLORS = [
        0x888888, // Z1 Gray
        0x0099FF, // Z2 Blue
        0x00CC44, // Z3 Green
        0xFF8800, // Z4 Orange
        0xFF1133  // Z5 Red
    ] as Array<Number>;

    function getZoneColor(zoneIdx as Number) as Number {
        if (zoneIdx < 0) {
            return ZONE_COLORS[0];
        }
        if (zoneIdx >= 5) {
            return ZONE_COLORS[4];
        }
        return ZONE_COLORS[zoneIdx];
    }

    // Native Garmin System Fonts (100% crash-free & authentic Forerunner look)
    var fLabel as Graphics.FontType = Graphics.FONT_XTINY;
    var fSmall as Graphics.FontType = Graphics.FONT_XTINY;
    var fMedium as Graphics.FontType = Graphics.FONT_TINY;
    var fValueMed as Graphics.FontType = Graphics.FONT_SMALL;
    var fValueBig as Graphics.FontType = Graphics.FONT_NUMBER_MILD;
    var fChronoHuge as Graphics.FontType = Graphics.FONT_NUMBER_MEDIUM;
    var fChronoSup as Graphics.FontType = Graphics.FONT_SMALL;

    function ensureFonts() as Void {
        // Uses native Garmin system fonts directly so typography matches
        // the built-in Forerunner 165 / 965 firmware with zero font crashes.
    }

    function enableAA(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
    }
}
