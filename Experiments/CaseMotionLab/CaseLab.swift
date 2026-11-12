import AppKit
import CoreBluetooth
import CoreAudio
import Foundation

@MainActor
final class CaseLab: NSObject, ObservableObject, @preconcurrency CBCentralManagerDelegate {
    @Published private(set) var active = false
    @Published private(set) var sampleCount = 0
    @Published private(set) var peak = 0.0
    @Published private(set) var detectedTaps = 0
    @Published private(set) var candidates = 0
    @Published private(set) var filterSummary = ""
    @Published private(set) var trainingStatus = "Teach a tap to compare the trained detector."
    @Published private(set) var trainedTaps = 0
    @Published private(set) var details = ""
    @Published private(set) var message = "Put both AirPods in their case, leave it open, and connect them to this Mac."

    private var bluetooth: CBCentralManager?
    private var helper: Process?
    private var pipe: Pipe?
    private var errorPipe: Pipe?
    private var errorTail = Data()
    private var timer: Timer?
    private var directory: URL?
    private var outputBefore: AudioDeviceID?
    private var pending = Data()
    private var meter = CaseMotionMeter()
    private var detector = CaseTapDetector()
    private var learner: ClosedCaseTapLearner?
    private var trainedDetector = ClosedCaseTapDetector()
    private var isTrained = false
    private var tapCount = 0
    private var received = 0
    private var stopping = false
    private var preparing = false
    private var generation = 0

    func toggle() {
        if active { stop("Test stopped."); return }
        generation += 1
        pending.removeAll()
        active = true
        preparing = true
        stopping = false
        received = 0
        sampleCount = 0
        meter.reset()
        detector.reset()
        learner = nil
        trainedDetector = ClosedCaseTapDetector()
        isTrained = false
        trainedTaps = 0
        trainingStatus = "Teach a tap to compare the trained detector."
        tapCount = 0
        detectedTaps = 0
        candidates = 0
        filterSummary = ""
        peak = 0
        details = ""
        errorTail.removeAll()
        message = "Checking Bluetooth permission…"
        bluetooth = CBCentralManager(delegate: self, queue: .main)
    }

    func resetPeak() {
        meter.reset()
        detector.reset()
        tapCount = 0
        detectedTaps = 0
        candidates = 0
        filterSummary = ""
        peak = 0
        trainedTaps = 0
        _ = trainedDetector.reset()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard preparing else { return }
        if CBManager.authorization == .denied || CBManager.authorization == .restricted {
            finish("Allow Bluetooth for AirMouse Case Lab in Privacy & Security.")
            return
        }
        if central.state == .poweredOff { finish("Bluetooth is off. Turn it on, then retry."); return }
        guard CBManager.authorization == .allowedAlways, central.state == .poweredOn else { return }
        preparing = false
        message = "Finding your connected AirPods…"
        let currentGeneration = generation
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Result { try BluetoothTarget.connectedAirPods() }
            DispatchQueue.main.async { self?.connect(result, generation: currentGeneration) }
        }
    }

    func teachTap() {
        guard active, received > 0 else { return }
        learner = ClosedCaseTapLearner()
        trainedDetector = ClosedCaseTapDetector()
        trainedTaps = 0
        isTrained = false
        trainingStatus = "Keep the case still; tap the same spot three to six times."
    }

    private func connect(_ result: Result<BluetoothTarget, Error>, generation: Int) {
        guard active, !stopping, generation == self.generation else { return }
        do {
            let target = try result.get()
            guard let output = currentAudioOutput() else { throw LabError.message("Couldn’t check the Mac’s audio output.") }
            outputBefore = output
            try launch(target: target)
        } catch {
            finish(error.localizedDescription)
        }
    }

    private func launch(target: BluetoothTarget) throws {
        guard let executable = Bundle.main.url(forResource: "CaseMotion", withExtension: "bin") else {
            throw LabError.message("Motion helper is missing.")
        }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("AirMouse-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        directory = folder
        let address = folder.appendingPathComponent("target.txt")
        try Data(target.address.utf8).write(to: address, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: address.path)
        try renewLease()
        let currentGeneration = generation
        let task = Process()
        let output = Pipe()
        let errors = Pipe()
        task.executableURL = executable
        task.arguments = [address.path, "--pointer-session", folder.appendingPathComponent("session").path]
        task.standardOutput = output
        task.standardError = errors
        errors.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { handle.readabilityHandler = nil; return }
            DispatchQueue.main.async {
                guard let self, self.generation == currentGeneration else { return }
                self.captureErrors(data)
            }
        }
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { handle.readabilityHandler = nil; return }
            DispatchQueue.main.async {
                guard let self, self.generation == currentGeneration else { return }
                self.receive(data)
            }
        }
        task.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                guard let self, self.generation == currentGeneration else { return }
                self.ended(code: process.terminationStatus)
            }
        }
        helper = task
        pipe = output
        errorPipe = errors
        try task.run()
        try output.fileHandleForWriting.close()
        try errors.fileHandleForWriting.close()
        message = "Connecting to \(target.name)… Keep the case open."
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard active, !stopping else { return }
        guard let initial = outputBefore, currentAudioOutput() == initial else {
            stop("The system audio output changed, so the test stopped. Check Sound settings.")
            return
        }
        do { try renewLease() } catch { stop("Couldn’t maintain the test session.") }
        sampleCount = received
        peak = meter.peak
        detectedTaps = tapCount
        let stats = detector.diagnostics
        candidates = stats.candidates
        filterSummary = "Unsettled: \(stats.insufficientRest), moving: \(stats.movement), no rotation: \(stats.missingRotation), rotating: \(stats.rotation)"
    }

    private func renewLease() throws {
        guard let directory else { return }
        try Data("\(ProcessInfo.processInfo.systemUptime)\n".utf8).write(to: directory.appendingPathComponent("app-lease.txt"), options: .atomic)
    }

    private func captureErrors(_ data: Data) {
        errorTail.append(data)
        if errorTail.count > 12000 { errorTail.removeFirst(errorTail.count - 12000) }
    }

    private func receive(_ data: Data) {
        guard active, !stopping else { return }
        pending.append(data)
        guard pending.count < 65536 else { stop("Motion data arrived too quickly to process."); return }
        var rows: [[Double]] = []
        while let end = pending.firstIndex(of: 10) {
            let line = String(data: pending.prefix(upTo: end), encoding: .utf8) ?? ""
            pending.removeSubrange(...end)
            guard let sample = CaseMotionSample(line: line) else { continue }
            received += 1
            meter.record(sample)
            if detector.record(sample) { tapCount += 1 }
            rows.append([0, Double(sample.service), sample.sensorTime * 1_000_000, 0,
                         sample.x * 100_000, sample.y * 100_000, sample.z * 100_000])
        }
        if learner != nil {
            let events = learner?.feed(rows) ?? []
            for event in events {
                switch event {
                case .tap(let agreeing, let total): trainingStatus = "Taps recorded: \(total); matching: \(agreeing)."
                case .tooSoft: trainingStatus = "Tap a little more firmly."
                case .finished(let direction):
                    trainedDetector.direction = direction
                    isTrained = true
                    learner = nil
                    trainingStatus = "Tap learned. Try five more taps to test it."
                case .failed:
                    learner = nil
                    trainingStatus = "Taps varied too much. Try teaching the same spot again."
                }
            }
        } else if isTrained {
            let events = trainedDetector.feed(rows)
            trainedTaps += events.filter { if case .tap = $0 { return true }; return false }.count
            trainedDetector.ignored.removeAll()
        }
        if received > 0 { message = "Motion is arriving. Reset the peak, then gently tap an AirPod in the case." }
    }

    func stop(_ reason: String = "Test stopped.") {
        guard active else { return }
        stopping = true
        preparing = false
        message = reason
        timer?.invalidate()
        timer = nil
        if let directory, helper?.isRunning == true {
            try? Data("stop\n".utf8).write(to: directory.appendingPathComponent("session/phase.txt"), options: .atomic)
            helper?.terminate()
            return
        }
        finish(reason)
    }

    private func ended(code: Int32) {
        let reason = stopping ? message : "Motion connection ended (code \(code)). Keep the case open and retry."
        details = String(data: errorTail, encoding: .utf8) ?? ""
        finish(reason)
    }

    private func finish(_ reason: String) {
        generation += 1
        pipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        timer?.invalidate()
        timer = nil
        if let directory { try? FileManager.default.removeItem(at: directory) }
        directory = nil
        helper = nil
        pipe = nil
        errorPipe = nil
        bluetooth = nil
        active = false
        preparing = false
        stopping = false
        message = reason
    }
}
