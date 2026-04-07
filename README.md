# MacRemap

A lightweight macOS menu bar app that remaps mouse buttons and keyboard keys to custom actions. Runs in the background, configured via a simple YAML file.

## Features

- Remap mouse buttons (back, forward, middle click, etc.) to system actions or key combos
- Remap keyboard keys with modifier support
- Built-in system actions: Mission Control, App Expose, Launchpad, Show Desktop
- Simulate arbitrary key combinations
- Run shell commands on trigger
- Menu bar icon with enable/disable toggle
- Launch at login support
- YAML config file — edit with any text editor

## Installation

### Download

1. Go to [Releases](../../releases) and download the latest `MacRemap.zip`
2. Unzip and move `MacRemap.app` to `/Applications`
3. Open the app — you may see a Gatekeeper warning since the app is not notarized

**Gatekeeper warning:** Right-click the app and select **Open**, then click **Open** in the dialog. You only need to do this once. Alternatively, run:

```bash
xattr -cr /Applications/MacRemap.app
```

### Build from Source

Requires macOS 13+ and Swift 5.9+ (Xcode 15+).

```bash
git clone https://github.com/gazjones00/MacRemap.git
cd MacRemap
make app
```

The app bundle is created at `.dist/MacRemap.app`. To install to `/Applications`:

```bash
make install
```

## Setup

1. Launch MacRemap
2. Grant **Accessibility** permission when prompted (see [Accessibility Permission](#accessibility-permission) below)
3. The app appears as a mouse icon in your menu bar
4. A default config is created at `~/.config/macremap/config.yaml`

## Configuration

### Config location

```
~/.config/macremap/config.yaml
```

A default config is created on first launch. Edit it with any text editor, then use **Reload Config** from the menu bar to apply changes.

### Config format

```yaml
mappings:
  # Remap mouse button to a system action
  - trigger:
      mouse_button: 4
    action:
      mission_control: true

  # Remap mouse button to a key combo
  - trigger:
      mouse_button: 5
    action:
      key_combo:
        key: 49                            # macOS virtual key code (49 = Space)
        modifiers: [shift, command, option]

  # Remap a keyboard shortcut to a shell command
  - trigger:
      key: 1                               # Key code for 'S'
      modifiers: [command, shift]
    action:
      shell: "echo 'hello' > /tmp/test.txt"
```

### Trigger types

| Field | Description |
|-------|-------------|
| `mouse_button` | Mouse button number (1=left, 2=right, 3=middle, 4=back, 5=forward) |
| `key` | macOS virtual key code (decimal) |
| `modifiers` | Optional list of modifier keys to require |

### Action types

| Action | Description |
|--------|-------------|
| `mission_control: true` | Open Mission Control |
| `app_expose: true` | Open App Expose |
| `launchpad: true` | Open Launchpad |
| `show_desktop: true` | Show Desktop |
| `key_combo: {key, modifiers}` | Simulate a key press |
| `shell: "command"` | Run a shell command |

### Modifier names

Use any of: `shift`, `control` / `ctrl`, `option` / `alt`, `command` / `cmd`

### Common key codes

| Code | Key | Code | Key |
|------|-----|------|-----|
| 0 | A | 49 | Space |
| 1 | S | 36 | Return |
| 2 | D | 53 | Escape |
| 3 | F | 48 | Tab |
| 12 | Q | 51 | Delete |
| 13 | W | 123 | Left Arrow |
| 14 | E | 124 | Right Arrow |
| 15 | R | 125 | Down Arrow |

### Example configurations

**Mouse back button opens Mission Control:**

```yaml
- trigger:
    mouse_button: 4
  action:
    mission_control: true
```

**Mouse forward button triggers a keyboard shortcut:**

```yaml
- trigger:
    mouse_button: 5
  action:
    key_combo:
      key: 49
      modifiers: [shift, command, option]
```

**Keyboard shortcut runs a shell command:**

```yaml
- trigger:
    key: 1
    modifiers: [command, shift]
  action:
    shell: "open -a Safari"
```

## Menu Bar

Click the mouse icon in the menu bar to:

- See current status (Active / Inactive)
- Toggle enable / disable
- Reload config after editing
- Open config file in your default editor
- Reveal config in Finder
- Toggle launch at login
- Quit

## Accessibility Permission

MacRemap uses a CGEvent tap to intercept input events. macOS requires you to grant Accessibility permission:

1. Open **System Settings > Privacy & Security > Accessibility**
2. Click the **+** button
3. Navigate to `MacRemap.app` (in `/Applications` or wherever you placed it)
4. Ensure the toggle is **on**

The app will print an error message to the console if this permission is missing.

> **Note:** If you update or move the app, you may need to re-grant Accessibility permission.

## Development

```bash
# Debug build + run (attached to Terminal)
swift build
swift run

# Release build
swift build -c release

# Build .app bundle
make app

# Clean build artifacts
make clean
```

### Commit conventions

This project uses [Conventional Commits](https://www.conventionalcommits.org/) and [release-please](https://github.com/googleapis/release-please) for automatic semantic versioning.

Prefix your commit messages:

| Prefix | Version bump | Example |
|--------|-------------|---------|
| `feat:` | Minor (1.0.0 → 1.1.0) | `feat: add volume control action` |
| `fix:` | Patch (1.0.0 → 1.0.1) | `fix: handle missing config directory` |
| `feat!:` or `BREAKING CHANGE:` | Major (1.0.0 → 2.0.0) | `feat!: change config format` |
| `docs:`, `chore:`, etc. | No release | `docs: update README` |

When commits land on `main`, release-please opens a Release PR. Merging it tags the release and publishes the `.app` bundle to GitHub Releases.

### Project structure

| File | Description |
|------|-------------|
| `Sources/MacRemap/main.swift` | Application entry point |
| `Sources/MacRemap/MenuBarApp.swift` | Menu bar UI |
| `Sources/MacRemap/Config.swift` | YAML config loading |
| `Sources/MacRemap/EventTap.swift` | CGEvent interception |
| `Sources/MacRemap/InputMapping.swift` | Event matching and routing |
| `Sources/MacRemap/ActionExecutor.swift` | Action execution |
| `Sources/MacRemap/LaunchAtLogin.swift` | Login item management |

## License

MIT — see [LICENSE](LICENSE) for details.
