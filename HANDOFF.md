# Session Handoff — jackjack (Jack Jack BLE sound monitor)

Last updated: 2026-07-04. State: **building, uploading, and running on TestFlight.**

## Where things stand

- `main` is the source of truth. It contains, in order:
  1. The developer's (Subhan Ahmed, `subhan-ahmd`) **latest app version** — adopted
     from a local folder he sent, preserved verbatim on branch `origin/dev-snapshot-1`
     (PR #8). This superseded his Dec-2025 commit `2fc7722`, which is what earlier
     work was mistakenly based on.
  2. **iOS build pins** that make the app compile under CocoaPods (see below).
  3. **Five bug fixes** re-ported onto his code (PR #8, commit `0f07766`): battery
     polling loop, unique notification IDs, ~15fps gauge throttle, per-device alert
     cooldown, startup failure guard (`StartupErrorApp`).
  4. Version **1.0.1+2** (PR #9) — uploaded to TestFlight and verified on-device.
  5. `design_handoff_jackjack_redesign/` — a **UI redesign spec** (tokens, mockups)
     uploaded 2026-07-04. **This is the likely next body of work.**
- PR history: #1 bug fixes (old base) · #2–#7 the iOS build saga · #8 new base+pins+fixes · #9 version bump.

## ⚠️ Critical: the SwiftProtobuf pins (do not "upgrade" these)

`pubspec.yaml` pins `flutter_reactive_ble: 5.4.0` **exactly**, plus
`dependency_overrides: reactive_ble_mobile: 5.4.0`. `ios/Podfile` pins
`pod 'SwiftProtobuf', '1.29.0'`.

Why: reactive_ble_mobile **5.4.1+** regenerated its `bledata.pb.swift` to call
`SwiftProtobuf._NameMap(bytecode:)`, which requires SwiftProtobuf ≥ 1.31 — and
1.31+ uses Swift `package` access that **does not compile under CocoaPods**
(no `-package-name`; apple/swift-protobuf#1334). Build-setting workarounds
(-package-name, wholemodule, disabling explicit modules) were all tried and failed.
The 5.4.0/1.29.0 pair is the only proven-green combination. Loosening any of these
pins reintroduces a wall of Swift compiler errors at archive time.

## Build & release runbook (macOS)

Project lives at `~/Documents/Jack-Jack-App-Test` on Harry's Mac. Flutter is pinned
to 3.32.7 via FVM (`.fvmrc`).

```bash
git pull origin main
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # *.g.dart are gitignored
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..  # after dependency changes
flutter build ipa --export-method app-store
```

Then upload the `.ipa` from `build/ios/ipa/` with **Transporter**, and in
App Store Connect → TestFlight assign the build to the Internal Testing group.

Gotchas that have each cost a build cycle before:
- **`.env` must exist at the project root** (gitignored; 16 BLE UUID keys read by
  `lib/utils/env_manager.dart`). Missing → `No file or variants found for asset: .env`.
  Never commit it.
- **Bump `version:` in pubspec (+build number) on every upload** — App Store Connect
  rejects duplicate build numbers and TestFlight keeps serving the old build.
- Run terminal commands **from the project root** (prompt should end
  `Jack-Jack-App-Test %`), one line at a time, without trailing `#` comments.
- If the local checkout looks stale: `git fetch origin && git reset --hard origin/main`
  (safe: `.env` is untracked).
- Signing: paid Apple Developer team **L9MCWXCMY7**, automatic signing, bundle id
  `com.jackjack1234`. Export compliance answer: **"None of the algorithms mentioned
  above"** (no custom crypto).
- Deprecation warnings in the archive log (permission_handler, fluttertoast,
  deployment-target 9.0/11.0 notices) are normal — only errors matter.

## Known follow-ups (open, in rough priority order)

1. **UI redesign** from `design_handoff_jackjack_redesign/` (tokens + JSX/HTML mockups).
2. Add `ITSAppUsesNonExemptEncryption = false` to `ios/Runner/Info.plist` to skip the
   export-compliance question on every upload (offered, never applied).
3. Bundle the Nunito Sans font instead of `google_fonts` runtime fetch (network
   download on first launch).
4. Stream/GATT-subscription leak hardening from PR #1 was **not** ported — the
   developer restructured subscription ownership around his background service;
   verify on-device before touching.
5. UIScene lifecycle migration (Flutter warns it will become required).
6. `origin/dev-snapshot-1` branch can be deleted once nobody needs the pristine
   snapshot for reference.

## Context that is easy to lose

- The app's author is Subhan Ahmed (`subhan-ahmd` on GitHub, subhan.ahmd@tuta.io);
  the canonical upstream repo is private and its URL is not recorded anywhere in
  this clone. This repo (`harrypout/Jack-Jack-App-Test`) is Harry's working copy.
- Harry has multiple local copies (Documents clone, a "drive" clone, developer zip
  folders). The Documents clone is the one that builds. When files "go missing",
  check the other copies first.
- The `.claude/` folder from the developer's snapshot was deliberately excluded.
