import CoreGraphics
import Foundation

protocol CaseOrientationSource {
    func feed(_ rows: [[Double]]) -> (ready: Bool, point: CGPoint?)?
    func setCenter() -> Bool
    func setAxis(_ axis: String) -> Bool
    func reset()
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
    private var filter = CasePointerFilter()
    private var holdUntil: TimeInterval = 0
    private var recentPoints: [(time: TimeInterval, position: CGPoint)] = []
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
        filter = CasePointerFilter()
        recentPoints.removeAll()
        return true
    }

    func resetCalibration() {
        pause()
        calibration = .center
        ready = false
        orientation.reset()
    }

    func pause() {
        enabled = false
        filter = CasePointerFilter()
        recentPoints.removeAll()
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
        let sensorTime = rows.compactMap { row -> TimeInterval? in
            guard row.count == 7, row[2].isFinite else { return nil }
            return row[2] / 1_000_000
        }.max() ?? time
        let smooth = filter.feed(next, at: sensorTime)
        let position = CGPoint(x: bounds.minX + smooth.x * bounds.width,
                               y: bounds.minY + smooth.y * bounds.height)
        recentPoints.append((time: sensorTime, position: position))
        recentPoints.removeAll { sensorTime - $0.time > 0.5 }
        controls.movePointer(to: position)
    }

    func click(time: TimeInterval, since: TimeInterval? = nil) {
        guard enabled else { return }
        let beforeTap = since.flatMap { start in recentPoints.last { $0.time < start }?.position }
        guard let position = beforeTap ?? controls.pointerPosition() else { return }
        holdUntil = time + 0.2
        controls.movePointer(to: position)
        controls.click(at: position)
    }
}
