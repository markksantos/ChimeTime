# ChimeTime — Overnight Worklog

## What it is

A native macOS menu bar app (Swift 5.9 / SwiftUI / AppKit, macOS 13+, Swift
Package Manager) that drops a notch-style animated time notification from the
top of the screen every hour — like a grandfather clock that registers without
breaking flow. It runs as a menu-bar agent (`LSUIElement`, no Dock icon) with a
popover (current time, master toggle, next-chime countdown, preview), a
multi-tab settings window, programmatic chime sounds (AVAudioEngine, zero
bundled audio), optional spoken time (`NSSpeechSynthesizer`), per-hour
scheduling, quiet hours, and drift-free hourly scheduling that survives
sleep/wake and clock changes.

Beyond the core, it ships **10 advanced features**, all implemented and wired:
half-hour chimes, chime-count striking, custom imported sounds, Focus/DND
suppression, calendar-busy suppression (EventKit), a global toggle hotkey,
multi-monitor display selection, a Pomodoro timer, chime history, and an
optional live menu-bar clock label.

Brand: **No Sleep Lab** (nosleeplab.com), per the in-app About tab.

## Starting state (honest starting completeness: ~78%)

The triage hint said 75% with `progress.txt` claiming "DONE / all 22 tests
passing". Reality on inspection:

- **It already built clean and 22/22 tests passed** — the core was genuinely
  far along (27 Swift source files, ~3,170 LOC, zero third-party deps, no TODOs
  / FIXMEs / stubs / mocks anywhere).
- But several things were **broken or unfinished for real production use**:
  1. **Launch at Login was a no-op.** `LoginItemManager` (SMAppService) was
     fully implemented and a toggle existed in Settings, but the manager was
     **never instantiated or called** in `AppDelegate` — toggling it only wrote
     a UserDefault. Dead feature.
  2. **Calendar Quiet Hours would crash the app.** `CalendarMonitor` calls
     `EKEventStore.requestFullAccessToEvents`, but neither `Info.plist` had
     `NSCalendarsUsageDescription` / `NSCalendarsFullAccessUsageDescription` —
     guaranteed crash the moment a user enabled that feature.
  3. **Info.plist was not bundled into the build.** `Package.swift` shipped no
     bundle metadata into the executable, and the README's run instructions
     pointed at a `Sources/ChimeTime/Resources/Info.plist` path that did not
     exist. There were two divergent `Info.plist` files (root vs. app bundle).
  4. **`Resources/Assets.xcassets` was an empty, invalid directory** declared
     as a processed resource — it produced a junk resource bundle and broke
     `codesign` on the `.app`.
  5. **`MenuBarClockLabel` was non-reactive** — it received snapshot values, so
     toggling the menu-bar clock setting did nothing until an app restart.
  6. **Pomodoro kept running** if you disabled the feature mid-cycle.
  7. **`.gitignore` did not exclude** the committed `ChimeTime.app` binary;
     `progress.txt` / `tests.json` were stale orchestration artifacts that
     misrepresented state; no LICENSE despite MIT claims; no git repo.

## What I changed, fixed, added, built

All changes are inside `/Users/markksantos/Developer/ChimeTime`.

### Bug fixes
- **Wired `LoginItemManager` into the app** —
  `Sources/ChimeTime/App/AppDelegate.swift`: added a `loginItemManager`
  instance, reconciled the stored `launchAtLogin` preference with the real
  `SMAppService.mainApp.status` on launch, and subscribed to
  `settingsManager.$launchAtLogin` so toggling actually
  registers/unregisters the login item.
- **Made `MenuBarClockLabel` reactive** —
  `Sources/ChimeTime/Views/MenuBar/MenuBarClockLabel.swift` now takes
  `@ObservedObject appState` + `settings` instead of static values; updated the
  call site in `Sources/ChimeTime/App/ChimeTimeApp.swift`.
- **Pomodoro stops when disabled** — `AppDelegate.swift` subscribes to
  `settingsManager.$pomodoroEnabled` and stops a running timer when the feature
  is turned off.

### Production hardening
- **Info.plist usage descriptions** — `Info.plist` now contains
  `NSCalendarsUsageDescription` and `NSCalendarsFullAccessUsageDescription`
  (prevents the EventKit crash), plus `CFBundleExecutable`, `NSPrincipalClass`,
  `NSHighResolutionCapable`, `CFBundleDisplayName`, and copyright. This is now
  the single canonical Info.plist.
- **Embedded Info.plist into the binary** — `Package.swift` adds linker flags
  (`-sectcreate __TEXT __info_plist Info.plist`) so the bundle identifier,
  usage strings, and `LSUIElement` are present even for the bare `swift run`
  binary. Verified the `__info_plist` section parses and contains
  `com.chimetime.app` + the calendar usage string.
- **Removed the empty/broken `Assets.xcassets`** and its `resources:` entry in
  `Package.swift` — this was producing an invalid resource bundle that broke
  `codesign`. (The asset catalog had no `Contents.json` and no images; nothing
  referenced `Bundle.module`. The build script will pick up
  `Resources/AppIcon.icns` automatically once an icon is added.)

### Build & packaging
- **`scripts/build-app.sh`** (new) — builds the package (`--release`
  supported), assembles a proper `ChimeTime.app` (Contents/MacOS + canonical
  Info.plist), optionally bundles `Resources/AppIcon.icns`, and ad-hoc signs so
  it runs locally. Produces a `codesign --verify`-clean bundle.

### Repo hygiene / docs
- **Rewrote `README.md`** to match reality: all 10 advanced features, correct
  build/run instructions via the script, a `swift build`/`swift run` note about
  which features need the full bundle, a tech-stack table, and a full
  sign+notarize distribution recipe.
- **Added `LICENSE`** (MIT, No Sleep Lab, 2026).
- **Hardened `.gitignore`** — ignores `.build/`, `ChimeTime.app/`, `*.dmg`,
  `*.zip`, `.DS_Store`, and signing secrets (`*.pem`, `*.p12`, `*.cer`,
  `*.mobileprovision`, `ExportOptions*.plist`).
- **Removed stale `progress.txt`** and `.DS_Store`; updated `tests.json`
  statuses to `passing`.
- **Initialized git** and committed the cleaned, working baseline (no secrets,
  no build artifacts staged). Verified staging excludes `.build/`,
  `ChimeTime.app/`, and `.claude/settings.local.json`.

## Current state

- **Builds?** Yes. `swift build` and `swift build -c release` complete with
  **zero warnings, zero errors**.
- **Runs?** Yes. `scripts/build-app.sh --release` produces a `codesign
  --verify`-valid `ChimeTime.app`. Launched it (`open ChimeTime.app`) — it
  started as a menu-bar agent (PID confirmed alive), ran stable with **no crash
  report**, and terminated cleanly.
- **Tests?** **22/22 passing** (NotchTests, SchedulerTests, AudioTests,
  UITests) across scheduling, audio, notch geometry, and UI logic.

## How to run it locally

```bash
cd /Users/markksantos/Developer/ChimeTime

# Build the menu-bar .app bundle (ad-hoc signed for local use):
./scripts/build-app.sh --release
open ChimeTime.app          # look for the clock icon in the menu bar

# Or run the bare binary (some features need the full bundle):
swift run

# Tests:
swift test
```

## How to deploy (when ready)

This is a desktop app — "deploy" means signed distribution, not a server.
**Do NOT distribute with the ad-hoc signature** the script applies; that only
runs on the build machine.

1. `./scripts/build-app.sh --release`
2. Sign with a Developer ID identity + hardened runtime:
   ```bash
   codesign --force --options runtime --timestamp \
     --sign "Developer ID Application: <Name> (<TEAMID>)" ChimeTime.app
   ```
3. Notarize:
   ```bash
   ditto -c -k --keepParent ChimeTime.app ChimeTime.zip
   xcrun notarytool submit ChimeTime.zip --keychain-profile "<profile>" --wait
   xcrun stapler staple ChimeTime.app
   ```
4. Distribute the stapled `.app` (in a DMG/zip) or submit to the Mac App Store
   (MAS adds App Sandbox + entitlement requirements — see below).

## NEEDS FROM MARK

1. **Apple Developer account credentials** — required to code-sign (Developer
   ID Application) and notarize for distribution. The current build is ad-hoc
   signed (local-only).
2. **Distribution channel decision** — DMG download (Developer ID + notarize),
   TestFlight, or Mac App Store. MAS would additionally require an App Sandbox
   entitlements file and review of the EventKit/global-hotkey usage (a global
   `NSEvent` key monitor is generally not allowed under the App Sandbox, so MAS
   would mean dropping or reworking the global-hotkey feature). DMG/Developer ID
   is the path of least resistance and keeps all features.
3. **App icon (optional but recommended)** — there is currently no app icon
   (the empty asset catalog was removed). Drop an `AppIcon.icns` into
   `Resources/` and `build-app.sh` will bundle it; the About tab and Dock/
   notifications will then show it.
4. **About-tab / repo URLs** — the About tab points at `nosleeplab.com` and
   `github.com/nosleeplab/ChimeTime`. Confirm these are the intended public
   URLs before publishing (the GitHub repo doesn't exist yet).

## Honest completeness now: ~92%

Everything builds, runs, signs (ad-hoc), and passes tests; every advertised
feature is implemented and now actually wired. The remaining ~8% is the part
that genuinely requires Mark's decisions/assets and cannot be done unattended:

- Real Developer ID code signing + notarization (needs Apple account).
- App icon asset.
- Distribution-channel decision (and, if MAS, App Sandbox entitlements +
  reworking the global hotkey).
- Optionally: a couple of the advanced features (Focus/DND detection reads
  private-ish `com.apple.*` defaults and is best-effort; it works but may need
  adjustment across macOS releases) could get integration tests, and
  `ChimeSoundPlayer.playRepeated` holds only the last AVAudioEngine reference
  (works in practice via closure capture, but could be made more robust).

## QA Verification

Performed by independent QA reviewer (Claude Sonnet 4.6), 2026-06-01.

### Commands run

```bash
swift build                  # debug build
swift build -c release       # release build
swift test                   # full test suite
./scripts/build-app.sh       # assemble .app bundle
codesign --verify --verbose ChimeTime.app
otool -l .build/debug/ChimeTime | grep -A4 __info_plist
```

### Real results

- `swift build` (debug): Build complete, zero warnings, zero errors. Confirmed.
- `swift build -c release`: Build complete, zero warnings, zero errors. Confirmed.
- `swift test`: 22/22 tests passed across AAA_TestSetup, AudioTests, NotchTests, SchedulerTests, UITests. Confirmed.
- `./scripts/build-app.sh`: Assembled ChimeTime.app bundle correctly.
- `codesign --verify --verbose ChimeTime.app`: "valid on disk", "satisfies its Designated Requirement". Ad-hoc signature confirmed valid.
- `otool -l`: `__info_plist` section present in binary at `__TEXT` segment, size 0x5a5 — Info.plist embedded via linker flags as claimed.

### Claimed fixes verified

- **LoginItemManager wired**: AppDelegate.swift instantiates `loginItemManager`, reconciles stored preference on launch, and subscribes to `settingsManager.$launchAtLogin`. Confirmed.
- **NSCalendarsUsageDescription in Info.plist**: Both `NSCalendarsUsageDescription` and `NSCalendarsFullAccessUsageDescription` present. Confirmed.
- **Info.plist bundled in binary**: `__TEXT/__info_plist` section verified via otool. Confirmed.
- **Assets.xcassets removed**: No `.xcassets` directory or `resources:` entry found in Package.swift. Confirmed.
- **MenuBarClockLabel reactive**: Takes `@ObservedObject appState` and `@ObservedObject settings`; call site in ChimeTimeApp.swift passes live references. Confirmed.
- **Pomodoro stops on disable**: AppDelegate subscribes to `settingsManager.$pomodoroEnabled` and calls `pomodoroTimer?.stop()` when toggled off. Confirmed.
- **Git initialized, clean tree**: 2 commits, working tree clean; all build artifacts excluded by .gitignore. Confirmed.
- **LICENSE (MIT)**: Present, No Sleep Lab copyright. Confirmed.

### Discrepancies found

None material. One minor observation: the git repository has only 2 commits (initial commit adding all 39 files + worklog commit). This is consistent with the worklog's statement that git was initialized from scratch by the overnight agent — the pre-existing source was not tracked in version control before this run.

### No fixes applied

Build and tests passed clean on first attempt. No build-breaking issues found. No commits made by QA reviewer.

### Remaining issues (confirming worklog's list)

- Ad-hoc signature only — requires Apple Developer ID for distribution.
- No app icon (AppIcon.icns missing).
- Distribution channel decision pending.
- About-tab URLs (nosleeplab.com, github.com/nosleeplab/ChimeTime) unverified.
