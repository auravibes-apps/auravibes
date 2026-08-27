import 'dart:ui' as ui;

import 'package:auravibes_ui/src/organisms/aura_date_time_input.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraDateTimeInput', () {
    testWidgets('propagates a date-only selection', (tester) async {
      DateTime? changedValue;
      final initialValue = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraDateTimeInput(
              value: initialValue,
              enableTime: false,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraDateTimeInput));
      final _ = await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('auraDateTimeInputPicker')),
        findsOneWidget,
      );
      expect(find.text('2024-01'), findsOneWidget);
      await tester.tap(find.text('20'));
      await tester.tap(find.text('Done'));
      final _ = await tester.pumpAndSettle();

      expect(changedValue, DateTime(2024, 1, 20));
    });

    testWidgets('propagates a time-only selection', (tester) async {
      DateTime? changedValue;
      final initialValue = DateTime(2024, 1, 15, 9);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraDateTimeInput(
              value: initialValue,
              enableDate: false,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraDateTimeInput));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Select time'), findsOneWidget);
      await tester.tap(find.text('Done'));
      final _ = await tester.pumpAndSettle();

      expect(changedValue, initialValue);
    });

    testWidgets('does not propagate a cancelled selection', (tester) async {
      DateTime? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraDateTimeInput(
              value: DateTime(2024, 1, 15),
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraDateTimeInput));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      expect(changedValue, isNull);
    });

    testWidgets('does not open when disabled', (tester) async {
      DateTime? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuraDateTimeInput(
              enabled: false,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraDateTimeInput), warnIfMissed: false);
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auraDateTimeInputPicker')),
        findsNothing,
      );
      expect(changedValue, isNull);
    });

    testWidgets('does not close when the modal background is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AuraDateTimeInput(value: DateTime(2024, 1, 15))),
        ),
      );

      await tester.tap(find.byType(AuraDateTimeInput));
      final _ = await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auraDateTimeInputPicker')),
        findsOneWidget,
      );
    });

    testWidgets('picker inherits the active Aura theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AuraDateTimeInput(value: DateTime(2024, 1, 15))),
          theme: ThemeData(extensions: [AuraTheme.dark]),
        ),
      );

      await tester.tap(find.byType(AuraDateTimeInput));
      final _ = await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('auraDateTimeInputPicker')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color ==
                    AuraTheme.dark.colors.surface,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('picker inherits the active text scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: AuraDateTimeInput(value: DateTime(2024, 1, 15)),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraDateTimeInput));
      final _ = await tester.pumpAndSettle();

      final title = tester.renderObject<RenderParagraph>(
        find.text('Select date and time'),
      );
      expect(title.textScaler.scale(10), 20);
    });

    testWidgets('picker uses the nearest navigator', (tester) async {
      final rootNavigatorKey = GlobalKey<NavigatorState>();
      final nestedNavigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: Navigator(
            key: nestedNavigatorKey,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                body: AuraDateTimeInput(value: DateTime(2024, 1, 15)),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuraDateTimeInput));
      final _ = await tester.pumpAndSettle();

      expect(nestedNavigatorKey.currentState?.canPop(), isTrue);
      expect(rootNavigatorKey.currentState?.canPop(), isFalse);
    });

    testWidgets('picker controls expose hover feedback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AuraDateTimeInput(value: DateTime(2024, 1, 15))),
        ),
      );

      await tester.tap(find.byType(AuraDateTimeInput));
      final _ = await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is FocusableActionDetector &&
              widget.onShowHoverHighlight != null,
        ),
        findsAtLeastNWidgets(2),
      );
    });

    testWidgets('exposes semantic label and enabled state', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraDateTimeInput(semanticLabel: 'Start date and time'),
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(AuraDateTimeInput));

      expect(node.label, 'Start date and time');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, ui.Tristate.isTrue);

      semantics.dispose();
    });
  });
}
