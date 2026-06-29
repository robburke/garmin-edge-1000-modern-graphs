using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Activity;
using Toybox.Application as App;

// Shared engine for the Varia-Safe graph fields (v0.6 "1050-style" layout).
//
// Layout per field, side-by-side:
//   [ metric icon + BIG current number ]  on the LEFT half
//   [ rolling sparkline graph ]           on the RIGHT half, to the very edge
//
// The number lives on the left where the 1000's Varia overlay can't reach, so
// we deliberately keep NO right margin -- the graph runs under the Varia bar and
// we accept losing its far-right sliver. The number auto-sizes to the largest
// font that fits 3 digits (4 digits overflow on purpose; nobody holds 1000W).
//
// Vertical scale is dynamic (fits the window) with padding, min-span, floor
// clamp, smoothing. Colour carries absolute zone; the number is the exact value;
// the sparkline is the trend. Subclasses provide sample/barColor/minSpan/
// floorClamp/referenceValue/drawIcon (+ onConfig).
class GraphField extends Ui.DataField {

    hidden const CAP = 180;
    hidden var mBuf;
    hidden var mHead = 0;
    hidden var mCount = 0;
    hidden var mCur = 0;
    hidden var mWindow = 120;
    hidden var mMargin = 10;      // px kept clear on the right for the Varia bar
    hidden var mSmBase = null;
    hidden var mSmTop = null;

    function initialize() {
        DataField.initialize();
        mBuf = new [CAP];
        for (var i = 0; i < CAP; i += 1) { mBuf[i] = 0; }
        reloadSettings();
    }

    // Read all user settings. Called on init and again from the app's
    // onSettingsChanged, so edits in Garmin Express apply live.
    function reloadSettings() {
        var a = App.getApp();
        var v = a.getProperty("windowSec");
        mWindow = (v != null) ? v : 120;
        v = a.getProperty("rmargin");
        mMargin = (v != null) ? v : 10;
        if (mWindow < 30) { mWindow = 30; }
        if (mWindow > CAP) { mWindow = CAP; }
        if (mMargin < 0) { mMargin = 0; }
        onConfig();
    }

    // overridables
    function onConfig() { }
    function sample(info) { return 0; }
    function barColor(v) { return Gfx.COLOR_DK_GRAY; }
    function minSpan() { return 20; }
    function floorClamp() { return 0; }
    function drawIcon(dc, x, y, s) { }   // metric glyph in an s-by-s box at (x,y)

    function compute(info) {
        var s = sample(info);
        if (s == null) { s = 0; }
        mCur = s;
        mBuf[mHead] = s;
        mHead = (mHead + 1) % CAP;
        if (mCount < CAP) { mCount += 1; }
    }

    hidden function pickNumFont(dc, maxW, maxH) {
        var fonts = [
            Gfx.FONT_NUMBER_THAI_HOT, Gfx.FONT_NUMBER_HOT, Gfx.FONT_NUMBER_MEDIUM,
            Gfx.FONT_NUMBER_MILD, Gfx.FONT_LARGE, Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY
        ];
        for (var i = 0; i < fonts.size(); i += 1) {
            if (dc.getFontHeight(fonts[i]) <= maxH && dc.getTextWidthInPixels("888", fonts[i]) <= maxW) {
                return fonts[i];
            }
        }
        return Gfx.FONT_XTINY;
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        dc.clear();

        // ----- left zone: small icon STACKED above a BIG number (digits get full width) -----
        var xL = 3;
        var graphMin = 78;                       // keep at least this much width for the graph
        var maxNumW = w - graphMin - xL;
        if (maxNumW < 24) { maxNumW = 24; }
        var maxNumH = h - 28;                     // leave room for the small icon on top
        if (maxNumH < 16) { maxNumH = 16; }
        var nf = pickNumFont(dc, maxNumW, maxNumH);
        var fH = dc.getFontHeight(nf);
        var iconS = (fH * 36) / 100;              // small icon, proportional to the number
        if (iconS < 12) { iconS = 12; }
        if (iconS > 28) { iconS = 28; }
        var numColW = dc.getTextWidthInPixels("888", nf);  // stable 3-digit reserve
        var blockH = iconS + 2 + fH;
        var blockTop = (h - blockH) / 2;
        if (blockTop < 0) { blockTop = 0; }

        // icon centered over the digit column; number centered within it
        var colCenter = xL + numColW / 2;
        drawIcon(dc, colCenter - iconS / 2, blockTop, iconS);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(colCenter, blockTop + iconS + 2, nf, mCur.format("%d"), Gfx.TEXT_JUSTIFY_CENTER);

        // ----- right: graph zone, left edge after the reserved digit column -----
        var gL = xL + numColW + 8;
        var gR = w - 1 - mMargin;
        if (gL > gR - 8) { gL = gR - 8; }
        var gW = gR - gL;
        if (gW < 8) { gW = 8; }
        var gTop = 2;
        var gBot = h - 2;
        var gH = gBot - gTop;
        if (gH < 6) { gH = 6; }

        // dynamic autoscale over the window (ignore <=0 = no data)
        var nShow = mWindow;
        if (nShow > mCount) { nShow = mCount; }
        var lo = null;
        var hi = null;
        for (var i = 0; i < nShow; i += 1) {
            var bi = (mHead - 1 - i + CAP * 2) % CAP;
            var v = mBuf[bi];
            if (v <= 0) { continue; }
            if (lo == null || v < lo) { lo = v; }
            if (hi == null || v > hi) { hi = v; }
        }
        var ms = minSpan();
        var fc = floorClamp();
        var tBase;
        var tTop;
        if (lo == null) {
            tBase = fc; tTop = fc + ms;
        } else {
            var span = hi - lo;
            if (span < 1) { span = 1; }
            var pad = span / 10;
            tBase = lo - pad; tTop = hi + pad;
            if (tTop - tBase < ms) { var mid = (tTop + tBase) / 2; tBase = mid - ms / 2; tTop = mid + ms / 2; }
            if (tBase < fc) { tBase = fc; }
            if (tTop <= tBase) { tTop = tBase + ms; }
        }
        if (mSmBase == null) { mSmBase = tBase * 1.0; mSmTop = tTop * 1.0; }
        else {
            mSmBase = mSmBase + (tBase - mSmBase) / 8.0;
            mSmTop = mSmTop + (tTop - mSmTop) / 8.0;
        }
        var base = mSmBase;
        var top = mSmTop;
        var vspan = top - base;
        if (vspan < 1) { vspan = 1; }

        // bars: newest at the right edge, scrolling left
        var stepf = gW * 1.0 / mWindow;
        if (stepf < 1.0) { stepf = 1.0; }
        var bw = stepf.toNumber() + 1;
        if (bw < 1) { bw = 1; }
        for (var k = 0; k < nShow; k += 1) {
            var x = (gR - bw - (k * stepf)).toNumber();
            if (x < gL) { break; }
            var bk = (mHead - 1 - k + CAP * 2) % CAP;
            var val = mBuf[bk];
            if (val <= 0) { continue; }
            var bh = (((val - base) * gH) / vspan).toNumber();
            if (bh > gH) { bh = gH; }
            if (bh < 1) { bh = 1; }
            dc.setColor(barColor(val), Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(x, gBot - bh, bw, bh);
        }

        // (Reference lines removed: with a floating auto-scale a fixed value
        // drifts vertically, and the zone colours already mark FTP / threshold.)
    }
}
