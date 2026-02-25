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

- **Notch drop-down animation** — A smooth spring-animated panel slides down from the MacBook notch showing the current time, holds for a configurable duration, then retracts back up
- **Hourly awareness without interruption** — Like a grandfather clock's chime, the notification is noticeable enough to register but not intrusive enough to break flow
- **Menu bar popover** — Clean popover with current time, master toggle, next chime countdown, and instant preview button
- **Programmatic chime sounds** — Four built-in sounds (gentle bell, tick, wood block, silent) generated with AVAudioEngine — zero bundled audio files
- **Spoken time** — Optional natural speech ("It's 2 PM") using NSSpeechSynthesizer after each chime
- **Per-hour scheduling** — Interactive 24-hour grid to enable/disable specific hours, plus quick presets (Work Hours, Waking Hours, All Hours)
- **Quiet hours** — Configurable suppression window (e.g., 11 PM to 7 AM)
- **Drift-free scheduling** — Recalculates from current time after each fire, handles sleep/wake and timezone changes
- **Reduce motion support** — Automatically respects macOS accessibility preference, falls back to fade animation
- **Launch at login** — Uses SMAppService for native login item management
- **Zero dependencies** — Built entirely with Apple frameworks, no third-party packages

## 🚀 Getting Started

### Prerequisites

- macOS 13.0+ (Ventura)
- Xcode 15.0+
- Swift 5.9+

### Installation

```bash
git clone https://github.com/markksantos/ChimeTime.git
cd ChimeTime
swift build
```

### Running

```bash
# Create app bundle and launch
mkdir -p ChimeTime.app/Contents/MacOS
cp .build/debug/ChimeTime ChimeTime.app/Contents/MacOS/ChimeTime
cp Sources/ChimeTime/Resources/Info.plist ChimeTime.app/Contents/Info.plist
open ChimeTime.app
```

### Testing

```bash
swift test
```

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| Window Management | AppKit (NSWindow, NSPanel) |
| Audio | AVAudioEngine (programmatic synthesis) |
| Speech | NSSpeechSynthesizer |
| Login Items | SMAppService (ServiceManagement) |
| Persistence | UserDefaults |
| Target | macOS 13.0+ |

## 📁 Project Structure

```
ChimeTime/
├── Sources/ChimeTime/
│   ├── App/
│   │   ├── ChimeTimeApp.swift          # @main entry point with MenuBarExtra
│   │   └── AppDelegate.swift            # Wires scheduler, audio, and animation
│   ├── Core/
│   │   ├── AppState.swift               # Central ObservableObject + shared enums
│   │   ├── SettingsManager.swift        # UserDefaults-backed preferences
│   │   ├── HourlyScheduler.swift        # Drift-free hourly timer with sleep/wake handling
│   │   └── LoginItemManager.swift       # SMAppService launch-at-login toggle
│   ├── Audio/
│   │   ├── ChimeSoundPlayer.swift       # Programmatic sound generation via AVAudioEngine
│   │   └── TimeSpeaker.swift            # Natural time speech via NSSpeechSynthesizer
│   ├── Views/
│   │   ├── Notch/
│   │   │   ├── NotchWindow.swift        # Borderless transparent overlay window
│   │   │   ├── NotchDropView.swift      # Dark translucent time display panel
│   │   │   └── NotchAnimator.swift      # 3-phase spring animation controller
│   │   ├── Components/
│   │   │   ├── TimeDisplay.swift        # Reusable time formatting component
│   │   │   └── NotchShape.swift         # Custom shape with flat top, rounded bottom
│   │   ├── MenuBar/
│   │   │   ├── MenuBarIcon.swift        # Menu bar popover with controls
│   │   │   └── StatusBarController.swift # NSStatusItem lifecycle manager
│   │   └── Settings/
│   │       ├── SettingsView.swift       # 4-tab settings window
│   │       ├── HourGridView.swift       # Interactive 24-hour toggle grid
│   │       ├── DurationSlider.swift     # Snapping slider with value label
│   │       └── SoundPreviewRow.swift    # Sound picker row with preview
│   └── Resources/
│       └── Info.plist
├── Tests/ChimeTimeTests/
│   ├── NotchTests.swift                 # Window positioning, animation, shape tests
│   ├── SchedulerTests.swift             # Hour calculation, quiet hours, persistence tests
│   ├── AudioTests.swift                 # Sound variants, speech phrasing, login item tests
│   └── UITests.swift                    # Popover, settings, hour grid, preset tests
└── Package.swift
```

## 📄 License

MIT License © 2025 Mark Santos
