import Foundation

enum CaseTapAction: Equatable {
    case verify
    case calibrate
    case click
    case ignore
}

struct CaseTapContext {
    let tapConfirmed: Bool
    let calibrated: Bool
    let motionReady: Bool
    let pointing: Bool
    let clickEnabled: Bool
}

func caseTapAction(for context: CaseTapContext) -> CaseTapAction {
    guard context.tapConfirmed else { return .verify }
    guard context.calibrated else { return context.motionReady ? .calibrate : .ignore }
    return context.pointing && context.clickEnabled ? .click : .ignore
}
