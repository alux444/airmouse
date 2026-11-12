import XCTest
@testable import AirMouse

final class CaseTapRoutingTests: XCTestCase {
    func testTapVerificationNeverClicks() {
        let context = CaseTapContext(tapConfirmed: false, calibrated: true, motionReady: true,
                                     pointing: true, clickEnabled: true)
        XCTAssertEqual(caseTapAction(for: context), .verify)
    }

    func testCalibrationTapOnlyCapturesWhenMotionIsReady() {
        let settling = CaseTapContext(tapConfirmed: true, calibrated: false, motionReady: false,
                                      pointing: false, clickEnabled: true)
        let ready = CaseTapContext(tapConfirmed: true, calibrated: false, motionReady: true,
                                   pointing: false, clickEnabled: true)
        XCTAssertEqual(caseTapAction(for: settling), .ignore)
        XCTAssertEqual(caseTapAction(for: ready), .calibrate)
    }

    func testClicksRequireCalibratedActivePointerAndExplicitEnablement() {
        let paused = CaseTapContext(tapConfirmed: true, calibrated: true, motionReady: true,
                                    pointing: false, clickEnabled: true)
        let disabled = CaseTapContext(tapConfirmed: true, calibrated: true, motionReady: true,
                                      pointing: true, clickEnabled: false)
        let active = CaseTapContext(tapConfirmed: true, calibrated: true, motionReady: true,
                                    pointing: true, clickEnabled: true)
        XCTAssertEqual(caseTapAction(for: paused), .ignore)
        XCTAssertEqual(caseTapAction(for: disabled), .ignore)
        XCTAssertEqual(caseTapAction(for: active), .click)
    }
}
