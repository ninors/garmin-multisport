import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module SportIcons {

    var bmpSwim as WatchUi.BitmapResource?;
    var bmpBike as WatchUi.BitmapResource?;
    var bmpRun as WatchUi.BitmapResource?;
    var bmpTrans as WatchUi.BitmapResource?;
    var bmpWalk as WatchUi.BitmapResource?;
    var bmpCardio as WatchUi.BitmapResource?;
    var iconsLoaded as Boolean = false;

    function ensureIcons() as Void {
        if (iconsLoaded) {
            return;
        }
        iconsLoaded = true;
        bmpSwim = WatchUi.loadResource(Rez.Drawables.IcSwim) as WatchUi.BitmapResource;
        bmpBike = WatchUi.loadResource(Rez.Drawables.IcBike) as WatchUi.BitmapResource;
        bmpRun = WatchUi.loadResource(Rez.Drawables.IcRun) as WatchUi.BitmapResource;
        bmpTrans = WatchUi.loadResource(Rez.Drawables.IcTrans) as WatchUi.BitmapResource;
        bmpWalk = WatchUi.loadResource(Rez.Drawables.IcWalk) as WatchUi.BitmapResource;
        bmpCardio = WatchUi.loadResource(Rez.Drawables.IcCardio) as WatchUi.BitmapResource;
    }

    // Draw crisp Google Material Symbols SVG icon centered at (cx, cy)
    function drawSportIcon(dc as Dc, sport as Number, cx as Number, cy as Number, r as Number, color as Number) as Void {
        ensureIcons();
        var bmp = null as WatchUi.BitmapResource?;
        if (sport == SportDefinitions.SPORT_SWIM_OPEN || sport == SportDefinitions.SPORT_SWIM_POOL) {
            bmp = bmpSwim;
        } else if (sport == SportDefinitions.SPORT_TRANSITION_1 || sport == SportDefinitions.SPORT_TRANSITION_2) {
            bmp = bmpTrans;
        } else if (sport == SportDefinitions.SPORT_BIKE) {
            bmp = bmpBike;
        } else if (sport == SportDefinitions.SPORT_RUN || sport == SportDefinitions.SPORT_TRAIL) {
            bmp = bmpRun;
        } else if (sport == SportDefinitions.SPORT_WALK) {
            bmp = bmpWalk;
        } else {
            bmp = bmpCardio;
        }

        if (bmp != null) {
            var bw = bmp.getWidth();
            var bh = bmp.getHeight();
            dc.drawBitmap(cx - (bw / 2), cy - (bh / 2), bmp);
        }
    }

    // Crisp vector Heart icon
    function drawHeart(dc as Dc, cx as Number, cy as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var r = size / 3;
        if (r < 3) { r = 3; }
        dc.fillCircle(cx - r + 1, cy - r / 2, r);
        dc.fillCircle(cx + r - 1, cy - r / 2, r);
        var pts = [
            [cx - (r * 2) + 1, cy - r / 4],
            [cx + (r * 2) - 1, cy - r / 4],
            [cx, cy + size / 2 + 2]
        ] as Array<[Numeric, Numeric]>;
        dc.fillPolygon(pts);
    }

    // Vector GPS satellite icon
    function drawGpsIcon(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.fillCircle(cx, cy, 4);
        dc.drawLine(cx - 8, cy - 4, cx - 3, cy - 1);
        dc.drawLine(cx + 3, cy + 1, cx + 8, cy + 4);
        dc.drawArc(cx - 2, cy + 2, 7, Graphics.ARC_CLOCKWISE, 260, 190);
        dc.drawArc(cx - 2, cy + 2, 11, Graphics.ARC_CLOCKWISE, 260, 190);
    }

    // Vector Battery icon with fill percentage
    function drawBatteryIcon(dc as Dc, x as Number, y as Number, w as Number, h as Number, pct as Number) as Void {
        var fillColor = Theme.COLOR_GPS_GREEN;
        if (pct <= 15) {
            fillColor = Theme.COLOR_GPS_RED;
        } else if (pct <= 30) {
            fillColor = Theme.COLOR_GPS_YELLOW;
        }
        dc.setColor(Theme.COLOR_LABEL, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(x, y, w, h, 3);
        dc.fillRectangle(x + w, y + h / 4, 3, h / 2);

        var innerW = ((w - 4) * pct) / 100;
        if (innerW < 1 && pct > 0) {
            innerW = 1;
        }
        dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 2, y + 2, innerW, h - 4);
    }

    // Vector Padlock icon
    function drawLockIcon(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawArc(cx, cy - 3, 4, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
        dc.fillRoundedRectangle(cx - 6, cy - 2, 12, 9, 2);
    }
}
