# AirPointer motion helper

`CaseSustainedRenewal.m` is copied without modification from [AirPointer](https://github.com/oscarcreatess/airpointer) at commit `7f44e6437aaab48ee7af26a16d2b90dd6a3ab4d9`. Its MIT licence is in this directory.

AirMouse uses this helper for an experimental case mouse. Once the open-case baseline and lid closure are confirmed, it sends `closed_confirmed`, which initiates the reference implementation’s case diagnostic keepalive and can consume case diagnostic data. The helper reconnects the AirPods and writes undocumented connection settings whose previous values cannot be read back.

`ClosedCaseTapCore.swift` is the detector and learner (the first 204 lines) from `Sources/AirPointer/Session/ClosedCaseTap.swift` at the same commit. Its recorded fixture checks were run from the original checkout; open-case gestures still require separate testing.

`Orientation.js` is copied without modification from `Sources/AirPointer/Session/Orientation.js` at the same commit. It provides motion fusion and the three-point screen calibration for the case pointer.

`Experiments/CaseMotionLab/CaseSilentOutput.swift` adapts the targeted silent output from `Sources/AirPointer/Session/AudioOutputGuard.swift` at the same commit. It does not include the reference app’s default audio-device switching.
