import Foundation

enum ControlMode: String, CaseIterable, Identifiable {
    case pointer = "Pointer"
    case scroll = "Scroll"
    case presentation = "Presentation"
    case shortcuts = "Shortcuts"

    var id: String { rawValue }

    var instructions: String {
        switch self {
        case .pointer: return "Move your head to guide the pointer."
        case .scroll: return "Look straight ahead, then tilt to scroll. Return to centre to stop."
        case .presentation: return "Turn right for the next slide or left for the previous slide."
        case .shortcuts: return "Turn left or right to run its assigned action."
        }
    }
}

enum ShortcutAction: String, CaseIterable, Identifiable {
    case none = "None"
    case missionControl = "Mission Control"
    case previousDesktop = "Previous Desktop"
    case nextDesktop = "Next Desktop"
    case openApp = "Open App"
    case runShortcut = "Run Apple Shortcut"

    var id: String { rawValue }
}
