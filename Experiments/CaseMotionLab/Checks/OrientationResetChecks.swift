import CoreGraphics
import Foundation

protocol CaseOrientationSource {
    func feed(_ rows: [[Double]]) -> (ready: Bool, point: CGPoint?)?
    func setCenter() -> Bool
    func setAxis(_ axis: String) -> Bool
    func reset()
}

enum LabError: Error { case message(String) }

@main
struct OrientationResetChecks {
    static func main() throws {
        let source = try String(contentsOfFile: "Vendor/AirPointer/Orientation.js", encoding: .utf8)
        let orientation = try CaseOrientation(source: source)
        for index in 1...160 { _ = orientation.feed(samples(index)) }
        guard orientation.feed(samples(161))?.ready == true else { fatalError("Initial motion did not settle") }
        orientation.reset()
        guard orientation.feed(samples(162))?.ready == false else { fatalError("Reset reused the old stillness") }
        for index in 163...323 { _ = orientation.feed(samples(index)) }
        guard orientation.feed(samples(324))?.ready == true else { fatalError("Fresh motion did not settle") }
        print("PASS: tap calibration waits for fresh stillness after reset")
    }

    private static func samples(_ index: Int) -> [[Double]] {
        let stamp = Double(index) * 10_000
        return [[0, 11, stamp, 0, 0, 0, 100_000], [0, 12, stamp, 0, 0, 0, 0]]
    }
}
