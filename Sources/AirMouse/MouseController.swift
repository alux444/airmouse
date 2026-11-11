import AppKit
import ApplicationServices
import Carbon
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
    @Published var reverseTurns = false { didSet { if reverseTurns != oldValue { pause() } } }
    @Published var leftAction: ShortcutAction = .none {
        didSet { if leftAction != oldValue { leftDetail = ""; updateSetting("leftAction", leftAction.rawValue) } }
    }
    @Published var rightAction: ShortcutAction = .none {
        didSet { if rightAction != oldValue { rightDetail = ""; updateSetting("rightAction", rightAction.rawValue) } }
    }
    @Published var leftDetail = "" { didSet { updateSetting("leftDetail", leftDetail) } }
    @Published var rightDetail = "" { didSet { updateSetting("rightDetail", rightDetail) } }

    private let manager: HeadphoneMotion
    private let controls: SystemControls
    private let preferences: UserDefaults
    private var pointerMotion = PointerMotion()
    private var dwellClick = DwellClick()
    private var gestureMotion = GestureMotion()
    private var scrollMotion = ScrollMotion()
    private var connectionTimer: Timer?
    private var startedAt: TimeInterval?
    private var firstSampleAt: TimeInterval?
    private var lastSampleAt: TimeInterval?
    private var lastScrollAt: TimeInterval = 0
    private var session = 0

    init(manager: HeadphoneMotion = CoreMotionHeadphones(),
         controls: SystemControls = MacSystemControls(), preferences: UserDefaults = .standard) {
        self.manager = manager
        self.controls = controls
        self.preferences = preferences
        leftAction = ShortcutAction(rawValue: preferences.string(forKey: "leftAction") ?? "") ?? .none
        rightAction = ShortcutAction(rawValue: preferences.string(forKey: "rightAction") ?? "") ?? .none
        leftDetail = preferences.string(forKey: "leftDetail") ?? ""
        rightDetail = preferences.string(forKey: "rightDetail") ?? ""
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
        gestureMotion.reset()
        scrollMotion.reset()
        firstSampleAt = nil
        lastSampleAt = nil
        lastScrollAt = 0
    }

    private func updateSetting(_ key: String, _ value: String) {
        preferences.set(value, forKey: key)
        if isTracking { pause() }
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
        guard mode != .shortcuts || leftAction != .none || rightAction != .none else {
            message = "Assign an action to at least one turn before starting."
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
        case .presentation, .shortcuts:
            guard let direction = gestureMotion.update(yaw: yaw) else { return }
            let effectiveDirection = reverseTurns ? direction.opposite : direction
            performTurn(effectiveDirection)
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

    private func performTurn(_ direction: TurnDirection) {
        if mode == .presentation {
            controls.key(CGKeyCode(direction == .right ? kVK_RightArrow : kVK_LeftArrow), flags: [])
            return
        }
        let action = direction == .left ? leftAction : rightAction
        let detail = direction == .left ? leftDetail : rightDetail
        performAction(action, detail: detail)
    }

    private func performAction(_ action: ShortcutAction, detail: String) {
        let currentSession = session
        let completion: (String?) -> Void = { [weak self] error in
            guard let error else { return }
            Task { @MainActor in
                guard let self, self.session == currentSession else { return }
                self.message = error
            }
        }
        switch action {
        case .none: break
        case .missionControl: controls.key(CGKeyCode(kVK_UpArrow), flags: .maskControl)
        case .previousDesktop: controls.key(CGKeyCode(kVK_LeftArrow), flags: .maskControl)
        case .nextDesktop: controls.key(CGKeyCode(kVK_RightArrow), flags: .maskControl)
        case .openApp: controls.openApp(at: detail, completion: completion)
        case .runShortcut: controls.runShortcut(named: detail, completion: completion)
        }
    }
}
