# ChimeTime: Mac App Store checklist

Status on 2026-09-24, branch `appstore-kit`. Nothing has been signed for distribution, uploaded or submitted, and no app source, build setting or icon was changed.

## Ready

- [x] **Sandbox, tested for real.** The Release build was ad-hoc signed **with `ChimeTime.entitlements`** and launched in the background with `open -g`. Before this, it had only passed an unsigned launch test, which has no entitlements.
  - `libsystem_secinit: AppSandbox` fired and the container was created.
  - The menu-bar status-item scene came up.
  - StoreKit 2 ran (`Products_SK2`, `TransactionQuery`, `TransactionUpdateStart`), brokered by `storekitagent`.
  - **One sandbox denial:** `mach-lookup com.apple.cmio.registerassistantservice.system-extensions`. It comes from AVFoundation initialising, the app doesn't use the camera, and it's harmless.
  - No crash report.
  - Evidence is in wiki `clients/_overnight/2026-09-22/MAC-SANDBOX-CHECK-2026-09-24.md`.
- [x] **Build.** Release is clean, a **universal binary** (x86_64 + arm64, checked with `lipo`), minimum macOS **13.0**.
- [x] **Metadata.** `METADATA.md` covers name, subtitle, promo text, description, keywords, IAP record, review notes, age rating (4+), privacy label and URLs. The generator script fails on any field over Apple's limit.
- [x] **Screenshot.** `screenshots/mac-2880x1800/01-notch-drop.png` is 2880×1800 with no alpha channel. Both UI elements are real (see "How the screenshot was made").
- [x] **Icon set.**
  - All 10 macOS slots are filled (16, 32, 128, 256 and 512 pt at 1x and 2x), plus the **1024×1024**.
  - Every PNG is RGBA with **alpha 0 in all four corners**. It's a squircle, not a full-bleed square.
  - The Release `Assets.car` holds all 10 renditions, 16 to 1024 px.
- [x] **In-app purchase code.** StoreKit 2, one non-consumable. The `Transaction.updates` listener and `finish()` are in place, and Restore is on the paywall and in Settings > About.
  - There are **no license keys** and no Gumroad, Paddle or LemonSqueezy code (Guideline 3.1.1).
- [x] **Export compliance.** `ITSAppUsesNonExemptEncryption = false` is already set.
- [x] **No TCC prompt at launch.** Calendar access is requested only when the user turns on Calendar Quiet Hours (Pro, off by default). Launch at Login registers only from its toggle.

## Blocks submission, in order

1. **Apple Distribution certificate.** This Mac has only `Apple Development: Mark Santos`. The Mac App Store needs an **Apple Distribution** cert and a **Mac Installer Distribution** cert. Create them in Xcode → Settings → Accounts → Manage Certificates; it needs Mark's Apple ID.
2. **Identity.** `DEVELOPMENT_TEAM` is empty in `project.yml`, and the bundle ID prefix is Mark's decision (see METADATA). Run `scripts/set-identity.sh <bundle-id> <TEAMID>`. It updates `Info.plist`, `StoreConfiguration.swift`, `Products.storekit` and `project.yml` together, then regenerates the project. The `.xcodeproj` is gitignored.
3. **Remove two About links before review.** Both are in `Sources/ChimeTime/Views/Settings/SettingsView.swift`:
   - [x] ~~Line 874, **"Donate"** → `https://nosleeplab.com/donate`. A payment call-to-action outside IAP in an app that sells IAP is rejected under 3.1.1, and donations are allowed only for approved nonprofits (3.2.1(vi)). The URL also returns **404**.~~ **Removed 2026-09-24** (the whole Support group).
   - [x] ~~Line 866, **"Check for Updates"** → GitHub releases. Mac App Store apps may only update through the App Store (2.4.5(vii)). This URL also returns **404**.~~ **Removed 2026-09-24.**
4. **App Store Connect records.** Create the app record (macOS, English (U.S.), bundle ID, SKU) and the non-consumable IAP. The IAP **must be submitted with the first build**. Its description has to be at most 45 characters; use METADATA.md, because `docs/store-listing.md` has an 80-character one.
5. **IAP review screenshot.** A capture of the paywall. Opening it takes a click, so it isn't in this kit.
6. **Archive and upload** with the release **Xcode 27.0** (27A266a), never a beta: `xcodegen generate`, then Product → Archive → Distribute App → App Store Connect.
7. **Fill in App Store Connect** from METADATA.md: description, keywords, URLs, categories, price, age rating 4+, App Privacy "Data Not Collected", and the screenshot.

## Should fix before review (not upload blockers)

- **Drop `com.apple.security.network.client`.**
  - The entitlements comment says it's for "StoreKit purchase + restore". StoreKit runs out of process, though: in the test run every connection came from `storekitagent`, never from ChimeTime.
  - Nothing in `Sources/` uses `URLSession` or sockets.
  - Dropping it makes the least-privilege story clean. Watchdog's entitlements already leave it out for the same reason, and Watchdog also uses StoreKit 2.
  - Re-test a purchase in the StoreKit sandbox after removing it.
- **Add `PrivacyInfo.xcprivacy`.** The app uses `UserDefaults`, a required-reason API. Declare `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`, set `NSPrivacyTracking` to false, and list no collected types. There's no manifest today.
- [x] ~~**Icon scale.**~~ **Fixed 2026-09-24:** the body was re-scaled to 824 px on the 1024 canvas with a soft shadow, and all 7 files regenerated. The Release build succeeds (universal).
- **Copyright string.** `Info.plist` says `Copyright © 2026 Mark Santos. MIT Licensed.` Align it with the seller name you choose.
- **Marketing page.** `nosleeplab.com/apps/chimetime` says "Free · Source only · Public on GitHub" and presents the 24-hour grid as free. Update it before listing it as the Marketing URL.
- **`CFBundleVersion` is hardcoded to `1` in `Info.plist`.** Bump it on every upload; App Store Connect rejects a duplicate build number.
- **More screenshots.** One is enough to submit. Good extras need a click to reach: the paywall, the Settings window (General and Sound tabs), and the Pomodoro panel.
- **Dead code:** `Views/MenuBar/StatusBarController.swift` is never instantiated. It's harmless.

## Not verified

- **The top-of-hour chime firing inside the sandbox.** The test instance was quit from its own menu at 14:55:50, before the 15:00 chime. The log shows a menu-bar navigation event, then `terminate:`: a clean quit, not a crash. The chime path uses `AVAudioEngine`, `NSSpeechSynthesizer` and a borderless window, which touch nothing sandbox-gated. But it wasn't observed.
- **A real purchase and restore.** That needs the App Store Connect IAP and a sandbox Apple Account.
- **Calendar Quiet Hours and Custom Sounds under the sandbox.** Both are Pro and need a click; custom sounds also need `NSOpenPanel`. The entitlements for them (`personal-information.calendars`, `files.user-selected.read-only`) are present. The picked file is copied into the container inside the panel callback, which is the pattern the sandbox allows.
- **Icon format on macOS 27.** Xcode 27's `actool` puts only 16, 32, 128 and 256 px entries in `AppIcon.icns`; the 512 and 1024 renditions are in `Assets.car`. Every app built this way shows the same thing, so it's toolchain behaviour, but the first upload is what confirms Apple accepts it. Older uploads failed with ITMS-90236 when the `.icns` had no 512/512@2x. Nobody has checked whether an Icon Composer `.icon` is now preferred.
- **Name availability.** No "ChimeTime" listing turned up in the iTunes Search API, but only the App Store Connect record confirms the name.

## How the screenshot was made (to retake it)

1. **Menu panel (right).** A window capture of the **sandboxed, ad-hoc-signed Release build** (bundle ID `com.nosleeplab.chimetime.sbcheck`), taken on 2026-09-24 with `screencapture -x -o -l<windowid>` while its menu-bar panel was open. It reads 2:46 PM, with the next chime at 3:00 PM.
2. **Notch drop (top).** The app's own `NotchDropView`, built from `Sources/ChimeTime`. A small harness links every source file except `ChimeTimeApp.swift` and renders the view offscreen with SwiftUI `ImageRenderer` at 4x. It uses free-tier values (`SettingsManager(entitlement: ProEntitlement(isPro: false))`, `.medium` size, date shown) at 3:00 PM. No window is ever put on screen.
3. **Compose.** Pillow places both on a navy-to-teal gradient sampled from the icon, adds an SF Pro Rounded headline, flattens to RGB and saves at 2880×1800. No UI was drawn by hand.

Method: wiki `concepts/macos-app-launch-test-without-the-screen.md`.
