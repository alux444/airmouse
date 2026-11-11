import Carbon
import CoreGraphics
import XCTest
@testable import AirMouse

private struct FakeHeadphones: HeadphoneMotion {
    var isAvailable: Bool { true }
    func start(_ handler: @escaping (MotionSample?, Error?) -> Void) {}
    func stop() {}
}

private final class FakeSystemControls: SystemControls {
    var keys: [(CGKeyCode, CGEventFlags)] = []
    var scrolls: [Int32] = []
    var openedApps: [String] = []
    var shortcuts: [String] = []

    func pointerPosition() -> CGPoint? { .zero }
    func movePointer(to position: CGPoint) {}
    func click(at position: CGPoint) {}
    func scroll(lines: Int32) { scrolls.append(lines) }
    func key(_ code: CGKeyCode, flags: CGEventFlags) { keys.append((code, flags)) }
    func openApp(at path: String, completion: @escaping (String?) -> Void) { openedApps.append(path) }
    func runShortcut(named name: String, completion: @escaping (String?) -> Void) { shortcuts.append(name) }
}

final class ModeDispatchTests: XCTestCase {
    func testPresentationTurnsSendOneArrowUntilRecentered() async {
        await MainActor.run {
            let controls = FakeSystemControls()
            let controller = MouseController(manager: FakeHeadphones(), controls: controls, preferences: UserDefaults(suiteName: UUID().uuidString)!)
            controller.mode = .presentation
            controller.process(yaw: 0, pitch: 0, time: 0)
            controller.process(yaw: -0.3, pitch: 0, time: 1)
            controller.process(yaw: -0.4, pitch: 0, time: 2)
            XCTAssertEqual(controls.keys.map { $0.0 }, [CGKeyCode(kVK_RightArrow)])
            controller.process(yaw: 0, pitch: 0, time: 3)
            controller.process(yaw: 0.3, pitch: 0, time: 4)
            XCTAssertEqual(controls.keys.map { $0.0 }, [CGKeyCode(kVK_RightArrow), CGKeyCode(kVK_LeftArrow)])
            controller.reverseTurns = true
            controller.process(yaw: 0, pitch: 0, time: 5)
            controller.process(yaw: -0.3, pitch: 0, time: 6)
            XCTAssertEqual(controls.keys.last?.0, CGKeyCode(kVK_LeftArrow))
        }
    }

    func testShortcutTurnsDispatchAssignedActions() async {
        await MainActor.run {
            let controls = FakeSystemControls()
            let controller = MouseController(manager: FakeHeadphones(), controls: controls, preferences: UserDefaults(suiteName: UUID().uuidString)!)
            controller.mode = .shortcuts
            controller.leftAction = .runShortcut
            controller.leftDetail = "Focus"
            controller.rightAction = .nextDesktop
            controller.process(yaw: 0, pitch: 0, time: 0)
            controller.process(yaw: 0.3, pitch: 0, time: 1)
            controller.process(yaw: 0, pitch: 0, time: 2)
            controller.process(yaw: -0.3, pitch: 0, time: 3)
            XCTAssertEqual(controls.shortcuts, ["Focus"])
            XCTAssertEqual(controls.keys.first?.0, CGKeyCode(kVK_RightArrow))
            XCTAssertEqual(controls.keys.first?.1, .maskControl)
        }
    }

    func testScrollModeStopsInNeutral() async {
        await MainActor.run {
            let controls = FakeSystemControls()
            let controller = MouseController(manager: FakeHeadphones(), controls: controls, preferences: UserDefaults(suiteName: UUID().uuidString)!)
            controller.mode = .scroll
            controller.process(yaw: 0, pitch: 0, time: 0)
            controller.process(yaw: 0, pitch: 0.3, time: 1)
            controller.process(yaw: 0, pitch: 0, time: 2)
            XCTAssertEqual(controls.scrolls.count, 1)
            XCTAssertTrue(controls.keys.isEmpty)
        }
    }
}
