import CoreMotion
import SwiftUI

@MainActor
final class CaseProbe: ObservableObject {
    @Published private(set) var running = false
    @Published private(set) var samples = 0
    @Published private(set) var currentAcceleration = 0.0
    @Published private(set) var peakAcceleration = 0.0
    @Published private(set) var status = "Put both AirPods in the case, open the lid, and connect them to this Mac."

    private let manager = CMHeadphoneMotionManager()
    private var timeout: Timer?

    func toggle() {
        if running {
            stop(message: "Test stopped.")
            return
        }
        start()
    }

    func resetPeak() {
        peakAcceleration = 0
    }

    private func start() {
        guard manager.isDeviceMotionAvailable else {
            status = "No headphone motion is available. Check that the AirPods are connected to this Mac."
            return
        }
        samples = 0
        currentAcceleration = 0
        peakAcceleration = 0
        running = true
        status = "Waiting for motion samples…"
        timeout = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.checkForSamples() }
        }
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            Task { @MainActor in self?.receive(motion, error: error) }
        }
    }

    private func receive(_ motion: CMDeviceMotion?, error: Error?) {
        guard running else { return }
        guard error == nil, let motion else {
            stop(message: "Motion stopped: \(error?.localizedDescription ?? "no data returned").")
            return
        }
        let acceleration = motion.userAcceleration
        let magnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)
        samples += 1
        currentAcceleration = magnitude
        peakAcceleration = max(peakAcceleration, magnitude)
        status = "Receiving motion. Reset the peak, then gently tap an AirPod and compare."
    }

    private func checkForSamples() {
        guard running, samples == 0 else { return }
        stop(message: "No samples arrived. Check Motion & Fitness permission and whether the AirPods are connected.")
    }

    private func stop(message: String) {
        manager.stopDeviceMotionUpdates()
        timeout?.invalidate()
        timeout = nil
        running = false
        status = message
    }
}

@main
struct OpenCaseProbeApp: App {
    @StateObject private var probe = CaseProbe()

    var body: some Scene {
        Window("Open-case sensor test", id: "probe") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Open-case sensor test").font(.title2.weight(.semibold))
                Text(probe.status)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button(probe.running ? "Stop test" : "Start test") { probe.toggle() }
                    Button("Reset peak") { probe.resetPeak() }
                        .disabled(probe.samples == 0)
                    Spacer()
                }
                Divider()
                LabeledContent("Samples", value: "\(probe.samples)")
                LabeledContent("Current motion", value: String(format: "%.3f g", probe.currentAcceleration))
                LabeledContent("Peak since reset", value: String(format: "%.3f g", probe.peakAcceleration))
                Text("This test only reads headphone motion. It does not click, move the cursor, or save recordings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(width: 450)
        }
        .windowResizability(.contentSize)
    }
}
