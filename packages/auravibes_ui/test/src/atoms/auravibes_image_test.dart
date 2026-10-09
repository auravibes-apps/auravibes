import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_image.dart';
import 'package:auravibes_ui/src/atoms/aura_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraImage', () {
    testWidgets('custom loading and error states retain their semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuraImage(
            url: 'https://example.com/failure.png',
            semanticLabel: 'Landscape',
            loadingChild: Text('Loading preview'),
            errorChild: Text('Preview unavailable'),
          ),
        ),
      );
      expect(find.text('Loading preview'), findsOneWidget);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Preview unavailable'), findsOneWidget);
      expect(find.bySemanticsLabel('Preview unavailable'), findsOneWidget);
    });

    testWidgets('passes image configuration to Image', (tester) async {
      const url = 'https://example.com/image.png';
      const semanticLabel = 'A mountain landscape';
      final provider = MemoryImage(.fromList(const [0, 1, 2]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const SizedBox(
                  width: 100,
                  height: 100,
                  child: AuraImage(
                    url: url,
                    key: ValueKey('network-image'),
                    fit: .cover,
                    semanticLabel: semanticLabel,
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: AuraImage(
                    url: 'unused',
                    key: const ValueKey('provided-image'),
                    imageProvider: provider,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final networkImage = tester.widget<Image>(
        find.descendant(
          of: find.byKey(const ValueKey('network-image')),
          matching: find.byType(Image),
        ),
      );
      expect((networkImage.image as NetworkImage).url, url);
      expect(networkImage.fit, BoxFit.cover);
      expect(networkImage.semanticLabel, semanticLabel);
      expect(find.bySemanticsLabel(semanticLabel), findsOneWidget);

      final providedImage = tester.widget<Image>(
        find.descendant(
          of: find.byKey(const ValueKey('provided-image')),
          matching: find.byType(Image),
        ),
      );
      expect(providedImage.image, same(provider));
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

    testWidgets('labels the image error state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraImage(
              url: 'http://127.0.0.1:1/missing-image.png',
              errorSemanticLabel: 'Preview unavailable',
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Preview unavailable'), findsOneWidget);
    });
  });
}
