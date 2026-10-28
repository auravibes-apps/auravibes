import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_field.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('money edits preserve decimal text and explicit currency', (
    tester,
  ) async {
    Object? changed;
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordField(
            column: const WorkspaceColumn(
              id: 'money',
              name: 'Amount',
              type: .money,
            ),
            value: const {
              'amount': '9007199254740993.010000000000000001',
              'currency': 'USD',
            },
            present: true,
            disabled: false,
            identifier: 'amount',
            onChanged: (value) => changed = value,
            onUnset: () => fail('Unexpected unset'),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    Finder input(String id) => find.byWidgetPredicate(
      (widget) => widget is AuraInput && widget.identifier == id,
    );
    await tester.enterText(input('amount_currency'), 'EUR');
    expect(changed, {
      'amount': '9007199254740993.010000000000000001',
      'currency': 'EUR',
    });
    await tester.enterText(input('amount'), '0.000000000000000001');
    expect(changed, {'amount': '0.000000000000000001', 'currency': 'EUR'});
  });
  testWidgets('multi-select values use a compact tag dropdown', (tester) async {
    Object? changed;
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordField(
            column: const WorkspaceColumn(
              id: 'tags',
              name: 'Tags',
              type: .multiSelect,
              options: ['A', 'B'],
            ),
            value: const ['A'],
            present: true,
            disabled: false,
            identifier: 'tags',
            onChanged: (value) => changed = value,
            onUnset: () => fail('Unexpected unset'),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('B').last, warnIfMissed: false);
    final _ = await tester.pumpAndSettle();
    expect(changed, ['A', 'B']);
  });
  testWidgets('timestamps display both sides of DST in selected IANA zone', (
    tester,
  ) async {
    Future<void> display(String instant) async {
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: WorkspaceRecordField(
              column: const WorkspaceColumn(
                id: 'instant',
                name: 'Time',
                type: .timestamp,
                timeZone: 'America/New_York',
              ),
              value: instant,
              present: true,
              disabled: false,
              identifier: 'instant',
              onChanged: (_) => fail('Unexpected edit'),
              onUnset: () => fail('Unexpected unset'),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
    }

    await display('2026-11-01T05:30:00.000Z');
    expect(
      find.text('2026-11-01T01:30:00.000-0400 (America/New_York)'),
      findsOneWidget,
    );
    await display('2026-11-01T06:30:00.000Z');
    expect(
      find.text('2026-11-01T01:30:00.000-0500 (America/New_York)'),
      findsOneWidget,
    );
  });
  testWidgets('date-only editing does not apply a timezone conversion', (
    tester,
  ) async {
    Object? changed;
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: WorkspaceRecordField(
            column: const WorkspaceColumn(
              id: 'day',
              name: 'Day',
              type: .dateOnly,
              timeZone: 'Pacific/Auckland',
            ),
            value: '2024-02-29',
            present: true,
            disabled: false,
            identifier: 'day',
            onChanged: (value) => changed = value,
            onUnset: () => fail('Unexpected unset'),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.text('2024-02-29'), findsOneWidget);
    await tester.tap(find.text('Edit exact value'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate((widget) => widget is AuraInput),
      '2024-03-01',
    );
    expect(changed, '2024-03-01');
  });
  testWidgets(
    'timestamp picker preserves fractional seconds while changing minute',
    (tester) async {
      Object? changed;
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: WorkspaceRecordField(
              column: const WorkspaceColumn(
                id: 'instant',
                name: 'Time',
                type: .timestamp,
              ),
              value: '2026-10-23T12:30:45.123456Z',
              present: true,
              disabled: false,
              identifier: 'instant',
              onChanged: (value) => changed = value,
              onUnset: () => fail('Unexpected unset'),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraDateTimeInput &&
              widget.enableTime &&
              !widget.enableDate,
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.ensureVisible(find.bySemanticsLabel('Increase minute'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Increase minute'));
      final _ = await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Done'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      final _ = await tester.pumpAndSettle();
      expect(changed, '2026-10-23T12:31:45.123456Z');
    },
  );
}
