import Carbon
import Foundation

final class HotKey {
    private static let signature: OSType = 0x414D4F55
    private static let toggleID: UInt32 = 1
    private static let escapeID: UInt32 = 2
    private var reference: EventHotKeyRef?
    private var escapeReference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var identifier = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                           nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard status == noErr, identifier.signature == HotKey.signature,
                  [HotKey.toggleID, HotKey.escapeID].contains(identifier.id) else { return OSStatus(eventNotHandledErr) }
            let hotKey = Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue()
            hotKey.action()
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
        let identifier = EventHotKeyID(signature: Self.signature, id: Self.toggleID)
        RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey | optionKey), identifier,
                            GetApplicationEventTarget(), 0, &reference)
    }

    @discardableResult
    func setEscapeEnabled(_ enabled: Bool) -> Bool {
        if !enabled {
            if let escapeReference { UnregisterEventHotKey(escapeReference) }
            escapeReference = nil
            return true
        }
        guard handler != nil else { return false }
        guard escapeReference == nil else { return true }
        let identifier = EventHotKeyID(signature: Self.signature, id: Self.escapeID)
        let status = RegisterEventHotKey(UInt32(kVK_Escape), 0, identifier,
                                         GetApplicationEventTarget(), 0, &escapeReference)
        return status == noErr && escapeReference != nil
    }

    deinit {
        if let escapeReference { UnregisterEventHotKey(escapeReference) }
        if let reference { UnregisterEventHotKey(reference) }
        if let handler { RemoveEventHandler(handler) }
    }
}
