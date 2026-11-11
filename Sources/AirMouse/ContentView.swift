import SwiftUI

private enum Palette {
    static let ink = Color(red: 0.12, green: 0.18, blue: 0.17)
    static let muted = Color(red: 0.35, green: 0.40, blue: 0.37)
    static let canvas = Color(red: 0.96, green: 0.96, blue: 0.92)
    static let forest = Color(red: 0.12, green: 0.25, blue: 0.21)
    static let lime = Color(red: 0.81, green: 0.92, blue: 0.60)
}

struct ContentView: View {
    @ObservedObject var controller: MouseController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 24)
            trackingCard
                .padding(.bottom, 24)
            controls
            Spacer(minLength: 20)
            footer
        }
        .padding(28)
        .frame(width: 440, height: 590)
        .background(Palette.canvas)
        .foregroundStyle(Palette.ink)
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 9) {
                Image(systemName: "cursorarrow.motionlines")
                    .font(.system(size: 18, weight: .semibold))
                Text("airmouse")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .tracking(-0.7)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(controller.isConnected ? Color(red: 0.36, green: 0.60, blue: 0.38) : Color.gray)
                    .frame(width: 7, height: 7)
                Text(controller.isConnected ? "Motion available" : "Not connected")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Palette.muted)
        }
    }

    private var trackingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(controller.isTracking ? "YOU’RE IN CONTROL" : "A LITTLE MORE HANDS-FREE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Palette.lime)
                    Text(controller.isTracking ? "Moving with you." : "Your head,\nyour cursor.")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .tracking(-0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                motionIllustration
            }
            Spacer(minLength: 18)
            Text(controller.message)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: controller.toggleTracking) {
                HStack {
                    Image(systemName: controller.isTracking ? "pause.fill" : "play.fill")
                    Text(controller.isTracking ? "Pause tracking" : "Start tracking")
                    Spacer()
                    Text("⌃ ⌥ Space").font(.system(size: 11, weight: .medium))
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 15)
                .frame(height: 42)
                .background(Palette.lime, in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 17)
            .accessibilityHint("Press Control Option Space to toggle tracking from anywhere.")
        }
        .padding(21)
        .frame(height: 250)
        .background(Palette.forest, in: RoundedRectangle(cornerRadius: 18))
        .foregroundStyle(.white)
    }

    private var motionIllustration: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.12), lineWidth: 1).frame(width: 98, height: 98)
            Circle().stroke(.white.opacity(0.12), lineWidth: 1).frame(width: 70, height: 70)
            Circle().fill(.white.opacity(0.08)).frame(width: 40, height: 40)
            Image(systemName: "cursorarrow")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Palette.lime)
                .offset(x: controller.motion.x * 16, y: controller.motion.y * 16)
        }
        .frame(width: 98, height: 98)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Pointer sensitivity").font(.system(size: 14, weight: .semibold))
                    Text("Find a movement that feels natural.").font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
                Spacer()
                Text(String(format: "%.1f×", controller.sensitivity))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
            }
            Slider(value: $controller.sensitivity, in: 0.4...2.5, step: 0.1)
                .tint(Palette.forest)
                .accessibilityLabel("Pointer sensitivity")
                .accessibilityValue(String(format: "%.1f times", controller.sensitivity))
            HStack {
                Text("Less")
                Spacer()
                Text("More")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Palette.muted)
        }
    }

    private var footer: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "hand.tap")
            Text("Use your trackpad or mouse to click. Pause anytime with Control–Option–Space.")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 11))
        .foregroundStyle(Palette.muted)
    }
}
