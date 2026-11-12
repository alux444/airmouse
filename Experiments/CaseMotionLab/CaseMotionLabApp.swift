import AppKit
import SwiftUI

@main
struct CaseMotionLabApp: App {
    @StateObject private var lab = CaseLab()

    var body: some Scene {
        Window("AirMouse", id: "lab") {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "airpods.gen3.chargingcase.wireless")
                        .font(.system(size: 62, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary)
                        .frame(height: 78)
                        .accessibilityHidden(true)
                    VStack(spacing: 7) {
                        Text(title).font(.title2.weight(.semibold))
                        Text(lab.message)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    actions
                    if lab.closed && !lab.caseIdentified {
                        Text("Waiting for the case to identify itself.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if lab.closed && lab.caseIdentified && lab.calibration != .complete { calibration }
                    if lab.closed && lab.caseIdentified { tapping }
                    if !lab.details.isEmpty { connectionDetails }
                    Text("Experimental: reconnecting may interrupt audio and play silence to your AirPods. A closed-case session can use case diagnostic data and change AirPods settings.")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .frame(width: 340, height: lab.closed ? 520 : 400)
            .background(.regularMaterial)
            .background(FloatingWindow())
            .onDisappear { lab.stop() }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }

    private var title: String {
        if lab.pointing { return "Mouse is on" }
        if lab.caseIdentified { return "Case ready" }
        if lab.active { return "Connecting…" }
        return "AirMouse"
    }

    private var actions: some View {
        VStack(spacing: 8) {
            if lab.closed && lab.caseIdentified && lab.calibration == .complete {
                Button(lab.pointing ? "Pause Mouse" : "Start Mouse") {
                    if lab.pointing { lab.pausePointer() } else { lab.startPointer() }
                }
                .disabled(!lab.orientationReady)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            if lab.active {
                Button("Disconnect") { lab.toggle() }.controlSize(.large)
            } else {
                Button("Connect") { lab.toggle() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            if lab.pointing {
                Text("Press Escape or Control–Option–Space to pause.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var calibration: some View {
        VStack(spacing: 8) {
            Divider()
            Text("Calibrate").font(.headline)
            Text(calibrationInstruction).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button(calibrationButton) { lab.captureCalibration() }
                .disabled(!lab.orientationReady)
            if !lab.orientationReady {
                Text("Set the case down and keep it still for a moment.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var tapping: some View {
        VStack(spacing: 8) {
            Divider()
            Text("Tap to click").font(.headline)
            Text("Pause the mouse, then teach and test a tap before enabling clicks.")
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Teach Tap") { lab.teachTap() }.disabled(lab.pointing)
                Text("Detected: \(lab.trainedTaps)").monospacedDigit()
            }
            Text(lab.trainingStatus).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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

private struct FloatingWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            view.window?.level = .floating
            view.window?.isMovableByWindowBackground = true
        }
    }
}
