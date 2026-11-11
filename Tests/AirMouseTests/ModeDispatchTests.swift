import CoreGraphics
import XCTest
@testable import AirMouse

private struct FakeHeadphones: HeadphoneMotion {
    var isAvailable: Bool { true }
    func start(_ handler: @escaping (MotionSample?, Error?) -> Void) {}
    func stop() {}
}

private final class FakeSystemControls: SystemControls {
    var scrolls: [Int32] = []

    func pointerPosition() -> CGPoint? { .zero }
    func movePointer(to position: CGPoint) {}
    func click(at position: CGPoint) {}
    func scroll(lines: Int32) { scrolls.append(lines) }

}

final class ModeDispatchTests: XCTestCase {
    func testScrollModeStopsInNeutral() async {
        await MainActor.run {
            let controls = FakeSystemControls()
            let controller = MouseController(manager: FakeHeadphones(), controls: controls)
            controller.mode = .scroll
            controller.process(yaw: 0, pitch: 0, time: 0)
            controller.process(yaw: 0, pitch: 0.3, time: 1)
            controller.process(yaw: 0, pitch: 0, time: 2)
            XCTAssertEqual(controls.scrolls.count, 1)
        }
    }
}
