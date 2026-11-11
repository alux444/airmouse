import XCTest
@testable import AirMouse

final class GestureMotionTests: XCTestCase {
    func testTurnFiresOnceUntilReturningToNeutral() {
        var gesture = GestureMotion()
        XCTAssertNil(gesture.update(yaw: 0))
        XCTAssertEqual(gesture.update(yaw: 0.3), .left)
        XCTAssertNil(gesture.update(yaw: 0.4))
        XCTAssertNil(gesture.update(yaw: -0.3))
        XCTAssertNil(gesture.update(yaw: 0.02))
        XCTAssertEqual(gesture.update(yaw: -0.3), .right)
    }

    func testResetRequiresNewBaseline() {
        var gesture = GestureMotion()
        _ = gesture.update(yaw: 0)
        _ = gesture.update(yaw: 0.3)
        gesture.reset()
        XCTAssertNil(gesture.update(yaw: 1))
        XCTAssertEqual(gesture.update(yaw: 1.3), .left)
    }

    func testScrollStopsInNeutralAndCanReverse() {
        var scroll = ScrollMotion()
        XCTAssertEqual(scroll.update(pitch: 0, reversed: false), 0)
        XCTAssertEqual(scroll.update(pitch: 0.05, reversed: false), 0)
        let forward = scroll.update(pitch: 0.3, reversed: false)
        XCTAssertNotEqual(forward, 0)
        XCTAssertEqual(scroll.update(pitch: 0.3, reversed: true), -forward)
        XCTAssertEqual(scroll.update(pitch: 0, reversed: false), 0)
    }
}
