import 'package:flutter/material.dart';
import 'package:jackjack/main.dart';
import 'package:jackjack/providers/notifications_provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jackjack/services/app_initializer.dart';
import 'package:jackjack/services/app_lifecycle_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class MonitoringReadiness extends ConsumerWidget {
  const MonitoringReadiness({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationsProvider);
    final init = ref.watch(appInitializerProvider);
    final bluetooth = ref.watch(bleStatusNotifierProvider);
    final monitoringError = ref.watch(monitoringErrorProvider);
    final deliveryError =
        prefs.getString('notification_delivery_error') == null
            ? null
            : 'A phone notification could not be delivered. Check phone settings and retry setup.';
    final message =
        monitoringError ??
        deliveryError ??
        (init.hasError
            ? 'Monitoring could not start. Retry setup.'
            : init.isLoading
            ? 'Checking monitoring permissions…'
            : init.valueOrNull == InitPhase.bluetoothDenied ||
                bluetooth == BleStatus.unauthorized
            ? 'Bluetooth access is required to connect to your Pebble.'
            : bluetooth == BleStatus.poweredOff
            ? 'Turn on Bluetooth to connect to your Pebble.'
            : bluetooth == BleStatus.unsupported
            ? 'Bluetooth monitoring is unavailable on this phone.'
            : bluetooth != BleStatus.ready
            ? 'Waiting for Bluetooth to become available…'
            : init.valueOrNull == InitPhase.notificationsDenied
            ? 'Phone notifications are off. Sound events will still appear in history while connected.'
            : null);
    if (message == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (!init.isLoading)
              Wrap(
                children: [
                  TextButton(
                    onPressed: () async {
                      await ref.read(appInitializerProvider.notifier).retry();
                      AppLifecycleManager.active?.retry();
                    },
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: openAppSettings,
                    child: const Text('Phone settings'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
