import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/shared/widgets/hotel_network_image.dart';

void main() {
  group('HotelNetworkImage', () {
    testWidgets('renders placeholder container with specified aspect ratio',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HotelNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-hotel-test',
              aspectRatio: 16 / 9,
              semanticLabel: 'Serena Hotel Islamabad',
            ),
          ),
        ),
      );

      // Verify widget builds and has Semantics
      expect(find.byType(HotelNetworkImage), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(HotelNetworkImage));
      expect(semantics.label, contains('Serena Hotel Islamabad'));
    });

    testWidgets('renders custom border radius and explicit dimensions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HotelNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-hotel-test',
              width: 200,
              height: 150,
              borderRadius: BorderRadius.all(Radius.circular(24)),
              aspectRatio: null,
            ),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, const BorderRadius.all(Radius.circular(24)));
    });
  });
}
