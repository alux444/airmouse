import CoreAudio
import Foundation

struct BluetoothTarget {
    let name: String
    let address: String

    static func connectedAirPods() throws -> BluetoothTarget {
        let task = Process()
        let output = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        task.arguments = ["SPBluetoothDataType", "-json"]
        task.standardOutput = output
        task.standardError = FileHandle.nullDevice
        try task.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard task.terminationStatus == 0,
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let info = (root["SPBluetoothDataType"] as? [[String: Any]])?.first else {
            throw LabError.message("Couldn’t read connected Bluetooth devices.")
        }
        let entries = info["device_connected"] as? [[String: Any]] ?? []
        let models: Set<String> = ["0x2014", "0x2024", "0x2027", "0x2019", "0x201b"]
        let matches: [BluetoothTarget] = entries.flatMap { entry in
            entry.compactMap { name, value in
                guard let fields = value as? [String: Any],
                      (fields["device_vendorID"] as? String)?.lowercased() == "0x004c",
                      let product = (fields["device_productID"] as? String)?.lowercased(),
                      models.contains(product), let address = fields["device_address"] as? String,
                      address.range(of: "^(?:[0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$", options: .regularExpression) != nil else { return nil }
                return BluetoothTarget(name: name, address: address)
            }
        }
        guard matches.count == 1, let target = matches.first else {
            throw LabError.message(matches.isEmpty ? "Connect your AirPods to this Mac with the case open." : "Connect only the AirPods you want to test.")
        }
        return target
    }
}

enum LabError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let value): return value }
    }
}

func currentAudioOutput() -> AudioDeviceID? {
    var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                             mScope: kAudioObjectPropertyScopeGlobal,
                                             mElement: kAudioObjectPropertyElementMain)
    var identifier = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    let result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &identifier)
    return result == noErr && identifier != 0 ? identifier : nil
}
