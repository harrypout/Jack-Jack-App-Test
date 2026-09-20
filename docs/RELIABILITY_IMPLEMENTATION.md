# Monitoring ownership and verification

The foreground app owns one `DeviceConnection` per desired Pebble. Its phase reaches monitoring only after service setup. Recovery closes the old session and constructs fresh services; a generation check rejects late setup completions. Discovery never owns a second connection and never removes a paired device merely because it is absent from a scan.

On iOS, that foreground engine retains its Core Bluetooth central when the app is backgrounded. The `bluetooth-central` capability supports event-driven wakeups. Dart polling timers are best effort, and this implementation does not promise continuous execution or restoration after termination/force-quit. The old no-op BGProcessingTask callbacks and audio background mode have been removed. [Apple's Core Bluetooth background guide](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html) describes the platform model; hardware acceptance must establish the app's actual performance.

On Android, the foreground service starts while the UI is active. Pause first releases foreground connections, then asks the worker to acquire desired devices. Resume waits for worker release before foreground connections restart. Requests have IDs, acknowledgements, bounded retries and duplicate suppression. The service's connection count distinguishes desired devices from initialized sessions. Its alert recorder initializes notifications and saves history without needing a foreground event listener.

Shared preferences contain per-device cooldown and battery episode state. Background reloads are serialized with alert writes to avoid a stale cache overwriting a recent event. Handoff release drains pending alert recording. Foreground events and service events use the same recorder; service-delivered events are marked handled so the UI reloads rather than delivering again. Old background event channels remain tolerated during updates.

A positive firmware alert is an event flag, not a measured dB value. Sound levels decode as signed 16-bit little-endian. The two-minute firmware latch and selected app repeat interval remain unchanged. Threshold writes await readback; failed reads never become zero or trigger an automatic hardware write.

Battery checks publish a new provider map, use unknown for failed reads and keep the last valid threshold intact. One warning is recorded below 20%; reaching 25% clears that episode. Muting a device suppresses phone notifications while history continues.

Fredoka and Nunito Sans static weights are bundled under the SIL Open Font License. Font assets include licenses and `sources.json` with upstream URLs, source hashes, generated hashes and weights. Instances were produced from the official Google Fonts variable files with fontTools 4.60.2. Runtime font downloading was removed. [Google Fonts repository](https://github.com/google/fonts).

The full source-to-provider and background-worker tests are under `test/providers/connection_integration_test.dart` and `test/services/background_worker_test.dart`. They exercise the application implementation but replace native BLE and notification boundaries. The physical acceptance record is therefore still required before TestFlight distribution.
