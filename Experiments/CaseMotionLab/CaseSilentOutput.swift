import CoreAudio
import Foundation

final class CaseSilentOutput {
    private let queue = DispatchQueue(label: "airmouse.case-silent-output", qos: .userInitiated)
    private let target: String
    private var device: AudioDeviceID?
    private var process: AudioDeviceIOProcID?
    private var stopped = false
    private var nextAttempt: TimeInterval = 0

    init(address: String) {
        target = Self.normalized(address)
    }

    func refresh() {
        queue.async { [self] in
            guard !stopped else { return }
            if let device, Self.number(device, kAudioDevicePropertyDeviceIsAlive) == 1,
               Self.number(device, kAudioDevicePropertyDeviceIsRunningSomewhere) == 1 { return }
            releaseStream()
            let now = ProcessInfo.processInfo.systemUptime
            guard now >= nextAttempt else { return }
            nextAttempt = now + 2
            guard target.count == 12, let output = Self.outputs().first(where: { output in
                Self.normalized(output.uid).contains(target)
            }) else { return }
            var created: AudioDeviceIOProcID?
            let result = AudioDeviceCreateIOProcID(output.id, { _, _, _, _, buffers, _, _ in
                for buffer in UnsafeMutableAudioBufferListPointer(buffers) {
                    if let data = buffer.mData { memset(data, 0, Int(buffer.mDataByteSize)) }
                }
                return noErr
            }, nil, &created)
            guard result == noErr, let created else { return }
            device = output.id
            process = created
            if AudioDeviceStart(output.id, created) != noErr { releaseStream() }
        }
    }

    func stop() {
        queue.async { [self] in
            stopped = true
            releaseStream()
        }
    }

    private func releaseStream() {
        if let device, let process {
            AudioDeviceStop(device, process)
            AudioDeviceDestroyIOProcID(device, process)
        }
        process = nil
        device = nil
    }

    private static func normalized(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func number(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> UInt32? {
        var property = address(selector)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(object, &property, 0, nil, &size, &value) == noErr else { return nil }
        return value
    }

    private static func address(_ selector: AudioObjectPropertySelector,
                                scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    private static func outputs() -> [(id: AudioDeviceID, uid: String)] {
        var property = address(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &property, 0, nil, &size) == noErr, size > 0 else { return [] }
        var identifiers = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard identifiers.withUnsafeMutableBytes({ AudioObjectGetPropertyData(system, &property, 0, nil, &size, $0.baseAddress!) }) == noErr else { return [] }
        return identifiers.compactMap { identifier in
            var streams = address(kAudioDevicePropertyStreams, scope: kAudioObjectPropertyScopeOutput)
            var bytes: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(identifier, &streams, 0, nil, &bytes) == noErr, bytes > 0,
                  number(identifier, kAudioDevicePropertyDeviceIsAlive) == 1,
                  let transport = number(identifier, kAudioDevicePropertyTransportType),
                  transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE,
                  let uid = deviceUID(identifier) else { return nil }
            return (identifier, uid)
        }
    }

    private static func deviceUID(_ device: AudioDeviceID) -> String? {
        var property = address(kAudioDevicePropertyDeviceUID)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(device, &property, 0, nil, &size, &value) == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }
}
