import CoreGraphics
import Foundation

struct DwellClick {
    private let duration: TimeInterval = 1.3
    private let movementTolerance: CGFloat = 12
    private let rearmDistance: CGFloat = 28
    private var anchor: CGPoint?
    private var startedAt: TimeInterval?
    private var lastClick: CGPoint?

    mutating func reset() {
        anchor = nil
        startedAt = nil
        lastClick = nil
    }

    mutating func update(position: CGPoint, time: TimeInterval) -> Bool {
        if let lastClick {
            guard distance(position, lastClick) >= rearmDistance else { return false }
            self.lastClick = nil
            anchor = nil
        }
        guard let anchor, let startedAt else {
            self.anchor = position
            self.startedAt = time
            return false
        }
        if distance(position, anchor) > movementTolerance {
            self.anchor = position
            self.startedAt = time
            return false
        }
        guard time - startedAt >= duration else { return false }
        lastClick = position
        self.anchor = nil
        self.startedAt = nil
        return true
    }

    private func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }
}
