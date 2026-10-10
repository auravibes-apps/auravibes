import 'package:auravibes_ui/src/atoms/aura_corner_radius_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/atoms/aura_tile.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraTile', () {
    testWidgets('renders full-width tile with leading and trailing widgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () {
                final _ = Object();
              },
              leading: const Icon(Icons.star),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );

      expect(find.text('Test Tile'), findsOneWidget);
      expect(find.byType(AuraTile), findsOneWidget);
      final tile = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(tile.width, double.infinity);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('centers different text heights vertically', (tester) async {
      for (final text in ['Short label', 'First line\nSecond line']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 220,
                  child: AuraTile(
                    child: Text(text),
                    onTap: () => fail('layout test must not tap tile'),
                    size: .small,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          tester.getRect(find.text(text)).center.dy,
          closeTo(tester.getRect(find.byType(AuraTile)).center.dy, 0.1),
        );
      }
    });

    testWidgets('keeps padding radius-independent and grows for content', (
      tester,
    ) async {
      final theme = AuraTheme.light;

      Future<void> pumpTile(AuraBorderRadius radius, String text) async {
        await tester.pumpWidget(
          AuraThemeScope(
            theme: theme,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 220,
                    child: AuraCornerRadiusScope.select(
                      level: radius,
                      child: AuraTile(
                        child: Text(text),
                        onTap: () => fail('layout test must not tap tile'),
                        size: .small,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
      }

      await pumpTile(.sm, 'Same label');
      final smallRadiusPadding = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .padding;
      final smallRadiusSize = tester.getSize(find.byType(AuraTile));

      await pumpTile(.xl, 'Same label');
      final largeRadiusPadding = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .padding;
      final largeRadiusSize = tester.getSize(find.byType(AuraTile));

      expect(largeRadiusPadding, smallRadiusPadding);
      expect(largeRadiusSize, smallRadiusSize);

      await pumpTile(.xl, 'First line\nSecond line');
      final multilineSize = tester.getSize(find.byType(AuraTile));

      expect(multilineSize.height, greaterThan(largeRadiusSize.height));
      expect(
        multilineSize.height,
        greaterThanOrEqualTo(theme.interactionSizes.minimumTargetSize),
      );
    });

    testWidgets('resolves the default border radius from AuraTheme', (
      tester,
    ) async {
      final theme = AuraTheme.light.copyWith(
        borderRadius: const AuraBorderRadiusScale(lg: 12),
      );
      await tester.pumpWidget(
        AuraThemeScope(
          theme: theme,
          child: const MaterialApp(
            home: Scaffold(body: AuraTile(child: Text('Configured radius'))),
          ),
        ),
      );

      final decoration = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .decoration;
      expect(
        decoration,
        isA<BoxDecoration>().having(
          (value) => value.borderRadius,
          'borderRadius',
          const BorderRadius.all(.circular(12)),
        ),
      );
    });

    testWidgets('uses scoped radius when no explicit radius is provided', (
      tester,
    ) async {
      final theme = AuraTheme.light;
      await tester.pumpWidget(
        AuraThemeScope(
          theme: theme,
          child: MaterialApp(
            home: Scaffold(
              body: AuraCornerRadiusScope.select(
                level: .xl,
                child: AuraCornerRadiusScope.adjust(
                  delta: 4,
                  child: const AuraTile(
                    child: Text('Scoped Tile'),
                    variant: .outlined,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final decoration = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .decoration;
      expect(
        decoration,
        isA<BoxDecoration>().having(
          (value) => value.borderRadius,
          'borderRadius',
          BorderRadius.circular(theme.fromBorderRadius(.xl) - 4),
        ),
      );
    });

    testWidgets('explicit radius overrides a local scope', (tester) async {
      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: Scaffold(
              body: AuraCornerRadiusScope.select(
                level: .xl,
                child: const AuraTile(
                  child: Text('Explicit Tile'),
                  borderRadius: .md,
                ),
              ),
            ),
          ),
        ),
      );

      final decoration = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .decoration;
      expect(
        decoration,
        isA<BoxDecoration>().having(
          (value) => value.borderRadius,
          'borderRadius',
          BorderRadius.circular(AuraTheme.light.fromBorderRadius(.md)),
        ),
      );
    });

    testWidgets('keeps child semantics when no tap callback is provided', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AuraTile(child: Text('Status Tile'))),
          ),
        );

        expect(find.bySemanticsLabel('Status Tile'), findsOneWidget);
        expect(find.bySemanticsLabel('Tile'), findsNothing);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('shows loading state and ignores taps', (tester) async {
      var wasTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () => wasTapped = true,
              isLoading: true,
            ),
          ),
        ),
      );

      final loadingCircle = tester.widget<AuraLoadingCircle>(
        find.byType(AuraLoadingCircle),
      );
      expect(loadingCircle.size, 20);
      expect(find.text('Test Tile'), findsNothing);
      await tester.tap(find.byType(AuraTile));
      await tester.pump();
      expect(wasTapped, false);
    });

    testWidgets('handles disabled state correctly', (tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () => wasTapped = true,
              enabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraTile));
      await tester.pump();

      expect(wasTapped, false);
    });

    testWidgets('activates by tap and keyboard when enabled', (tester) async {
      var presses = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () => presses++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraTile));
      await tester.pump();
      expect(presses, 1);

      final _ = await tester.sendKeyEvent(.tab);
      await tester.pump();
      final _ = await tester.sendKeyEvent(.enter);
      await tester.pump();

      expect(presses, 2);
    });

    testWidgets('renders every variant and size', (tester) async {
      for (final variant in AuraTileVariant.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraTile(
                child: const Text('Test Tile'),
                onTap: () {
                  final _ = Object();
                },
                variant: variant,
              ),
            ),
          ),
        );

        expect(find.byType(AuraTile), findsOneWidget, reason: '$variant');
        expect(find.text('Test Tile'), findsOneWidget, reason: '$variant');
      }

      for (final size in AuraTileSize.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuraTile(
                child: const Text('Test Tile'),
                onTap: () {
                  final _ = Object();
                },
                size: size,
              ),
            ),
          ),
        );

        expect(find.byType(AuraTile), findsOneWidget, reason: '$size');
        expect(find.text('Test Tile'), findsOneWidget, reason: '$size');
      }
    });

    testWidgets('uses theme colors for ghost and selected text', (
      tester,
    ) async {
      final colors = AuraTheme.light.colors;
      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AuraTile(child: Text('Ghost tile'), variant: .ghost),
                  AuraTile(child: Text('Selected tile'), variant: .selected),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        DefaultTextStyle.of(tester.element(find.text('Ghost tile')))
            .style
            .color,
        colors.foregroundOnSurface,
      );
      expect(
        DefaultTextStyle.of(tester.element(find.text('Selected tile')))
            .style
            .color,
        colors.primary,
      );
    });
  });
}
