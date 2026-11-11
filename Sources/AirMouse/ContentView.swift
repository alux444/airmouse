import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: MouseController

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            heading
            status
            Divider()
            Picker("Control mode", selection: $controller.mode) {
                ForEach(ControlMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Control mode")
            modeSettings
        }
        .padding(24)
        .frame(width: 440)
    }

    private var heading: some View {
        HStack(spacing: 12) {
            Image(systemName: "cursorarrow.motionlines")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 3) {
                Text("AirMouse").font(.title2.weight(.semibold))
                Text("Headphone motion · Case control unavailable")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
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
                if controller.isTracking {
                    Button("Recenter") { controller.recenter() }
                }
                Spacer()
                Text("⌃⌥ Space")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Control Option Space")
            }
        }
    }

    @ViewBuilder
    private var modeSettings: some View {
        switch controller.mode {
        case .pointer:
            VStack(alignment: .leading, spacing: 12) {
                sensitivity
                Toggle("Click when pointer rests", isOn: $controller.dwellEnabled)
                Text("Hold still to click outside AirMouse. Move away before clicking again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .scroll:
            VStack(alignment: .leading, spacing: 12) {
                Text("Tilt to scroll; return to centre to stop.").font(.callout)
                Toggle("Reverse scroll direction", isOn: $controller.reverseScroll)
                Text("Start while looking straight ahead. Use Recenter whenever you need to reset.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        }
    }

    private var sensitivity: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pointer sensitivity").font(.headline)
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
