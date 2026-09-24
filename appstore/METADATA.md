# ChimeTime: Mac App Store metadata

Drafted 2026-09-24 on branch `appstore-kit`, from the source code, `docs/store-listing.md` and a sandboxed test run of the Release build. A script counted every field and fails if any is over Apple's limit. **⚠ MARK'S DECISION** marks a field only Mark can settle.

This replaces `docs/store-listing.md` where the two disagree. That file's IAP description is 80 characters, but the limit is 45. It also says there is "no mention of external payment" in the app, but Settings > About has a **Donate** link (see CHECKLIST).

| Field | Value | Chars / limit |
|---|---|---|
| App name | ChimeTime | 9 / 30 |
| Subtitle | Hourly chime from the notch | 27 / 30 |
| Bundle ID | `com.nosleeplab.chimetime` (from `project.yml`). Its comment calls this a placeholder, and the other apps use `com.markstudios.*` **⚠ MARK'S DECISION** | — |
| Version / build | 1.0.0 (1). Both are hardcoded in `Info.plist` | — |
| SKU | CHIMETIME-MAC-001 (any unique string) | — |
| Primary category | Utilities (matches `LSApplicationCategoryType` in `Info.plist`) | — |
| Secondary category | Productivity **⚠ MARK'S DECISION** (Lifestyle is the other option) | — |
| Price | Free download with one in-app purchase. The $4.99 comes from `Products.storekit`. **⚠ MARK'S DECISION** | — |
| Copyright | 2026 Mark Studios LLC **⚠ MARK'S DECISION**. `Info.plist` has `Copyright © 2026 Mark Santos. MIT Licensed.` | — |
| Support URL | https://nosleeplab.com/support (200; general NoSleepLab page with a contact address) | — |
| Privacy Policy URL | https://nosleeplab.com/privacy (200; general NoSleepLab policy) | — |
| Marketing URL (optional) | https://nosleeplab.com/apps/chimetime (200, but **update it first**, see below) | — |
| Minimum macOS | 13.0. Universal binary: `lipo` on the Release build shows x86_64 + arm64 | — |

## Promotional text (155 / 170)

On the hour, the time drops from the top of your screen and a soft chime plays. The chime is free; Pro is a one-time unlock for sounds, schedules and more.

## Description (1718 / 4000)

```text
ChimeTime gives you a calm sense of time. On the hour, the time drops from the top of your screen (right out of the notch on MacBooks that have one) and a soft chime plays. Then it gets out of the way.

It lives in your menu bar. There's no Dock icon, no window to manage and no account.

FREE
• The hourly chime with the notch-drop panel
• Speak the time out loud on the hour, instead of the chime or as well as it
• Quiet Hours, so it never chimes while you sleep
• Launch at login
• Turn chiming on or off from the menu bar
• Preview the chime at any time
• Follows your Reduce Motion setting

CHIMETIME PRO: ONE-TIME PURCHASE
Pro is a single in-app purchase, not a subscription. Restore it on any Mac signed in with the same Apple Account.
• Appearance: theme, accent colour, panel colour, size and how long it stays
• Chime Sounds: choose any built-in chime
• Custom Sounds: use your own audio file as the chime
• Custom Schedule: pick exactly which hours chime on a 24-hour grid
• Pomodoro Timer: work and break cycles with a panel and a sound at each change
• Global Shortcut: turn chiming on or off from anywhere
• Half-Hour Chime: a lighter chime at half past
• Chime Count: strike once for each hour, like a grandfather clock
• Menu Bar Clock: show a live clock in place of the icon
• Chime History: a list of recent chimes in the menu
• Multi-Monitor: choose which display shows the panel
• Calendar Quiet Hours: stay silent during events on your calendar. ChimeTime asks for calendar access only when you turn this on.

PRIVATE BY DESIGN
ChimeTime collects no data. No analytics, no tracking, no account. Your settings stay on your Mac. The only network traffic is the App Store checking your Pro purchase.
```

Every feature claim was checked against the code:

- Free and Pro match the `effective*` gates in `Core/SettingsManager.swift` and the list in `Purchase/ProFeature.swift`.
- Speak Time, Quiet Hours and Launch at Login are not Pro-gated.
- The panel sits "horizontally centred, flush with the top of the screen" (`Views/Notch/NotchWindow.swift`), so the copy says "top of your screen" rather than promising a notch.
- The old copy said the panel drops "from your Mac's notch", which isn't true on Macs without one.

## Keywords (94 / 100)

```text
hourly,bell,clock,time,menubar,notch,pomodoro,reminder,announce,speak,timer,focus,mindful,tick
```

- No spaces after the commas, and no duplicates.
- `chime` is not repeated, because the App Store already indexes the name.
- No competitor or trademarked names.

## In-app purchase

| Field | Value | Chars / limit |
|---|---|---|
| Type | Non-Consumable | — |
| Product ID | `com.nosleeplab.chimetime.pro` (`Purchase/StoreConfiguration.swift`). It changes with the bundle ID if `scripts/set-identity.sh` is run. | — |
| Reference name | ChimeTime Pro | — |
| Display name | ChimeTime Pro | 13 / 30 |
| Description | Every sound, schedule and style option. | 39 / 45 |
| Price | $4.99 **⚠ MARK'S DECISION** | — |
| Review screenshot | The paywall. It needs a click to open, so it isn't in this kit | — |

Submit the IAP **together with the first build**. If it's submitted afterwards, it sits in "Waiting for Review" and every purchase attempt fails.

## App Review notes (749 / 4000)

```text
ChimeTime is a menu bar app (LSUIElement): it has no Dock icon and no main window. After launch, click the bell icon in the menu bar.

To hear a chime without waiting for the top of the hour, click Preview in that menu. Speak Time can be chosen in Settings > Sound.

In-app purchase: one non-consumable, "ChimeTime Pro" (com.nosleeplab.chimetime.pro). Open it from "Unlock ChimeTime Pro" in the menu. Restore Purchases is on the paywall and in Settings > About.

Calendar access is requested only when the user turns on Calendar Quiet Hours (a Pro feature), and is used only to check whether an event is in progress at the top of the hour. The app makes no network requests of its own; StoreKit handles the purchase. No account or sign-in is needed.
```

## Age rating questionnaire

Every answer is "None" or "No", which gives a **4+** rating. There's no web view, no user-generated content, no messaging, no ads, no gambling and no mature content.

## App Privacy ("nutrition label") draft

**Answer "Data Not Collected"** for every data type. The evidence:

- **No networking of its own.** There's no `URLSession`, socket or HTTP URL in `Sources/` (only `NSWorkspace.open` for the About links).
  - In the sandboxed test run (2026-09-24), the only network connection tied to this app was made by **`storekitagent`** on its behalf. The app process made none.
- **No SDKs or analytics.** The app has no Swift packages and no third-party frameworks.
- **Calendar (Pro, off by default).** Events are read on-device only, to decide whether to stay silent. Nothing is stored or sent, so it isn't "collected" under Apple's definition.
- **Required-reason API:** `UserDefaults` is used, but there is **no `PrivacyInfo.xcprivacy`**. Add one with `NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1` (see CHECKLIST).

## Export compliance

`ITSAppUsesNonExemptEncryption` is already `false` in `Info.plist`, so App Store Connect won't ask on upload.

## URLs (checked with curl, 2026-09-24)

- `https://nosleeplab.com/privacy` returns **200**. It's the general NoSleepLab policy (no analytics, data stays local), and it doesn't name ChimeTime.
- `https://nosleeplab.com/support` returns **200** and has a contact address (Guideline 1.5).
- `https://nosleeplab.com/apps/chimetime` returns **200**, but it says **"Price: Free · Status: Source only · Source: Public on GitHub"** and lists the 24-hour schedule grid as if it were free. That contradicts a store listing with a $4.99 Pro unlock. Update the page before using it as the Marketing URL.
- `docs/legal/privacy.html` and `docs/legal/support.html` are ChimeTime-specific alternatives, but they still have `[BRACKET]` placeholders and aren't hosted anywhere.
- **Dead links inside the app:** `https://nosleeplab.com/donate` returns **404**, and `https://github.com/nosleeplab/ChimeTime/releases` returns **404**.

## Name check

- iTunes Search API (Mac software, US) on 2026-09-24: **no listing containing "ChimeTime"** among 11 results for the term.
- The API only shows published apps. Only creating the App Store Connect record confirms the name is free.

## ⚠ Decisions only Mark can make

- **Bundle ID prefix:** `com.nosleeplab.chimetime` (current) or `com.markstudios.chimetime`, to match the other apps. `scripts/set-identity.sh` changes all four places at once.
- **Price** of Pro ($4.99 in `Products.storekit`) and the secondary category.
- **Open source vs. paid unlock.**
  - `LICENSE` is MIT, `Info.plist` says "MIT Licensed", and the marketing page says the source is public.
  - The Mac App Store allows this, but anyone can build Pro for free from source.
  - Either keep it that way on purpose, or change the licence or visibility before launch.
- **Seller, brand and copyright:** Mark Studios LLC, NoSleepLab or Mark Santos. Use one consistently across the copyright field, the pages and the About screen.
- **Donate and Check for Updates rows:** remove them from the store build (a review rejection, see CHECKLIST). Decide whether a direct-download build keeps them.
