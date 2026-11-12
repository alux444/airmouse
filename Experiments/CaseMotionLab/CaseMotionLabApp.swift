import SwiftUI

@main
struct CaseMotionLabApp: App {
    @StateObject private var lab = CaseLab()

    var body: some Scene {
        Window("AirMouse Case Lab", id: "lab") {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    casePreview
                    connection
                    if lab.closed && lab.calibration != .complete { calibration }
                    if lab.closed { tapping }
                    if !lab.details.isEmpty { connectionDetails }
                    Text("Experimental: reconnecting may interrupt audio and play silence to your AirPods. Closed-case sessions can use case diagnostic data and change AirPods connection settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
            .frame(width: 500, height: 520)
            .onDisappear { lab.stop() }
        }
        .windowResizability(.contentSize)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("AirMouse").font(.title2.weight(.semibold))
            Spacer()
            Text("Case experiment").font(.callout).foregroundStyle(.secondary)
        }
    }

    private var casePreview: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
            CaseIllustration(lidOpen: !lab.closed)
                .accessibilityHidden(true)
            Text("SETUP ILLUSTRATION")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
                .padding(16)
        }
        .frame(height: 220)
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.05)))
    }

    private var connection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Circle().fill(lab.pointing ? Color.green : Color.secondary.opacity(0.55))
                    .frame(width: 6, height: 6)
                Text(connectionStatus).font(.headline)
            }
            Text(lab.message)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                if lab.closed && lab.calibration == .complete {
                    Button(lab.pointing ? "Pause Mouse" : "Start Mouse") {
                        if lab.pointing { lab.pausePointer() } else { lab.startPointer() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!lab.orientationReady)
                    .controlSize(.large)
                }
                if lab.active {
                    Button("Disconnect") { lab.toggle() }.controlSize(.large)
                } else {
                    Button("Connect Case") { lab.toggle() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
            .padding(.top, 2)
            if lab.pointing {
                Text("Pause anytime with Control–Option–Space.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var calibration: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text("Calibrate").font(.headline)
            Text(calibrationInstruction).fixedSize(horizontal: false, vertical: true)
            Button(calibrationButton) { lab.captureCalibration() }
                .disabled(!lab.orientationReady)
            if !lab.orientationReady {
                Text("Hold the case still while motion settles.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var tapping: some View {
        VStack(alignment: .leading, spacing: 8) {
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
    }

    private var connectionDetails: some View {
        DisclosureGroup("Connection details") {
            ScrollView {
                Text(lab.details).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            }
            .frame(height: 100)
        }
    }

    private var connectionStatus: String {
        if lab.pointing { return "Mouse is on" }
        if lab.closed { return "Case connected" }
        if lab.active { return "Setting up" }
        return "Not connected"
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
