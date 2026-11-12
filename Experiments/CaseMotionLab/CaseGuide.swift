import SwiftUI

enum CaseGuidePose {
    case connect
    case rest
    case tap
    case centre
    case right
    case top
}

struct CaseGuide: View {
    let pose: CaseGuidePose
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let phase = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            ZStack {
                if pose == .rest {
                    Capsule().fill(.primary.opacity(0.18))
                        .frame(width: 150, height: 2).offset(y: 55)
                }
                Image(systemName: "airpods.gen3.chargingcase.wireless")
                    .font(.system(size: 72, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .rotationEffect(.degrees(rotation(for: phase)))
                    .offset(y: verticalOffset(for: phase))
                if pose == .tap {
                    Circle().stroke(.tint.opacity(ringOpacity(for: phase)), lineWidth: 2)
                        .frame(width: ringSize(for: phase), height: ringSize(for: phase))
                        .offset(y: 11)
                }
                if pose == .right || pose == .top {
                    Image(systemName: pose == .right ? "arrow.right" : "arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .offset(x: pose == .right ? 78 : 0, y: pose == .top ? -62 : 0)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
        }
        .accessibilityHidden(true)
    }

    private func rotation(for phase: TimeInterval) -> Double {
        guard !reduceMotion else { return 0 }
        switch pose {
        case .right: return 12 * (0.5 + 0.5 * sin(phase * 1.8))
        case .top: return -9 * (0.5 + 0.5 * sin(phase * 1.8))
        default: return 0
        }
    }

    private func verticalOffset(for phase: TimeInterval) -> CGFloat {
        guard pose == .rest, !reduceMotion else { return 0 }
        return -4 * (0.5 + 0.5 * cos(phase * 1.6))
    }

    private func ringSize(for phase: TimeInterval) -> CGFloat {
        guard !reduceMotion else { return 28 }
        return 20 + 18 * ((phase * 0.7).truncatingRemainder(dividingBy: 1))
    }

    private func ringOpacity(for phase: TimeInterval) -> Double {
        guard !reduceMotion else { return 0.55 }
        return 0.8 * (1 - (phase * 0.7).truncatingRemainder(dividingBy: 1))
    }
}
