import SwiftUI

@main
struct CaseMotionLabApp: App {
    @StateObject private var lab = CaseLab()

    var body: some Scene {
        Window("AirMouse Case Lab", id: "lab") {
            VStack(alignment: .leading, spacing: 16) {
                Text("AirMouse Case Lab").font(.title2.weight(.semibold))
                Text("Open-case motion test").foregroundStyle(.secondary)
                Text(lab.message)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Button(lab.active ? "Stop Test" : "Start Test") { lab.toggle() }
                        .controlSize(.large)
                    Button("Reset") { lab.resetPeak() }
                        .disabled(lab.sampleCount == 0)
                    Button("Teach Tap") { lab.teachTap() }.disabled(!lab.active || lab.sampleCount == 0)
                    Spacer()
                }
                Text(lab.trainingStatus).font(.caption).foregroundStyle(.secondary)
                if !lab.details.isEmpty {
                    DisclosureGroup("Connection details") {
                        ScrollView { Text(lab.details).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
                            .frame(height: 120)
                    }
                }
                Divider()
                LabeledContent("Motion samples", value: "\(lab.sampleCount)")
                LabeledContent("Largest motion spike", value: String(format: "%.3f g", lab.peak))
                LabeledContent("Threshold taps", value: "\(lab.detectedTaps)")
                LabeledContent("Trained taps", value: "\(lab.trainedTaps)")
                LabeledContent("Strong spikes", value: "\(lab.candidates)")
                if !lab.filterSummary.isEmpty { Text(lab.filterSummary).font(.caption).foregroundStyle(.secondary) }
                Text("This test does not click or move the pointer. It briefly reconnects your AirPods and stops if your Mac’s audio output changes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(width: 460)
            .onDisappear { lab.stop() }
        }
        .windowResizability(.contentSize)
    }
}
