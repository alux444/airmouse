import Foundation

@main
struct CaseLidChecks {
    static func main() throws {
        func status(_ reports: [[String: Any]]) throws -> CaseLidStatus {
            let value: [String: Any] = [
                "open_baseline_verified": true,
                "case_snapshot": ["root_identity_verified": true],
                "earbud_state_events": reports
            ]
            let data = try JSONSerialization.data(withJSONObject: value)
            guard let status = CaseLidStatus(data: data) else { fatalError("Invalid status") }
            return status
        }
        func report(_ time: Double, _ primary: Int, _ secondary: Int) -> [String: Any] {
            ["received_uptime": time, "primary_code": primary, "secondary_code": secondary]
        }
        let opened = try status([])
        precondition(opened.baselineReady && !opened.closed)
        let closed = try status([report(1, 3, 0)])
        precondition(closed.closed)
        let reopened = try status([report(1, 3, 0), report(2, 2, 2), report(2.2, 2, 2)])
        precondition(!reopened.closed)
        let separated = try status([report(1, 3, 0), report(2, 2, 2), report(3, 2, 2)])
        precondition(separated.closed)
        print("PASS: case lid reports distinguish closure and reopening")
    }
}
