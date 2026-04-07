import Cocoa
import CoreGraphics

// MARK: - Action Executor

enum ActionExecutor {

    static func execute(_ action: Action) {
        guard let executionKind = action.executionKind else { return }

        switch executionKind {
        case .missionControl:
            triggerMissionControl()
        case .appExpose:
            triggerAppExpose()
        case .launchpad:
            triggerLaunchpad()
        case .showDesktop:
            triggerShowDesktop()
        case let .keyCombo(combo):
            sendKeyCombo(combo)
        case let .shell(shell):
            runShellCommand(shell)
        }
    }

    // MARK: - Key Combo

    private static func sendKeyCombo(_ combo: KeyCombo) {
        let keyCode = CGKeyCode(combo.key)
        let flags = InputModifier.eventFlags(from: combo.modifiers)

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp   = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        else { return }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
    }

    // MARK: - System Actions via NSWorkspace / Private APIs

    private static func triggerMissionControl() {
        openApplication(named: "Mission Control")
    }

    private static func triggerAppExpose() {
        sendKeyCombo(KeyCombo(key: 125, modifiers: ["control"]))
    }

    private static func triggerLaunchpad() {
        openApplication(named: "Launchpad")
    }

    private static func triggerShowDesktop() {
        // F11 key or Fn+F11 triggers Show Desktop
        // Using the CGEvent approach: key code 103 = F11
        sendKeyCombo(KeyCombo(key: 103, modifiers: []))
    }

    // MARK: - Shell Command

    private static func runShellCommand(_ command: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            runDetachedProcess(
                executableURL: URL(fileURLWithPath: "/bin/zsh"),
                arguments: ["-c", command]
            )
        }
    }

    private static func openApplication(named applicationName: String) {
        runDetachedProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/open"),
            arguments: ["-a", applicationName]
        )
    }

    private static func runDetachedProcess(executableURL: URL, arguments: [String]) {
        let task = Process()
        task.executableURL = executableURL
        task.arguments = arguments
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
        } catch {
            print("[MacRemap] Failed to launch process \(executableURL.path): \(error)")
        }
    }
}
