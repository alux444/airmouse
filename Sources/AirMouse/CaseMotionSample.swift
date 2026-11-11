import Foundation

struct CaseMotionSample: Equatable {
    let service: Int
    let sensorTime: TimeInterval
    let x: Double
    let y: Double
    let z: Double

    init?(line: String) {
        let fields = line.split(separator: ",", omittingEmptySubsequences: false)
        guard fields.count == 7, let service = Int(fields[1]), [11, 12].contains(service),
              let timestamp = Double(fields[2]), let x = Double(fields[4]),
              let y = Double(fields[5]), let z = Double(fields[6]),
              [timestamp, x, y, z].allSatisfy(\.isFinite), timestamp > 0 else { return nil }
        self.service = service
        sensorTime = timestamp * 0.000001
        self.x = x * 0.00001
        self.y = y * 0.00001
        self.z = z * 0.00001
    }
}

struct CaseMotionMeter {
    private var baseline: CaseMotionSample?
    private(set) var peak = 0.0

    mutating func reset() {
        baseline = nil
        peak = 0
    }

    mutating func record(_ sample: CaseMotionSample) {
        guard sample.service == 11 else { return }
        guard let baseline else {
            self.baseline = sample
            return
        }
        let elapsed = sample.sensorTime - baseline.sensorTime
        guard elapsed > 0 else { return }
        guard elapsed >= 0.015 else { return }
        if elapsed <= 0.1 {
            let x = sample.x - baseline.x
            let y = sample.y - baseline.y
            let z = sample.z - baseline.z
            peak = max(peak, sqrt(x * x + y * y + z * z))
        }
        self.baseline = sample
    }
}
