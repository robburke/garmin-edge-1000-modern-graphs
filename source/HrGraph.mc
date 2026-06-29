using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.UserProfile;

// Varia-Safe Heart Rate: heart icon, dynamic scale.
// Colours come from the rider's ACTUAL device HR zones (UserProfile), so they
// auto-update when the profile changes. Falls back to % of a max-HR setting if
// the device can't supply zones. Reference line = zone 4/5 boundary (threshold).
class HrField extends GraphField {
    hidden var mZones;   // null, or [minZ1, maxZ1, maxZ2, maxZ3, maxZ4, maxZ5]
    hidden var mMaxHr;

    function initialize() { GraphField.initialize(); }

    function onConfig() {
        mMaxHr = 181;
        var v = App.getApp().getProperty("maxHr");
        if (v != null) { mMaxHr = v; }
        if (mMaxHr < 120) { mMaxHr = 120; }

        mZones = null;
        if (UserProfile has :getHeartRateZones) {
            var z = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
            if (z != null && z.size() >= 6) { mZones = z; }
        }
    }

    function sample(info) {
        return (info has :currentHeartRate && info.currentHeartRate != null) ? info.currentHeartRate : 0;
    }
    function minSpan() { return 25; }
    function floorClamp() { return 40; }
    function barColor(v) {
        if (mZones != null) {
            if (v < mZones[1]) { return Gfx.COLOR_LT_GRAY; } // zone 1
            if (v < mZones[2]) { return Gfx.COLOR_BLUE; }    // zone 2
            if (v < mZones[3]) { return Gfx.COLOR_GREEN; }   // zone 3
            if (v < mZones[4]) { return Gfx.COLOR_ORANGE; }  // zone 4
            return Gfx.COLOR_RED;                             // zone 5
        }
        var pct = (v * 100) / mMaxHr;
        if (pct < 60) { return Gfx.COLOR_LT_GRAY; }
        if (pct < 70) { return Gfx.COLOR_BLUE; }
        if (pct < 80) { return Gfx.COLOR_GREEN; }
        if (pct < 90) { return Gfx.COLOR_ORANGE; }
        return Gfx.COLOR_RED;
    }

    // heart: two lobes + a point (has natural top padding)
    function drawIcon(dc, x, y, s) {
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        var r = (26 * s) / 100;
        var ly = y + (34 * s) / 100;
        dc.fillCircle(x + (32 * s) / 100, ly, r);
        dc.fillCircle(x + (68 * s) / 100, ly, r);
        dc.fillPolygon([
            [x + (5 * s) / 100, y + (42 * s) / 100],
            [x + (95 * s) / 100, y + (42 * s) / 100],
            [x + (50 * s) / 100, y + s]
        ]);
    }
}

class HrGraphApp extends App.AppBase {
    hidden var mView;
    function initialize() { AppBase.initialize(); }
    function onStart(s) { }
    function onStop(s) { }
    function getInitialView() { mView = new HrField(); return [ mView ]; }
    function onSettingsChanged() { if (mView != null) { mView.reloadSettings(); } Ui.requestUpdate(); }
}
