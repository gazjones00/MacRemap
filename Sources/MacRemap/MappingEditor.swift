import SwiftUI
import Cocoa

// MARK: - Editor Types

enum TriggerKind: String, CaseIterable, Identifiable {
    case mouseButton = "Mouse Button"
    case keyboard = "Keyboard Key"
    var id: String { rawValue }
}

enum ActionKind: String, CaseIterable, Identifiable {
    case systemAction = "System Action"
    case keyCombo = "Key Combo"
    case shell = "Shell Command"
    var id: String { rawValue }
}

enum SystemActionKind: String, CaseIterable, Identifiable {
    case missionControl = "Mission Control"
    case appExpose = "App Exposé"
    case launchpad = "Launchpad"
    case showDesktop = "Show Desktop"
    var id: String { rawValue }
}

enum ModifierKey: String, CaseIterable, Identifiable {
    case command, control, option, shift
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .shift: return "⇧"
        case .control: return "⌃"
        case .option: return "⌥"
        case .command: return "⌘"
        }
    }
    var displayName: String { rawValue.capitalized + " " + symbol }
}

// MARK: - Key Code Names

enum KeyNames {
    private static let names: [Int: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
        36: "Return", 37: "L", 38: "J", 39: "'", 40: "K", 41: ";",
        42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        48: "Tab", 49: "Space", 50: "`", 51: "Delete", 53: "Escape",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
        101: "F9", 103: "F11", 105: "F13", 107: "F14",
        109: "F10", 111: "F12", 113: "F15", 115: "Home",
        116: "Page Up", 117: "Fwd Delete", 119: "End",
        120: "F2", 121: "Page Down", 122: "F1", 123: "←",
        124: "→", 125: "↓", 126: "↑",
    ]

    static func name(for keyCode: Int) -> String {
        names[keyCode] ?? "Key \(keyCode)"
    }

    static func mouseButtonName(_ button: Int) -> String {
        switch button {
        case 3: return "Middle"
        case 4: return "Back"
        case 5: return "Forward"
        default: return "Button \(button)"
        }
    }
}

// MARK: - Editable Mapping

struct EditableMapping: Identifiable, Equatable {
    let id: UUID
    var triggerKind: TriggerKind
    var mouseButton: Int
    var keyCode: Int
    var triggerModifiers: Set<ModifierKey>
    var actionKind: ActionKind
    var systemAction: SystemActionKind
    var comboKeyCode: Int
    var comboModifiers: Set<ModifierKey>
    var shellCommand: String

    init(
        id: UUID = UUID(),
        triggerKind: TriggerKind = .mouseButton,
        mouseButton: Int = 4,
        keyCode: Int = 0,
        triggerModifiers: Set<ModifierKey> = [],
        actionKind: ActionKind = .systemAction,
        systemAction: SystemActionKind = .missionControl,
        comboKeyCode: Int = 49,
        comboModifiers: Set<ModifierKey> = [],
        shellCommand: String = ""
    ) {
        self.id = id
        self.triggerKind = triggerKind
        self.mouseButton = mouseButton
        self.keyCode = keyCode
        self.triggerModifiers = triggerModifiers
        self.actionKind = actionKind
        self.systemAction = systemAction
        self.comboKeyCode = comboKeyCode
        self.comboModifiers = comboModifiers
        self.shellCommand = shellCommand
    }

    init(from mapping: Mapping) {
        self.id = UUID()

        if let mb = mapping.trigger.mouseButton {
            self.triggerKind = .mouseButton
            self.mouseButton = mb
        } else {
            self.triggerKind = .keyboard
            self.mouseButton = 4
        }
        self.keyCode = mapping.trigger.key ?? 0
        self.triggerModifiers = Self.parseModifiers(mapping.trigger.modifiers)

        if mapping.action.missionControl == true {
            self.actionKind = .systemAction; self.systemAction = .missionControl
        } else if mapping.action.appExpose == true {
            self.actionKind = .systemAction; self.systemAction = .appExpose
        } else if mapping.action.launchpad == true {
            self.actionKind = .systemAction; self.systemAction = .launchpad
        } else if mapping.action.showDesktop == true {
            self.actionKind = .systemAction; self.systemAction = .showDesktop
        } else if let combo = mapping.action.keyCombo {
            self.actionKind = .keyCombo
            self.systemAction = .missionControl
            self.comboKeyCode = combo.key
            self.comboModifiers = Self.parseModifiers(combo.modifiers)
            self.shellCommand = ""
            return
        } else if let shell = mapping.action.shell {
            self.actionKind = .shell
            self.systemAction = .missionControl
            self.comboKeyCode = 49
            self.comboModifiers = []
            self.shellCommand = shell
            return
        } else {
            self.actionKind = .systemAction; self.systemAction = .missionControl
        }

        self.comboKeyCode = 49
        self.comboModifiers = []
        self.shellCommand = ""
    }

    func toMapping() -> Mapping {
        var trigger = Trigger()
        switch triggerKind {
        case .mouseButton:
            trigger.mouseButton = mouseButton
        case .keyboard:
            trigger.key = keyCode
            if !triggerModifiers.isEmpty {
                trigger.modifiers = triggerModifiers.sorted(by: { $0.rawValue < $1.rawValue }).map(\.rawValue)
            }
        }

        var action = Action()
        switch actionKind {
        case .systemAction:
            switch systemAction {
            case .missionControl: action.missionControl = true
            case .appExpose: action.appExpose = true
            case .launchpad: action.launchpad = true
            case .showDesktop: action.showDesktop = true
            }
        case .keyCombo:
            let mods: [String]? = comboModifiers.isEmpty
                ? nil
                : comboModifiers.sorted(by: { $0.rawValue < $1.rawValue }).map(\.rawValue)
            action.keyCombo = KeyCombo(key: comboKeyCode, modifiers: mods)
        case .shell:
            action.shell = shellCommand
        }

        return Mapping(trigger: trigger, action: action)
    }

    // MARK: Display

    var triggerDescription: String {
        switch triggerKind {
        case .mouseButton:
            return "Mouse \(KeyNames.mouseButtonName(mouseButton))"
        case .keyboard:
            let mods = triggerModifiers.sorted(by: { $0.rawValue < $1.rawValue }).map(\.symbol).joined()
            return mods + KeyNames.name(for: keyCode)
        }
    }

    var actionDescription: String {
        switch actionKind {
        case .systemAction:
            return systemAction.rawValue
        case .keyCombo:
            let mods = comboModifiers.sorted(by: { $0.rawValue < $1.rawValue }).map(\.symbol).joined()
            return mods + KeyNames.name(for: comboKeyCode)
        case .shell:
            let truncated = shellCommand.prefix(30)
            return shellCommand.count > 30 ? "\(truncated)..." : String(truncated)
        }
    }

    // MARK: Helpers

    private static func parseModifiers(_ names: [String]?) -> Set<ModifierKey> {
        guard let names else { return [] }
        var result = Set<ModifierKey>()
        for name in names {
            switch name.lowercased() {
            case "shift": result.insert(.shift)
            case "control", "ctrl": result.insert(.control)
            case "option", "alt": result.insert(.option)
            case "command", "cmd": result.insert(.command)
            default: break
            }
        }
        return result
    }
}

// MARK: - View Model

final class MappingEditorViewModel: ObservableObject {
    @Published var mappings: [EditableMapping] = []
    @Published var selectedID: UUID?
    @Published var hasChanges = false

    init() {
        loadFromConfig()
    }

    func loadFromConfig() {
        mappings = ConfigManager.shared.config.mappings.map(EditableMapping.init(from:))
        selectedID = mappings.first?.id
        hasChanges = false
    }

    func save() {
        let config = AppConfig(mappings: mappings.map { $0.toMapping() })
        ConfigManager.shared.saveConfig(config)
        hasChanges = false
    }

    func addMapping() {
        let mapping = EditableMapping()
        mappings.append(mapping)
        selectedID = mapping.id
        hasChanges = true
    }

    func removeSelected() {
        guard let selectedID else { return }
        mappings.removeAll { $0.id == selectedID }
        self.selectedID = mappings.first?.id
        hasChanges = true
    }

    func markChanged() {
        hasChanges = true
    }
}

// MARK: - Main Editor View

struct MappingEditorView: View {
    @ObservedObject var viewModel: MappingEditorViewModel

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 640, minHeight: 420)
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $viewModel.selectedID) {
                ForEach(viewModel.mappings) { mapping in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mapping.triggerDescription)
                            .fontWeight(.medium)
                        Text(mapping.actionDescription)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .tag(mapping.id)
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.sidebar)

            Divider()

            HStack(spacing: 12) {
                Button(action: viewModel.addMapping) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)

                Button(action: viewModel.removeSelected) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.selectedID == nil)

                Spacer()

                if viewModel.hasChanges {
                    Text("Unsaved changes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Button("Save") { viewModel.save() }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(!viewModel.hasChanges)
            }
            .padding(8)
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        if let index = viewModel.mappings.firstIndex(where: { $0.id == viewModel.selectedID }) {
            MappingDetailView(mapping: $viewModel.mappings[index], onChange: viewModel.markChanged)
                .id(viewModel.selectedID)
        } else {
            Text("Select a mapping or click + to add one")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Detail View

struct MappingDetailView: View {
    @Binding var mapping: EditableMapping
    let onChange: () -> Void

    var body: some View {
        Form {
            Section("Trigger") {
                Picker("Type", selection: $mapping.triggerKind) {
                    ForEach(TriggerKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .onChange(of: mapping.triggerKind) { _ in onChange() }

                switch mapping.triggerKind {
                case .mouseButton:
                    Picker("Button", selection: $mapping.mouseButton) {
                        Text("Middle (3)").tag(3)
                        Text("Back (4)").tag(4)
                        Text("Forward (5)").tag(5)
                        ForEach(6..<13) { n in
                            Text("Button \(n)").tag(n)
                        }
                    }
                    .onChange(of: mapping.mouseButton) { _ in onChange() }

                case .keyboard:
                    KeyRecorderField(label: "Key", keyCode: $mapping.keyCode, onChange: onChange)

                    ModifierToggles(label: "Modifiers", modifiers: $mapping.triggerModifiers, onChange: onChange)
                }
            }

            Section("Action") {
                Picker("Type", selection: $mapping.actionKind) {
                    ForEach(ActionKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .onChange(of: mapping.actionKind) { _ in onChange() }

                switch mapping.actionKind {
                case .systemAction:
                    Picker("Action", selection: $mapping.systemAction) {
                        ForEach(SystemActionKind.allCases) { action in
                            Text(action.rawValue).tag(action)
                        }
                    }
                    .onChange(of: mapping.systemAction) { _ in onChange() }

                case .keyCombo:
                    KeyRecorderField(label: "Key", keyCode: $mapping.comboKeyCode, onChange: onChange)

                    ModifierToggles(label: "Modifiers", modifiers: $mapping.comboModifiers, onChange: onChange)

                case .shell:
                    TextField("Command", text: $mapping.shellCommand)
                        .onChange(of: mapping.shellCommand) { _ in onChange() }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Key Recorder Field

struct KeyRecorderField: View {
    let label: String
    @Binding var keyCode: Int
    let onChange: () -> Void
    @State private var isRecording = false
    @State private var eventTapWasRunning = false
    @State private var monitor: Any?

    var body: some View {
        LabeledContent(label) {
            Button(action: toggleRecording) {
                Text(isRecording ? "Press a key..." : KeyNames.name(for: keyCode))
                    .frame(minWidth: 80)
            }
            .foregroundColor(isRecording ? .accentColor : .primary)
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        eventTapWasRunning = EventTapManager.shared.isRunning
        if eventTapWasRunning {
            EventTapManager.shared.stop()
        }

        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            keyCode = Int(event.keyCode)
            onChange()
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false

        if eventTapWasRunning {
            EventTapManager.shared.start()
        }
    }
}

// MARK: - Modifier Toggles

struct ModifierToggles: View {
    let label: String
    @Binding var modifiers: Set<ModifierKey>
    let onChange: () -> Void

    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 12) {
                ForEach(ModifierKey.allCases) { key in
                    Toggle(key.displayName, isOn: binding(for: key))
                        .toggleStyle(.checkbox)
                }
            }
        }
    }

    private func binding(for key: ModifierKey) -> Binding<Bool> {
        Binding(
            get: { modifiers.contains(key) },
            set: { isOn in
                if isOn { modifiers.insert(key) } else { modifiers.remove(key) }
                onChange()
            }
        )
    }
}

// MARK: - Window Controller

final class MappingEditorWindowController: NSObject, NSWindowDelegate {
    static let shared = MappingEditorWindowController()
    private var window: NSWindow?

    func showWindow() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let viewModel = MappingEditorViewModel()
        let hostingView = NSHostingView(rootView: MappingEditorView(viewModel: viewModel))

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 480),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacRemap"
        window.contentView = hostingView
        window.delegate = self
        window.center()
        window.setFrameAutosaveName("MappingEditor")
        window.isReleasedWhenClosed = false

        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
