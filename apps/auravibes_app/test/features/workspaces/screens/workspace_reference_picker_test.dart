import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_ui/ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'picker pages and searches, retains selection and hides unauthorized creation',
    (tester) async {
      final repository = _References();
      List<String>? selected;
      await tester.pumpWidget(
        TestableApp(
          workspaceId: 'one',
          overrides: [
            workspaceReferencesUsecaseProvider('one').overrideWith(
              (ref) async => BrowseWorkspaceReferencesUsecase(repository),
            ),
            workspaceTableProvider(
              'one',
              'target',
            ).overrideWith((ref) async => _target),
          ],
          child: WorkspaceReferencePicker(
            workspaceId: 'one',
            table: _source,
            column: _source.columns.last,
            selected: const [],
            onSelected: (ids) => selected = ids,
          ),
        ),
      );
      await _flush(tester);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Email: ada@example.com'), findsOneWidget);
      expect(find.text('Add record'), findsNothing);
      await tester.tap(find.text('Ada'));
      await tester.tap(find.text('Next page'));
      await _flush(tester);
      expect(repository.cursors, [null, 'first']);
      expect(find.text('Grace'), findsOneWidget);
      await tester.tap(find.text('Grace'));
      await tester.enterText(find.byType(AuraInput), 'Ada');
      await _flush(tester);
      expect(repository.searches.last, 'Ada');
      expect(repository.cursors.last, isNull);
      await tester.tap(find.text('Done'));
      expect(selected, ['first', 'second']);
    },
  );
  testWidgets('authorized target creation selects the new stable record ID', (
    tester,
  ) async {
    final repository = _References();
    final tables = _Tables();
    List<String>? selected;
    final target = WorkspaceTable(
      id: _target.id,
      name: _target.name,
      labelColumnId: _target.labelColumnId,
      columns: _target.columns,
      revision: 1,
      schemaRevision: 1,
    );
    await tester.pumpWidget(
      TestableApp(
        workspaceId: 'one',
        overrides: [
          workspaceReferencesUsecaseProvider('one').overrideWith(
            (ref) async => BrowseWorkspaceReferencesUsecase(repository),
          ),
          workspaceTableProvider(
            'one',
            'target',
          ).overrideWith((ref) async => target),
          workspaceTableUsecaseProvider(
            'one',
          ).overrideWith((ref) async => OrganizeWorkspaceTablesUsecase(tables)),
        ],
        child: WorkspaceReferencePicker(
          workspaceId: 'one',
          table: _source,
          column: _source.columns.last,
          selected: const [],
          onSelected: (ids) => selected = ids,
        ),
      ),
    );
    await _flush(tester);
    await tester.tap(find.text('Add record'));
    await _flush(tester);
    await tester.tap(find.text('Name'));
    await _flush(tester);
    final input = find.byWidgetPredicate(
      (widget) =>
          widget is AuraInput && widget.identifier == 'workspace_record_value',
    );
    await tester.enterText(input, 'New person');
    final save = find.byWidgetPredicate(
      (widget) =>
          widget is AuraButton && widget.identifier == 'workspace_record_save',
    );
    await tester.tap(save);
    await _flush(tester);
    expect(tables.saved, {'name': 'New person'});
    await tester.tap(find.text('Done'));
    expect(selected, ['created']);
  });
}

const _target = WorkspaceTable(
  id: 'target',
  name: 'People',
  labelColumnId: 'name',
  columns: [
    WorkspaceColumn(id: 'name', name: 'Name'),
    WorkspaceColumn(id: 'email', name: 'Email'),
  ],
  revision: 1,
  schemaRevision: 1,
  canEditRecords: false,
);
const _source = WorkspaceTable(
  id: 'source',
  name: 'Tasks',
  labelColumnId: 'title',
  columns: [
    WorkspaceColumn(id: 'title', name: 'Title'),
    WorkspaceColumn(
      id: 'link',
      name: 'People',
      type: .reference,
      targetTableId: 'target',
      referenceMultiple: true,
    ),
  ],
  revision: 1,
  schemaRevision: 1,
);

class _References implements WorkspaceReferenceRepository {
  final cursors = <String?>[];
  final searches = <String>[];
  @override
  Future<WorkspaceRecord> record(String tableId, String id) async =>
      throw UnimplementedError();
  @override
  Future<WorkspaceReferencePage> targets(
    WorkspaceReferenceSource source, {
    required String search,
    String? afterId,
  }) async {
    cursors.add(afterId);
    searches.add(search);

    return afterId == null
        ? const WorkspaceReferencePage(
            records: [
              WorkspaceRecord(
                id: 'first',
                tableId: 'target',
                values: {'name': 'Ada', 'email': 'ada@example.com'},
                revision: 1,
              ),
            ],
            nextId: 'first',
          )
        : const WorkspaceReferencePage(
            records: [
              WorkspaceRecord(
                id: 'second',
                tableId: 'target',
                values: {'name': 'Grace'},
                revision: 1,
              ),
            ],
          );
  }

  @override
  Future<WorkspaceReferencePage> reverse({
    required String tableId,
    required String recordId,
    String? afterId,
  }) async => const WorkspaceReferencePage(records: []);
}

Future<void> _flush(WidgetTester tester) async {
  for (var index = 0; index < 5; index++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  final _ = await tester.pumpAndSettle();
}

class _Tables extends Fake implements WorkspaceTableRepository {
  Map<String, Object?>? saved;
  @override
  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, Object?> values,
  }) async {
    saved = values;
    return WorkspaceRecord(
      id: 'created',
      tableId: table.id,
      values: values,
      revision: 1,
    );
  }
}
