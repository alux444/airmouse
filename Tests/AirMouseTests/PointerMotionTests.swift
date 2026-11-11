import XCTest
@testable import AirMouse

final class PointerMotionTests: XCTestCase {
    func testFirstSampleAndResetDoNotMoveCursor() {
        var motion = PointerMotion()
        XCTAssertEqual(motion.update(yaw: 1, pitch: 1, sensitivity: 1), .zero)
        _ = motion.update(yaw: 1.1, pitch: 1, sensitivity: 1)
        motion.reset()
        XCTAssertEqual(motion.update(yaw: -2, pitch: -2, sensitivity: 1), .zero)
    }

    func testAngleWrapUsesShortPath() {
        var motion = PointerMotion()
        _ = motion.update(yaw: .pi - 0.01, pitch: 0, sensitivity: 1)
        let delta = motion.update(yaw: -.pi + 0.01, pitch: 0, sensitivity: 1)
        XCTAssertLessThan(abs(delta.x), 20)
        XCTAssertGreaterThan(abs(delta.x), 0)
    }

    func testSensitivityScalesMovement() {
        var slow = PointerMotion()
        var fast = PointerMotion()
        _ = slow.update(yaw: 0, pitch: 0, sensitivity: 1)
        _ = fast.update(yaw: 0, pitch: 0, sensitivity: 2)
        let slowDelta = slow.update(yaw: 0.1, pitch: 0, sensitivity: 1)
        let fastDelta = fast.update(yaw: 0.1, pitch: 0, sensitivity: 2)
        XCTAssertEqual(fastDelta.x, slowDelta.x * 2, accuracy: 0.001)
    }
}
