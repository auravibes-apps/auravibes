import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraScreen', () {
    testWidgets('renders child content correctly', (tester) async {
      const childText = 'Screen Content';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AuraTheme.light,
            ],
          ),
          home: const AuraScreen(
            child: Text(childText),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
    });

    testWidgets('renders standard variant with solid background', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AuraTheme.light,
            ],
          ),
          home: const AuraScreen(
            variant: AuraScreenVariation.standard,
            child: SizedBox(),
          ),
        ),
      );

      // Standard variant uses ColoredBox
      // We look for the specific ColoredBox with the background color
      final coloredBoxFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox &&
            widget.color == AuraTheme.light.colors.background,
      );
      expect(coloredBoxFinder, findsOneWidget);

      // Should not have BackdropFilter (used in aurora)
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('renders aurora variant with mesh gradient and blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AuraTheme.light,
            ],
          ),
          home: const AuraScreen(
            child: SizedBox(),
          ),
        ),
      );

      // Aurora variant uses a Stack for background
      expect(find.byType(Stack), findsWidgets);

      // Should have BackdropFilter for the blur effect
      expect(find.byType(BackdropFilter), findsOneWidget);

      // Verify blur amount
      final backdropFilter = tester.widget<BackdropFilter>(
        find.byType(BackdropFilter),
      );
      final imageFilter = backdropFilter.filter;
      // Note: We can't easily inspect ImageFilter properties in tests without
      // casting to internal types or relying on implementation details, but
      // finding it exists is a good check.
      expect(imageFilter, isNotNull);
    });

    testWidgets('renders AppBar when provided', (tester) async {
      const titleText = 'My Screen';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AuraTheme.light,
            ],
          ),
          home: const AuraScreen(
            appBar: AuraAppBar(
              title: Text(titleText),
            ),
            child: SizedBox(),
          ),
        ),
      );

      expect(find.text(titleText), findsOneWidget);
      expect(find.byType(AuraAppBar), findsOneWidget);
    });

    testWidgets('applies padding when provided', (tester) async {
      const padding = AuraEdgeInsetsGeometry.medium;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AuraTheme.light,
            ],
          ),
          home: const AuraScreen(
            padding: padding,
            child: SizedBox(),
          ),
        ),
      );

      expect(find.byType(AuraPadding), findsOneWidget);
    });

    testWidgets('uses aurora variant by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AuraTheme.light,
            ],
          ),
          home: const AuraScreen(
            child: SizedBox(),
          ),
        ),
      );

      // Should have BackdropFilter (used in aurora)
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets(
      'renders default app bar when provided via AuraScreenDefaults',
      (
        tester,
      ) async {
        const titleText = 'Default Header';

        await tester.pumpWidget(
          AuraScreenDefaults(
            appBarBuilder: (context) => const AuraAppBar(
              title: Text(titleText),
            ),
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AuraTheme.light,
                ],
              ),
              home: const AuraScreen(
                child: SizedBox(),
              ),
            ),
          ),
        );

        expect(find.text(titleText), findsOneWidget);
        expect(find.byType(AuraAppBar), findsOneWidget);
      },
    );

    testWidgets('explicit app bar overrides default app bar', (
      tester,
    ) async {
      const defaultTitle = 'Default Header';
      const explicitTitle = 'Explicit Header';

      await tester.pumpWidget(
        AuraScreenDefaults(
          appBarBuilder: (context) => const AuraAppBar(
            title: Text(defaultTitle),
          ),
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AuraTheme.light,
              ],
            ),
            home: const AuraScreen(
              appBar: AuraAppBar(
                title: Text(explicitTitle),
              ),
              child: SizedBox(),
            ),
          ),
        ),
      );

      // Should only see explicit app bar, not default
      expect(find.text(explicitTitle), findsOneWidget);
      expect(find.text(defaultTitle), findsNothing);
    });

    testWidgets('renders AuraAppBar with leading widget', (tester) async {
      const titleText = 'Screen with Leading';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AuraTheme.light,
            ],
          ),
          home: const AuraScreen(
            appBar: AuraAppBar(
              title: Text(titleText),
              leading: Text('Leading'),
            ),
            child: SizedBox(),
          ),
        ),
      );

      expect(find.text(titleText), findsOneWidget);
      expect(find.text('Leading'), findsOneWidget);
      expect(find.byType(AuraAppBar), findsOneWidget);
    });

    testWidgets(
      'inherits leading from default when screen provides AppBar '
      'without leading',
      (tester) async {
        const defaultLeadingText = 'Hamburger Menu';
        const screenTitleText = 'My Screen';

        await tester.pumpWidget(
          AuraScreenDefaults(
            appBarBuilder: (context) => const AuraAppBar(
              leading: Text(defaultLeadingText),
            ),
            inheritLeadingWhen: (context) => true,
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AuraTheme.light,
                ],
              ),
              home: const AuraScreen(
                appBar: AuraAppBar(
                  title: Text(screenTitleText),
                ),
                child: SizedBox(),
              ),
            ),
          ),
        );

        // Should see screen's title, not default title
        expect(find.text(screenTitleText), findsOneWidget);
        // Should see default's leading (hamburger)
        expect(find.text(defaultLeadingText), findsOneWidget);
        expect(find.byType(AuraAppBar), findsOneWidget);
      },
    );

    testWidgets(
      'does not inherit leading when inheritLeadingWhen returns false',
      (tester) async {
        const defaultLeadingText = 'Hamburger Menu';
        const screenTitleText = 'My Screen';

        await tester.pumpWidget(
          AuraScreenDefaults(
            appBarBuilder: (context) => const AuraAppBar(
              leading: Text(defaultLeadingText),
            ),
            inheritLeadingWhen: (context) => false,
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AuraTheme.light,
                ],
              ),
              home: const AuraScreen(
                appBar: AuraAppBar(
                  title: Text(screenTitleText),
                ),
                child: SizedBox(),
              ),
            ),
          ),
        );

        // Should NOT see default's leading (hamburger)
        expect(find.text(defaultLeadingText), findsNothing);
        expect(find.byType(AuraAppBar), findsOneWidget);
      },
    );

    testWidgets(
      'does not inherit leading when screen provides its own leading',
      (tester) async {
        const defaultLeadingText = 'Hamburger Menu';
        const screenLeadingText = 'Custom Leading';
        const screenTitleText = 'My Screen';

        await tester.pumpWidget(
          AuraScreenDefaults(
            appBarBuilder: (context) => const AuraAppBar(
              leading: Text(defaultLeadingText),
            ),
            inheritLeadingWhen: (context) => true,
            child: MaterialApp(
              theme: ThemeData(
                extensions: [
                  AuraTheme.light,
                ],
              ),
              home: const AuraScreen(
                appBar: AuraAppBar(
                  title: Text(screenTitleText),
                  leading: Text(screenLeadingText),
                ),
                child: SizedBox(),
              ),
            ),
          ),
        );

        // Should see screen's leading, not default
        expect(find.text(screenLeadingText), findsOneWidget);
        expect(find.text(defaultLeadingText), findsNothing);
      },
    );

    testWidgets('app layer controls leading via AuraAppBar leading parameter', (
      tester,
    ) async {
      const customLeadingText = 'Back Button';
      const screenTitleText = 'My Screen';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AuraTheme.light,
            ],
          ),
          home: const AuraScreen(
            appBar: AuraAppBar(
              title: Text(screenTitleText),
              leading: Text(customLeadingText),
            ),
            child: SizedBox(),
          ),
        ),
      );

      // Should see custom leading provided by app layer
      expect(find.text(customLeadingText), findsOneWidget);
      expect(find.byType(AuraAppBar), findsOneWidget);
    });
  });
}
