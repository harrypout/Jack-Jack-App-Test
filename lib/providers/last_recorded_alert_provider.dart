import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-local time of the last recorded threshold alert for a stable device
/// ID. This is separate from the live sound reading and does not claim that a
/// firmware latch is currently active or that monitoring is ready.
final lastRecordedAlertProvider = StateProvider.family<DateTime?, String>(
  (ref, deviceId) => null,
);
