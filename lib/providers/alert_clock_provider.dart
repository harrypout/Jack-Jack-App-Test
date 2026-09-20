import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defaults to the system clock; tests can advance alert cooldowns without
/// waiting in real time or changing device-wide time settings.
final alertClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
