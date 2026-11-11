import Foundation

enum ControlMode: String, CaseIterable, Identifiable {
    case pointer = "Pointer"
    case scroll = "Scroll"

    var id: String { rawValue }

    var instructions: String {
        switch self {
        case .pointer: return "Move your head to guide the pointer."
        case .scroll: return "Look straight ahead, then tilt to scroll. Return to centre to stop."
        }
    }
}
