# Testing Jack Jack

Updated 20 September 2026. Current suite: **119 passing Dart tests plus one passing native iOS test**. The original 13 red regressions are fixed and remain in the default test run.

## Run the gate

Use Flutter **3.41.4**, matching `.fvmrc`:

```sh
bash tool/check.sh full
```

With dependencies already cached:

```sh
JACKJACK_OFFLINE=1 bash tool/check.sh full
```

The command verifies the SDK, enforces `pubspec.lock`, regenerates Riverpod code, checks formatting and analysis, then runs every test with coverage. `baseline` and `known` remain historical diagnostic options; there are currently no `known_issue` tests. Only `full` is the release gate. A subset or an unsigned compile is not release approval.

If `.env` is missing, the script creates it from `test/fixtures/ble.env` with synthetic UUIDs. It does not replace an existing `.env`. **Use the real BLE configuration before physical testing or distribution.** Tests never contact a real Jack Jack.

## Coverage of behaviour

- Real threshold provider: readback, failed writes/reads, missing devices, per-device state and write-before-read ordering.
- Real foreground alert provider and background worker: positive/reset packets, cooldowns, repeat intervals, independent devices, muted history, worker-only delivery and acknowledged handoff release.
- Connection controller and actual GATT/provider integration: repeated recovery, native errors/completion, timeout, Bluetooth off/on, duplicate requests, failed setup, stopping during backoff, late completions, forget and manual-disconnect races.
- Battery: reactive provider updates, unknown failed readings, independent persistent low-battery episodes, hysteresis and invalid values.
- Readiness: denied/revoked Bluetooth, denied notifications, initialization failure and retry without extra permission prompts. Startup through actual discovery is covered with the iOS plugin’s `initialize=false` response, including resume and recovery. The shared native test double reproduces that response.
- Settings and navigation: independent persisted selections, 320-point layouts at 160% text size, centre Home action and left Connect action. Legacy device names render as Jack Jack in cards, notifications and stored history.
- History: corruption tolerance, stable identity, ordering, Unicode, clear, 30-day expiry and the newest 1,000 entries.
- Meter and Home widgets: approved animation/freshness/identity/accessibility cases, direct selection, row state after removal and narrow-card text layout.
- Unsupported audio countdown cancellation and notification event labelling.

Only platform boundaries are faked. These tests run production providers, BLE service construction, retry logic, alert recording and worker command handlers. They cannot establish OS delivery, radio recovery, microphone calibration or suspended iOS execution.

## Build checks

On macOS, install the Ruby build tools from the committed `Gemfile.lock` using Ruby 3.4.4. Run both CocoaPods and Flutter through Bundler so any CocoaPods subprocess uses the same versions:

```sh
bundle install
bundle exec pod install --deployment --project-directory=ios
bundle exec flutter build ios --simulator --debug --no-pub
bash tool/test_ios_native.sh
```

Android compilation requires Java 17 and an Android SDK:

```sh
flutter build apk --debug --no-pub
```

The iOS simulator compile and the native `RunnerTests` notification-plugin contract test pass locally. The iOS GitHub job now runs that native test after compilation. Android SDK/JDK are not installed on this Mac, so Android compilation has not run here. `.github/workflows/validate.yml` prepares Android compilation with Java 17, plus iOS compilation and the full test gate. The first GitHub runs passed the test job and exposed two native setup errors: CocoaPods/checksum differences on iOS and an outdated Android Gradle plugin. The corrected workflow pins Ruby 3.4.4, CocoaPods 1.16.2 and JSON 2.9.1 through Bundler; Android uses AGP 8.11.1 with Gradle 8.13. `Gemfile.lock` also fixes the Ruby tool dependencies. Keep `--deployment` enabled and retain both application dependency locks. Check the latest candidate commit in [GitHub Actions](https://github.com/harrypout/Jack-Jack-App-Test/actions/workflows/validate.yml) for the current native build results.

The clean-source check uses a new temporary folder containing tracked/candidate source files, dependency locks and font assets, without `build`, `.dart_tool`, Pods or the real `.env`. Generated providers and Flutter assets are recreated. This checks clean assembly with cached dependencies; it does not claim fresh network dependency downloads or a clean native Android build.

## Evidence and remaining work

See `coverage/validation-reliability.log`, `coverage/tests-full.log`, `coverage/analyze-tests.log`, `coverage/validation-clean.log` and `coverage/ios-reliability-build.log`. `coverage/lcov.info` contains line coverage. Coverage percentage alone is not a reliability guarantee.

The full app analyzer still reports legacy notices in unused/deferred audio and platform utilities and the older dropdown. Amended core providers/services and tests are checked with fatal infos and warnings.

Use the requested TestFlight candidate to complete [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md) before broader release sign-off. Confirm actual app version/build/signing, real BLE UUIDs, exact firmware hash, microphone and board. Test screen lock, overnight monitoring, interruptions, range loss/return, Bluetooth toggles, app resume, two devices and notification settings. Record system termination and user force-quit separately.

No test result here marks a physical acceptance row as passed. Harry confirmed build 1.0.2 (5) uploaded successfully, then reported a discovery failure. Candidate 1.0.2 (6) fixes its notification-startup gate; physical retesting is required.

## Build 6 regression evidence

The five new iOS startup/discovery regressions all failed against build 5 code with `Notification initialization failed`; they pass after the fix. The native XCTest exercises the actual locked iOS plugin, confirming that successful setup with all permission prompts disabled returns false. Android failure checking remains enforced.

`coverage/ios-native-tests.log` records the native test, `coverage/tests-full.log` records all 119 Dart tests, and `coverage/analyze-tests.log` records clean strict analysis of amended code. Nine existing analyzer notices remain in deferred audio/platform utilities. The simulator cannot verify radio discovery, firmware communication or notification delivery on a physical phone.

Optional rendered UI previews: `flutter test --no-pub --dart-define=CAPTURE_UI=true test/widgets/settings_navigation_test.dart` writes screenshots under ignored `coverage/ui/`.
