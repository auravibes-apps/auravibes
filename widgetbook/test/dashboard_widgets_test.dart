import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_workspace/aura_ui/auravibes_choice_picker.stories.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('dashboard examples ${brightness.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final theme = brightness == Brightness.light
          ? AuraTheme.light
          : AuraTheme.dark;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey('dashboard'),
              child: ColoredBox(
                color: theme.colors.surface,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      spacing: 24,
                      children: [
                        const AuraAvatarGroup(
                          children: [
                            AuraAvatar(
                              child: Text('AL'),
                              semanticLabel: 'Alex Lee',
                            ),
                            AuraAvatar(
                              child: Text('SR'),
                              semanticLabel: 'Sam Rivera',
                            ),
                            AuraAvatar(
                              child: Text('JT'),
                              semanticLabel: 'Jamie Taylor',
                            ),
                          ],
                          maxVisible: 2,
                          overflowSemanticLabel: '1 more person',
                        ),
                        Row(
                          spacing: 24,
                          children: [
                            for (final type in const [
                              AuraChartType.line,
                              AuraChartType.bar,
                            ])
                              Expanded(
                                child: AuraChart(
                                  labels: const ['A', 'B', 'C'],
                                  series: const [
                                    AuraChartSeries(
                                      label: 'Samples',
                                      values: [2, -1, 4],
                                    ),
                                    AuraChartSeries(
                                      label: 'Comparison',
                                      values: [1, 3, 2],
                                      tint: AuraTint.secondary,
                                    ),
                                  ],
                                  semanticLabel:
                                      'Samples and comparison over A, B, C.',
                                  type: type,
                                ),
                              ),
                          ],
                        ),
                        const AuraTable(
                          columns: ['Name', 'Count', 'Available'],
                          rows: [
                            ['Sample A', 12, true],
                            ['Sample B', 0, false],
                          ],
                          caption: Text('Inventory'),
                        ),
                        const ChoicePickerDemo(
                          variant: AuraChoicePickerVariant.multipleSelection,
                          tint: AuraTint.primary,
                          presentation: AuraChoicePickerPresentation.chips,
                        ),
                        const AuraAnimatedContent(
                          child: AuraEmptyState(
                            title: Text('No more items'),
                            description: Text('New items appear here.'),
                          ),
                          transition: AuraContentTransition.none,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          theme: ThemeData(extensions: [theme], brightness: brightness),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Samples'), findsNWidgets(2));
      expect(find.text('Comparison'), findsNWidgets(2));
      await expectLater(
        find.byKey(const ValueKey('dashboard')),
        matchesGoldenFile('goldens/dashboard_${brightness.name}.png'),
      );
    });
  }
}
