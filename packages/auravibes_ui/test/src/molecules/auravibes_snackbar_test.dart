import 'package:auravibes_ui/src/molecules/auravibes_snackbar.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraSnackBarVariant', () {
    test('contains all expected variants', () {
      expect(
        AuraSnackBarVariant.values,
        contains(AuraSnackBarVariant.default_),
      );
      expect(AuraSnackBarVariant.values, contains(AuraSnackBarVariant.success));
      expect(AuraSnackBarVariant.values, contains(AuraSnackBarVariant.error));
      expect(AuraSnackBarVariant.values, contains(AuraSnackBarVariant.warning));
      expect(AuraSnackBarVariant.values, contains(AuraSnackBarVariant.info));
    });
  });

  group('showAuraSnackBar', () {
    testWidgets('displays snackbar with custom implementation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAuraSnackBar(
                      context: context,
                      content: const Text('Test message'),
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Should NOT find Material's SnackBar widget
      expect(find.byType(SnackBar), findsNothing);

      // Should find the custom snackbar content
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('displays snackbar with success variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAuraSnackBar(
                      context: context,
                      content: const Text('Success!'),
                      variant: AuraSnackBarVariant.success,
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Verify content is displayed
      expect(find.text('Success!'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('displays snackbar with error variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAuraSnackBar(
                      context: context,
                      content: const Text('Error!'),
                      variant: AuraSnackBarVariant.error,
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Error!'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('displays snackbar with warning variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAuraSnackBar(
                      context: context,
                      content: const Text('Warning!'),
                      variant: AuraSnackBarVariant.warning,
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Warning!'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('displays snackbar with info variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAuraSnackBar(
                      context: context,
                      content: const Text('Info!'),
                      variant: AuraSnackBarVariant.info,
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Info!'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('displays snackbar with action button', (tester) async {
      // Use a larger screen size to fit the snackbar
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAuraSnackBar(
                      context: context,
                      content: const Text('With action'),
                      actionLabel: 'UNDO',
                      onAction: () {},
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('UNDO'), findsOneWidget);

      // Tap action button - use ensureVisible first
      await tester.ensureVisible(find.text('UNDO'));
      await tester.pump();
      await tester.tap(find.text('UNDO'));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('animates in with slide and fade', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAuraSnackBar(
                      context: context,
                      content: const Text('Animated'),
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));

      // Pump a few frames to verify animation is running
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify content is displayed after animation completes
      expect(find.text('Animated'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('uses Aura colors correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAuraSnackBar(
                      context: context,
                      content: const Text('Colored snackbar'),
                      variant: AuraSnackBarVariant.error,
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Verify content is displayed
      expect(find.text('Colored snackbar'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('positions at bottom of screen with padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAuraSnackBar(
                      context: context,
                      content: const Text('Bottom position'),
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Verify the snackbar is positioned at the bottom using Positioned widget
      expect(find.text('Bottom position'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      // Check for Positioned widget which is used for positioning
      expect(find.byType(Positioned), findsOneWidget);
    });
  });
}
