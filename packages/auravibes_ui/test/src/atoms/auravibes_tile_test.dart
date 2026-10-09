import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/atoms/aura_tile.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
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
