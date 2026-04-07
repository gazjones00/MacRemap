import ServiceManagement

// MARK: - Launch at Login

enum LaunchAtLoginManager {
    private static var service: SMAppService {
        .mainApp
    }

    static var isEnabled: Bool {
        guard #available(macOS 13.0, *) else { return false }
        return service.status == .enabled
    }

    static func toggle() {
        guard #available(macOS 13.0, *) else { return }

        do {
            if isEnabled {
                try service.unregister()
                print("[MacRemap] Removed from login items")
            } else {
                try service.register()
                print("[MacRemap] Added to login items")
            }
        } catch {
            print("[MacRemap] Launch-at-login toggle failed: \(error)")
        }
    }
}
