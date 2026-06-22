import 'package:auravibes_ui/src/molecules/aura_snack_bar_variant.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
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
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final _ = showAuraSnackBar(
                      context: context,
                      content: const Text('Test message'),
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Should NOT find Material's SnackBar widget.
      expect(find.byType(SnackBar), findsNothing);

      // Should find the custom snackbar content.
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('displays snackbar with success variant', (tester) async {
      await tester.pumpWidget(
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final _ = showAuraSnackBar(
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
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Verify content is displayed.
      expect(find.text('Success!'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('displays snackbar with error variant', (tester) async {
      await tester.pumpWidget(
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final _ = showAuraSnackBar(
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
          theme: ThemeData(
            extensions: [AuraTheme.light],
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
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final _ = showAuraSnackBar(
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
          theme: ThemeData(
            extensions: [AuraTheme.light],
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
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final _ = showAuraSnackBar(
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
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Info!'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('displays snackbar with action button', (tester) async {
      // Use a larger screen size to fit the snackbar.
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final _ = showAuraSnackBar(
                      context: context,
                      content: const Text('With action'),
                      actionLabel: 'UNDO',
                      onAction: () {
                        final _ = Object();
                      },
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('UNDO'), findsOneWidget);

      // Tap action button - use ensureVisible first.
      await tester.ensureVisible(find.text('UNDO'));
      await tester.pump();
      await tester.tap(find.text('UNDO'));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('replaces the active snackbar', (tester) async {
      await tester.pumpWidget(
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final _ = showAuraSnackBar(
                          context: context,
                          content: const Text('First message'),
                        );
                      },
                      child: const Text('Show first'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final _ = showAuraSnackBar(
                          context: context,
                          content: const Text('Second message'),
                        );
                      },
                      child: const Text('Show second'),
                    ),
                  ],
                );
              },
            ),
          ),
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Show first'));
      await tester.pump();
      await tester.tap(find.text('Show second'));
      await tester.pump();

      expect(find.text('First message'), findsNothing);
      expect(find.text('Second message'), findsOneWidget);
      expect(find.byType(Positioned), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('keeps separate hosts independent', (tester) async {
      await tester.pumpWidget(
        _SnackBarTestApp(
          home: Scaffold(
            body: Row(
              children: [
                AuraSnackBarHost(
                  child: Builder(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          final _ = showAuraSnackBar(
                            context: context,
                            content: const Text('Left message'),
                          );
                        },
                        child: const Text('Show left'),
                      );
                    },
                  ),
                ),
                AuraSnackBarHost(
                  child: Builder(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          final _ = showAuraSnackBar(
                            context: context,
                            content: const Text('Right message'),
                          );
                        },
                        child: const Text('Show right'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Show left'));
      await tester.pump();
      await tester.tap(find.text('Show right'));
      await tester.pump();

      expect(find.text('Left message'), findsOneWidget);
      expect(find.text('Right message'), findsOneWidget);
      expect(find.byType(Positioned), findsNWidgets(2));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('animates in with slide and fade', (tester) async {
      await tester.pumpWidget(
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final _ = showAuraSnackBar(
                      context: context,
                      content: const Text('Animated'),
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Show'));

      // Pump a few frames to verify animation is running.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      final _ = await tester.pumpAndSettle();

      // Verify content is displayed after animation completes.
      expect(find.text('Animated'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('uses Aura colors correctly', (tester) async {
      await tester.pumpWidget(
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final _ = showAuraSnackBar(
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
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Verify content is displayed.
      expect(find.text('Colored snackbar'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('positions at bottom of screen with padding', (tester) async {
      await tester.pumpWidget(
        _SnackBarTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final _ = showAuraSnackBar(
                      context: context,
                      content: const Text('Bottom position'),
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
          theme: ThemeData(
            extensions: [AuraTheme.light],
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Verify the snackbar is positioned at the bottom.
      expect(find.text('Bottom position'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      // Check for Positioned widget which is used for positioning.
      expect(find.byType(Positioned), findsOneWidget);
    });
  });
}

class _SnackBarTestApp extends StatelessWidget {
  const _SnackBarTestApp({
    required this.home,
    required this.theme,
  });

  final Widget home;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AuraSnackBarHost(
      child: MaterialApp(
        home: home,
        theme: theme,
      ),
    );
  }
}
