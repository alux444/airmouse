import AppKit
import Carbon
import CoreGraphics

protocol SystemControls {
    func pointerPosition() -> CGPoint?
    func movePointer(to position: CGPoint)
    func click(at position: CGPoint)
    func scroll(lines: Int32)
    func key(_ code: CGKeyCode, flags: CGEventFlags)
    func openApp(at path: String, completion: @escaping (String?) -> Void)
    func runShortcut(named name: String, completion: @escaping (String?) -> Void)
}

struct MacSystemControls: SystemControls {
    func pointerPosition() -> CGPoint? {
        CGEvent(source: nil)?.location
    }

    func movePointer(to position: CGPoint) {
        CGWarpMouseCursorPosition(position)
    }

    func click(at position: CGPoint) {
        guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left),
              let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position, mouseButton: .left) else { return }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    func scroll(lines: Int32) {
        CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: lines, wheel2: 0, wheel3: 0)?
            .post(tap: .cghidEventTap)
    }

    func key(_ code: CGKeyCode, flags: CGEventFlags = []) {
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) else { return }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    func openApp(at path: String, completion: @escaping (String?) -> Void) {
        guard !path.isEmpty else {
            completion("Choose an app for this gesture first.")
            return
        }
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: .init()) { _, error in
            completion(error.map { "Couldn’t open app: \($0.localizedDescription)" })
        }
    }

    func runShortcut(named name: String, completion: @escaping (String?) -> Void) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            completion("Enter an Apple Shortcut name for this gesture first.")
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", trimmedName]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { result in
            completion(result.terminationStatus == 0 ? nil : "Couldn’t run ‘\(trimmedName)’. Check its name in Shortcuts.")
        }
        do {
            try process.run()
        } catch {
            completion("Couldn’t start Shortcuts: \(error.localizedDescription)")
        }
    }
}
