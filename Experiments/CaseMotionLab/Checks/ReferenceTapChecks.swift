import Foundation

enum CheckError: Error {
    case failed(String)
}

@main
struct ReferenceTapChecks {
    static func main() throws {
        let direction = SIMD3<Double>(0.5, 0, 0)
        let calibration = samples(tapTimes: [1, 2, 3], direction: direction)
        var learner = ClosedCaseTapLearner()
        let events = learner.feed(calibration)
        guard let learned = events.compactMap({ event -> SIMD3<Double>? in
            if case .finished(let value) = event { return value }
            return nil
        }).first else { throw CheckError.failed("Three consistent taps did not teach a direction") }
        var detector = ClosedCaseTapDetector()
        detector.direction = learned
        let test = samples(tapTimes: [4], direction: direction)
        let detections = detector.feed(test).filter { if case .tap = $0 { return true }; return false }
        guard detections.count == 1 else { throw CheckError.failed("The taught detector did not count one tap") }
        print("PASS: three consistent taps teach a direction, then one tap is detected")
    }

    private static func samples(tapTimes: [Double], direction: SIMD3<Double>) -> [[Double]] {
        let end = (tapTimes.max() ?? 1) + 1
        return (0...Int(end / 0.02)).flatMap { step -> [[Double]] in
            let time = Double(step) * 0.02
            let tapped = tapTimes.contains { abs($0 - time) < 0.001 }
            let acceleration = SIMD3<Double>(0, 0, 1) + (tapped ? direction : .zero)
            let stamp = 1_000_000_000 + time * 1_000_000
            return [[0, 12, stamp - 1, 0, 0, 0, 0],
                    [0, 11, stamp, 0, acceleration.x * 100_000, acceleration.y * 100_000, acceleration.z * 100_000]]
        }
    }
}
