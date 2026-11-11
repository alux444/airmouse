import CoreGraphics
import Foundation

struct PointerMotion {
    private var previous: (yaw: Double, pitch: Double)?
    private var filtered = CGPoint.zero

    mutating func reset() {
        previous = nil
        filtered = .zero
    }

    mutating func update(yaw: Double, pitch: Double, sensitivity: Double) -> CGPoint {
        defer { previous = (yaw, pitch) }
        guard let previous else { return .zero }

        let horizontal = angleDifference(yaw, previous.yaw)
        let vertical = angleDifference(pitch, previous.pitch)
        let threshold = 0.0008
        let scale = sensitivity * 850
        let target = CGPoint(
            x: abs(horizontal) < threshold ? 0 : -horizontal * scale,
            y: abs(vertical) < threshold ? 0 : -vertical * scale
        )
        filtered.x += (target.x - filtered.x) * 0.55
        filtered.y += (target.y - filtered.y) * 0.55
        return filtered
    }

    private func angleDifference(_ current: Double, _ previous: Double) -> Double {
        atan2(sin(current - previous), cos(current - previous))
    }
}
