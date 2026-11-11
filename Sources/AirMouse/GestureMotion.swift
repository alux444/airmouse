import Foundation

enum TurnDirection: Equatable {
    case left
    case right

    var opposite: TurnDirection { self == .left ? .right : .left }
}

struct GestureMotion {
    private let activationAngle = 0.22
    private let releaseAngle = 0.08
    private var baseline: Double?
    private var isArmed = true

    mutating func reset() {
        baseline = nil
        isArmed = true
    }

    mutating func update(yaw: Double) -> TurnDirection? {
        guard let baseline else {
            self.baseline = yaw
            return nil
        }
        let angle = atan2(sin(yaw - baseline), cos(yaw - baseline))
        if abs(angle) <= releaseAngle {
            isArmed = true
            return nil
        }
        guard isArmed, abs(angle) >= activationAngle else { return nil }
        isArmed = false
        return angle > 0 ? .left : .right
    }
}

struct ScrollMotion {
    private let neutralAngle = 0.08
    private let maximumAngle = 0.40
    private var baseline: Double?

    mutating func reset() {
        baseline = nil
    }

    mutating func update(pitch: Double, reversed: Bool) -> Int32 {
        guard let baseline else {
            self.baseline = pitch
            return 0
        }
        let angle = atan2(sin(pitch - baseline), cos(pitch - baseline))
        guard abs(angle) > neutralAngle else { return 0 }
        let magnitude = min((abs(angle) - neutralAngle) / (maximumAngle - neutralAngle), 1)
        let direction: Double = angle > 0 ? -1 : 1
        let sign: Double = reversed ? -1 : 1
        return Int32((direction * sign * (1 + magnitude * 3)).rounded())
    }
}
