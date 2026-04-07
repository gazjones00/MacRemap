import Foundation
import Yams

// MARK: - Configuration Model

struct AppConfig: Codable {
    var mappings: [Mapping]
}

struct Mapping: Codable {
    var trigger: Trigger
    var action: Action
}

struct Trigger: Codable {
    var mouseButton: Int?
    var key: Int?
    var modifiers: [String]?

    enum CodingKeys: String, CodingKey {
        case mouseButton = "mouse_button"
        case key
        case modifiers
    }
}

struct Action: Codable {
    var keyCombo: KeyCombo?
    var shell: String?
    var missionControl: Bool?
    var appExpose: Bool?
    var launchpad: Bool?
    var showDesktop: Bool?

    enum CodingKeys: String, CodingKey {
        case keyCombo = "key_combo"
        case shell
        case missionControl = "mission_control"
        case appExpose = "app_expose"
        case launchpad
        case showDesktop = "show_desktop"
    }
}

struct KeyCombo: Codable {
    var key: Int
    var modifiers: [String]?
}

// MARK: - Config File Manager

final class ConfigManager {
    static let shared = ConfigManager()
    private static let defaultConfigContents = """
    # MacRemap Configuration
    # ========================
    #
    # Each mapping has:
    #   trigger:  The input event to intercept
    #   action:   What to do when the trigger fires
    #
    # Trigger types:
    #   mouse_button: <number>    — Mouse button (1=left, 2=right, 3=middle, 4=back, 5=forward)
    #   key: <keycode>            — Keyboard key code (decimal)
    #   modifiers: [list]         — Optional modifier keys: shift, control, option, command
    #
    # Action types:
    #   key_combo:
    #     key: <keycode>          — Virtual key code to send
    #     modifiers: [list]       — Modifier keys to hold
    #   shell: <command>          — Run a shell command
    #   mission_control: true     — Trigger Mission Control
    #   app_expose: true          — Trigger App Exposé
    #   launchpad: true           — Trigger Launchpad
    #   show_desktop: true        — Trigger Show Desktop
    #
    # Common key codes:
    #   49 = Space, 36 = Return, 53 = Escape, 48 = Tab
    #   0 = A, 1 = S, 2 = D, 3 = F, ...
    #
    # -------------------------------------------------------

    mappings:
      # Mouse 4 (Back button) → Mission Control
      - trigger:
          mouse_button: 4
        action:
          mission_control: true

      # Mouse 5 (Forward button) → App Exposé
      - trigger:
          mouse_button: 5
        action:
          app_expose: true
    """

    private(set) var config: AppConfig = AppConfig(mappings: [])
    private(set) var mappingIndex = MappingIndex(mappings: [])
    private let configURL: URL

    private init() {
        let configDir = Self.configDirectoryURL()
        configURL = configDir.appendingPathComponent("config.yaml")

        ensureConfigExists(configDir: configDir)
        loadConfig()
    }

    private static func configDirectoryURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("macremap")
    }

    /// Copies the default config into ~/.config/macremap/ if none exists
    private func ensureConfigExists(configDir: URL) {
        let fm = FileManager.default
        if !fm.fileExists(atPath: configURL.path) {
            try? fm.createDirectory(at: configDir, withIntermediateDirectories: true)

            try? Self.defaultConfigContents.write(to: configURL, atomically: true, encoding: .utf8)
            print("[MacRemap] Created default config at \(configURL.path)")
        }
    }

    /// Loads (or reloads) the YAML config from disk
    @discardableResult
    func loadConfig() -> Bool {
        do {
            let yamlString = try String(contentsOf: configURL, encoding: .utf8)
            let decoder = YAMLDecoder()
            let loadedConfig = try decoder.decode(AppConfig.self, from: yamlString)
            config = loadedConfig
            mappingIndex = MappingIndex(mappings: loadedConfig.mappings)
            print("[MacRemap] Loaded \(config.mappings.count) mapping(s) from config")
            return true
        } catch {
            print("[MacRemap] Failed to load config: \(error)")
            return false
        }
    }

    /// Saves a new config to disk and reloads it
    func saveConfig(_ config: AppConfig) {
        let encoder = YAMLEncoder()
        do {
            let yamlString = try encoder.encode(config)
            let header = "# MacRemap Configuration\n# Managed by MacRemap — edit here or use Configure Mappings in the menu bar\n\n"
            try (header + yamlString).write(to: configURL, atomically: true, encoding: .utf8)
            loadConfig()
            print("[MacRemap] Saved \(config.mappings.count) mapping(s) to config")
        } catch {
            print("[MacRemap] Failed to save config: \(error)")
        }
    }

    /// Returns the path to the config file (for "Edit Config" menu item)
    var configFilePath: String {
        configURL.path
    }
}
