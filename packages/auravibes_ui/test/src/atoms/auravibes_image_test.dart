import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_image.dart';
import 'package:auravibes_ui/src/atoms/aura_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraImage', () {
    testWidgets('passes URL to Image.network', (tester) async {
      const url = 'https://example.com/image.png';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuraImage(url: url)),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;

      expect(provider.url, url);
    });

    testWidgets('passes fit to Image.network', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraImage(
              url: 'https://example.com/image.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));

      expect(image.fit, BoxFit.cover);
    });

    testWidgets('exposes semantic label', (tester) async {
      const semanticLabel = 'A mountain landscape';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraImage(
              url: 'https://example.com/image.png',
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));

      expect(image.semanticLabel, semanticLabel);
      expect(find.bySemanticsLabel(semanticLabel), findsOneWidget);
    });

    testWidgets('shows loading fallback before first image frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraImage(url: 'https://example.com/loading-image.png'),
          ),
        ),
      );

      expect(find.byType(AuraSpinner), findsOneWidget);
    });

    testWidgets('shows Aura fallback when image fails', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraImage(url: 'http://127.0.0.1:1/missing-image.png'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(AuraIcon), findsOneWidget);
    });
  });
}
