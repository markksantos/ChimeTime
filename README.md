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
- **Quiet hours** — Configurable suppression window (e.g., 11 PM to 7 AM), wraps midnight correctly.
- **Drift-free scheduling** — Recalculates from the current time after each fire; handles sleep/wake and system clock/timezone changes.
- **Reduce motion support** — Respects the macOS accessibility preference (or an explicit app override), falling back to a fade animation.
- **Launch at login** — Uses `SMAppService` for native login-item management; reconciles the stored preference with the real system state on launch.

### ChimeTime Pro (one-time $4.99 in-app purchase)
- **Appearance** — Theme, accent color, notch background color, notification size, display duration.
- **Chime sounds** — Choose any built-in sound instead of the default.
- **Custom sounds** — Import your own audio files; stored in the app's container.
- **Half-hour chimes** — Optional lighter chime at `:30` with its own sound.
- **Chime count** — Strike the chime once per hour, grandfather-clock style (capped configurably).
- **Custom schedule** — The interactive 24-hour grid for enabling/disabling specific hours.
- **Global hotkey** — Toggle chiming on/off with a configurable keyboard shortcut.
- **Pomodoro timer** — Built-in work/break cycle with notch + sound notifications, driven from the menu bar.
- **Menu bar clock** — Live clock in the menu bar instead of the icon.
- **Chime history** — Optional log of recent chimes shown in the menu bar.
- **Multi-monitor** — Choose which display the notch drop appears on.
- **Calendar quiet hours** — Suppress chimes during busy calendar events (EventKit).

The free tier is deliberately complete on its own: hourly chiming, the master
toggle, preview, Quiet Hours, Launch at Login, spoken time, and Reduce Motion
all work without paying. Accessibility settings are never gated.

Purchases use StoreKit 2 with no server — entitlement comes from
`Transaction.currentEntitlements`, so it survives reinstalls and works offline.

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
swift test   # 32 tests across scheduling, audio, notch, UI logic, and Pro gating
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
| Purchases | StoreKit 2 (non-consumable, no server) |
| Hotkeys | Carbon `RegisterEventHotKey` (sandbox-safe) |
| Persistence | UserDefaults |
| Target | macOS 13.0+ |
| Build | Swift Package Manager (dev) · XcodeGen → Xcode (App Store) |

## 📁 Project Structure

```
ChimeTime/
├── Sources/ChimeTime/
│   ├── App/            # @main entry point + AppDelegate (wires everything)
│   ├── Core/           # Scheduler, settings + Pro gating, login item,
│   │                   #   calendar/hotkey monitors, pomodoro, history
│   ├── Purchase/       # StoreKit 2 store, entitlement, feature catalog
│   ├── Audio/          # Chime synthesis, spoken time, custom sound manager
│   └── Views/
│       ├── Notch/      # Borderless overlay window + 3-phase drop animation
│       ├── Components/ # Time display, notch shape
│       ├── MenuBar/    # Status item + popover + clock label
│       ├── Purchase/   # Paywall + locked-section wrapper
│       └── Settings/   # Multi-tab settings window
├── Tests/ChimeTimeTests/
├── docs/APP_STORE_LAUNCH.md  # Remaining steps to ship
├── scripts/build-app.sh      # Local dev .app bundle (SwiftPM)
├── scripts/set-identity.sh   # Set bundle ID / product ID / Team ID everywhere
├── project.yml               # XcodeGen spec for the App Store build
├── Products.storekit         # Local StoreKit testing config
├── ChimeTime.entitlements    # App Sandbox + StoreKit + files + calendars
├── Info.plist                # Canonical bundle metadata
└── Package.swift
```

## 📦 Distribution

ChimeTime ships through the **Mac App Store**, which requires the Xcode project
(SwiftPM alone cannot archive, sign, or upload) and mandates the App Sandbox.

```bash
brew install xcodegen                                   # once
./scripts/set-identity.sh com.yourco.chimetime TEAMID   # set real identity
xcodegen generate                                       # produce ChimeTime.xcodeproj
open ChimeTime.xcodeproj                                # Run uses Products.storekit
```

Full step-by-step, including certificates, App Store Connect setup, and the
remaining blockers, is in **[docs/APP_STORE_LAUNCH.md](docs/APP_STORE_LAUNCH.md)**.

`scripts/build-app.sh` still produces an ad-hoc signed `.app` for quick local
development, but it is not a distribution path.

## 📄 License

MIT License © 2026 No Sleep Lab — see [LICENSE](LICENSE).
