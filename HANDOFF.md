# Jack Jack working handoff

Updated 20 September 2026. Current working folder: `/Users/Harry/Projects/jackjack`; branch: `codex/regression-test-baseline`.

The September reliability amendments and the approved meter refinements are implemented. All **106 automated tests pass**, including the 13 earlier regressions. The user has requested help pushing the changes and uploading a new TestFlight build.

Use [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md) for the current upload walkthrough, [docs/ISSUE_STATUS.md](docs/ISSUE_STATUS.md) for the original 1–15 issue reconciliation, and [docs/TESTING.md](docs/TESTING.md) for validation commands. Physical iPhone/Pebble acceptance remains unexecuted; record it in [docs/DEVICE_ACCEPTANCE.md](docs/DEVICE_ACCEPTANCE.md).

## Build baseline

- Flutter **3.41.4** is pinned in `.fvmrc`.
- Retain Dart, CocoaPods and Ruby (`Gemfile.lock`) dependency locks. Use Ruby 3.4.4, `bundle install`, and `bundle exec` for CocoaPods and Flutter iOS build commands. CocoaPods 1.16.2 and JSON 2.9.1 match the native lockfile checksums.
- Keep `flutter_reactive_ble: 5.4.0`, `reactive_ble_mobile: 5.4.0` and `SwiftProtobuf: 1.29.0` pinned. The historical native compatibility problem is documented in `pubspec.yaml` and `ios/Podfile`.
- The real `.env` is ignored by Git. The test fixture uses synthetic identifiers and must not be used for a TestFlight archive.
- Git currently declares **1.0.2+5**, committed by Harry. Verify this build number is unused before uploading it.
- Confirm the existing app's bundle ID in App Store Connect. The prior Documents archive uses **com.jackjack1234**, while the project config uses **com.jackjack**. Both have local signing profiles under **Jack Jack Pty Ltd / L9MCWXCMY7**; archive history alone does not resolve which Apple app to update.

## Agreed scope

Prioritize iOS/TestFlight and preserve Android compatibility. Hide live listening. Alerts off suppresses phone presentation while keeping history. Keep the firmware's two-minute alert window and configurable repeats. Warn once below 20% battery per episode, re-arming at 25%. Retain 30 days or the newest 1,000 history entries. Meter refinements are approved and implemented.

## Historical source

The amendments start from main commit `181a8d19feafd85606cad9ddbe4c581669a3ee4b`, which includes the developer's adopted source, native dependency fixes, the UI redesign and the 1.0.2+4 build bump. Older instructions pointing to `~/Documents/Jack-Jack-App-Test`, Flutter 3.32.7 or deleting dependency locks have been superseded by this handoff.
