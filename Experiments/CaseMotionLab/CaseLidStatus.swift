import Foundation

struct CaseLidStatus {
    let baselineReady: Bool
    let closed: Bool
    let caseIdentified: Bool
    let error: String?

    init?(data: Data) {
        guard let status = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let snapshot = status["case_snapshot"] as? [String: Any] else { return nil }
        baselineReady = status["open_baseline_verified"] as? Bool == true &&
            snapshot["root_identity_verified"] as? Bool == true
        caseIdentified = snapshot["case_identity_verified"] as? Bool == true
        error = snapshot["error"] as? String
        let reports = (status["earbud_state_events"] as? [[String: Any]] ?? []).compactMap { report -> LidReport? in
            guard let uptime = report["received_uptime"] as? Double,
                  let primary = report["primary_code"] as? Int,
                  let secondary = report["secondary_code"] as? Int else { return nil }
            return LidReport(uptime: uptime, primary: primary, secondary: secondary)
        }
        closed = Self.isClosed(reports)
    }

    private static func isClosed(_ reports: [LidReport]) -> Bool {
        var closed = false
        var index = 0
        while index < reports.count {
            let report = reports[index]
            if report.primary == 3 || report.secondary == 3 {
                closed = true
            } else if index + 1 < reports.count,
                      report.primary == 2, report.secondary == 2,
                      reports[index + 1].primary == 2, reports[index + 1].secondary == 2,
                      reports[index + 1].uptime - report.uptime <= 0.5 {
                closed.toggle()
                index += 1
            }
            index += 1
        }
        return closed
    }
}

private struct LidReport {
    let uptime: Double
    let primary: Int
    let secondary: Int
}
