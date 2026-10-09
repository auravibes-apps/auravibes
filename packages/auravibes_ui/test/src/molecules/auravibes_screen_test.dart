import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraScreen', () {
    testWidgets('renders default standard screen child', (tester) async {
      const childText = 'Screen Content';

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: const AuraScreen(child: Text(childText)),
            theme: .new(),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AuraTheme.light.colors.background);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('renders explicit standard screen with padding', (
      tester,
    ) async {
      const padding = AuraEdgeInsetsGeometry.medium;

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: const AuraScreen(child: SizedBox(), padding: padding),
            theme: .new(),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AuraTheme.light.colors.background);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(AuraPadding), findsOneWidget);
    });

    testWidgets('renders aurora variant with mesh gradient and blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: const AuraScreen(child: SizedBox(), variant: .aurora),
            theme: .new(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('renders AppBar properties and body layout', (tester) async {
      final bodyKey = UniqueKey();
      const leadingWidth = 96.0;

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: AuraScreen(
              child: SizedBox(key: bodyKey, height: 20),
              appBar: const AuraAppBar(
                title: Text('My Screen'),
                leading: Text('Back Button'),
                leadingWidth: leadingWidth,
              ),
            ),
            theme: .new(),
          ),
        ),
      );

      expect(find.text('My Screen'), findsOneWidget);
      expect(find.text('Back Button'), findsOneWidget);
      expect(find.byType(AuraAppBar), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      final title = tester.widget<AuraText>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(AuraText),
        ),
      );
      expect(title.style, AuraTextStyle.heading5);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.leadingWidth, leadingWidth);

      final appBarBottom = tester.getBottomRight(find.byType(AppBar)).dy;
      final bodyTop = tester.getTopLeft(find.byKey(bodyKey)).dy;
      expect(bodyTop, closeTo(appBarBottom, 0.01));
    });
  });
}
