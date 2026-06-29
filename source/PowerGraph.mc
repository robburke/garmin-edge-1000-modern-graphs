using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

// Varia-Safe Power: lightning icon, dynamic scale, Coggan zone colours, FTP line.
class PowerField extends GraphField {
    hidden var mFtp;

    function initialize() { GraphField.initialize(); }

    function onConfig() {
        mFtp = 240;
        var v = App.getApp().getProperty("ftp");
        if (v != null) { mFtp = v; }
        if (mFtp < 50) { mFtp = 50; }
    }

    function sample(info) {
        return (info has :currentPower && info.currentPower != null) ? info.currentPower : 0;
    }
    function minSpan() { return 80; }
    function floorClamp() { return 0; }
    function referenceValue() { return mFtp; }
    function barColor(v) {
        var pct = (v * 100) / mFtp;
        if (pct < 55)  { return Gfx.COLOR_LT_GRAY; }
        if (pct < 76)  { return Gfx.COLOR_BLUE; }
        if (pct < 91)  { return Gfx.COLOR_GREEN; }
        if (pct < 106) { return Gfx.COLOR_YELLOW; }
        if (pct < 121) { return Gfx.COLOR_ORANGE; }
        return Gfx.COLOR_RED;
    }

    // lightning bolt (inset from the top so it has a little breathing gap)
    function drawIcon(dc, x, y, s) {
        dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [x + (55 * s) / 100, y + (8 * s) / 100],
            [x + (15 * s) / 100, y + (60 * s) / 100],
            [x + (45 * s) / 100, y + (60 * s) / 100],
            [x + (28 * s) / 100, y + (98 * s) / 100],
            [x + (85 * s) / 100, y + (42 * s) / 100],
            [x + (52 * s) / 100, y + (42 * s) / 100],
            [x + (72 * s) / 100, y + (8 * s) / 100]
        ]);
    }
}

class PowerGraphApp extends App.AppBase {
    function initialize() { AppBase.initialize(); }
    function onStart(s) { }
    function onStop(s) { }
    function getInitialView() { return [ new PowerField() ]; }
    function onSettingsChanged() { Ui.requestUpdate(); }
}
