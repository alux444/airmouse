# AirMouse

AirMouse is an experimental Mac app that turns an AirPods case into a pointer. Move the closed case to point and tap it to click. Press Escape to pause.

The case mode has been tested with AirPods 4 with Active Noise Cancellation. Connection and tap detection can be unreliable, and tap-to-click in the current setup still needs live testing.

## Build and open

You need macOS 14 or later, Xcode or the Swift toolchain, and compatible AirPods. Build the app from the repository root:

```sh
./Experiments/CaseMotionLab/build.sh
open "build/AirMouse Case.app"
```

Allow Bluetooth access when prompted. Add the exact app you opened to **System Settings → Privacy & Security → Accessibility** so it can move and click the pointer. Development builds are ad-hoc signed, so you may need to remove the old Accessibility entry and add the app again after rebuilding.

## Set up the case

1. Put both AirPods in their open case and connect them to your Mac.
2. Open AirMouse Case, select **Connect**, and close the lid when prompted.
3. Tap the closed case to teach your tap, then tap three more times to check it.
4. Set the case down and hold it still. Aim at the centre, right edge, and top edge of the screen, tapping at each position.

After calibration, the pointer starts and taps are set to click. Use the AirMouse menu-bar icon, Escape, or Control–Option–Space to pause. While paused, you can turn tap clicking off or teach it again. If tapping is difficult during calibration, use **Capture with Button**.

## Connection details

Case mode uses an undocumented connection adapted from [AirPointer](https://github.com/oscarcreatess/airpointer). It reconnects the AirPods, may interrupt audio, and can consume case diagnostic data. It also changes connection settings whose previous values cannot be read back. AirMouse may play silence directly to the AirPods to maintain the connection; it does not change the Mac’s selected audio output and stops if that output changes. See [the vendor notes](Vendor/AirPointer/README.md) for attribution.

## Development

Run the Swift tests and case-specific checks:

```sh
swift test
./Experiments/CaseMotionLab/check.sh
```

The repository also contains an earlier wearable experiment. Build it with `./build.sh` and open `build/AirMouse.app`. It supports head-controlled pointing and scrolling with compatible AirPods worn in your ears.
