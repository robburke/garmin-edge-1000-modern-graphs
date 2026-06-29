using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

// Varia-Safe Cadence: rotation-ring icon, dynamic scale.
// Colours encode a configurable TARGET BAND (defaults grey<70, amber 70-85,
// green 85-100, amber 100-110, red>110). The cutoffs are user settings, and
// the whole colour scheme can be switched off (all grey) for a clean look.
// Caveat: cadence is terrain-dependent; on steep climbs 70-85 is correct.
class CadenceField extends GraphField {
    hidden var mColor;
    hidden var mLow;     // below this = grey (coasting)
    hidden var mGLo;     // green band lower edge
    hidden var mGHi;     // green band upper edge
    hidden var mHigh;    // above this = red

    function initialize() { GraphField.initialize(); }

    function onConfig() {
        var a = App.getApp();
        mColor = true;
        var v = a.getProperty("cadColor"); if (v != null) { mColor = v; }
        mLow = 70;  v = a.getProperty("cadLow");     if (v != null) { mLow = v; }
        mGLo = 85;  v = a.getProperty("cadGreenLo"); if (v != null) { mGLo = v; }
        mGHi = 100; v = a.getProperty("cadGreenHi"); if (v != null) { mGHi = v; }
        mHigh = 110; v = a.getProperty("cadHigh");   if (v != null) { mHigh = v; }
    }

    function sample(info) {
        return (info has :currentCadence && info.currentCadence != null) ? info.currentCadence : 0;
    }
    function minSpan() { return 25; }
    function floorClamp() { return 0; }
    function barColor(v) {
        if (!mColor) { return Gfx.COLOR_DK_GRAY; }   // colours off: clean grey
        if (v < mLow)  { return Gfx.COLOR_LT_GRAY; }
        if (v < mGLo)  { return Gfx.COLOR_ORANGE; }
        if (v <= mGHi) { return Gfx.COLOR_GREEN; }
        if (v <= mHigh){ return Gfx.COLOR_ORANGE; }
        return Gfx.COLOR_RED;
    }

    // rotation ring with a clockwise arrowhead (shifted down for a top gap)
    function drawIcon(dc, x, y, s) {
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        var cx = x + s / 2;
        var cy = y + (58 * s) / 100;
        var r = (32 * s) / 100;
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, r);
        dc.setPenWidth(1);
        dc.fillPolygon([
            [cx - 1, cy - r - 3],
            [cx - 1, cy - r + 3],
            [cx + 5, cy - r]
        ]);
    }
}

class CadenceGraphApp extends App.AppBase {
    function initialize() { AppBase.initialize(); }
    function onStart(s) { }
    function onStop(s) { }
    function getInitialView() { return [ new CadenceField() ]; }
    function onSettingsChanged() { Ui.requestUpdate(); }
}
