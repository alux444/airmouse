import XCTest
@testable import AirMouse

final class CaseTapDetectorTests: XCTestCase {
    private func sample(service: Int, time: Double, x: Double) -> CaseMotionSample {
        let stamp = Int(time * 1_000_000)
        let value = Int(x * 100_000)
        return CaseMotionSample(line: "1,\(service),\(stamp),1,\(value),0,0")!
    }

    func testStillTapFiresOnceAndCanRearm() {
        var detector = CaseTapDetector()
        for step in 0...20 {
            let time = 1 + Double(step) * 0.01
            XCTAssertFalse(detector.record(sample(service: 12, time: time, x: 0)))
            XCTAssertFalse(detector.record(sample(service: 11, time: time, x: 0)))
        }
        XCTAssertTrue(detector.record(sample(service: 11, time: 1.21, x: 0.6)))
        XCTAssertFalse(detector.record(sample(service: 11, time: 1.22, x: 0)))
        for step in 23...80 {
            let time = 1 + Double(step) * 0.01
            _ = detector.record(sample(service: 12, time: time, x: 0))
            _ = detector.record(sample(service: 11, time: time, x: 0))
        }
        XCTAssertTrue(detector.record(sample(service: 11, time: 1.81, x: 0.6)))
    }

    func testMovementBeforeImpactDoesNotClick() {
        var detector = CaseTapDetector()
        for step in 0...20 {
            let time = 1 + Double(step) * 0.01
            _ = detector.record(sample(service: 12, time: time, x: 80))
            _ = detector.record(sample(service: 11, time: time, x: 0))
        }
        XCTAssertFalse(detector.record(sample(service: 11, time: 1.21, x: 0.8)))
    }
}
