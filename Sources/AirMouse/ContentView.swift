import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: MouseController

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            heading
            status
            Divider()
            sensitivity
            Divider()
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "hand.tap")
                    .frame(width: 16)
                Text("Use your trackpad or mouse to click.")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 400)
    }

    private var heading: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "cursorarrow.motionlines")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 3) {
                Text("AirMouse")
                    .font(.title2.weight(.semibold))
                Text("Control your pointer with AirPods")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Circle()
                    .fill(controller.isTracking ? Color.green : Color.secondary.opacity(0.5))
                    .frame(width: 7, height: 7)
                    .accessibilityHidden(true)
                Text(controller.isTracking ? "Tracking on" : "Tracking paused")
                    .font(.headline)
                Spacer()
                Text(controller.isConnected ? "Motion available" : "AirPods unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(controller.message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(controller.isTracking ? "Pause Tracking" : "Start Tracking") {
                    controller.toggleTracking()
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                Spacer()
                Text("⌃⌥ Space")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Control Option Space")
            }
        }
    }

    private var sensitivity: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pointer sensitivity")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f×", controller.sensitivity))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $controller.sensitivity, in: 0.4...2.5, step: 0.1)
                .accessibilityLabel("Pointer sensitivity")
                .accessibilityValue(String(format: "%.1f times", controller.sensitivity))
            HStack {
                Text("Slower")
                Spacer()
                Text("Faster")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
