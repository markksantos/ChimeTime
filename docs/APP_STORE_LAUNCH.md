# ChimeTime — App Store launch checklist

The in-app purchase is implemented and tested. What follows is everything
between the current repo and a live listing. Items marked **BLOCKER** must be
done before a build can even be uploaded.

---

## 1. Identity (BLOCKER)

Nothing can be signed or uploaded until the bundle ID and Team ID are real.
The placeholders are `com.nosleeplab.chimetime` and an empty `DEVELOPMENT_TEAM`.

```bash
./scripts/set-identity.sh com.yourcompany.chimetime YOURTEAMID
```

That one command updates `Info.plist`, `StoreConfiguration.swift`,
`Products.storekit`, and `project.yml` together, then regenerates the Xcode
project. They must agree — a mismatch between the app's bundle ID and the IAP
product ID is the usual cause of "Cannot connect to iTunes Store".

## 2. Certificates (BLOCKER)

This Mac currently has only an **Apple Development** certificate. Mac App Store
distribution additionally needs:

- **Apple Distribution** (signs the app)
- **Mac Installer Distribution** (signs the `.pkg` that gets uploaded)

Easiest path: Xcode → Settings → Accounts → Manage Certificates → `+`. Then let
automatic signing create the provisioning profile once the App ID exists.

## 3. App icon ✅ DONE

`Resources/Assets.xcassets/AppIcon.appiconset` holds the full macOS icon set
(16–1024px, a golden bell with sound-wave arcs on a navy→teal gradient, squircle
mask baked in). It's wired into `project.yml`
(`ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`) and `Info.plist`
(`CFBundleIconName`), and a Release build compiles it into `Assets.car`. Verified.

To swap in a different icon later: replace the PNGs in the appiconset (keep the
filenames/sizes), then `xcodegen generate`. No other change needed.

## 4. App Store Connect

1. Register the App ID from step 1 in the Developer portal.
2. Create the app record in App Store Connect.
3. Create the in-app purchase:
   - Type: **Non-Consumable**
   - Product ID: **`<your-bundle-id>.pro`** (exactly what `set-identity.sh` printed)
   - Reference name: `ChimeTime Pro`
   - Price: **Tier 5 ($4.99)**
   - Display name + description: reuse the copy in `Products.storekit`
   - Add a review screenshot of the paywall
4. Join the **Small Business Program** if you haven't — it drops Apple's cut
   from 30% to 15% under $1M/year. On a $4.99 unlock that's $4.24 vs $3.49 per
   sale, and it applies to this app either way.

> A new IAP must be submitted **together with the app's first build**. Submitting
> the app alone leaves the purchase in "Waiting for Review" and every buy attempt
> fails.

## 5. Required metadata

The listing copy is written and validated in **`docs/store-listing.md`** (name,
subtitle, promo text, keywords, description, What's New, IAP record, privacy
answers — all within Apple's character limits). Paste it into App Store Connect.

- **Privacy policy URL** — page written at **`docs/legal/privacy.html`**. Fill the
  `[BRACKET]` placeholders (date, email, name), host it anywhere static, paste the
  URL. ChimeTime collects nothing, so the policy is short and true.
- **Support URL** — page written at **`docs/legal/support.html`**. Same deal: fill
  placeholders, host, paste. Includes an FAQ and a contact line.
- **App privacy questionnaire** — answer "Data Not Collected" (details in
  `store-listing.md`).
- **Screenshots** — at least one 1280×800 or 1440×900. Show the notch drop, the
  settings window, and the paywall.

> Both legal pages are self-contained HTML (no external assets, light/dark aware)
> — drop them on GitHub Pages, Netlify, or any static host as-is.

## 6. Testing the purchase before shipping

**Locally**, without App Store Connect — the scheme already points at
`Products.storekit`:

1. Open `ChimeTime.xcodeproj`, Run.
2. The paywall shows a real $4.99 price and purchases complete instantly.
3. Xcode → Debug → StoreKit → Manage Transactions to refund/reset and re-test
   the locked state.

There is also a DEBUG-only override for exercising Pro UI without any store:

```bash
defaults write com.nosleeplab.chimetime chimetime.debugForcePro -bool YES
```

It is compiled out of Release builds, so it cannot be used to bypass the paywall
in a shipped app.

**In sandbox**, after the IAP exists in App Store Connect: create a Sandbox
Apple ID in Users and Access, sign into it in System Settings → Developer, then
run a Release build.

## 7. Archive and upload

```bash
xcodegen generate
xcodebuild -project ChimeTime.xcodeproj -scheme ChimeTime \
    -configuration Release archive -archivePath build/ChimeTime.xcarchive
```

Then Xcode → Window → Organizer → Distribute App → App Store Connect.

---

## What App Review will look at

- **Restore Purchases** exists and works — it's in the paywall and in the About
  tab. Reviewers check for this on every non-consumable.
- **The free tier is genuinely usable.** Hourly chiming, Quiet Hours, and Launch
  at Login are all free. An app that locks its core function behind IAP gets
  rejected under 3.1.1.
- **No mention of external payment** anywhere in the app.
- **The Focus Mode feature was removed**, not hidden. It read preference
  domains the sandbox blocks, so it could never have worked in a shipped build.

## Known gaps, deliberately

- **Custom sound files are copied into the sandbox container.** Existing users
  of a pre-sandbox local build won't see previously imported sounds, since the
  container path changes. Not an issue for a first release.
- **`CFBundleVersion` is `1.0`.** Bump it on every upload; App Store Connect
  rejects a duplicate build number.
