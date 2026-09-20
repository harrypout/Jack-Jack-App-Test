# Agreed app amendment scope — 13 September 2026

## Confirmed by Harry

| Decision | Agreed direction |
| --- | --- |
| Platforms | iOS/TestFlight first; preserve Android compatibility |
| Live listening | Hide for this milestone; no new audio firmware transport in this round |
| Alerts off | Stop phone banners, sound and vibration; continue recording history |
| Alert timing | Retain firmware's two-minute alert window and the app's configurable repeat interval |
| Low battery | One warning below 20% per low-battery episode |
| History | Retain at most 30 days or the newest 1,000 entries, whichever limit is reached first |
| Device naming | Jack Jack throughout the app, setup, notifications and help; display old stored names using current wording |
| Navigation | Home is the green centre action; Connect moves to the left |
| Settings controls | Roomier selectors, readable labels/options and larger text support |
| Meter | Approved: shorter fall, explicit waiting/stale states, reset on device changes, consistent near-threshold labels and separate recorded-alert information |

These choices have now been implemented in the local app reliability amendments. Ordinary engineering decisions such as cleanup, retry structure, readback correctness, stable device keys and tolerant persistence do not need another product decision.

Implement a low-battery episode with hysteresis to prevent repeated warnings as readings bounce around 20%; the implemented re-arm level is at least 25%. Treat unknown/stale readings as unknown, preserve per-device identity, and test the selected reset/persistence rule. Alerts off should be applied consistently to device notifications while events continue in history. Suppressed phone alerts should not accidentally suppress history through a shared early return.

Assume locked-screen and normal background use are essential monitoring cases. Test system termination and user force-quit separately and describe the actual platform limitations; do not infer support from the presence of a background capability flag.

## Amendment order

1. Use the new regression suite as the baseline.
2. Fix threshold correctness, cleanup/forget and recovery/readiness; coordinate background notification ownership and fresh subscriptions after reconnect.
3. Apply the agreed alert semantics, correct event history labels/identity/retention, and implement reliable battery updates and low-battery episodes.
4. Hide unsupported live listening, correct device selection and stale gauge states, then align support text and offline assets with supported features.
5. The approved meter refinements are now implemented locally. The app fixes and full automated suite are complete. Harry requested a TestFlight upload on 20 September; use that candidate for recorded phone-and-Jack Jack acceptance before broader release sign-off.

## Remaining guidance / release dependencies

- **Meter design:** approved and implemented locally. The initial settings are a 0.5-second falling time constant, two-second freshness timeout and five-dB near-threshold band. Verify the response with the actual microphone/firmware during device acceptance; no further design approval is pending.
- **Physical release baseline:** identify the Jack Jack used for acceptance, its microphone and flashed image, then verify the actual TestFlight build. The local firmware folder contains mixed release artifacts, so filenames are insufficient. These are release checks, not reasons to delay independent app fixes.
- **Test access:** a real iPhone and Jack Jack are needed for locked-screen/overnight/reconnection testing. A second Jack Jack is needed to sign off simultaneous-device behaviour. Android release acceptance remains deferred. Android build compatibility has a prepared CI job, but local compilation is unverified because this Mac has no Android SDK/JDK.

This branch now includes the approved application amendments and an expanded 119-test suite plus a native iOS test. All 13 earlier failures pass. See ISSUE_STATUS.md for the 1–15 reconciliation and the remaining physical/build-baseline checks. Firmware is unchanged.
