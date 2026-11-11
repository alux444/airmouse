import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ShortcutSettings: View {
    @Binding var leftAction: ShortcutAction
    @Binding var rightAction: ShortcutAction
    @Binding var leftDetail: String
    @Binding var rightDetail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Turn actions").font(.headline)
            actionRow("Turn left", action: $leftAction, detail: $leftDetail)
            actionRow("Turn right", action: $rightAction, detail: $rightDetail)
            Text("Return to centre before turning again. Changing an action pauses tracking.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func actionRow(_ label: String, action: Binding<ShortcutAction>, detail: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(label)
                Spacer()
                Picker(label, selection: action) {
                    ForEach(ShortcutAction.allCases) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                .labelsHidden()
                .frame(width: 185)
            }
            if action.wrappedValue == .openApp {
                HStack {
                    Text(detail.wrappedValue.isEmpty ? "No app selected" : URL(fileURLWithPath: detail.wrappedValue).lastPathComponent)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose App…") { chooseApp(detail: detail) }
                }
                .font(.callout)
            }
            if action.wrappedValue == .runShortcut {
                TextField("Shortcut name", text: detail)
                    .accessibilityLabel("\(label) shortcut name")
            }
        }
    }

    private func chooseApp(detail: Binding<String>) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Choose App"
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            detail.wrappedValue = url.path
        }
    }
}
