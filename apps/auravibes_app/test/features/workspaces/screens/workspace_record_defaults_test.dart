import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_editor.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final existing in [false, true]) {
    testWidgets(existing ? 'existing missing values stay missing' : 'new draft displays persisted defaults', (tester) async {
      await tester.pumpWidget(TestableApp(child: WorkspaceRecordEditor(workspaceId: 'one',
        table: _table, record: existing ? const WorkspaceRecord(id: 'record', tableId: 'table', values: {}, revision: 1) : null,
        onBack: () {})));
      await _flush(tester);
      final input = find.byWidgetPredicate((widget) => widget is AuraInput && widget.identifier == 'workspace_record_value_quantity');
      if (existing) { expect(input, findsNothing); }
      else { expect(input, findsOneWidget); expect(tester.widget<AuraInput>(input).controller?.text, '7'); }
      final presence = find.text('Quantity');
      final hints = find.text('Unique values');
      expect(hints, findsOneWidget);
      expect(tester.getTopLeft(hints).dy, greaterThan(tester.getTopLeft(presence).dy));
    });
  }
}

const _table = WorkspaceTable(id: 'table', name: 'Values', labelColumnId: 'label',
  columns: [WorkspaceColumn(id: 'label', name: 'Name'), WorkspaceColumn(id: 'quantity',
    name: 'Quantity', type: .number, defaultValue: 7, isUnique: true)], revision: 1, schemaRevision: 1);

Future<void> _flush(WidgetTester tester) async {
  for (var index = 0; index < 5; index++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
  final _ = await tester.pumpAndSettle();
}
