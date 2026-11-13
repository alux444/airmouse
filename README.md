# AirMouse

AirMouse is a native macOS prototype for controlling your Mac using motion from compatible AirPods. The main app uses motion from AirPods worn in your ears. A separate case-mouse experiment is in progress. Motion stays on your Mac.

For the case-controlled app, open `build/AirMouse Case.app` or follow [the case mouse instructions](#try-the-experimental-case-mouse) below.

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

AirMouse Case explores using AirPods in their closed case as a pointer. It is separate from the main app. Closed-case motion and pointer movement have been observed, but reconnection and tap detection remain unreliable.

Build and open AirMouse Case:

```sh
./Experiments/CaseMotionLab/build.sh
open "build/AirMouse Case.app"
```

Connect your AirPods with both earbuds in the open case. Choose **Connect**, wait for the prompt, and close the lid. Teach your tap, then tap three more times to check the count. Set the case down until it settles, then aim at the centre, right and top of the screen, tapping to capture each position.

After calibration, AirMouse starts pointing and uses taps to click. macOS must grant Accessibility permission to this exact AirMouse Case app. Press Escape or Control–Option–Space to pause the pointer and clicking. While paused, you can turn tap clicking off or teach it again. Tap detection remains experimental and may miss taps or count unintended motion.

AirMouse Case uses an undocumented connection from [AirPointer](https://github.com/oscarcreatess/airpointer). It reconnects the AirPods, may interrupt audio, and can consume case diagnostic data during a closed-case session. It leaves some connection settings changed because their previous values cannot be read. AirMouse Case tries to play silence directly to the AirPods to keep their audio link active. It does not select a different system audio output and stops if that output changes.
