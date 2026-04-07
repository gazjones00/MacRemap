import Cocoa
import ServiceManagement
import UserNotifications

// MARK: - Menu Bar App

final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateStatusIcon()
        buildMenu()
    }

    private func buildMenu() {
        menu = NSMenu()

        let statusTitle = EventTapManager.shared.isRunning ? "Status: Active" : "Status: Inactive"
        menu.addItem(makeMenuItem(title: statusTitle, isEnabled: false))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(makeMenuItem(title: "Configure Mappings...", action: #selector(openMappingEditor)))

        menu.addItem(NSMenuItem.separator())

        let toggleTitle = EventTapManager.shared.isRunning ? "Disable" : "Enable"
        menu.addItem(makeMenuItem(title: toggleTitle, action: #selector(toggleEventTap), keyEquivalent: "t"))
        menu.addItem(makeMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: "r"))
        menu.addItem(makeMenuItem(title: "Edit Config...", action: #selector(editConfig), keyEquivalent: ","))
        menu.addItem(makeMenuItem(title: "Reveal Config in Finder", action: #selector(revealConfig)))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            makeMenuItem(
                title: "Launch at Login",
                action: #selector(toggleLaunchAtLogin),
                state: LaunchAtLoginManager.isEnabled ? .on : .off
            )
        )

        menu.addItem(NSMenuItem.separator())

        menu.addItem(makeMenuItem(title: "Quit MacRemap", action: #selector(quitApp), keyEquivalent: "q"))

        self.statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func openMappingEditor() {
        MappingEditorWindowController.shared.showWindow()
    }

    @objc private func toggleEventTap() {
        EventTapManager.shared.toggle()
        updateStatusIcon()
        buildMenu()  // Rebuild to update status text
    }

    @objc private func reloadConfig() {
        let success = ConfigManager.shared.loadConfig()
        if success {
            showNotification(title: "MacRemap", body: "Config reloaded — \(ConfigManager.shared.config.mappings.count) mapping(s)")
        } else {
            showNotification(title: "MacRemap", body: "Failed to reload config. Check YAML syntax.")
        }
    }

    @objc private func editConfig() {
        let configPath = ConfigManager.shared.configFilePath
        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
    }

    @objc private func revealConfig() {
        let configPath = ConfigManager.shared.configFilePath
        NSWorkspace.shared.selectFile(configPath, inFileViewerRootedAtPath: "")
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLoginManager.toggle()
        buildMenu()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Helpers

    private func updateStatusIcon() {
        if let button = statusItem.button {
            let symbolName = EventTapManager.shared.isRunning ? "computermouse" : "computermouse.fill"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "MacRemap")
            button.image?.isTemplate = true
        }
    }

    private func makeMenuItem(
        title: String,
        action: Selector? = nil,
        keyEquivalent: String = "",
        state: NSControl.StateValue = .off,
        isEnabled: Bool = true
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = action == nil ? nil : self
        item.state = state
        item.isEnabled = isEnabled
        return item
    }

    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
