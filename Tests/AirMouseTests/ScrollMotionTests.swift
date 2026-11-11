import XCTest
@testable import AirMouse

final class ScrollMotionTests: XCTestCase {
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
