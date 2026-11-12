# AirMouse

AirMouse is a native macOS prototype for controlling your Mac using motion from compatible AirPods. The main app uses motion from AirPods worn in your ears. A separate case-mouse experiment is in progress. Motion stays on your Mac.

## Run it

Requires macOS 14 or later, Xcode or the Swift toolchain, and headphones that provide motion data.

```sh
./build.sh
open build/AirMouse.app
```

Put in your AirPods and connect them to the Mac. Start tracking and allow Motion and Accessibility access when requested. If Accessibility is already enabled but AirMouse still asks for access, quit AirMouse, remove its old entry from System Settings → Privacy & Security → Accessibility, and add the exact app you are opening. Development builds are ad-hoc signed, so rebuilding changes their identity and can require this again.

Use **Control–Option–Space** to start or pause from anywhere. Switching modes pauses tracking; start again while looking straight ahead to set the centre. Use **Recenter** to reset it.

- **Pointer:** move the pointer with your head. Optionally enable dwell clicking: hold the pointer still outside AirMouse, then move away before the next click. Dwell clicking is off by default.
- **Scroll:** tilt to scroll and return to centre to stop. Reverse the direction if needed.

Run `swift test` for motion and action tests. Live tracking and permissions need a real Mac and compatible headphones.

## Try the experimental case mouse

The Case Lab explores using AirPods in their closed case as a pointer. It is separate from the main app, and closed-case pointing and tapping have not yet been verified on this pair.

Build and open the lab:

```sh
./Experiments/CaseMotionLab/build.sh
open build/CaseMotionLab.app
```

Connect your AirPods with both earbuds in the open case. Choose **Connect Case**, wait for the prompt, and close the lid. If the case connects, follow the calibration prompts. **Start Mouse** requires Accessibility permission for this exact Case Lab app. Control–Option–Space pauses the pointer.

With the mouse paused, choose **Teach Tap** and tap the same spot three to six times. Test several more taps against the count before enabling **Use taps to click**. Tap detection remains experimental and may miss taps or count unintended motion.

The lab uses an undocumented connection from [AirPointer](https://github.com/oscarcreatess/airpointer). It reconnects the AirPods, may interrupt audio, and can consume case diagnostic data during a closed-case session. It leaves some connection settings changed because their previous values cannot be read. The lab tries to play silence directly to the AirPods to keep their audio link active. It does not select a different system audio output and stops if that output changes.
