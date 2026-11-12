import CoreGraphics
import Foundation

struct CasePointerFilter {
    private var previous: CGPoint?
    private var filtered: CGPoint?
    private var timestamp: TimeInterval?
    private var velocity = CGPoint.zero

    mutating func feed(_ point: CGPoint, at time: TimeInterval) -> CGPoint {
        guard let previous, let filtered, let timestamp else {
            self.previous = point
            self.filtered = point
            self.timestamp = time
            return point
        }
        let elapsed = time - timestamp
        guard elapsed > 0 else { return filtered }
        if elapsed > 0.25 {
            self = CasePointerFilter()
            return feed(point, at: time)
        }

        let velocityWeight = weight(cutoff: 1.5, elapsed: elapsed)
        velocity.x += velocityWeight * ((point.x - previous.x) / elapsed - velocity.x)
        velocity.y += velocityWeight * ((point.y - previous.y) / elapsed - velocity.y)
        let speed = max(0, hypot(velocity.x, velocity.y) - 0.03)
        let cutoff = min(20, 0.9 + 10 * speed + 18 * speed * speed)
        let smoothingWeight = weight(cutoff: cutoff, elapsed: elapsed)
        let next = CGPoint(x: filtered.x + smoothingWeight * (point.x - filtered.x),
                           y: filtered.y + smoothingWeight * (point.y - filtered.y))
        self.previous = point
        self.filtered = next
        self.timestamp = time
        return next
    }

    private func weight(cutoff: Double, elapsed: TimeInterval) -> Double {
        elapsed / (elapsed + 1 / (2 * .pi * cutoff))
    }
}
