import CoreGraphics

enum InputModifier: CaseIterable, Hashable {
    case shift
    case control
    case option
    case command

    init?(name: String) {
        switch name.lowercased() {
        case "shift":
            self = .shift
        case "control", "ctrl":
            self = .control
        case "option", "alt":
            self = .option
        case "command", "cmd":
            self = .command
        default:
            return nil
        }
    }

    var eventFlag: CGEventFlags {
        switch self {
        case .shift:
            return .maskShift
        case .control:
            return .maskControl
        case .option:
            return .maskAlternate
        case .command:
            return .maskCommand
        }
    }

    static func eventFlags(from names: [String]?) -> CGEventFlags {
        guard let names else { return [] }

        return names.reduce(into: []) { flags, name in
            guard let modifier = InputModifier(name: name) else { return }
            flags.insert(modifier.eventFlag)
        }
    }

    static func matches(required names: [String]?, actual: CGEventFlags) -> Bool {
        guard let names, !names.isEmpty else { return true }

        let requiredModifiers = names.compactMap(InputModifier.init(name:))
        return requiredModifiers.allSatisfy { actual.contains($0.eventFlag) }
    }
}

extension Action {
    enum ExecutionKind {
        case missionControl
        case appExpose
        case launchpad
        case showDesktop
        case keyCombo(KeyCombo)
        case shell(String)
    }

    var executionKind: ExecutionKind? {
        if missionControl == true {
            return .missionControl
        }

        if appExpose == true {
            return .appExpose
        }

        if launchpad == true {
            return .launchpad
        }

        if showDesktop == true {
            return .showDesktop
        }

        if let keyCombo {
            return .keyCombo(keyCombo)
        }

        if let shell {
            return .shell(shell)
        }

        return nil
    }
}

private struct KeyboardMapping {
    let keyCode: Int
    let requiredModifiers: [String]?
    let action: Action

    init?(mapping: Mapping) {
        guard let keyCode = mapping.trigger.key else { return nil }
        self.keyCode = keyCode
        self.requiredModifiers = mapping.trigger.modifiers
        self.action = mapping.action
    }

    func matches(keyCode: Int, flags: CGEventFlags) -> Bool {
        guard self.keyCode == keyCode else { return false }
        return InputModifier.matches(required: requiredModifiers, actual: flags)
    }
}

struct MappingIndex {
    private let mouseActions: [Int: Action]
    private let keyboardMappings: [KeyboardMapping]

    init(mappings: [Mapping]) {
        var mouseActions: [Int: Action] = [:]
        var keyboardMappings: [KeyboardMapping] = []

        for mapping in mappings {
            if let mouseButton = mapping.trigger.mouseButton {
                if mouseActions[mouseButton] == nil {
                    mouseActions[mouseButton] = mapping.action
                }
                continue
            }

            if let keyboardMapping = KeyboardMapping(mapping: mapping) {
                keyboardMappings.append(keyboardMapping)
            }
        }

        self.mouseActions = mouseActions
        self.keyboardMappings = keyboardMappings
    }

    func action(forMouseButton button: Int) -> Action? {
        mouseActions[button]
    }

    func action(forKeyCode keyCode: Int, flags: CGEventFlags) -> Action? {
        keyboardMappings.first { $0.matches(keyCode: keyCode, flags: flags) }?.action
    }
}
