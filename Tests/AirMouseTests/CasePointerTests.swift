import CoreGraphics
import XCTest
@testable import AirMouse

private final class FakeOrientation: CaseOrientationSource {
    var ready = true
    var point: CGPoint? = CGPoint(x: 1, y: 0)
    var axes: [String] = []
    func feed(_ rows: [[Double]]) -> (ready: Bool, point: CGPoint?)? { (ready, point) }
    func setCenter() -> Bool { true }
    func setAxis(_ axis: String) -> Bool { axes.append(axis); return true }
}

private final class FakePointerControls: SystemControls {
    var moves: [CGPoint] = []
    var clicks: [CGPoint] = []
    func pointerPosition() -> CGPoint? { moves.last }
    func movePointer(to position: CGPoint) { moves.append(position) }
    func click(at position: CGPoint) { clicks.append(position) }
    func scroll(lines: Int32) {}
}

final class CasePointerTests: XCTestCase {
    func testRequiresCalibrationBeforeMovingAndStopsWhenPaused() {
        let orientation = FakeOrientation()
        let controls = FakePointerControls()
        let pointer = CasePointer(orientation: orientation, controls: controls)
        let bounds = CGRect(x: 10, y: 20, width: 100, height: 80)
        pointer.feed([], bounds: bounds, time: 0)
        XCTAssertFalse(pointer.start())
        XCTAssertTrue(pointer.capture())
        XCTAssertTrue(pointer.capture())
        XCTAssertTrue(pointer.capture())
        XCTAssertEqual(orientation.axes, ["right", "up"])
        XCTAssertTrue(pointer.start())
        pointer.feed([], bounds: bounds, time: 1)
        XCTAssertEqual(controls.moves, [CGPoint(x: 110, y: 20)])
        pointer.pause()
        pointer.feed([], bounds: bounds, time: 2)
        XCTAssertEqual(controls.moves.count, 1)
        pointer.click(time: 2)
        XCTAssertTrue(controls.clicks.isEmpty)
    }

    func testLostOrientationPausesAndRequiresCalibrationAgain() {
        let orientation = FakeOrientation()
        let controls = FakePointerControls()
        let pointer = CasePointer(orientation: orientation, controls: controls)
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        pointer.feed([], bounds: bounds, time: 0)
        _ = pointer.capture(); _ = pointer.capture(); _ = pointer.capture(); _ = pointer.start()
        orientation.ready = false
        pointer.feed([], bounds: bounds, time: 1)
        XCTAssertFalse(pointer.enabled)
        XCTAssertEqual(pointer.calibration, .center)
        orientation.ready = true
        pointer.feed([], bounds: bounds, time: 2)
        XCTAssertFalse(pointer.start())
    }

    func testSteadiesSmallJitterWhileFollowingDeliberateMovement() {
        let orientation = FakeOrientation()
        orientation.point = CGPoint(x: 0.5, y: 0.5)
        let controls = FakePointerControls()
        let pointer = CasePointer(orientation: orientation, controls: controls)
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        pointer.feed([], bounds: bounds, time: 0)
        _ = pointer.capture(); _ = pointer.capture(); _ = pointer.capture(); _ = pointer.start()
        pointer.feed([], bounds: bounds, time: 1)
        for step in 1...60 {
            orientation.point = CGPoint(x: step.isMultiple(of: 2) ? 0.49 : 0.51, y: 0.5)
            pointer.feed([], bounds: bounds, time: 1 + Double(step) * 0.01)
        }
        let recent = controls.moves.suffix(30).map(\.x)
        XCTAssertLessThan((recent.max() ?? 0) - (recent.min() ?? 0), 1.5)
        orientation.point = CGPoint(x: 0.9, y: 0.5)
        for step in 61...80 {
            pointer.feed([], bounds: bounds, time: 1 + Double(step) * 0.01)
        }
        XCTAssertGreaterThan(controls.moves.last?.x ?? 0, 850)
    }

    func testClickUsesPointerPositionBeforeTapMotion() {
        let orientation = FakeOrientation()
        orientation.point = CGPoint(x: 0.4, y: 0.5)
        let controls = FakePointerControls()
        let pointer = CasePointer(orientation: orientation, controls: controls)
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        pointer.feed([], bounds: bounds, time: 0)
        _ = pointer.capture(); _ = pointer.capture(); _ = pointer.capture(); _ = pointer.start()
        pointer.feed([], bounds: bounds, time: 1)
        orientation.point = CGPoint(x: 0.8, y: 0.5)
        pointer.feed([], bounds: bounds, time: 1.3)
        pointer.click(time: 1.3, since: 1.1)
        XCTAssertEqual(controls.clicks, [CGPoint(x: 40, y: 50)])
    }

    func testClickFreezesPointerBriefly() {
        let controls = FakePointerControls()
        let pointer = CasePointer(orientation: FakeOrientation(), controls: controls)
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        pointer.feed([], bounds: bounds, time: 0)
        _ = pointer.capture(); _ = pointer.capture(); _ = pointer.capture(); _ = pointer.start()
        pointer.feed([], bounds: bounds, time: 1)
        pointer.click(time: 1)
        pointer.feed([], bounds: bounds, time: 1.1)
        XCTAssertEqual(controls.clicks.count, 1)
        XCTAssertEqual(controls.moves.count, 2)
        pointer.feed([], bounds: bounds, time: 1.3)
        XCTAssertEqual(controls.moves.count, 3)
    }
}
