import Foundation
import JavaScriptCore

enum OrientationCheckError: Error {
    case failed
}

@main
struct OrientationChecks {
    static func main() throws {
        let source = try String(contentsOfFile: "Vendor/AirPointer/Orientation.js", encoding: .utf8)
            .replacingOccurrences(of: "export ", with: "")
        guard let context = JSContext() else { throw OrientationCheckError.failed }
        context.evaluateScript(source + """

        const testGrip = new Grip();
        testGrip.setCenter([1, 0, 0, 0], [0, 0, 1]);
        testGrip.setAxis('right', [Math.cos(0.1), Math.sin(0.1), 0, 0]);
        testGrip.setAxis('up', [Math.cos(0.1), 0, Math.sin(0.1), 0]);
        const center = testGrip.point([1, 0, 0, 0]);
        const right = testGrip.point([Math.cos(0.1), Math.sin(0.1), 0, 0]);
        const top = testGrip.point([Math.cos(0.1), 0, Math.sin(0.1), 0]);
        const close = (a, b) => Math.abs(a - b) < 0.001;
        close(center[0], 0.5) && close(center[1], 0.5) &&
        close(right[0], 1) && close(right[1], 0.5) &&
        close(top[0], 0.5) && close(top[1], 0);
        """)
        guard context.exception == nil, context.evaluateScript("close(center[0],0.5) && close(right[0],1) && close(top[1],0)")?.toBool() == true else {
            throw OrientationCheckError.failed
        }
        print("PASS: three calibration poses map to the screen centre, right and top")
    }
}
