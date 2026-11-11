import XCTest
@testable import AirMouse

final class CaseMotionSampleTests: XCTestCase {
    func testParseAcceptsOnlyValidMotionRows() throws {
        let sample = try XCTUnwrap(CaseMotionSample(line: "1,11,1000000,42,10000,-20000,100000"))
        XCTAssertEqual(sample.service, 11)
        XCTAssertEqual(sample.sensorTime, 1, accuracy: 0.0001)
        XCTAssertEqual(sample.y, -0.2, accuracy: 0.0001)
        XCTAssertNil(CaseMotionSample(line: "1,99,1000000,42,0,0,0"))
        XCTAssertNil(CaseMotionSample(line: "1,11,nan,42,0,0,0"))
        XCTAssertNil(CaseMotionSample(line: "not a sample"))
    }

    func testMeterMeasuresSpikesWithoutCountingGravityOrStaleSamples() throws {
        var meter = CaseMotionMeter()
        meter.record(try XCTUnwrap(CaseMotionSample(line: "1,11,1000000,1,0,0,100000")))
        meter.record(try XCTUnwrap(CaseMotionSample(line: "2,11,1020000,1,30000,0,100000")))
        XCTAssertEqual(meter.peak, 0.3, accuracy: 0.0001)
        meter.record(try XCTUnwrap(CaseMotionSample(line: "3,11,2000000,2,100000,0,0")))
        XCTAssertEqual(meter.peak, 0.3, accuracy: 0.0001)
        meter.reset()
        XCTAssertEqual(meter.peak, 0)
    }
}
