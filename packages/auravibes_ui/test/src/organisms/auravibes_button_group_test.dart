import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/organisms/aura_button_group.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuraButtonGroup', () {
    group('Single mode (.single)', () {
      testWidgets('renders single button group correctly', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(value: 'b', child: Text('B')),
                AuraButtonGroupItem(value: 'c', child: Text('C')),
              ],
              selectedValue: 'a',
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        );

        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
        expect(find.text('C'), findsOneWidget);
      });

      testWidgets('calls onChanged when item is tapped', (tester) async {
        String? receivedValue;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(value: 'b', child: Text('B')),
              ],
              selectedValue: 'a',
              onChanged: (value) => receivedValue = value,
            ),
          ),
        );

        await tester.tap(find.text('B'));
        await tester.pump();

        expect(receivedValue, 'b');
      });

      testWidgets('calls onChanged when item padding is tapped', (
        tester,
      ) async {
        String? receivedValue;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [AuraButtonGroupItem(value: 'a', child: Text('A'))],
              selectedValue: 'selected',
              onChanged: (value) => receivedValue = value,
            ),
          ),
        );

        final itemRect = tester.getRect(find.byType(AnimatedContainer));
        final labelRect = tester.getRect(find.text('A'));
        expect(itemRect.left, lessThan(labelRect.left));

        await tester.tapAt(.new(itemRect.left + 1, itemRect.center.dy));
        await tester.pump();

        expect(receivedValue, 'a');
      });

      testWidgets('does not call onChanged when disabled item is tapped', (
        tester,
      ) async {
        var wasCalled = false;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(
                  value: 'b',
                  child: Text('B'),
                  disabled: true,
                ),
              ],
              selectedValue: 'a',
              onChanged: (_) => wasCalled = true,
            ),
          ),
        );

        await tester.tap(find.text('B'));
        await tester.pump();

        expect(wasCalled, isFalse);
      });

      testWidgets('does not call onChanged when group is disabled', (
        tester,
      ) async {
        var wasCalled = false;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(value: 'b', child: Text('B')),
              ],
              selectedValue: 'a',
              onChanged: (_) => wasCalled = true,
              disabled: true,
            ),
          ),
        );

        await tester.tap(find.text('B'));
        await tester.pump();

        expect(wasCalled, isFalse);
      });

      testWidgets('does not call onChanged when loading', (tester) async {
        var wasCalled = false;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(value: 'b', child: Text('B')),
              ],
              selectedValue: 'a',
              onChanged: (_) => wasCalled = true,
              isLoading: true,
            ),
          ),
        );

        // Find a GestureDetector to tap since loading spinner replaces text.
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        expect(wasCalled, isFalse);
      });

      testWidgets('shows loading indicator when isLoading is true', (
        tester,
      ) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(value: 'b', child: Text('B')),
              ],
              selectedValue: 'a',
              onChanged: (_) {
                final _ = Object();
              },
              isLoading: true,
            ),
          ),
        );

        expect(find.byType(AuraLoadingCircle), findsWidgets);
      });

      testWidgets('shows loading indicator for item-level isLoading', (
        tester,
      ) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(
                  value: 'b',
                  child: Text('B'),
                  isLoading: true,
                ),
              ],
              selectedValue: 'a',
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        );

        expect(find.byType(AuraLoadingCircle), findsOneWidget);
        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsNothing);
      });
    });

    group('Multi mode (.multi)', () {
      testWidgets('renders multi button group correctly', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.multi(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(value: 'b', child: Text('B')),
                AuraButtonGroupItem(value: 'c', child: Text('C')),
              ],
              selectedValues: const {'a', 'c'},
              onMultiChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        );

        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
        expect(find.text('C'), findsOneWidget);
      });

      testWidgets('adds item to selection when tapped', (tester) async {
        Set<String>? receivedValues;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.multi(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(value: 'b', child: Text('B')),
              ],
              selectedValues: const {'a'},
              onMultiChanged: (values) => receivedValues = values,
            ),
          ),
        );

        await tester.tap(find.text('B'));
        await tester.pump();

        expect(receivedValues, {'a', 'b'});
      });

      testWidgets('removes item from selection when already selected', (
        tester,
      ) async {
        Set<String>? receivedValues;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.multi(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(value: 'b', child: Text('B')),
              ],
              selectedValues: const {'a', 'b'},
              onMultiChanged: (values) => receivedValues = values,
            ),
          ),
        );

        await tester.tap(find.text('A'));
        await tester.pump();

        expect(receivedValues, {'b'});
      });

      testWidgets('does not modify selection when disabled', (tester) async {
        var wasCalled = false;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.multi(
              items: const [
                AuraButtonGroupItem(value: 'a', child: Text('A')),
                AuraButtonGroupItem(value: 'b', child: Text('B')),
              ],
              selectedValues: const {'a'},
              onMultiChanged: (_) => wasCalled = true,
              disabled: true,
            ),
          ),
        );

        await tester.tap(find.text('B'));
        await tester.pump();

        expect(wasCalled, isFalse);
      });
    });

    group('Action mode (.action)', () {
      testWidgets('renders action button group correctly', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.action(
              items: const [
                AuraButtonGroupItem(value: 'edit', child: Text('Edit')),
                AuraButtonGroupItem(value: 'delete', child: Text('Delete')),
              ],
              onPressed: (_) {
                final _ = Object();
              },
            ),
          ),
        );

        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('calls onPressed when item is tapped', (tester) async {
        String? pressedValue;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.action(
              items: const [
                AuraButtonGroupItem(value: 'edit', child: Text('Edit')),
                AuraButtonGroupItem(value: 'delete', child: Text('Delete')),
              ],
              onPressed: (value) => pressedValue = value,
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        expect(pressedValue, 'delete');
      });

      testWidgets('does not call onPressed when disabled', (tester) async {
        var wasCalled = false;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.action(
              items: const [
                AuraButtonGroupItem(value: 'edit', child: Text('Edit')),
                AuraButtonGroupItem(value: 'delete', child: Text('Delete')),
              ],
              onPressed: (_) => wasCalled = true,
              disabled: true,
            ),
          ),
        );

        await tester.tap(find.text('Edit'));
        await tester.pump();

        expect(wasCalled, isFalse);
      });

      testWidgets('does not call onPressed for disabled item', (tester) async {
        String? pressedValue;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.action(
              items: const [
                AuraButtonGroupItem(value: 'edit', child: Text('Edit')),
                AuraButtonGroupItem(
                  value: 'delete',
                  child: Text('Delete'),
                  disabled: true,
                ),
              ],
              onPressed: (value) => pressedValue = value,
            ),
          ),
        );

        await tester.tap(find.text('Delete'));
        await tester.pump();

        expect(pressedValue, isNull);

        await tester.tap(find.text('Edit'));
        await tester.pump();

        expect(pressedValue, 'edit');
      });
    });

    test('stores size, variant, and orientation options', () {
      const items = <AuraButtonGroupItem<String>>[];
      void onChanged(String _) {
        final _ = Object();
      }

      final groups = [
        AuraButtonGroup<String>.single(
          items: items,
          selectedValue: 'a',
          onChanged: onChanged,
          size: .sm,
        ),
        AuraButtonGroup<String>.single(
          items: items,
          selectedValue: 'a',
          onChanged: onChanged,
        ),
        AuraButtonGroup<String>.single(
          items: items,
          selectedValue: 'a',
          onChanged: onChanged,
          size: .lg,
        ),
        AuraButtonGroup<String>.single(
          items: items,
          selectedValue: 'a',
          onChanged: onChanged,
          variant: .filled,
        ),
        AuraButtonGroup<String>.single(
          items: items,
          selectedValue: 'a',
          onChanged: onChanged,
        ),
        AuraButtonGroup<String>.single(
          items: items,
          selectedValue: 'a',
          onChanged: onChanged,
          variant: .ghost,
        ),
        AuraButtonGroup<String>.single(
          items: items,
          selectedValue: 'a',
          onChanged: onChanged,
        ),
        AuraButtonGroup<String>.single(
          items: items,
          selectedValue: 'a',
          onChanged: onChanged,
          orientation: .vertical,
        ),
      ];

      expect(groups.map((group) => group.size), [
        AuraButtonGroupSize.sm,
        AuraButtonGroupSize.base,
        AuraButtonGroupSize.lg,
        AuraButtonGroupSize.base,
        AuraButtonGroupSize.base,
        AuraButtonGroupSize.base,
        AuraButtonGroupSize.base,
        AuraButtonGroupSize.base,
      ]);
      expect(groups.map((group) => group.variant), [
        AuraButtonGroupVariant.outlined,
        AuraButtonGroupVariant.outlined,
        AuraButtonGroupVariant.outlined,
        AuraButtonGroupVariant.filled,
        AuraButtonGroupVariant.outlined,
        AuraButtonGroupVariant.ghost,
        AuraButtonGroupVariant.outlined,
        AuraButtonGroupVariant.outlined,
      ]);
      expect(groups.map((group) => group.orientation), [
        Axis.horizontal,
        Axis.horizontal,
        Axis.horizontal,
        Axis.horizontal,
        Axis.horizontal,
        Axis.horizontal,
        Axis.horizontal,
        Axis.vertical,
      ]);
    });

    testWidgets('lays out horizontal and vertical groups', (tester) async {
      const items = [
        AuraButtonGroupItem(value: 'a', child: Text('A')),
        AuraButtonGroupItem(value: 'b', child: Text('B')),
      ];

      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: Column(
            mainAxisSize: .min,
            children: [
              AuraButtonGroup<String>.single(
                items: items,
                selectedValue: 'a',
                onChanged: (_) {
                  final _ = Object();
                },
                key: const ValueKey('horizontal'),
              ),
              AuraButtonGroup<String>.single(
                items: items,
                selectedValue: 'a',
                onChanged: (_) {
                  final _ = Object();
                },
                key: const ValueKey('vertical'),
                orientation: .vertical,
              ),
            ],
          ),
        ),
      );

      final horizontal = find.byKey(const ValueKey('horizontal'));
      expect(
        find.descendant(of: horizontal, matching: find.byType(Row)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: horizontal, matching: find.byType(Column)),
        findsNothing,
      );

      final vertical = find.byKey(const ValueKey('vertical'));
      expect(
        find.descendant(of: vertical, matching: find.byType(Column)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: vertical, matching: find.byType(Row)),
        findsNothing,
      );
    });

    group('Cursor behavior', () {
      testWidgets('shows click cursor when enabled', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [AuraButtonGroupItem(value: 'a', child: Text('A'))],
              selectedValue: 'a',
              onChanged: (_) {
                final _ = Object();
              },
            ),
          ),
        );

        final mouseRegion = tester.widget<MouseRegion>(
          find.descendant(
            of: find.byType(AuraButtonGroup<String>),
            matching: find.byType(MouseRegion),
          ),
        );
        expect(mouseRegion.cursor, SystemMouseCursors.click);
      });

      testWidgets('shows basic cursor when disabled', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [AuraButtonGroupItem(value: 'a', child: Text('A'))],
              selectedValue: 'a',
              onChanged: (_) {
                final _ = Object();
              },
              disabled: true,
            ),
          ),
        );

        final mouseRegion = tester.widget<MouseRegion>(
          find.descendant(
            of: find.byType(AuraButtonGroup<String>),
            matching: find.byType(MouseRegion),
          ),
        );
        expect(mouseRegion.cursor, SystemMouseCursors.basic);
      });

      testWidgets('shows basic cursor when loading', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<String>.single(
              items: const [AuraButtonGroupItem(value: 'a', child: Text('A'))],
              selectedValue: 'a',
              onChanged: (_) {
                final _ = Object();
              },
              isLoading: true,
            ),
          ),
        );

        final mouseRegion = tester.widget<MouseRegion>(
          find.descendant(
            of: find.byType(AuraButtonGroup<String>),
            matching: find.byType(MouseRegion),
          ),
        );
        expect(mouseRegion.cursor, SystemMouseCursors.basic);
      });
    });

    group('Enums', () {
      test('AuraButtonGroupSize has all expected values', () {
        expect(AuraButtonGroupSize.values, hasLength(3));
        expect(AuraButtonGroupSize.values, contains(AuraButtonGroupSize.sm));
        expect(AuraButtonGroupSize.values, contains(AuraButtonGroupSize.base));
        expect(AuraButtonGroupSize.values, contains(AuraButtonGroupSize.lg));
      });

      test('AuraButtonGroupVariant has all expected values', () {
        expect(AuraButtonGroupVariant.values, hasLength(3));
        expect(
          AuraButtonGroupVariant.values,
          contains(AuraButtonGroupVariant.filled),
        );
        expect(
          AuraButtonGroupVariant.values,
          contains(AuraButtonGroupVariant.outlined),
        );
        expect(
          AuraButtonGroupVariant.values,
          contains(AuraButtonGroupVariant.ghost),
        );
      });
    });

    group('AuraButtonGroupItem', () {
      test('creates item with required parameters', () {
        const item = AuraButtonGroupItem<String>(
          value: 'test',
          child: Text('Test'),
        );

        expect(item.value, 'test');
        expect(item.disabled, isFalse);
        expect(item.isLoading, isFalse);
      });

      test('creates item with disabled flag', () {
        const item = AuraButtonGroupItem<String>(
          value: 'test',
          child: Text('Test'),
          disabled: true,
        );

        expect(item.disabled, isTrue);
      });

      test('creates item with isLoading flag', () {
        const item = AuraButtonGroupItem<String>(
          value: 'test',
          child: Text('Test'),
          isLoading: true,
        );

        expect(item.isLoading, isTrue);
      });
    });

    group('Generic type support', () {
      testWidgets('works with int values', (tester) async {
        int? receivedValue;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<int>.single(
              items: const [
                AuraButtonGroupItem(value: 1, child: Text('One')),
                AuraButtonGroupItem(value: 2, child: Text('Two')),
              ],
              selectedValue: 1,
              onChanged: (value) => receivedValue = value,
            ),
          ),
        );

        await tester.tap(find.text('Two'));
        await tester.pump();

        expect(receivedValue, 2);
      });

      testWidgets('works with enum values', (tester) async {
        _TestEnum? receivedValue;

        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: AuraButtonGroup<_TestEnum>.single(
              items: const [
                AuraButtonGroupItem(
                  value: _TestEnum.first,
                  child: Text('First'),
                ),
                AuraButtonGroupItem(
                  value: _TestEnum.second,
                  child: Text('Second'),
                ),
              ],
              selectedValue: _TestEnum.first,
              onChanged: (value) => receivedValue = value,
            ),
          ),
        );

        await tester.tap(find.text('Second'));
        await tester.pump();

        expect(receivedValue, _TestEnum.second);
      });
    });
  });
}

enum _TestEnum { first, second }
