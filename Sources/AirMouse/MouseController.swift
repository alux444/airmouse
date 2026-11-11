import AppKit
import ApplicationServices
import CoreMotion
import SwiftUI

@MainActor
final class MouseController: ObservableObject {
    @Published private(set) var isTracking = false
    @Published private(set) var isConnected = false
    @Published private(set) var message = "Put in your AirPods and connect them to this Mac."
    @Published private(set) var motion = CGPoint.zero
    @Published var sensitivity = 1.0

    private let manager = CMHeadphoneMotionManager()
    private var pointerMotion = PointerMotion()
    private var connectionTimer: Timer?

    init() {
        refreshConnection()
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshConnection() }
        }
    }

    func toggleTracking() {
        if isTracking {
            pause()
            return
        }
        start()
    }

    func pause() {
        manager.stopDeviceMotionUpdates()
        pointerMotion.reset()
        motion = .zero
        isTracking = false
        message = isConnected ? "Ready when you are." : "Put in your AirPods and connect them to this Mac."
    }

    private func refreshConnection() {
        let available = manager.isDeviceMotionAvailable
        guard available != isConnected else { return }
        isConnected = available
        if !available && isTracking {
            pause()
            return
        }
        message = available ? "Ready when you are." : "Put in your AirPods and connect them to this Mac."
    }

    private func start() {
        refreshConnection()
        guard isConnected else {
            message = "No headphone motion detected. Wear your AirPods and connect them to this Mac."
            return
        }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            message = "Allow AirMouse in System Settings → Privacy & Security → Accessibility, then try again."
            return
        }
        pointerMotion.reset()
        isTracking = true
        message = "Move your head gently to guide the pointer."
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            Task { @MainActor in self?.receive(data, error: error) }
        }
    }

    private func receive(_ data: CMDeviceMotion?, error: Error?) {
        guard isTracking else { return }
        guard error == nil, let data else {
            pause()
            message = "Motion tracking stopped. Check your AirPods connection and try again."
            return
        }
        let delta = pointerMotion.update(
            yaw: data.attitude.yaw,
            pitch: data.attitude.pitch,
            sensitivity: sensitivity
        )
        motion = CGPoint(x: max(-1, min(1, delta.x / 8)), y: max(-1, min(1, delta.y / 8)))
        guard let position = CGEvent(source: nil)?.location else { return }
        let destination = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
        CGWarpMouseCursorPosition(destination)
    }
}
