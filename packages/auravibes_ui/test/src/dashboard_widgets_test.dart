import 'dart:typed_data';

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 280, child: child)),
    ),
    theme: ThemeData(extensions: [AuraTheme.light]),
  );

  testWidgets('avatar preserves labeled fallback when image fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        AuraAvatar(
          child: const Text('AL'),
          imageProvider: MemoryImage(Uint8List.fromList([0])),
          semanticLabel: 'Alex Lee',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.text('AL'), findsOneWidget);
    expect(find.bySemanticsLabel('Alex Lee'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avatar group limits visible members and labels overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const AuraAvatarGroup(
          children: [
            AuraAvatar(child: Text('A')),
            AuraAvatar(child: Text('B')),
            AuraAvatar(child: Text('C')),
          ],
          maxVisible: 1,
          overflowSemanticLabel: '2 more people',
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
    expect(find.bySemanticsLabel('2 more people'), findsOneWidget);
  });

  testWidgets('scalar table scrolls, shows caption and empty rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const AuraTable(
          columns: ['Name', 'Quantity', 'Available', 'Notes'],
          rows: [
            ['Sample', 12, true, 'A long note that requires scrolling'],
          ],
          caption: Text('Inventory'),
        ),
      ),
    );
    expect(find.text('Inventory'), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-300, 0),
    );
    final _ = await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    await tester.pumpWidget(app(const AuraTable(columns: ['Name'], rows: [])));
    expect(find.text('Name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('table rejects mismatched and non-scalar rows', (tester) async {
    for (final rows in <List<List<Object?>>>[
      [[]],
      [
        [<String>[]],
      ],
      [
        [double.nan],
      ],
    ]) {
      await tester.pumpWidget(
        app(AuraTable(columns: const ['Name'], rows: rows)),
      );
      expect(tester.takeException(), isArgumentError);
    }
  });

  testWidgets('charts render signed, constant, empty and extreme series', (
    tester,
  ) async {
    for (final type in AuraChartType.values) {
      final valuesByType =
          type == AuraChartType.pie || type == AuraChartType.donut
          ? <List<double>>[
              [],
              [0],
              [2, 2],
              [double.maxFinite, double.maxFinite],
            ]
          : <List<double>>[
              [],
              [0],
              [2, 2],
              [-2, 3],
              [-double.maxFinite, double.maxFinite],
            ];
      for (final values in valuesByType) {
        await tester.pumpWidget(
          app(
            AuraChart(
              labels: List.generate(values.length, (index) => '$index'),
              series: [AuraChartSeries(label: 'Samples', values: values)],
              semanticLabel: 'Sample summary',
              type: type,
            ),
          ),
        );
        expect(find.bySemanticsLabel('Sample summary'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('chart rejects missing summary and mismatched data', (
    tester,
  ) async {
    for (final chart in [
      const AuraChart(labels: [], series: [], semanticLabel: ''),
      const AuraChart(
        labels: ['A'],
        series: [AuraChartSeries(label: 'S', values: [])],
        semanticLabel: 'S',
      ),
      const AuraChart(
        labels: ['A'],
        series: [
          AuraChartSeries(label: 'S', values: [double.infinity]),
        ],
        semanticLabel: 'S',
      ),
    ]) {
      await tester.pumpWidget(app(chart));
      expect(tester.takeException(), isArgumentError);
    }
  });

  testWidgets('empty state renders caller action', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      app(
        AuraEmptyState(
          title: const Text('No items'),
          description: const Text('Add one'),
          action: AuraButton(
            onPressed: () => pressed = true,
            child: const Text('Add'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    final _ = await tester.pumpAndSettle();
    expect(pressed, isTrue);
  });

  testWidgets(
    'content replaces immediately with motion disabled or ticker muted',
    (tester) async {
      for (final mode in ['ticker', 'motion', 'navigation', 'none']) {
        for (final text in ['Before', 'After']) {
          await tester.pumpWidget(
            app(
              MediaQuery(
                data: MediaQueryData(
                  accessibleNavigation: mode == 'navigation',
                  disableAnimations: mode == 'motion',
                ),
                child: TickerMode(
                  enabled: mode != 'ticker',
                  child: AuraAnimatedContent(
                    child: Text(text, key: ValueKey(text)),
                    transition: mode == 'none'
                        ? AuraContentTransition.none
                        : AuraContentTransition.fade,
                  ),
                ),
              ),
            ),
          );
        }
        expect(find.text('Before'), findsNothing);
        expect(find.text('After'), findsOneWidget);
        expect(find.byType(AnimatedSwitcher), findsNothing);
      }
    },
  );

  testWidgets('enabled fade retires old keyed content', (tester) async {
    for (final text in ['Before', 'After']) {
      await tester.pumpWidget(
        app(AuraAnimatedContent(child: Text(text, key: ValueKey(text)))),
      );
    }
    expect(find.text('Before'), findsOneWidget);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Before'), findsNothing);
    expect(find.text('After'), findsOneWidget);
  });
}
