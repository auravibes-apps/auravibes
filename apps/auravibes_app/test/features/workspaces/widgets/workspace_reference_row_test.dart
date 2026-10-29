import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows a record label literally even when it is a locale key', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestableApp(
        child: const WorkspaceReferenceRow(
          workspaceId: 'one',
          record: .new(
            id: 'record',
            tableId: 'table',
            values: {'label': 'common.cancel'},
            revision: 1,
          ),
        ),
        overrides: [
          workspaceTableProvider('one', 'table').overrideWith(
            (ref) async => const WorkspaceTable(
              id: 'table',
              name: 'Records',
              labelColumnId: 'label',
              columns: [WorkspaceColumn(id: 'label', name: 'Label')],
              revision: 1,
              schemaRevision: 1,
            ),
          ),
        ],
        workspaceId: 'one',
      ),
    );
    for (var index = 0; index < 5; index++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    final _ = await tester.pumpAndSettle();
    expect(find.text('common.cancel'), findsOneWidget);
  });
}
