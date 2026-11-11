import AppKit
import CoreGraphics

protocol SystemControls {
    func pointerPosition() -> CGPoint?
    func movePointer(to position: CGPoint)
    func click(at position: CGPoint)
    func scroll(lines: Int32)

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

}
