import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackjack/main.dart';

void main() {
  testWidgets(
    'startup failure renders an explanation instead of crash-looping',
    (tester) async {
      await tester.pumpWidget(
        const StartupErrorApp(message: 'Configuration could not be loaded'),
      );
      expect(
        find.text('Something went wrong while starting the app.'),
        findsOneWidget,
      );
      expect(find.text('Configuration could not be loaded'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
