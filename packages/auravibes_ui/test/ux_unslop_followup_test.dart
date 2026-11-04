import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class const _TestApp({required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraThemeScope(
    theme: .light,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('tag removal remains accessible and works', (tester) async {
    final handle = tester.ensureSemantics();
    List<String>? changed;
    await tester.pumpWidget(
      _TestApp(
        child: AuraTagInput(
          value: const ['Work'],
          onChanged: (value) => changed = value,
          removeLabel: (tag) => 'Remove $tag',
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byTooltip('Remove Work')).tooltip,
      'Remove Work',
    );
    await tester.tap(find.byTooltip('Remove Work'));
    expect(changed, isEmpty);
    handle.dispose();
  });

  testWidgets('wrapped tab titles expose their names', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _TestApp(
        child: AuraTabs<void>(
          items: [
            AuraTabItem(
              title: Builder(builder: (_) => const Text('Security')),
              child: const Text('Content'),
            ),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Security'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Security')).role,
      SemanticsRole.tab,
    );
    handle.dispose();
  });

  testWidgets('interactive tile preserves visible content semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _TestApp(
        child: AuraTile(
          child: const Text('Theme'),
          onTap: () {
            return;
          },
          trailing: const Text('Dark'),
        ),
      ),
    );
    final data = tester.getSemantics(find.byType(AuraTile)).getSemanticsData();
    expect(data.label, contains('Theme'));
    expect(data.label, contains('Dark'));
    handle.dispose();
  });

  testWidgets('modal trigger preserves its child name', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const _TestApp(
        child: AuraModal(
          entryPointChild: Text('Open details'),
          contentChild: Text('Details'),
          barrierLabel: 'Dismiss',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Open details'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('modal trigger merges a button child name', (tester) async {
    final handle = tester.ensureSemantics();
    var childTaps = 0;
    await tester.pumpWidget(
      _TestApp(
        child: AuraModal(
          entryPointChild: AuraButton(
            onPressed: () => childTaps++,
            child: const Text('Open details'),
          ),
          contentChild: const Text('Details'),
          barrierLabel: 'Dismiss',
        ),
      ),
    );
    final node = tester.getSemantics(find.byType(MergeSemantics).first);
    expect(node.getSemanticsData().label, 'Open details');
    node.owner?.performAction(node.id, .tap);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    expect(childTaps, 0);
    handle.dispose();
  });

  testWidgets('collapsed sidebar preserves names without overrides', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _TestApp(
        child: AuraSidebar(
          navigationItems: const [
            AuraNavigationData(icon: Icon(Icons.home), label: Text('Home')),
            AuraNavigationData(
              icon: Icon(Icons.settings),
              label: Text('Settings'),
            ),
          ],
          onNavigationTap: (_) {
            return;
          },
          isExpanded: false,
        ),
      ),
    );
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('slider semantic values use the display formatter', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _TestApp(
        child: AuraLabeledSlider(
          value: 0.5,
          onChanged: (_) {
            return;
          },
          step: 0.1,
          label: 'Volume',
          valueFormatter: (value) => '${(value * 100).round()}%',
        ),
      ),
    );
    expect(find.text('50%'), findsOneWidget);
    expect(tester.getSemantics(find.byType(AuraSlider)).value, '50%');
    handle.dispose();
  });

  testWidgets('scaled tab and slider labels have their full height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: .linear(3)),
          child: Column(
            children: [
              const AuraTabs<void>(
                items: [
                  AuraTabItem(title: Text('Security'), child: Text('Content')),
                ],
              ),
              AuraLabeledSlider(
                value: 0.5,
                onChanged: (_) {
                  return;
                },
                step: 0.1,
                marks: const [AuraSliderMark(value: 0.5, label: 'Medium')],
              ),
            ],
          ),
        ),
      ),
    );
    for (final label in ['Security', 'Medium']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(
        paragraph.size.height,
        greaterThanOrEqualTo(paragraph.getMaxIntrinsicHeight(.infinity)),
      );
    }
  });

  testWidgets('checkbox row announces its title once', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _TestApp(
        child: AuraCheckboxListTile(
          value: false,
          onChanged: (_) {
            return;
          },
          title: const Text('Enable sync'),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Enable sync'), findsOneWidget);
    expect(find.bySemanticsLabel('Checkbox'), findsNothing);
    handle.dispose();
  });

  testWidgets('pie legend maps each category to a distinct default tint', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: AuraChart(
          labels: ['Home', 'Food', 'Travel'],
          series: [
            AuraChartSeries(label: 'Spending', values: [60, 25, 15]),
          ],
          semanticLabel: 'Home 60, Food 25, Travel 15',
          type: .pie,
        ),
      ),
    );
    Color swatch(String label) {
      final row = find
          .ancestor(of: find.text(label), matching: find.byType(Row))
          .first;

      return tester
          .widget<ColoredBox>(
            find.descendant(of: row, matching: find.byType(ColoredBox)),
          )
          .color;
    }

    final colors = [
      swatch('Home: 60'),
      swatch('Food: 25'),
      swatch('Travel: 15'),
    ];
    expect(colors.toSet(), hasLength(3));
  });

  testWidgets('cartesian legend shows labels, values and units', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: AuraChart(
          labels: ['Mon', 'Tue'],
          series: [
            AuraChartSeries(label: 'Completed', values: [4, 8]),
          ],
          semanticLabel: 'Completed Monday 4, Tuesday 8 tasks',
          type: .bar,
          unit: 'tasks',
        ),
      ),
    );
    expect(find.text('Completed (tasks): Mon 4, Tue 8'), findsOneWidget);
  });

  testWidgets(
    'indeterminate progress differs from 35 percent in reduced motion',
    (tester) async {
      await tester.pumpWidget(
        const _TestApp(
          child: MediaQuery(
            data: .new(disableAnimations: true),
            child: Column(
              children: [
                AuraLinearProgressIndicator(key: ValueKey('unknown')),
                AuraLinearProgressIndicator(
                  value: 0.35,
                  key: ValueKey('known'),
                ),
              ],
            ),
          ),
        ),
      );
      FractionallySizedBox fill(String key) => tester.widget(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(fill('unknown').alignment, AlignmentDirectional.center);
      expect(fill('known').alignment, AlignmentDirectional.centerStart);
    },
  );

  testWidgets(
    'table shows and announces sort direction and supports keyboard',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const _TestApp(
          child: AuraTable(
            columns: ['Name'],
            rows: [
              ['Zed'],
              ['Ada'],
            ],
            sortableColumns: [true],
            ascendingLabel: 'Ascending',
            descendingLabel: 'Descending',
          ),
        ),
      );
      final _ = await tester.sendKeyEvent(.tab);
      final _ = await tester.sendKeyEvent(.enter);
      await tester.pump();
      expect(find.text(.fromCharCode(0x2191)), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Ada')).dy,
        lessThan(tester.getTopLeft(find.text('Zed')).dy),
      );
      expect(tester.getSemantics(find.text('Name')).value, 'Ascending');
      final _ = await tester.sendKeyEvent(.enter);
      await tester.pump();
      expect(find.text(.fromCharCode(0x2193)), findsOneWidget);
      expect(tester.getSemantics(find.text('Name')).value, 'Descending');
      handle.dispose();
    },
  );

  testWidgets('stats stay flat inside existing surfaces', (tester) async {
    await tester.pumpWidget(
      const _TestApp(
        child: AuraCard(
          child: AuraStat(value: '11', label: 'Tasks'),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(AuraStat),
        matching: find.byType(AuraCard),
      ),
      findsNothing,
    );
  });

  testWidgets('ratings and step states accept caller text', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _TestApp(
        child: Column(
          children: [
            AuraRating(
              value: 2,
              onChanged: (_) {
                return;
              },
              label: 'Rating',
              semanticValue: '2 de 5',
            ),
            const AuraStepper(
              steps: [
                AuraStep(
                  title: 'Review',
                  state: .current,
                  semanticLabel: 'Actual',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(tester.getSemantics(find.byType(AuraRating)).value, '2 de 5');
    expect(find.bySemanticsLabel('Actual'), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'labeled badges preserve nested actions without repeating simple labels',
    (tester) async {
      final handle = tester.ensureSemantics();
      var removed = false;
      await tester.pumpWidget(
        _TestApp(
          child: Column(
            children: [
              AuraBadge.text(
                child: const Text('Status'),
                semanticLabel: 'Status',
              ),
              AuraBadge(
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    const Text('Work'),
                    IconButton(
                      onPressed: () => removed = true,
                      tooltip: 'Remove Work',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                semanticLabel: 'Work tag',
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Status'), findsOneWidget);
      expect(
        tester.getSemantics(find.byTooltip('Remove Work')).tooltip,
        'Remove Work',
      );
      await tester.tap(find.byTooltip('Remove Work'));
      expect(removed, isTrue);
      handle.dispose();
    },
  );

  testWidgets('labeled tiles preserve independent trailing actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var edited = false;
    await tester.pumpWidget(
      _TestApp(
        child: AuraTile(
          child: const Text('Theme'),
          onTap: () {
            return;
          },
          trailing: IconButton(
            onPressed: () => edited = true,
            tooltip: 'Edit theme',
            icon: const Icon(Icons.edit),
          ),
          semanticLabel: 'Appearance',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Appearance'), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip('Edit theme')).tooltip,
      'Edit theme',
    );
    await tester.tap(find.byTooltip('Edit theme'));
    expect(edited, isTrue);
    handle.dispose();
  });

  testWidgets('indeterminate progress moves when motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(child: AuraLinearProgressIndicator()),
    );
    final finder = find.byType(FractionallySizedBox);
    final before = tester.widget<FractionallySizedBox>(finder).alignment;
    await tester.pump(const Duration(milliseconds: 300));
    final after = tester.widget<FractionallySizedBox>(finder).alignment;
    expect(after, isNot(before));
  });
}
