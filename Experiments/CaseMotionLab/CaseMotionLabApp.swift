import AppKit
import SwiftUI

@main
struct CaseMotionLabApp: App {
    @StateObject private var lab = CaseLab()

    var body: some Scene {
        Window("AirMouse", id: "lab") {
            expanded
            .frame(width: 360, height: 450)
            .background(.regularMaterial)
            .background(FloatingWindow(pointing: lab.pointing, onClose: { lab.stop() }))
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarControls(lab: lab)
        } label: {
            Image(systemName: "airpods.gen3.chargingcase.wireless")
                .accessibilityLabel(lab.pointing ? "AirMouse, mouse active" : "AirMouse")
        }
    }

    private var expanded: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    CaseGuide(pose: guidePose)
                    content
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 26)
                .padding(.top, 26)
                .padding(.bottom, 18)
            }
            footer
        }
    }

    @ViewBuilder
    private var content: some View {
        if !lab.active {
            introduction
        } else if !lab.closed || !lab.caseIdentified {
            connecting
        } else if !lab.tapConfirmed {
            tapSetup
        } else if lab.calibration != .complete {
            calibration
        } else {
            ready
        }
    }

    private var introduction: some View {
        VStack(spacing: 9) {
            heading("AirMouse", lab.message)
            Button("Connect") { lab.toggle() }.buttonStyle(.borderedProminent).controlSize(.large)
            Text("Experimental: reconnecting may interrupt audio and play silence to your AirPods. Closed-case sessions can use case diagnostic data and change AirPods settings.")
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if !lab.details.isEmpty { connectionDetails }
        }
    }

    private var connecting: some View {
        VStack(spacing: 12) {
            heading("Connecting…", lab.message)
            if lab.closed && !lab.caseIdentified {
                Text("Waiting for the case to identify itself.").font(.caption).foregroundStyle(.secondary)
            }
            ProgressView().controlSize(.small)
            Button("Cancel") { lab.toggle() }
        }
    }

    private var tapSetup: some View {
        VStack(spacing: 12) {
            heading(lab.tapTrained ? "Try your tap" : "Teach your tap", tapInstruction)
            if lab.tapTeaching || lab.tapTrained || lab.tapFailure {
                Text(lab.tapTrained ? "Taps detected: \(lab.trainedTaps) of 3" : lab.trainingStatus)
                    .font(.callout).foregroundStyle(.secondary).monospacedDigit()
                    .multilineTextAlignment(.center)
            }
            if lab.tapFailure || (!lab.tapTeaching && !lab.tapTrained) {
                Button("Try Again") { lab.teachTap() }.buttonStyle(.borderedProminent)
            }
            Button("Disconnect") { lab.toggle() }
        }
    }

    private var calibration: some View {
        VStack(spacing: 12) {
            heading(lab.orientationReady ? calibrationTitle : "Hold still", calibrationInstruction)
            if lab.message == "Move the case farther in that direction and try again." {
                Text(lab.message).font(.caption).foregroundStyle(.secondary)
            }
            if lab.orientationReady {
                Button("Capture with Button") { lab.captureCalibration() }
                    .help("Use this if tapping the case is difficult.")
            }
            Button("Disconnect") { lab.toggle() }
        }
    }

    private var ready: some View {
        VStack(spacing: 12) {
            heading("Ready to point", lab.message)
            Button("Start Mouse") { lab.startPointer() }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(!lab.orientationReady)
            Toggle("Tap to click", isOn: Binding(get: { lab.tapClickEnabled }, set: { lab.setTapClickEnabled($0) }))
                .toggleStyle(.switch)
            Button("Teach Tap Again") { lab.teachTap() }
            Button("Disconnect") { lab.toggle() }
        }
    }

    private var footer: some View {
        HStack {
            Text("AirMouse").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            Spacer()
            if lab.active { Text("Experimental").font(.caption).foregroundStyle(.tertiary) }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }

    private func heading(_ title: String, _ detail: String) -> some View {
        VStack(spacing: 7) {
            Text(title).font(.title2.weight(.semibold))
            Text(detail).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var guidePose: CaseGuidePose {
        if !lab.active || !lab.closed { return .connect }
        if !lab.caseIdentified { return .rest }
        if !lab.tapConfirmed { return .tap }
        if !lab.orientationReady { return .rest }
        switch lab.calibration {
        case .center: return .centre
        case .right: return .right
        case .top: return .top
        case .complete: return .centre
        }
    }

    private var tapInstruction: String {
        if lab.tapTrained { return "Tap the case three more times to check it. After calibration, taps will click." }
        if lab.tapTeaching { return "Hold the closed case still and tap the same spot three to six times." }
        return "We’ll learn your tap before using it to calibrate and click."
    }

    private var connectionDetails: some View {
        DisclosureGroup("Connection details") {
            ScrollView {
                Text(lab.details).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            }
            .frame(height: 100)
        }
    }

    private var calibrationTitle: String {
        switch lab.calibration {
        case .center: return "Aim for the centre"
        case .right: return "Aim to the right"
        case .top: return "Aim for the top"
        case .complete: return "Calibration complete"
        }
    }

    private var calibrationInstruction: String {
        guard lab.orientationReady else { return "Set the closed case down and keep it still for a moment." }
        switch lab.calibration {
        case .center: return "Hold the case comfortably, aim at the centre of your screen, then tap."
        case .right: return "Keep your hand in place, aim toward the right edge, then tap."
        case .top: return "Return to centre, aim toward the top edge, then tap."
        case .complete: return "Calibration complete."
        }
    }
}

private struct MenuBarControls: View {
    @ObservedObject var lab: CaseLab
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(status)
        if lab.pointing {
            Button("Pause Mouse") { lab.pausePointer() }
        }
        Button(lab.pointing ? "Pause and Open AirMouse" : "Open AirMouse") {
            if lab.pointing { lab.pausePointer() }
            openWindow(id: "lab")
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("Quit AirMouse") {
            lab.stop()
            NSApp.terminate(nil)
        }
    }

    private var status: String {
        if lab.pointing { return "Mouse active" }
        if !lab.active { return "Not connected" }
        if lab.calibration == .complete { return "Mouse paused" }
        return "Setting up"
    }
}

private struct FloatingWindow: NSViewRepresentable {
    let pointing: Bool
    let onClose: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.level = .floating
            window.isMovableByWindowBackground = true
            if context.coordinator.closeObserver == nil {
                context.coordinator.closeObserver = NotificationCenter.default.addObserver(
                    forName: NSWindow.willCloseNotification, object: window, queue: .main
                ) { _ in onClose() }
            }
            if context.coordinator.pointing == nil, let screen = window.screen ?? NSScreen.main {
                let visible = screen.visibleFrame
                window.setFrameOrigin(NSPoint(x: visible.midX - window.frame.width / 2,
                                              y: visible.maxY - window.frame.height - 8))
            }
            guard context.coordinator.pointing != pointing else { return }
            let wasPointing = context.coordinator.pointing == true
            context.coordinator.pointing = pointing
            if pointing { window.orderOut(nil) }
            if wasPointing && !pointing { window.orderFrontRegardless() }
        }
    }

    final class Coordinator {
        var pointing: Bool?
        var closeObserver: NSObjectProtocol?

        deinit {
            if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
        }
    }
}
