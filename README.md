# AirMouse

AirMouse is a native macOS prototype for controlling your Mac with compatible AirPods. Motion stays on your Mac.

## Run it

Requires macOS 14 or later, Xcode or the Swift toolchain, and headphones that provide motion data. AirPods 4 with ANC support head tracking.

```sh
./build.sh
open build/AirMouse.app
```

Put in your AirPods and connect them to the Mac. Start tracking and allow Motion and Accessibility access when requested. If Accessibility is already enabled but AirMouse still asks for access, quit AirMouse, remove its old entry from System Settings → Privacy & Security → Accessibility, and add the exact app you are opening. Development builds are ad-hoc signed, so rebuilding changes their identity and can require this again.

Use **Control–Option–Space** to start or pause from anywhere. Switching modes pauses tracking; start again while looking straight ahead to set the centre. Use **Recenter** to reset it.

- **Pointer:** move the pointer with your head. Optionally enable dwell clicking: hold the pointer still outside AirMouse, then move away before the next click. Dwell clicking is off by default.
- **Scroll:** tilt to scroll and return to centre to stop. Reverse the direction if needed.
- **Presentation:** turn right or left to send the next or previous arrow key to the active app. Return to centre between turns. Reverse the turn direction if needed.
- **Shortcuts:** assign each turn to Mission Control, a desktop switch, an app, or a named Apple Shortcut. Return to centre between turns. macOS keyboard shortcut settings affect Mission Control and desktop switching.

Apps and shortcuts run only when assigned. AirMouse uses macOS Accessibility access for pointer, scrolling and keyboard actions. Some Apple Shortcuts may request additional permissions.

Run `swift test` for motion and action tests. Live tracking, operating-system permissions and gesture comfort need a real Mac and compatible headphones.
