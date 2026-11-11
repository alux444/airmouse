# AirMouse

AirMouse is a native macOS prototype for controlling your Mac using motion from compatible AirPods. The current motion implementation assumes the AirPods are being worn; closed-case control is not implemented. Motion stays on your Mac.

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
