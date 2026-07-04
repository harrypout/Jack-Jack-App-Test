# Handoff: Jack Jack App — DS Compliance Redesign (Onboarding + 4 screens)

## Overview
This package covers a design-system compliance pass over the Jack Jack mobile app plus a
refreshed onboarding flow. Two design references are included:

1. **Onboarding — before & after** (`onboarding.html`): the shipped 3-page onboarding is
   replaced with warm, product-specific copy and live in-brand previews of the *current*
   Pebble screens (the old flow baked in stale screenshots `onboarding0–2.png` of a
   previous app version).
2. **App screens — DS compliance audit** (`app-audit.html`): the four core screens —
   **Home**, **Connect Device**, **Manual Monitoring**, **Settings** — rebuilt to the
   design system's tokens. Structure and functionality are unchanged; every change is
   cosmetic. Includes a **Current ↔ Colour-diverse** toggle demonstrating five optional
   colour treatments.

## About the Design Files
The files in this bundle are **design references authored in HTML/React** — prototypes that
show the intended look and behaviour. They are **not** production code to copy directly.

The target codebase is a **Flutter app** (Dart; the source is `harrypout/Jack-Jack-App-Test`).
The task is to **recreate these designs in the existing Flutter app**, reusing its established
widget structure (`lib/screens/**`, `lib/widgets/**`) and its `ColorManager` / `ThemeManager`
utilities. Do not port the HTML/CSS; translate the tokens and layouts below into Flutter
`ThemeData`, `TextStyle`s, and widgets.

## Fidelity
**High-fidelity.** Final colours, typography, spacing, radii, and interactions. Recreate
pixel-faithfully using Flutter's widget system. Exact values are given in **Design Tokens**.

---

## What's changing vs. the shipped app (the four findings)
Every amendment traces to one of these four systemic gaps found in `color_manager.dart` /
`theme_manager.dart` and the screen widgets:

1. **Text colour** — the app uses cool Untitled-UI greys (`#101828`, `#667085`, …). Migrate
   every text role to the warm **slate** ramp (base `#4A5568` at descending opacity).
2. **Display type** — titles currently render in Nunito Sans. Screen headers and the gauge
   value should use **Fredoka** (display family). Body/UI stays Nunito Sans.
3. **Status accents** — error/warning states are HSL-rotated off the sage seed. Use the real
   accents: **coral** `#E8A89C` for alerts/streaming, **yellow** `#F4D35E` for warnings.
4. **Shape & radii** — hardcoded `radius: 8` throughout. Adopt the token scale: **lg (16)**
   cards, **full (999)** pills, **md (12)** fields, **sm (8)** tags only.

---

## Screens / Views

### 1. Onboarding (`onboarding.html`, "After" phone)
- **Purpose**: First-run intro; 3 swipeable pages ending in "Get Started".
- **Layout**: Full-height column. Top ~55% is a hero stage on a soft radial sage wash
  (`radial-gradient(120% 80% at 50% 18%, sage-10, transparent 70%)`). Bottom is a white
  sheet with 34px top corners, `-10px` soft top shadow, 26px padding.
- **Components**:
  - **Hero, page 1**: concentric pulsing rings (sage-20, 2.6s ease-out, staggered 0.85s) behind a
    150px sage-10 disc and an organic "Pebble" blob (`border-radius: 46% 54% 52% 48% / 56% 50% 50% 44%`,
    gradient `150deg #A6C7BA→#6E9E8D`).
  - **Hero, page 2**: a mini "pairing" card preview — 60px sage-10 circle + Bluetooth glyph with a
    pulsing ring, "Pebble found", a device chip (Pebble blob, "Signal strong · 82%", sage check).
  - **Hero, page 3**: a mini "monitor" card — 70px sage mic circle, "Quiet", a 16-bar waveform
    (sage-20, centre 3 bars sage), a threshold track with a sage thumb at 62%.
  - **Title**: Fredoka 600, 23px, slate. **Body**: Nunito Sans 13.5px, slate-70, 1.55 line-height,
    min-height 64px (keeps sheet stable across pages).
  - **Dots**: active is a 22×8 sage pill, inactive 8×8 slate-20; 220ms width/background transition.
  - **Actions**: "Skip" (secondary, white, 1px slate-10 border, slate-70, pill) + "Continue"/
    "Get Started" (sage fill, white, pill, shadow `0 8px 18px -8px rgba(142,184,168,.9)`).
- **Copy** (exact):
  - P1 — "Meet Jack Jack" / "Your Pebble listens to the room so you don't have to — real-time
    sound levels, live audio, and a gentle nudge only when it matters."
  - P2 — "Pairs in seconds" / "Hold your phone close and connect the Pebble over Bluetooth.
    No accounts, no cables — just tap and you're listening."
  - P3 — "Listen in, anytime" / "Watch live sound, set a threshold that fits your home, and
    stream audio straight from the Pebble whenever you want to check in."

### 2. Home (`app-audit.html`, "Home")
- **Purpose**: At-a-glance state of the current device + device list.
- **Layout**: Column. Header row (title left, bell button right). Then a centred radial dB
  gauge, a 2-up indicator row (Battery / Status), a "Devices" eyebrow, and device cards.
  Bottom nav pinned.
- **Components**:
  - **Header**: "Jack Jack" in Fredoka 600 20px slate. Bell button 40px circle, white,
    1px border-nav, with a coral notification dot (8px, 1.5px white ring).
  - **Gauge**: 150px conic-gradient ring (`from 225deg`), fill colour by state (see logic),
    remainder sage-20, 270° sweep. Inner 118px disc = page bg. Value in Fredoka 500 36px slate,
    "dB" caption 11px slate-60. Below: device name (12.5px bold slate), "Threshold · 85 dB"
    (11px slate-60). All nowrap.
  - **Indicator cards** (×2, flex:1): title 11.5px slate-60; value 14px bold slate; trailing
    sage icon 18px. Card = white, 1px border-card, radius-lg, shadow-sm, 14px padding.
  - **Device cards**: 34px pebble-radius blob (sage gradient; coral gradient
    `150deg #F0C3BA→#D98A7C` for a secondary device in colour mode), name 13px bold, a coral
    "Current" pill for the active device, meta row "82% · Connected · 85 dB" (11px slate-60,
    slate-20 dot separators), trailing chevron-down slate-60.
- **Copy**: "Jack Jack"; "Battery" 82%; "Status" Connected; devices "The Pebble" (Current) and
  "Nursery Pod".

### 3. Connect Device (`app-audit.html`, "Connect Device")
- **Purpose**: BLE scan → pair. Reached via the centre scanner FAB.
- **Layout**: Header (title + "Refresh" text button in sage). Centred scan animation. Then
  "Paired Devices" and "Available Devices" sections of device rows.
- **Components**:
  - **Scan hero**: 118px sage-10 disc + 40px Bluetooth glyph, two pulsing sage-20 rings
    (2.4s). "Scan Complete" in Fredoka 600 17px slate.
  - **Device row**: white card, radius-lg, 1px border-card. Leading 36px radius-md icon block
    (sage-10 bg / sage icon; in colour mode secondary devices tint coral-10/coral and yellow).
    Name 13px bold, meta 11px slate-60. Trailing: sage "Paired" pill *or* a sage "Connect ›"
    affordance.
- **Copy**: "Connect Device", "Refresh", "Scan Complete", "Paired Devices" (The Pebble · Signal
  strong · 82%), "Available Devices" (Nursery Pod · Signal 61%; JJ-4471 · Signal 44%).

### 4. Manual Monitoring (`app-audit.html`, "Manual Monitoring")
- **Purpose**: Live-stream audio from the device with a running timer.
- **Layout**: Back-arrow + title header. Centred gauge, a streaming status pill, 2-up indicator
  row, a "Background Audio" toggle row, and a pinned "Stop Streaming" button.
- **Components**:
  - **Header**: back arrow (slate) + "Manual Monitoring" Fredoka 600 17px nowrap.
  - **Gauge**: same as Home; here value 88 vs threshold 85 → **over threshold → coral arc** in
    colour mode.
  - **Streaming pill**: coral pill "Streaming · 00:01:23" with coral dot.
  - **Toggle row**: white card, volume icon + "Background Audio" (14px bold), 44×26 sage toggle
    (thumb 20px, white, shadow-sm).
  - **Stop button**: full-width sage pill, white label, stop glyph, shadow.

### 5. Settings (`app-audit.html`, "Settings")
- **Purpose**: Preferences grouped into sections.
- **Layout**: "Settings" title (Fredoka 600 20px). Four grouped cards, each = an eyebrow label
  + a white radius-lg card whose rows are divided by 1px border-card hairlines.
- **Components**:
  - **Row**: leading 18px icon (slate-60; colour-coded per section in colour mode), label
    12.5px semibold slate nowrap, trailing control — a **Toggle**, a **dropdown chip**
    (1px border-input, radius-md, 11.5px bold slate-70, chevron-down), or a **chevron-right**.
  - **Sections**: General (BLE Auto Connect toggle, Notification Timeout 15s) · Notification
    Sounds (Connect/Disconnect/Threshold sound dropdowns) · Support (Help, Contact Us, Rate App)
    · About App (App Info).

### Bottom navigation (Home, Connect, Settings)
- 62px white bar, 1px border-nav top. Two labelled items (Home / Settings, 22px icon + 10px
  label; active = sage, bold). Centre **scanner FAB**: 56px sage circle, white scan glyph,
  raised `-24px`, 4px page-bg ring, shadow-md (sage glow when active).

---

## Interactions & Behavior
- **Onboarding**: Continue advances page (fade 320ms translateY 6px). Dots are tappable → jump
  to page. Skip and final "Get Started" both dismiss onboarding → Home. Page state is local.
- **Colour-diverse toggle** (audit card only — a *demo control*, not an app feature): segmented
  control flips a boolean that drives the five treatments below. Default = Current.
- **Gauge colour logic** (`value / threshold`): `< 0.82` → sage; `≥ 0.82` → yellow; `≥ 1.0`
  → coral. In "Current" mode the arc is always sage.
- **Battery colour** (colour mode): `< 30%` → coral; `< 50%` → yellow; else slate-60.
- **Motion**: colour changes 200ms, transforms 300ms, fades 400ms, standard easing. Pulse rings
  ~2.4–2.6s ease-out infinite. No springs/parallax.
- **Toggles/pills/nav**: standard tap states; sage is the pressed/active accent.

## The five colour treatments (optional, behind the toggle)
1. **State-aware gauge** — arc tracks sound vs threshold (sage→yellow→coral).
2. **Colour-coded Settings** — section icons: General sage, Notification Sounds yellow,
   Support coral.
3. **Yellow eyebrow ticks** — a 5px accent dot precedes each section label.
4. **Device identity tint** — primary device sage; secondary devices coral / yellow pebble +
   icon block.
5. **Battery as status** — yellow under 50%, coral under 30%.
All stay within the "accents are punctuation, not fields" rule — no accent becomes a large fill.

## State Management
- `onboardingPage: int` (0–2); `onboardingComplete: bool` (persist so it shows once).
- Per device: `name, isCurrent, batteryPct, status, thresholdDb, signalPct, paired`.
- `soundLevelDb` (live) drives the gauge; compare to `thresholdDb` for colour + alerts.
- `isStreaming: bool` + `streamElapsed` timer for Manual Monitoring.
- Settings values: `bleAutoConnect: bool`, `notificationTimeout`, three sound selections.
- `colourDiverse: bool` is **prototype-only** — if you ship the treatments, make them
  unconditional rather than gating on a flag.

## Design Tokens
Map these into `ColorManager` / `ThemeManager`. (CSS var → value → suggested use.)

**Colours**
- sage `#8EB8A8` — primary accent, CTAs, active nav, positive
- coral `#E8A89C` (icon-strength `#C77A6C`) — alerts, streaming, selection, secondary device
- yellow `#F4D35E` (icon-strength `#B99114`) — badges, eyebrow ticks, warnings
- slate `#4A5568` — primary text / buttons; opacity ramp: 90/80/70/60/20/10/5%
  (70% secondary body, 60% captions/icons, 20% input borders, 10% nav rule, 5% card hairline)
- bg `#FDFBF7` (warm off-white — never pure white for a full screen)
- white `#FFFFFF` — card surfaces only
- Tinted fills: sage/coral/yellow at 10% and 20% alpha (icon blocks, pills, callouts)
- Selection: coral bg + white text

**Typography** — Fredoka (display) + Nunito Sans (body/UI), both Google Fonts.
- Weights: regular 400, medium 500, semibold 600 (headings), bold 700 (labels/eyebrows)
- In-app sizes used: screen title 20 (Fredoka 600), sub-header 17 (Fredoka 600), gauge value
  36 (Fredoka 500), row label 12.5–14, meta/caption 11–11.5, eyebrow 10 (uppercase, tracking
  0.15em), nav label 10.
- Line height: body 1.5–1.6; letter spacing: eyebrows/pills 0.15em.

**Radii** — sm 8 (tags), md 12 (fields/dropdowns), lg 16 (cards), xl 24 (feature cards),
full 999 (pills/buttons). Signature **pebble** radius `40% 60% 70% 30% / 40% 50% 60% 50%`
(and its alt) for device blobs — never rotate it. In Flutter, approximate with an asymmetric
`BorderRadius.only(...)` or a custom clipper.

**Elevation** — shadow-sm `0 1px 2px rgba(74,85,104,.06)` (cards), shadow-md
`0 4px 6px -1px rgba(74,85,104,.08)` (FAB), sage CTA glow `0 8px 18px -8px rgba(142,184,168,.9)`.

**Spacing** — 4px base unit; use multiples. Screen padding 20px; card padding 12–15px; gaps
8–16px.

## Assets
- **No raster assets required.** The old `onboarding0–2.png` screenshots are intentionally
  removed — replace with rendered widgets, not images.
- **Fonts**: Fredoka + Nunito Sans (Google Fonts; add via `google_fonts` package or bundle).
- **Icons**: Feather-style line icons (Bluetooth, mic, battery, bell, cog, chevrons, volume,
  scan, stop, help, mail, star, info, clock, activity). Use the app's existing icon set or a
  Feather/Lucide Flutter package at 2px stroke.

## Files
Design references in this bundle:
- `onboarding.html` + `onboarding.jsx` — onboarding before/after
- `app-audit.html` + `app-audit.jsx` — four screens + colour-diverse toggle
- `frame.jsx` — shared phone shell / status bar / icon helpers used by both
- `styles.css` + `tokens/` — the full design-system token source of truth

Original Flutter source to modify: `lib/screens/{onboarding,home,pairing,manual_monitoring,
settings}/**` and `lib/widgets/**`, with tokens landing in `lib/utils/{color_manager,
theme_manager}.dart`.
