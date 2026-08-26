import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraList', () {
    testWidgets('renders an empty scrollable list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuraList(children: [])),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Flex), findsOneWidget);
    });

    testWidgets('renders children vertically by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraList(children: [Text('First'), Text('Second')]),
          ),
        ),
      );

      final list = tester.widget<AuraList>(find.byType(AuraList));
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final flex = tester.widget<Flex>(find.byType(Flex));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(list.direction, Axis.vertical);
      expect(scrollView.scrollDirection, Axis.vertical);
      expect(flex.direction, Axis.vertical);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.stretch);
    });

    testWidgets('renders children horizontally with requested alignment', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuraList(
              children: [Text('First'), Text('Second')],
              direction: Axis.horizontal,
              alignment: CrossAxisAlignment.center,
            ),
          ),
        ),
      );

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final flex = tester.widget<Flex>(find.byType(Flex));

      expect(scrollView.scrollDirection, Axis.horizontal);
      expect(flex.direction, Axis.horizontal);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.center);
    });

    testWidgets('scrolls within bounded constraints', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: ValueKey('bounded-list'),
                width: 120,
                height: 80,
                child: AuraList(children: [SizedBox(height: 160)]),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('bounded-list'))),
        const Size(120, 80),
      );
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('shrink-wraps in an unbounded scroll axis', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuraList(children: [SizedBox(height: 24)]),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AuraList)), const Size(800, 24));
    });
  });
}
