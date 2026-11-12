import Foundation

enum CaseTapRejection {
    case insufficientRest
    case movement
    case missingRotation
    case rotation
}

struct CaseTapDiagnostics {
    var candidates = 0
    var insufficientRest = 0
    var movement = 0
    var missingRotation = 0
    var rotation = 0
}

struct CaseTapDetector {
    private let minimumSpike = 0.35
    private let restingTolerance = 0.09
    private let maximumRotation = 45.0
    private let refractory: TimeInterval = 0.45
    private var accelerations: [CaseMotionSample] = []
    private var rotations: [CaseMotionSample] = []
    private var lastTap = -Double.infinity
    private var lastCandidate = -Double.infinity
    private(set) var diagnostics = CaseTapDiagnostics()

    mutating func reset() {
        accelerations.removeAll()
        rotations.removeAll()
        lastTap = -.infinity
        lastCandidate = -.infinity
        diagnostics = CaseTapDiagnostics()
    }

    mutating func record(_ sample: CaseMotionSample) -> Bool {
        if sample.service == 12 {
            rotations.append(sample)
            rotations.removeAll { sample.sensorTime - $0.sensorTime > 0.3 }
            return false
        }
        guard sample.service == 11 else { return false }
        defer {
            accelerations.append(sample)
            accelerations.removeAll { sample.sensorTime - $0.sensorTime > 0.35 }
        }
        guard sample.sensorTime - lastTap >= refractory,
              let recent = accelerations.last(where: { sample.sensorTime - $0.sensorTime >= 0.015 }),
              sample.sensorTime - recent.sensorTime <= 0.1,
              distance(sample, recent) >= minimumSpike else { return false }
        let rejection = rejectionReason(for: sample)
        if sample.sensorTime - lastCandidate >= refractory {
            lastCandidate = sample.sensorTime
            diagnostics.candidates += 1
            count(rejection)
        }
        guard rejection == nil else { return false }
        lastTap = sample.sensorTime
        return true
    }

    private func rejectionReason(for sample: CaseMotionSample) -> CaseTapRejection? {
        let restEnd = sample.sensorTime - 0.035
        let rest = accelerations.filter { restEnd - $0.sensorTime >= 0 && restEnd - $0.sensorTime <= 0.16 }
        let rotation = rotations.filter { restEnd - $0.sensorTime >= 0 && restEnd - $0.sensorTime <= 0.16 }
        guard let first = rest.first, let last = rest.last,
              last.sensorTime - first.sensorTime >= 0.10 else { return .insufficientRest }
        guard rest.allSatisfy({ distance($0, first) <= restingTolerance }) else { return .movement }
        guard !rotation.isEmpty else { return .missingRotation }
        guard rotation.allSatisfy({ magnitude($0) <= maximumRotation }) else { return .rotation }
        return nil
    }

    private mutating func count(_ rejection: CaseTapRejection?) {
        switch rejection {
        case .insufficientRest: diagnostics.insufficientRest += 1
        case .movement: diagnostics.movement += 1
        case .missingRotation: diagnostics.missingRotation += 1
        case .rotation: diagnostics.rotation += 1
        case nil: break
        }
    }

    private func distance(_ first: CaseMotionSample, _ second: CaseMotionSample) -> Double {
        let x = first.x - second.x
        let y = first.y - second.y
        let z = first.z - second.z
        return sqrt(x * x + y * y + z * z)
    }

    private func magnitude(_ sample: CaseMotionSample) -> Double {
        sqrt(sample.x * sample.x + sample.y * sample.y + sample.z * sample.z)
    }
}
