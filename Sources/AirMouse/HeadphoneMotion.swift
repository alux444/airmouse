import CoreMotion
import Foundation

struct MotionSample {
    let yaw: Double
    let pitch: Double
    let timestamp: TimeInterval
}

protocol HeadphoneMotion {
    var isAvailable: Bool { get }
    func start(_ handler: @escaping (MotionSample?, Error?) -> Void)
    func stop()
}

final class CoreMotionHeadphones: HeadphoneMotion {
    private let manager = CMHeadphoneMotionManager()

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start(_ handler: @escaping (MotionSample?, Error?) -> Void) {
        manager.startDeviceMotionUpdates(to: .main) { data, error in
            let sample = data.map { MotionSample(yaw: $0.attitude.yaw, pitch: $0.attitude.pitch, timestamp: $0.timestamp) }
            handler(sample, error)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
