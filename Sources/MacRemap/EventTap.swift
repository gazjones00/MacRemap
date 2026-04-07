import Cocoa
import CoreGraphics

// MARK: - Event Tap (CGEvent interception)

final class EventTapManager {
    static let shared = EventTapManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isRunning = false

    private init() {}

    private let eventMask: CGEventMask = (
        (1 << CGEventType.otherMouseDown.rawValue) |
        (1 << CGEventType.otherMouseUp.rawValue) |
        (1 << CGEventType.keyDown.rawValue)
    )

    // MARK: - Start / Stop

    func start() {
        guard !isRunning else { return }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            print("[MacRemap] ❌ Failed to create event tap.")
            print("[MacRemap]    Grant Accessibility permission in System Settings → Privacy & Security → Accessibility")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        print("[MacRemap] ✅ Event tap started")
    }

    func stop() {
        guard isRunning, let tap = eventTap, let source = runLoopSource else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        eventTap = nil
        runLoopSource = nil
        isRunning = false
        print("[MacRemap] Event tap stopped")
    }

    func toggle() {
        if isRunning { stop() } else { start() }
    }

    func reenableIfNeeded(for type: CGEventType) -> Bool {
        guard type == .tapDisabledByTimeout || type == .tapDisabledByUserInput else {
            return false
        }

        guard let eventTap else { return true }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return true
    }

    func handleEvent(type: CGEventType, event: CGEvent) -> Bool {
        switch type {
        case .otherMouseDown:
            let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
            let configButton = Int(buttonNumber) + 1

            guard let action = ConfigManager.shared.mappingIndex.action(forMouseButton: configButton) else {
                return false
            }

            ActionExecutor.execute(action)
            return true

        case .keyDown:
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))

            guard let action = ConfigManager.shared.mappingIndex.action(
                forKeyCode: keyCode,
                flags: event.flags
            ) else {
                return false
            }

            ActionExecutor.execute(action)
            return true

        default:
            return false
        }
    }
}

// MARK: - Event Tap Callback (C-function)

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if EventTapManager.shared.reenableIfNeeded(for: type) {
        return Unmanaged.passUnretained(event)
    }

    if EventTapManager.shared.handleEvent(type: type, event: event) {
        return nil
    }

    return Unmanaged.passUnretained(event)
}
