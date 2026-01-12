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

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ColoredBox), findsWidgets);
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

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(BackdropFilter), findsOneWidget);
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
      expect(find.byType(AppBar), findsOneWidget);
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

      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(BackdropFilter), findsOneWidget);
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

      expect(find.text(customLeadingText), findsOneWidget);
      expect(find.byType(AuraAppBar), findsOneWidget);
    });
  });
}
