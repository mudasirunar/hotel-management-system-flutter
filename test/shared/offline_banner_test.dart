import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/shared/widgets/offline_banner.dart';

void main() {
  group('OfflineBanner', () {
    testWidgets('renders message and retry button when onRetry provided',
        (tester) async {
      var retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              onRetry: () {
                retryClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('Offline mode'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);

      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(retryClicked, isTrue);
    });

    testWidgets('renders without retry button when onRetry is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              onRetry: null,
            ),
          ),
        ),
      );

      expect(find.textContaining('Offline mode'), findsOneWidget);
      expect(find.text('Check'), findsNothing);
    });
  });
}
