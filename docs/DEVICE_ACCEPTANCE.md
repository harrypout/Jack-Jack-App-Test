# Physical-device acceptance record

Status: **not executed**. Use the requested TestFlight candidate to complete these checks before broader release sign-off.

Record: app version/build and Git commit; installed firmware image/hash and microphone; board revision; iPhone model/iOS version; real BLE configuration; permissions; battery state; tester/date; measured result and log/screenshot reference. Include an Android baseline only if preparing an Android release.

| Scenario | Pass condition | Status |
| --- | --- | --- |
| First install; permission granted / denied / changed in Settings | Accurate readiness and actionable recovery; no claim of active monitoring when delivery is unavailable | Not run |
| Threshold save and power cycle | Device readback, UI and persisted threshold agree; failed reads/writes never overwrite the device setting | Not run |
| Known quiet/noisy inputs for the exact microphone | Readings respond to sound and the configured alert threshold; no reliance on the MAX nominal calibration without checking the input path | Not run |
| Foreground, screen locked and another app foregrounded | Alerts and history arrive at the intended cadence with live listening hidden | Not run |
| Overnight locked-screen run | Record elapsed hours, test-sound times, actual alert times, missed/duplicate events, battery drain and connection state | Not run |
| Range loss / return, Bluetooth off / on, repeated app resume | Automatic recovery reaches monitoring-ready and produces a fresh threshold alert after every recovery | Not run |
| System termination / user force-quit | Record each case separately and document measured OS limitations; no unsupported background promise | Not run |
| Forget while connected, disconnected and backgrounded | No later alerts, retries or automatic reappearance from the forgotten device | Not run |
| Two Pebbles with different names/settings | Independent cooldowns/alerts, correct history identity and selection, no settings transferred when a row disappears | Not run |
| Alerts off | No phone banner/sound/vibration, history retained, and turning back on works with the agreed repeat policy | Not run |
| Battery refresh and warning episode | UI refreshes without reconnect; one warning below 20%; no repeats from noisy boundary readings; verify agreed re-arm rule | Not run |
| Meter: quiet → noisy → quiet; lost packets; device switch | Verify the approved fast rise/shorter fall, two-second missing-data timeout, device changes, Reduce Motion and separate recorded-alert timestamp against real firmware; no stale reading assigned to another device | Not run |
| Fresh install offline | Core screens and help work; no font/network failure obscures monitoring controls | Not run |
| Distribution baseline | Full tests pass; unsigned builds pass; actual release signing/configuration and firmware pair are verified | Not run |

A successful simulated test or simulator compile does not mark a row here as passed. For background tests, exercise actual local notifications on the phone and compare them with firmware event logs where available. The two-minute firmware latch can legitimately outlast the noise, so assess measured sound and active alert-window state separately.
