import CoreGraphics
import Foundation

protocol CaseOrientationSource {
    func feed(_ rows: [[Double]]) -> (ready: Bool, point: CGPoint?)?
    func setCenter() -> Bool
    func setAxis(_ axis: String) -> Bool
}

enum CaseCalibration: Equatable {
    case center
    case right
    case top
    case complete
}

final class CasePointer {
    private let orientation: CaseOrientationSource
    private let controls: SystemControls
    private var filtered: CGPoint?
    private var holdUntil: TimeInterval = 0
    private(set) var calibration: CaseCalibration = .center
    private(set) var ready = false
    private(set) var enabled = false

    init(orientation: CaseOrientationSource, controls: SystemControls) {
        self.orientation = orientation
        self.controls = controls
    }

    func capture() -> Bool {
        guard ready else { return false }
        switch calibration {
        case .center:
            guard orientation.setCenter() else { return false }
            calibration = .right
        case .right:
            guard orientation.setAxis("right") else { return false }
            calibration = .top
        case .top:
            guard orientation.setAxis("up") else { return false }
            calibration = .complete
        case .complete:
            return false
        }
        return true
    }

    func start() -> Bool {
        guard ready, calibration == .complete else { return false }
        enabled = true
        filtered = nil
        return true
    }

    func pause() {
        enabled = false
        filtered = nil
    }

    func feed(_ rows: [[Double]], bounds: CGRect, time: TimeInterval) {
        guard let result = orientation.feed(rows), result.ready else {
            ready = false
            calibration = .center
            pause()
            return
        }
        ready = true
        guard enabled, time >= holdUntil, let point = result.point,
              point.x.isFinite, point.y.isFinite, bounds.width > 0, bounds.height > 0 else { return }
        let next = CGPoint(x: min(1, max(0, point.x)), y: min(1, max(0, point.y)))
        let previous = filtered ?? next
        let smooth = CGPoint(x: previous.x + (next.x - previous.x) * 0.25,
                             y: previous.y + (next.y - previous.y) * 0.25)
        filtered = smooth
        controls.movePointer(to: CGPoint(x: bounds.minX + smooth.x * bounds.width,
                                         y: bounds.minY + smooth.y * bounds.height))
    }

    func click(time: TimeInterval) {
        guard enabled, let position = controls.pointerPosition() else { return }
        holdUntil = time + 0.2
        controls.click(at: position)
    }
}
