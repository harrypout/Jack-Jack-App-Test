import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/models/notification_sf.dart';
import 'package:jackjack/screens/notifications/widgets/notification_item.dart';

void main() {
  testWidgets(
    'older history displays the current device name without changing the record',
    (tester) async {
      final event = NotificationSF(device: 'Pebble 2', value: 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationItem(item: event, readTime: DateTime.now()),
          ),
        ),
      );
      expect(find.text('Sound alert detected by Jack Jack 2'), findsOneWidget);
      expect(event.device, 'Pebble 2');
    },
  );
  testWidgets('history row identifies the event and device', (tester) async {
    final event = NotificationSF(device: 'Nursery', value: 1);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationItem(item: event, readTime: DateTime.now()),
        ),
      ),
    );
    expect(find.text('Threshold Exceeded!'), findsOneWidget);
    expect(find.textContaining('Nursery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'JJ-07: an alert flag must not be labelled as a 1 dB measurement',
    (tester) async {
      final event = NotificationSF(device: 'Nursery', value: 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationItem(item: event, readTime: DateTime.now()),
          ),
        ),
      );
      expect(find.text('Threshold Exceeded!'), findsOneWidget);
      expect(find.textContaining('1 dB'), findsNothing);
    },
  );
}
