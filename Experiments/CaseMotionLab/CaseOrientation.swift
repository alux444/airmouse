import Foundation
import JavaScriptCore

final class CaseOrientation: CaseOrientationSource {
    private let context: JSContext

    convenience init() throws {
        guard let path = Bundle.main.url(forResource: "CaseOrientation", withExtension: "js") else {
            throw LabError.message("Motion calibration component is missing.")
        }
        try self.init(source: String(contentsOf: path, encoding: .utf8))
    }

    init(source: String) throws {
        guard let context = JSContext() else { throw LabError.message("Motion calibration component is missing.") }
        self.context = context
        let script = source.replacingOccurrences(of: "export ", with: "")
        context.evaluateScript(script + "\nvar fusion = new Orientation(); var grip = new Grip();")
        guard context.exception == nil else { throw LabError.message("Motion calibration couldn’t start.") }
    }

    func feed(_ rows: [[Double]]) -> (ready: Bool, point: CGPoint?)? {
        context.exception = nil
        context.setObject(rows, forKeyedSubscript: "rows" as NSString)
        guard let result = context.evaluateScript("for (const row of rows) fusion.feed(row); ({ready: fusion.ready, point: grip.point(fusion.q)})")?.toDictionary() as? [String: Any],
              context.exception == nil, let ready = result["ready"] as? Bool else { return nil }
        guard let values = result["point"] as? [Double], values.count == 2,
              values.allSatisfy(\.isFinite) else { return (ready, nil) }
        return (ready, CGPoint(x: values[0], y: values[1]))
    }

    func reset() {
        context.exception = nil
        context.evaluateScript("fusion = new Orientation(); grip = new Grip();")
    }

    func setCenter() -> Bool {
        context.exception = nil
        context.evaluateScript("grip.setCenter(fusion.q, fusion.referenceGravity)")
        return context.exception == nil
    }

    func setAxis(_ axis: String) -> Bool {
        guard ["right", "up"].contains(axis) else { return false }
        context.exception = nil
        context.setObject(axis, forKeyedSubscript: "axis" as NSString)
        context.evaluateScript("grip.setAxis(axis, fusion.q)")
        return context.exception == nil
    }
}
