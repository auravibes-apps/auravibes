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
              onTap: () {},
              child: const Text('Test Tile'),
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
              onTap: () {},
              child: const Text('Test Tile'),
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
              onTap: () {},
              isLoading: true,
              child: const Text('Test Tile'),
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
              onTap: () {},
              leading: const Icon(Icons.star),
              trailing: const Icon(Icons.arrow_forward),
              child: const Text('Test Tile'),
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
              onTap: () => wasTapped = true,
              enabled: false,
              child: const Text('Test Tile'),
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
              onTap: () => wasTapped = true,
              child: const Text('Test Tile'),
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
              onTap: () => wasTapped = true,
              isLoading: true,
              child: const Text('Test Tile'),
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
                  onTap: () {},
                  variant: variant,
                  child: const Text('Test Tile'),
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
                  onTap: () {},
                  size: size,
                  child: const Text('Test Tile'),
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
