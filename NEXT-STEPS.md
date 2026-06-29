# Build status — BUILT & SIDELOADED (2026-06-28)

All three fields compiled successfully with **Connect IQ SDK 9.2.0** and
sideloaded to the Edge 1000. Two things that tripped the build (fixed, noted
here for anyone reproducing):

1. **Device id is `edge_1000`** (underscore), not `edge1000`. Same for
   `edge_520`. Used in both the manifest `<iq:product id="...">` and
   `monkeyc -d edge_1000`. The Edge Explore 1000 isn't in SDK 9.2.0's device
   list, so it was dropped from the manifests.
2. **`minApiVersion` is not allowed** on `<iq:application>` in manifest v3 under
   SDK 9; the attribute was removed.

JDK 25 (Eclipse Adoptium) compiled fine, no JDK downgrade needed.

Build command used:
`monkeyc -d edge_1000 -f power.jungle -o bin/VariaSafe-power.prg -y developer_key`
(and likewise cadence.jungle / hr.jungle). Or just `./build.sh`.

---

## Original notes — finishing the build (kept for reference)

The Connect IQ SDK (`monkeyc`) ships only via Garmin's **SDK Manager GUI**
(requires a Garmin account login), so it can't be installed fully headlessly.

## To produce the sideloadable `.prg`

1. **Install the Connect IQ SDK** via the SDK Manager:
   `https://developer.garmin.com/connect-iq/sdk/` → download the Windows SDK
   Manager, sign in with your Garmin account, install the latest SDK, and add
   its `bin/` to PATH so `monkeyc` resolves.

2. **Build** (a developer key is already generated in the repo root, gitignored):
   ```
   ./build.sh                # or: build.ps1
   # = monkeyc -d edge1000 -f monkey.jungle -o bin/VariaSafeGraph.prg -y developer_key
   ```

3. **Sideload**: copy `bin/VariaSafeGraph.prg` to `<EDGE>/GARMIN/Apps/` over USB,
   eject, unplug. It appears under a 1-field data screen → Connect IQ.

## Known gotchas (read before building)

- **JDK version:** this box has JDK 25. Recent `monkeyc` wants JDK 17–21. If the
  build throws Java errors, install JDK 21 LTS and point `JAVA_HOME` at it.
- **edge1000 device definition:** very new SDKs may have dropped the Edge 1000.
  If `monkeyc -d edge1000` reports an unknown device, install an older SDK
  (3.x / 4.1.x era) that still includes `edge1000`, or build for a device that
  is present and confirm the layout, then build edge1000 from the older SDK.
- **API level:** manifest `minApiVersion` is 1.4.0 and the code only uses basic
  `Graphics`/`Activity` calls, so it should compile against old SDKs too.

## After it works

- Test on the Edge 1000 with the Varia active; tune `marginPx` so the threat bar
  never covers the power number.
- Then publish: GitHub under `robburke/`, MIT-licensed, and (optionally) submit
  to the Connect IQ store. See the vault project page for the sharing plan.
