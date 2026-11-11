import AppKit
import ApplicationServices
import SwiftUI

@MainActor
final class MouseController: ObservableObject {
    @Published private(set) var isTracking = false
    @Published private(set) var isConnected = false
    @Published private(set) var message = "Put in your AirPods and connect them to this Mac."
    @Published var mode: ControlMode = .pointer { didSet { if mode != oldValue { pause() } } }
    @Published var sensitivity = 1.0
    @Published var dwellEnabled = false { didSet { if dwellEnabled != oldValue { pause() } } }
    @Published var reverseScroll = false


    private let manager: HeadphoneMotion
    private let controls: SystemControls
    private var pointerMotion = PointerMotion()
    private var dwellClick = DwellClick()
    private var scrollMotion = ScrollMotion()
    private var connectionTimer: Timer?
    private var startedAt: TimeInterval?
    private var firstSampleAt: TimeInterval?
    private var lastSampleAt: TimeInterval?
    private var lastScrollAt: TimeInterval = 0
    private var session = 0

    init(manager: HeadphoneMotion = CoreMotionHeadphones(),
         controls: SystemControls = MacSystemControls()) {
        self.manager = manager
        self.controls = controls
        refreshConnection()
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkConnection() }
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
        manager.stop()
        isTracking = false
        session += 1
        resetMotion()
        message = isConnected ? "Ready when you are." : "Put in your AirPods and connect them to this Mac."
    }

    func recenter() {
        startedAt = ProcessInfo.processInfo.systemUptime
        resetMotion()
        message = "Look straight ahead to set the centre."
    }

    private func resetMotion() {
        pointerMotion.reset()
        dwellClick.reset()
        scrollMotion.reset()
        firstSampleAt = nil
        lastSampleAt = nil
        lastScrollAt = 0
    }

    private func refreshConnection() {
        let available = manager.isAvailable
        guard available != isConnected else { return }
        isConnected = available
        if !available && isTracking {
            pause()
            return
        }
        message = available ? "Ready when you are." : "Put in your AirPods and connect them to this Mac."
    }

    private func checkConnection() {
        refreshConnection()
        guard isTracking, let referenceTime = lastSampleAt ?? startedAt,
              ProcessInfo.processInfo.systemUptime - referenceTime > 6 else { return }
        pause()
        message = "No motion received. Check AirPods and Motion & Fitness permission, then try again."
    }

    private func start() {
        refreshConnection()
        guard isConnected else {
            message = "No headphone motion detected. Wear your AirPods and connect them to this Mac."
            return
        }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            message = "Allow this copy in Accessibility. If it’s already on, remove and add it again."
            return
        }
        resetMotion()
        startedAt = ProcessInfo.processInfo.systemUptime
        isTracking = true
        message = "Waiting for AirPods motion…"
        let currentSession = session
        manager.start { [weak self] data, error in
            Task { @MainActor in
                guard let self, self.session == currentSession else { return }
                self.receive(data, error: error)
            }
        }
    }

    private func receive(_ data: MotionSample?, error: Error?) {
        guard isTracking else { return }
        guard error == nil, let data else {
            pause()
            message = "Motion tracking stopped. Check your AirPods connection and try again."
            return
        }
        lastSampleAt = ProcessInfo.processInfo.systemUptime
        if firstSampleAt == nil {
            firstSampleAt = data.timestamp
            message = mode.instructions
        }
        process(yaw: data.yaw, pitch: data.pitch, time: data.timestamp)
    }

    func process(yaw: Double, pitch: Double, time: TimeInterval) {
        switch mode {
        case .pointer: movePointer(yaw: yaw, pitch: pitch, time: time)
        case .scroll: scroll(pitch: pitch, time: time)

        }
    }

    private func movePointer(yaw: Double, pitch: Double, time: TimeInterval) {
        let delta = pointerMotion.update(yaw: yaw, pitch: pitch, sensitivity: sensitivity)
        guard let position = controls.pointerPosition() else { return }
        let destination = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
        controls.movePointer(to: destination)
        guard dwellEnabled, !NSApp.isActive, let firstSampleAt, time - firstSampleAt >= 2 else {
            dwellClick.reset()
            return
        }
        if dwellClick.update(position: destination, time: time) { controls.click(at: destination) }
    }

    private func scroll(pitch: Double, time: TimeInterval) {
        let lines = scrollMotion.update(pitch: pitch, reversed: reverseScroll)
        guard lines != 0, time - lastScrollAt >= 0.08 else { return }
        lastScrollAt = time
        controls.scroll(lines: lines)
    }

}
