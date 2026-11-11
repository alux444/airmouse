import XCTest
@testable import AirMouse

final class DwellClickTests: XCTestCase {
    func testClickRequiresRestAndMovementBeforeRepeating() {
        var dwell = DwellClick()
        let origin = CGPoint(x: 100, y: 100)
        XCTAssertFalse(dwell.update(position: origin, time: 0))
        XCTAssertFalse(dwell.update(position: origin, time: 1))
        XCTAssertTrue(dwell.update(position: origin, time: 1.3))
        XCTAssertFalse(dwell.update(position: origin, time: 5))
        let next = CGPoint(x: 130, y: 100)
        XCTAssertFalse(dwell.update(position: next, time: 6))
        XCTAssertTrue(dwell.update(position: next, time: 7.4))
    }

    func testMovementResetsTimer() {
        var dwell = DwellClick()
        XCTAssertFalse(dwell.update(position: .zero, time: 0))
        XCTAssertFalse(dwell.update(position: CGPoint(x: 20, y: 0), time: 1))
        XCTAssertFalse(dwell.update(position: CGPoint(x: 20, y: 0), time: 1.4))
        XCTAssertTrue(dwell.update(position: CGPoint(x: 20, y: 0), time: 2.4))
    }
}
