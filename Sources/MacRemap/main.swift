import Cocoa

// MARK: - Application Entry Point

// We run as an NSApplication without a main window (menu-bar only / agent app).
// Set LSUIElement = true in Info.plist to hide from the Dock.

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // No dock icon

// Initialize config (loads from ~/.config/macremap/config.yaml)
_ = ConfigManager.shared

// Set up the menu bar
let menuBar = MenuBarController()
menuBar.setup()

// Start the event tap
EventTapManager.shared.start()

// Run the app
app.run()
