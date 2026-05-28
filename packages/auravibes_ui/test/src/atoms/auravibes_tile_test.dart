// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
import 'package:auravibes_ui/src/atoms/aura_tile.dart';
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
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Tile'), findsOneWidget);
      expect(find.byType(AuraTile), findsOneWidget);
    });

    testWidgets('has correct width (full width)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () {},
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
              onTap: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Tile'), findsNothing);
    });

    testWidgets('renders leading and trailing widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraTile(
              child: const Text('Test Tile'),
              onTap: () {},
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
                  onTap: () {},
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

    group('sizes', () {
      for (final size in AuraTileSize.values) {
        testWidgets('renders $size size', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AuraTile(
                  child: const Text('Test Tile'),
                  onTap: () {},
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
