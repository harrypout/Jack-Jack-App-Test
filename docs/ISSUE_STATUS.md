# Original review issues — current status

Updated 20 September 2026 while preparing the requested TestFlight candidate. The full 106-test gate passed again today.

**The application amendments are implemented locally. This is not release sign-off.** The 13 previously failing checks now pass. The expanded suite has **106 tests, all passing**, covering actual providers, the background worker and UI controls as well as isolated logic. Physical iPhone/Pebble acceptance, the exact TestFlight/firmware baseline, Android compilation and execution of CI on GitHub remain open.

| Original ID | Area | Implemented locally | Remaining closure condition |
| --- | --- | --- | --- |
| JJ-01 | Background alerts | iOS retains one main-engine BLE owner. Android explicitly releases/acknowledges ownership; its worker initializes notifications and persists/delivers alerts without a foreground listener. Cooldowns survive handoff. Obsolete iOS background-task/audio claims removed. | Locked-screen, overnight, interruption and OS-termination checks on the actual phone. |
| JJ-02 | Reconnection | One connection owner per device, bounded setup timeout/backoff, Bluetooth-state gating, fresh GATT services on recovery and handled stream errors/completion. Desired devices are separate from discovery and actual ready connections. | Repeated range loss, Bluetooth toggling and resume with the real Pebble; Android native compile/device checks. |
| JJ-03 | Forget/remove cleanup | Cancels native subscriptions and retries, handles delayed setup, removes names/settings/paired identity, rejects forgotten IDs in both owners and preserves manual disconnect preferences. | Repeat on physical hardware during interrupted/background sessions. |
| JJ-04 | Threshold correctness | Serialized writes, device readback as authority, rollback on failure, missing-device errors, strict packet parsing and no fabricated zero or automatic threshold clamping. Both threshold controls handle save failures. | Hardware readback/power-cycle persistence. Unsupported threshold values require investigation rather than an automatic write. |
| JJ-05 | Live audio / session control | Unsupported route and onboarding claims removed; navigation remains hidden. Countdown cancellation fixed. Unused audio implementation retained for future work. | Continuous audio delivery remains explicitly deferred. |
| JJ-06 | Battery / warning | Reactive battery publication, failed reads shown as unknown, battery polling in both owners, persistent one-off warning below 20%, re-armed at 25%, independent per device. Battery read failures do not prevent alert-service setup. | Confirm reported battery accuracy, wakeup cadence and warning delivery on phone/Pebble. iOS timers are best effort when suspended. |
| JJ-07 | Firmware compatibility | Signed 16-bit little-endian sound decoding; one-byte alert flag treated as an event. History no longer labels it as 1 dB. Missing audio characteristics are not requested. Prior firmware-file investigation remains valid. | Identify the exact installed image/microphone; measure sound response, calibration and persistence. No firmware was flashed or changed. |
| JJ-08 | Reproducible baseline | Flutter pinned to 3.41.4, Dart/native dependency locks retained, offline fonts bundled, clean-source validation prepared and iOS simulator compilation/launch checked. | Confirm actual TestFlight build, signing/bundle identity and installed firmware. Android SDK/JDK are not installed locally, so Android compilation remains unverified. |
| JJ-09 | Tests / CI | 106 tests, default full regression gate, coverage output, strict analysis of amended core code, and pinned iOS/Android/test CI jobs. Original failures are ordinary passing regressions, not excluded tests. | Run CI on GitHub after the branch is pushed; complete native/physical acceptance. |
| JJ-10 | Alerts off | All device notification helpers suppress banners/sound/vibration when both device alert switches are off; event history continues. Tested in foreground and the actual background worker. | Check OS presentation on the phone, including Focus/silent settings and re-enabling alerts. |
| JJ-11 | Permissions / readiness | Denied Bluetooth/notifications and initialization failures have distinct states and recovery controls. Resume rechecks permissions without another prompt and avoids overlapping the initial permission flow. | Real denied/revoked permissions and OS service-start failures. |
| JJ-12 | Meter | Approved meter refinements remain in place: shorter fall, unknown/stale state, stable identity, five-dB band, Reduce Motion and separate recorded-alert timestamp. | Confirm measured response on actual hardware. |
| JJ-13 | Multiple devices / row state | Direct Show on meter control, serialized selection, stable row keys and list index mapping; preserved row state after removal. Status/threshold text wraps within narrow cards. | Physical two-Pebble acceptance; widget tests cover selection and retained alert settings. |
| JJ-14 | History | Per-record corruption tolerance, stable device ID/event kind, newest-first ordering, 30-day/1,000-entry limits, retention on load/add and calendar-day grouping. | Verify history across actual foreground/background sessions and OS restarts. |
| JJ-15 | Help / offline / unfinished actions | Bundled licensed Fredoka/Nunito Sans fonts; removed runtime font downloading. Help/onboarding reflect sound-level detection and supported alert behaviour. Dead rating action removed, App Info opens, placeholder email replaced with TestFlight feedback instructions/copyable notes. | Confirm final support address and store links when preparing a public release; these are not used as fake destinations in this milestone. |

## Verification evidence

- Full regression gate: `coverage/validation-reliability.log`; raw tests: `coverage/tests-full.log`.
- Strict analysis: `coverage/analyze-tests.log`. Legacy analyzer notices in unused audio/platform utilities and the older dropdown are visible separately; they are not failing tests.
- iOS simulator compile: `coverage/ios-reliability-build.log`. Startup smoke test used an isolated iPhone 16 Pro / iOS 26.3 simulator; screenshot retained in coverage.
- Clean-source check: `coverage/validation-clean.log` after re-creating generated files with the synthetic BLE fixture and enforcing dependency locks.
- [Test guide](TESTING.md), [decisions](DECISIONS.md), [device acceptance](DEVICE_ACCEPTANCE.md), [meter assessment](METER_REVIEW.md).
- Original source review and firmware evidence remain in `/Users/Harry/Projects/jackjack-review-2026-09-13`.

The earlier 13 failures comprised JJ-03 (2), JJ-04 (4), JJ-05 (1), JJ-07 (2), JJ-10 (1) and JJ-14 (3). Each remains represented by a passing regression. The suite grew from 74 to 106 checks. Native mocks and an iOS simulator do not establish reliable real-phone Bluetooth or notification delivery.

Candidate branch: `codex/regression-test-baseline`. TestFlight upload preparation is in progress; the exact Apple app/build identity and physical acceptance remain open. See [TESTFLIGHT.md](TESTFLIGHT.md) for the upload walkthrough and current candidate details.
