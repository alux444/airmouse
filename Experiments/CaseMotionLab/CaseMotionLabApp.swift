import SwiftUI

@main
struct CaseMotionLabApp: App {
    @StateObject private var lab = CaseLab()

    var body: some Scene {
        Window("AirMouse Case Lab", id: "lab") {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AirMouse").font(.title2.weight(.semibold))
                    Text("Case mouse · Experimental").foregroundStyle(.secondary)
                }
                Text(lab.message)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Button(lab.active ? "Disconnect" : "Connect Case") { lab.toggle() }
                        .controlSize(.large)
                    if lab.closed && lab.calibration == .complete {
                        Button(lab.pointing ? "Pause Mouse" : "Start Mouse") {
                            if lab.pointing { lab.pausePointer() } else { lab.startPointer() }
                        }
                        .disabled(!lab.orientationReady)
                        .controlSize(.large)
                    }
                }
                if lab.closed && lab.calibration != .complete {
                    Divider()
                    Text("Calibrate").font(.headline)
                    Text(calibrationInstruction).fixedSize(horizontal: false, vertical: true)
                    Button(calibrationButton) { lab.captureCalibration() }
                        .disabled(!lab.orientationReady)
                    if !lab.orientationReady { Text("Hold the case still while motion settles.").font(.caption).foregroundStyle(.secondary) }
                }
                if lab.closed {
                    Divider()
                    Text("Tap to click").font(.headline)
                    Text("With the mouse paused, teach a tap on the closed case. Test the count before enabling clicks.")
                        .font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("Teach Tap") { lab.teachTap() }.disabled(lab.pointing)
                        Text("Detected: \(lab.trainedTaps)").monospacedDigit()
                    }
                    Text(lab.trainingStatus).font(.caption).foregroundStyle(.secondary)
                    Toggle("Use taps to click", isOn: $lab.tapClickEnabled)
                        .disabled(!lab.tapTrained || lab.trainedTaps < 3 || !lab.pointing)
                }
                if !lab.details.isEmpty {
                    DisclosureGroup("Connection details") {
                        ScrollView { Text(lab.details).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
                            .frame(height: 100)
                    }
                }
                Text("The case reconnects during setup and may receive silent audio. Control–Option–Space pauses the mouse. Closed-case operation uses an undocumented diagnostic connection.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(width: 460)
            .onDisappear { lab.stop() }
        }
        .windowResizability(.contentSize)
    }

    private var calibrationInstruction: String {
        switch lab.calibration {
        case .center: return "Hold the case comfortably and aim at the centre of your screen."
        case .right: return "Keeping your hand in place, aim toward the right edge of the screen."
        case .top: return "Return to centre, then aim toward the top edge of the screen."
        case .complete: return "Calibration complete."
        }
    }

    private var calibrationButton: String {
        switch lab.calibration {
        case .center: return "Set Centre"
        case .right: return "Set Right"
        case .top: return "Set Top"
        case .complete: return "Done"
        }
    }
}
