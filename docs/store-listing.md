# ChimeTime — App Store Connect listing copy

Paste-ready metadata for the App Store Connect app record. Character limits are
Apple's; each field is already within budget. Anything in `[BRACKETS]` is yours
to fill.

---

## Name (max 30)

```
ChimeTime
```

## Subtitle (max 30)

```
Hourly chime from the notch
```
*(27 chars)*

## Promotional text (max 170 — editable anytime without review)

```
A gentle chime every hour, dropping right from your Mac's notch. Free forever for the core chime; unlock sounds, schedules, Pomodoro & more with a one-time Pro purchase.
```
*(169 chars)*

## Keywords (max 100, comma-separated — no spaces between)

```
hourly,chime,clock,bell,time,menubar,notch,pomodoro,reminder,announce,speak,timer,focus,productivity
```
*(100/100 — at the limit; recount if you edit)*

## Description (max 4000)

```
ChimeTime marks the passing hour with a gentle chime that drops right from your Mac's notch — a calm, glanceable sense of time without another window to manage.

It lives in your menu bar and stays out of the way. On the hour, a small notch drop appears and a soft chime plays. That's it. No account, no clutter, nothing to learn.

FREE, FOR AS LONG AS YOU USE IT
• Hourly chime with the notch-drop animation
• Speak the time out loud on the hour
• Quiet Hours — silence chosen hours so you're never woken at 3am
• Launch at login
• One-click on/off from the menu bar
• Preview the chime anytime
• Reduce Motion support

The core function is genuinely free. An hourly chimer that can't be silenced isn't one — so Quiet Hours and the master toggle will never cost a cent.

CHIMETIME PRO — ONE-TIME PURCHASE
Unlock every way to make ChimeTime yours. Buy once, own it on every Mac signed into your Apple ID. Not a subscription.

• Appearance — theme, accent color, notch color, size, and display duration
• Chime Sounds — pick from every built-in chime
• Custom Sounds — use your own audio files as the chime
• Custom Schedule — choose exactly which hours chime with a 24-hour grid
• Pomodoro Timer — work/break cycles with notch and sound alerts
• Global Shortcut — toggle chiming from anywhere with a hotkey
• Half-Hour Chime — a lighter chime on the 30-minute mark
• Chime Count — strike once per hour, grandfather-clock style
• Menu Bar Clock — show a live clock instead of the icon
• Chime History — a log of recent chimes
• Multi-Monitor — choose which display the notch drop appears on
• Calendar Quiet Hours — stay silent automatically during meetings

PRIVATE BY DESIGN
ChimeTime collects nothing. No analytics, no tracking, no account. Everything stays on your Mac. The only network call it ever makes is to the App Store, to verify your Pro purchase.

Made by an independent developer. Thank you for supporting small software.
```

## What's New — v1.0.0 (max 4000)

```
First release. A gentle hourly chime that drops from your Mac's notch, free forever — with an optional one-time Pro unlock for sounds, schedules, Pomodoro, and more.
```

---

## App Privacy questionnaire

Answer **Data Not Collected** across the board. ChimeTime has no analytics, makes
no network calls except to StoreKit for purchase verification, and stores all
settings in UserDefaults and its own sandbox container.

- Contact Info: Not Collected
- Identifiers: Not Collected
- Usage Data: Not Collected
- Diagnostics: Not Collected

## In-app purchase record

- Type: **Non-Consumable**
- Reference name: `ChimeTime Pro`
- Product ID: **`<your-bundle-id>.pro`** (exactly what `set-identity.sh` prints)
- Price: **Tier 5 ($4.99)**
- Display name: `ChimeTime Pro`
- Description: `Unlock every sound, schedule, and way to customize ChimeTime. One-time purchase.`
- Review screenshot: the paywall (already captured during development)

> Submit this IAP **with the first build**, not after — otherwise it sits in
> "Waiting for Review" and every purchase attempt fails.

## URLs required by App Store Connect

- **Privacy Policy URL** → host `docs/legal/privacy.html` and paste the URL
- **Support URL** → host `docs/legal/support.html` and paste the URL
- **Marketing URL** (optional) → a landing page if/when you have one

## Screenshots (at least one; 1280×800 or 1440×900)

Show, in order of impact:
1. The notch drop mid-chime
2. The settings window (free tab)
3. The paywall

Capture on a clean desktop, light mode. macOS App Store accepts 16:10 shots.
```
