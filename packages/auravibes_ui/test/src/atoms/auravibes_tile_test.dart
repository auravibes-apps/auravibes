import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/atoms/aura_tile.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraTile', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Tile'), findsOneWidget);
      expect(find.byType(AuraTile), findsOneWidget);
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

    testWidgets('has correct width (full width)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () {
                final _ = Object();
              },
            ),
          ),
        ),
      );

      final tile = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(tile.width, double.infinity);
    });

    testWidgets('shows loading state correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () {
                final _ = Object();
              },
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
    });

    testWidgets('renders leading and trailing widgets', (tester) async {
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

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('Test Tile'), findsOneWidget);
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

    testWidgets('calls onTap when enabled', (tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraTile));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('can be focused and activated with keyboard', (tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      final _ = await tester.sendKeyEvent(.tab);
      await tester.pump();
      final _ = await tester.sendKeyEvent(.enter);
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('does not call onTap when loading', (tester) async {
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

      await tester.tap(find.byType(AuraTile));
      await tester.pump();

      expect(wasTapped, false);
    });

    group('variants', () {
      for (final variant in AuraTileVariant.values) {
        testWidgets('renders $variant variant', (tester) async {
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

          expect(find.byType(AuraTile), findsOneWidget);
          expect(find.text('Test Tile'), findsOneWidget);
        });
      }
    });

    testWidgets('ghost text uses the surface foreground', (tester) async {
      final colors = AuraTheme.light.colors;

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: const MaterialApp(
            home: Scaffold(
              body: AuraTile(child: Text('Ghost tile'), variant: .ghost),
            ),
          ),
        ),
      );

      final textContext = tester.element(find.text('Ghost tile'));
      expect(
        DefaultTextStyle.of(textContext).style.color,
        colors.foregroundOnSurface,
      );
    });

    testWidgets('selected text keeps the primary accent', (tester) async {
      final colors = AuraTheme.light.colors;

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: const MaterialApp(
            home: Scaffold(
              body: AuraTile(child: Text('Selected tile'), variant: .selected),
            ),
          ),
        ),
      );

      final textContext = tester.element(find.text('Selected tile'));
      expect(DefaultTextStyle.of(textContext).style.color, colors.primary);
    });

    group('sizes', () {
      for (final size in AuraTileSize.values) {
        testWidgets('renders $size size', (tester) async {
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

          expect(find.byType(AuraTile), findsOneWidget);
          expect(find.text('Test Tile'), findsOneWidget);
        });
      }
    });
  });
}
