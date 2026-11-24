import Toybox.Graphics;
import Toybox.Lang;

module SportIcons {

    // Draw crisp vector sport icon centered at (cx, cy) with radius r
    function drawSportIcon(dc as Dc, sport as Number, cx as Number, cy as Number, r as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        if (sport == SportDefinitions.SPORT_SWIM_OPEN || sport == SportDefinitions.SPORT_SWIM_POOL) {
            drawSwimIcon(dc, cx, cy, r);
        } else if (sport == SportDefinitions.SPORT_TRANSITION_1 || sport == SportDefinitions.SPORT_TRANSITION_2) {
            drawTransitionIcon(dc, cx, cy, r, (sport == SportDefinitions.SPORT_TRANSITION_1) ? "T1" : "T2");
        } else if (sport == SportDefinitions.SPORT_BIKE) {
            drawBikeIcon(dc, cx, cy, r);
        } else if (sport == SportDefinitions.SPORT_RUN || sport == SportDefinitions.SPORT_TRAIL) {
            drawRunIcon(dc, cx, cy, r);
        } else if (sport == SportDefinitions.SPORT_WALK) {
            drawWalkIcon(dc, cx, cy, r);
        } else {
            drawCardioIcon(dc, cx, cy, r);
        }
    }

    function drawSwimIcon(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        var s = r.toFloat() / 16.0f;
        // Head
        dc.fillCircle(cx + (6.0f * s).toNumber(), cy - (4.0f * s).toNumber(), (3.0f * s).toNumber());
        // Arm & torso stroke
        dc.setPenWidth(3);
        dc.drawLine(
            cx - (8.0f * s).toNumber(), cy + (1.0f * s).toNumber(),
            cx + (1.0f * s).toNumber(), cy - (6.0f * s).toNumber()
        );
        dc.drawLine(
            cx + (1.0f * s).toNumber(), cy - (6.0f * s).toNumber(),
            cx + (4.0f * s).toNumber(), cy + (1.0f * s).toNumber()
        );
        // Water wave
        dc.setPenWidth(2);
        var wy = cy + (6.0f * s).toNumber();
        dc.drawLine(cx - (11.0f * s).toNumber(), wy, cx - (5.0f * s).toNumber(), wy - (2.0f * s).toNumber());
        dc.drawLine(cx - (5.0f * s).toNumber(), wy - (2.0f * s).toNumber(), cx, wy + (1.0f * s).toNumber());
        dc.drawLine(cx, wy + (1.0f * s).toNumber(), cx + (5.0f * s).toNumber(), wy - (2.0f * s).toNumber());
        dc.drawLine(cx + (5.0f * s).toNumber(), wy - (2.0f * s).toNumber(), cx + (11.0f * s).toNumber(), wy);
    }

    function drawTransitionIcon(dc as Dc, cx as Number, cy as Number, r as Number, label as String) as Void {
        var s = r.toFloat() / 16.0f;
        // Double transfer arrows above/below or crisp T1/T2 badge
        Theme.ensureFonts();
        if (r >= 14) {
            dc.drawText(cx, cy, Theme.fLabel as Graphics.FontType, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            // Compact right arrow chevron
            dc.setPenWidth(2);
            var w = (6.0f * s).toNumber();
            dc.drawLine(cx - w, cy - (3.0f * s).toNumber(), cx + w, cy - (3.0f * s).toNumber());
            dc.drawLine(cx + w - 3, cy - (6.0f * s).toNumber(), cx + w, cy - (3.0f * s).toNumber());
            dc.drawLine(cx + w, cy + (3.0f * s).toNumber(), cx - w, cy + (3.0f * s).toNumber());
            dc.drawLine(cx - w + 3, cy + (6.0f * s).toNumber(), cx - w, cy + (3.0f * s).toNumber());
        }
    }

    function drawBikeIcon(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        var s = r.toFloat() / 16.0f;
        var wr = (4.5f * s).toNumber();
        if (wr < 3) { wr = 3; }
        var wy = cy + (4.0f * s).toNumber();
        var lx = cx - (7.0f * s).toNumber();
        var rx = cx + (7.0f * s).toNumber();
        // Wheels
        dc.setPenWidth(2);
        dc.drawCircle(lx, wy, wr);
        dc.drawCircle(rx, wy, wr);
        // Frame triangle
        var seatX = cx - (2.0f * s).toNumber();
        var seatY = cy - (3.0f * s).toNumber();
        var barX = cx + (4.0f * s).toNumber();
        var barY = cy - (4.0f * s).toNumber();
        dc.drawLine(lx, wy, seatX, seatY);
        dc.drawLine(seatX, seatY, barX, barY);
        dc.drawLine(barX, barY, rx, wy);
        dc.drawLine(seatX, seatY, cx, wy);
        // Rider head
        dc.fillCircle(cx + (2.0f * s).toNumber(), cy - (9.0f * s).toNumber(), (2.5f * s).toNumber());
    }

    function drawRunIcon(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        var s = r.toFloat() / 16.0f;
        // Head
        dc.fillCircle(cx + (3.0f * s).toNumber(), cy - (9.0f * s).toNumber(), (3.0f * s).toNumber());
        dc.setPenWidth(3);
        // Torso
        dc.drawLine(cx + (1.0f * s).toNumber(), cy - (5.0f * s).toNumber(), cx - (2.0f * s).toNumber(), cy + (2.0f * s).toNumber());
        // Arms
        dc.setPenWidth(2);
        dc.drawLine(cx + (1.0f * s).toNumber(), cy - (4.0f * s).toNumber(), cx + (7.0f * s).toNumber(), cy - (2.0f * s).toNumber());
        dc.drawLine(cx, cy - (3.0f * s).toNumber(), cx - (6.0f * s).toNumber(), cy - (1.0f * s).toNumber());
        // Legs
        dc.drawLine(cx - (2.0f * s).toNumber(), cy + (2.0f * s).toNumber(), cx + (5.0f * s).toNumber(), cy + (6.0f * s).toNumber());
        dc.drawLine(cx + (5.0f * s).toNumber(), cy + (6.0f * s).toNumber(), cx + (3.0f * s).toNumber(), cy + (11.0f * s).toNumber());
        dc.drawLine(cx - (2.0f * s).toNumber(), cy + (2.0f * s).toNumber(), cx - (7.0f * s).toNumber(), cy + (8.0f * s).toNumber());
    }

    function drawWalkIcon(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        var s = r.toFloat() / 16.0f;
        dc.fillCircle(cx, cy - (9.0f * s).toNumber(), (3.0f * s).toNumber());
        dc.setPenWidth(2);
        dc.drawLine(cx, cy - (5.0f * s).toNumber(), cx, cy + (3.0f * s).toNumber());
        dc.drawLine(cx, cy + (3.0f * s).toNumber(), cx - (5.0f * s).toNumber(), cy + (10.0f * s).toNumber());
        dc.drawLine(cx, cy + (3.0f * s).toNumber(), cx + (5.0f * s).toNumber(), cy + (10.0f * s).toNumber());
    }

    function drawCardioIcon(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        var s = r.toFloat() / 16.0f;
        dc.setPenWidth(2);
        dc.drawLine(cx - (10.0f * s).toNumber(), cy, cx - (4.0f * s).toNumber(), cy);
        dc.drawLine(cx - (4.0f * s).toNumber(), cy, cx - (1.0f * s).toNumber(), cy - (8.0f * s).toNumber());
        dc.drawLine(cx - (1.0f * s).toNumber(), cy - (8.0f * s).toNumber(), cx + (2.0f * s).toNumber(), cy + (8.0f * s).toNumber());
        dc.drawLine(cx + (2.0f * s).toNumber(), cy + (8.0f * s).toNumber(), cx + (5.0f * s).toNumber(), cy);
        dc.drawLine(cx + (5.0f * s).toNumber(), cy, cx + (10.0f * s).toNumber(), cy);
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
        // Satellite body (tilted)
        dc.fillCircle(cx, cy, 4);
        dc.drawLine(cx - 8, cy - 4, cx - 3, cy - 1);
        dc.drawLine(cx + 3, cy + 1, cx + 8, cy + 4);
        // Signal arcs
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
