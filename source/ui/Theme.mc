import Toybox.Graphics;
import Toybox.Lang;

module Theme {
    // Pure AMOLED Forerunner 965 Palette
    const COLOR_BG = 0x000000;
    const COLOR_WHITE = 0xFFFFFF;
    const COLOR_LABEL = 0xAAAAAA;
    const COLOR_DIM = 0x555555;
    const COLOR_DARK_LINE = 0x333333;
    const COLOR_RED_DIVIDER = 0xFF0033;   // Signature FR965 red data grid lines
    const COLOR_GREEN_RING = 0x00E64D;    // Active sport luminous green ring
    const COLOR_GREEN_GLOW = 0x005522;
    const COLOR_GPS_RED = 0xFF2233;
    const COLOR_GPS_YELLOW = 0xFFCC00;
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

    // Vector font cache for crisp 390x390 AMOLED rendering
    var fLabel as Graphics.FontType?;
    var fSmall as Graphics.FontType?;
    var fMedium as Graphics.FontType?;
    var fValueMed as Graphics.FontType?;
    var fValueBig as Graphics.FontType?;
    var fChronoHuge as Graphics.FontType?;
    var fChronoSup as Graphics.FontType?;
    var fontsLoaded as Boolean = false;

    function ensureFonts() as Void {
        if (fontsLoaded) {
            return;
        }
        fontsLoaded = true;
        if (Graphics has :getVectorFont) {
            fLabel = Graphics.getVectorFont({:face => "RobotoCondensedBold", :size => 18});
            fSmall = Graphics.getVectorFont({:face => "RobotoCondensedRegular", :size => 20});
            fMedium = Graphics.getVectorFont({:face => "RobotoCondensedBold", :size => 26});
            fValueMed = Graphics.getVectorFont({:face => "BionicBold", :size => 34});
            fValueBig = Graphics.getVectorFont({:face => "BionicBold", :size => 52});
            fChronoHuge = Graphics.getVectorFont({:face => "BionicBold", :size => 64});
            fChronoSup = Graphics.getVectorFont({:face => "BionicBold", :size => 32});
        }
        if (fLabel == null) { fLabel = Graphics.FONT_XTINY; }
        if (fSmall == null) { fSmall = Graphics.FONT_XTINY; }
        if (fMedium == null) { fMedium = Graphics.FONT_TINY; }
        if (fValueMed == null) { fValueMed = Graphics.FONT_SMALL; }
        if (fValueBig == null) { fValueBig = Graphics.FONT_NUMBER_MILD; }
        if (fChronoHuge == null) { fChronoHuge = Graphics.FONT_NUMBER_MEDIUM; }
        if (fChronoSup == null) { fChronoSup = Graphics.FONT_SMALL; }
    }
}
