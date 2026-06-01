<div align="center">

# 🔔 ChimeTime

A native macOS menu bar app that drops a beautiful time notification from the MacBook notch every hour.

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-0071E3?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/swiftui/)
[![macOS](https://img.shields.io/badge/macOS-13.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

[Features](#-features) · [Getting Started](#-getting-started) · [Tech Stack](#️-tech-stack) · [Project Structure](#-project-structure) · [License](#-license)

</div>

---

## ✨ Features

### Core
- **Notch drop-down animation** — A smooth spring-animated panel slides down from the MacBook notch showing the current time, holds for a configurable duration, then retracts back up. Click to dismiss early.
- **Menu bar popover** — Clean popover with current time, master toggle, next-chime countdown, and an instant preview button. Optional live clock label in the menu bar.
- **Programmatic chime sounds** — Four built-in sounds (gentle bell, tick, wood block, silent) generated with AVAudioEngine — zero bundled audio files.
- **Spoken time** — Optional natural speech ("It's 2 PM") using `NSSpeechSynthesizer` after each chime.
- **Per-hour scheduling** — Interactive 24-hour grid to enable/disable specific hours, plus quick presets (Work Hours, Waking Hours, All Hours).
- **Quiet hours** — Configurable suppression window (e.g., 11 PM to 7 AM), wraps midnight correctly.
- **Drift-free scheduling** — Recalculates from the current time after each fire; handles sleep/wake and system clock/timezone changes.
- **Reduce motion support** — Respects the macOS accessibility preference (or an explicit app override), falling back to a fade animation.
- **Launch at login** — Uses `SMAppService` for native login-item management; reconciles the stored preference with the real system state on launch.

### Advanced
- **Half-hour chimes** — Optional lighter chime at `:30` with its own sound.
- **Chime count** — Strike the chime once per hour, grandfather-clock style (capped configurably).
- **Custom sounds** — Import your own audio files; stored in Application Support.
- **Focus / Do-Not-Disturb integration** — Suppress chimes while a macOS Focus mode is active.
- **Calendar quiet hours** — Suppress chimes during busy calendar events (EventKit).
- **Global hotkey** — Toggle chiming on/off with a configurable keyboard shortcut.
- **Multi-monitor** — Choose which display the notch drop appears on.
- **Pomodoro timer** — Built-in work/break cycle with notch + sound notifications, driven from the menu bar.
- **Chime history** — Optional log of recent chimes shown in the menu bar.
- **Zero third-party dependencies** — Built entirely with Apple frameworks.

## 🚀 Getting Started

### Prerequisites

- macOS 13.0+ (Ventura)
- Xcode 15.0+ / Swift 5.9+ toolchain

### Build & run

```bash
git clone https://github.com/nosleeplab/ChimeTime.git
cd ChimeTime

# Build a proper menu-bar .app bundle (ad-hoc signed for local use):
./scripts/build-app.sh            # debug
./scripts/build-app.sh --release  # optimized

open ChimeTime.app
```

The app runs as a menu-bar agent (`LSUIElement` — no Dock icon). Look for the
clock icon in the right side of the menu bar.

### Plain `swift build`

```bash
swift build              # compiles the executable (Info.plist is embedded via linker flags)
swift run                # runs the bare binary (no .app bundle)
```

> Some features need the full `.app` bundle to behave correctly: **Launch at
> Login** (`SMAppService` requires a registered bundle) and **Calendar Quiet
> Hours** (the EventKit usage prompt reads the bundle's `Info.plist`). Use
> `scripts/build-app.sh` for those.

### Testing

```bash
swift test   # 22 tests across scheduling, audio, notch, and UI logic
```

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Swift 5.9 |
| UI Framework | SwiftUI + AppKit (`NSWindow`, `NSStatusItem`) |
| Audio | AVAudioEngine (programmatic synthesis) |
| Speech | NSSpeechSynthesizer |
| Calendar | EventKit |
| Login Items | SMAppService (ServiceManagement) |
| Persistence | UserDefaults |
| Target | macOS 13.0+ |
| Build | Swift Package Manager |

## 📁 Project Structure

```
ChimeTime/
├── Sources/ChimeTime/
│   ├── App/            # @main entry point + AppDelegate (wires everything)
│   ├── Core/           # Scheduler, settings, login item, focus/calendar/hotkey
│   │                   #   monitors, pomodoro, chime history, screen selector
│   ├── Audio/          # Chime synthesis, spoken time, custom sound manager
│   └── Views/
│       ├── Notch/      # Borderless overlay window + 3-phase drop animation
│       ├── Components/ # Time display, notch shape
│       ├── MenuBar/    # Status item + popover + clock label
│       └── Settings/   # Multi-tab settings window
├── Tests/ChimeTimeTests/
├── scripts/build-app.sh   # Builds and signs ChimeTime.app
├── Info.plist             # Canonical bundle metadata (embedded + copied into .app)
└── Package.swift
```

## 📦 Distribution

The build script ad-hoc signs the app so it runs on the build machine. For
sharing the app you must sign it with a Developer ID identity and notarize it:

```bash
# 1. Build a release app
./scripts/build-app.sh --release

# 2. Sign with a Developer ID Application identity + hardened runtime
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: <Your Name> (<TEAMID>)" ChimeTime.app

# 3. Zip and notarize
ditto -c -k --keepParent ChimeTime.app ChimeTime.zip
xcrun notarytool submit ChimeTime.zip --keychain-profile "<profile>" --wait
xcrun stapler staple ChimeTime.app
```

Code signing requires an Apple Developer account — see **NEEDS FROM MARK** in
the worklog.

## 📄 License

MIT License © 2026 No Sleep Lab — see [LICENSE](LICENSE).
