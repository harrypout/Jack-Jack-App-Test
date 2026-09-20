# Meter animation assessment — 13 September 2026

**Recommendation: keep the circular meter, visible threshold marker and fast rise; revisit the falling response and the way unavailable data is shown.** The present design is a useful indication of changing room sound. It should not also carry the meaning of “monitoring is working” or “an alert is active”. Those need their own reliable states.

Harry approved the refinements after this assessment. They are now implemented in the local checkout. The original assessment below describes commit `181a8d19feafd85606cad9ddbe4c581669a3ee4b` and is retained as the before/after rationale.

## Implemented amendment

- The first packet displays its actual level. The meter no longer invents an initial zero or animates from another device's value.
- Falling smoothing uses a 0.5-second time constant; the quick rise remains approximately 0.15 seconds. Animation uses elapsed frame time, with paints capped at roughly 15 updates per second. The 90-to-43 fall reaches within 1 dB in about two seconds while quiet packets continue.
- Missing initial input shows “Waiting for reading”, followed by “No recent data” after two seconds. Stale input, stream errors and stream completion clear the number and active arc. A valid new packet recovers immediately.
- Every device-ID or stream change, including null, detaches the old listener and clears its measurement. Renaming the same device preserves its reading.
- A consistent five-dB visual margin produces text labels for below, near, and at/above the alert setting. The colour and text follow the displayed number; an unknown threshold is not presented as zero.
- Reduce Motion bypasses interpolation. Backgrounding or hiding a route stops visual animation; returning requires fresh input. The widget does not change the independent alert subscriptions or send firmware commands.
- The last recorded alert is shown separately, with date and time, using a session-local timestamp keyed by stable device ID. It advances only when the existing alert coordinator records an event after its usual cooldown. It is not labelled as a currently active firmware latch and is not inferred from the gauge level.
- Screen-reader semantics provide the device, reading, status and setting without repeated live-region announcements. A narrow phone with enlarged text is covered by a layout check.

All 22 meter/colour tests pass. The amended iOS simulator build also passed, and all changed code passes the strict analyzer. The full suite has 61 passes and 13 remaining failures outside this amendment; both original JJ-12 meter regressions are resolved. Physical microphone response, background notification delivery and phone energy use still require the device acceptance run. The two-second freshness timeout is an initial accepted setting to verify against the actual radio/firmware traces.

## Original assessment

The review used source-derived timing calculations and actual Flutter widget tests. No physical microphone, screen recording or performance trace was measured.

## What the original meter did

The home screen passes the selected device's sound-level stream and configured threshold to `BLEGauge`. The widget starts at zero, receives each numeric sample as a new target, and moves the displayed number and arc towards that target every 66 milliseconds (about 15 updates per second).

Each step closes 36% of the remaining gap when rising and 4.3% when falling. Once the gap is below 0.5, the next step snaps to the target and stops the timer. The Syncfusion pointer's own animation is disabled, so there is no second animation layered on top. New samples arriving before the next tick replace the target.

The ring covers 0–120 displayed dB over 270 degrees. A marker shows the threshold. Its colour is sage below 82% of the threshold number, yellow from there to the threshold, and coral at or above it.

The current firmware already calculates a sound level over a short sample window: approximately 107 ms for the ICS source and 100 ms for the MAX source. The app receives a level, not a continuous audio waveform. The meter adds visual smoothing to that level.

## How it feels, quantified

For an ideal sustained step between 43 and 90, starting from a settled reading:

| Display response after the new packet arrives | Current | Proposed |
| --- | ---: | ---: |
| Rise from 43 to within 1 dB of 90 | 0.59 s | 0.59 s |
| Fall from 90 to within 1 dB of 43 | 5.81 s | 1.98 s |
| Fall from 90 to exactly 43 after the final snap | 6.93 s | 2.38 s |

The proposed falling time constant is 0.5 seconds, keeping the existing rise. These are calculations using the source's 66 ms steps, not end-to-end measurements; they exclude acoustic acquisition, radio delays and phone scheduling. Starting from a different level changes the settling time.

The source comment says falls settle over approximately 1.5 seconds. That is the approximate time constant, not the time needed to reach the new level. The actual long tail can make the room look louder than its latest received measurement for several seconds after it becomes quiet.

A very brief peak can also be understated: a 100 ms input at 90 from a settled 43 may allow only one or two rising ticks, reaching about 60–71 before the input falls again. That is acceptable for a calm sound trend display, but the number should not be presented as a precise peak measurement. No peak-hold addition is necessary for this milestone unless observing short sound peaks becomes a specific product goal.

## Findings and priorities

| Priority | Finding | Recommended amendment |
| --- | --- | --- |
| High | Zero appears before the first packet; the last reading can persist indefinitely if packets stop. There is no freshness, done or error state. | Show “Waiting for reading” initially and “No recent data” when the stream stops, errors or becomes stale. Use a dash and neutral arc for unknown data. A two-second freshness timeout is a prototype starting point; confirm it against the accepted firmware and phone traces. |
| High | Switching to a null stream does not detach the previous listener. Switching devices retains the previous device's number until new samples move it. | Cancel/reset on every stream or device-ID change, including null. Reset freshness and displayed measurement, and require fresh input for the new device. Use the stable device ID, since names can match. |
| Medium | The slow fall leaves an exaggerated number long after the sound falls. | Keep the fast attack, shorten the fall to the proposed 0.5-second time constant, and verify quiet/noisy/quiet recordings on the phone. |
| Medium | Ring colour is determined by the smoothed level, while alerts use a separate firmware event. | Describe colour as the current displayed level relative to the setting. Show an active/recent alert separately, with timing and labels based on the real event state. |
| Medium | “Near threshold” changes meaning with the threshold setting. At 75, yellow starts at 61.5; at 40, it starts at 32.8. | Use a consistent displayed-unit margin, provisionally 5 dB below the setting. Pair colour with “Below”, “Near” or “Above alert setting” text. This visual margin must not change the firmware trigger. |
| Lower | The timer is independent of screen visibility and uses a fixed step per callback. No frame or battery profile has been captured. | Keep rendering bounded; suspend visual work when hidden while preserving alert monitoring. If timing is refactored, base smoothing on elapsed time so delayed callbacks do not extend the lag. Profile before raising the frame rate. |

The review initially reproduced two device-switching failures under JJ-12. Both now pass. The added tests also cover freshness, startup, stream errors/completion, shortened fall, delayed frames, accessibility labels, reduced motion and visual lifecycle behaviour.

## Meter level and alert state are different

In the inspected firmware, sound at or above the configured threshold must qualify over roughly two seconds, with up to 700 ms tolerated pauses, before an alert starts. A confirmed alert then remains latched for two minutes, with firmware events every three seconds; the app applies its own selected repeat interval. Harry has chosen to retain that timing for this release.

The gauge's smoothing is display-only and does not cause that confirmation delay or suppress the separate firmware alert. Equally, shortening the animation will not repair the background/reconnection issues found in the main review. A red meter during a short sound is not proof an alert should already have arrived, and a falling meter while reminders continue is consistent with the retained two-minute window. Avoid making the meter falsely track the latch just to make those states look identical.

The displayed dB values also depend on the installed microphone and calibration. The ICS source contains a measured correction; the MAX source records a historical input-path problem and only a nominal correction. This does not establish that the current physical board is faulty, but it prevents treating the folder's “calibrated” label as proof of acoustic accuracy. Confirm the actual hardware and firmware before making precision claims or changing the recommended threshold.

## Design decision

Harry approved the shorter fall, explicit waiting/stale states, reset on device changes, and consistent near-threshold labels. Retain the overall circular design and existing firmware alert timing. This is a focused refinement, not a proposed screen redesign.

The accompanying interactive comparison illustrates sustained noise, a brief sound and a stopped stream. It is a mathematical illustration of the current and proposed behaviour, with schematic colours; it is not a recording of the app or a final visual design. Its light/dark and desktop/mobile layouts and controls were checked locally.

## Evidence

- App: `lib/widgets/ble_gauge.dart`, `lib/screens/home/widgets/selected_device_widget.dart`, `lib/providers/selected_device_provider.dart`, `lib/utils/status_colors.dart`.
- Alert ownership and timing: `lib/providers/threshold_alert_provider.dart` and the prior firmware compatibility review.
- Firmware: `02 Firmware/Aug 26/drive-download-20260913T065050Z-1-001/BLE_Version_6.0/BLE_Version_5.0/{Ics_v2,max_v2}/src/main.c` in the shared App and Firmware folder.
- Executable app checks: `test/widgets/gauge_test.dart` and `test/providers/alerts_test.dart`.
- Source-derived step-response data: `meter-response-evidence.json` in the adjacent `jackjack-review-2026-09-13` review folder. The app snapshot reviewed is commit `181a8d19feafd85606cad9ddbe4c581669a3ee4b`; test setup is on `codex/regression-test-baseline`.
