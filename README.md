# AirMouse

Move your Mac's pointer with the motion sensors in your AirPods. AirMouse is an early, local macOS prototype built with SwiftUI and Core Motion.

## Run it

Requires macOS 14 or later, Xcode or the Swift toolchain, and AirPods that provide headphone motion. AirPods 4 with ANC are a good fit.

```sh
./build.sh
open build/AirMouse.app
```

Put in your AirPods and connect them to the Mac. Choose **Start tracking** and allow Motion and Accessibility access if macOS asks. If Accessibility access is denied, enable AirMouse in System Settings → Privacy & Security → Accessibility, then try again. Use **Control–Option–Space** to start or pause from anywhere. Click with your trackpad or mouse.

The first motion sample establishes a baseline, and pausing clears it. Adjust sensitivity to suit your setup. Motion data stays on your Mac; AirMouse does not send it anywhere. The app is locally signed for development, so rebuilding may require Accessibility permission to be re-enabled.

Run focused pointer-mapping tests with `swift test`. Hardware tracking and permission prompts require a real Mac and compatible headphones.
