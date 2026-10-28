import 'dart:ui' show Size;

import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_field.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_picker.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'dependent picker receives draft parent without changing selections',
    (tester) async {
      final repository = _References();
      List<String>? selected;
      await tester.pumpWidget(
        TestableApp(
          child: WorkspaceReferencePicker(
            workspaceId: 'one',
            table: _source,
            column: _source.columns.last,
            selected: const ['first'],
            onSelected: (ids) => selected = ids,
            parentId: 'parent-two',
          ),
          overrides: [
            workspaceReferencesUsecaseProvider('one').overrideWith(
              (ref) async => BrowseWorkspaceReferencesUsecase(repository),
            ),
            workspaceTableProvider(
              'one',
              'target',
            ).overrideWith((ref) async => _target),
          ],
          workspaceId: 'one',
        ),
      );
      await _flush(tester);
      expect(find.text('Choose records from People'), findsOneWidget);
      expect(repository.parents, ['parent-two']);
      await tester.tap(find.text('Apply selection'));
      expect(selected, ['first']);
    },
  );
  testWidgets(
    'query filter uses target table with one choice and no creation',
    (tester) async {
      final repository = _References();
      List<String>? selected;
      await tester.pumpWidget(
        TestableApp(
          child: WorkspaceReferencePicker(
            workspaceId: 'one',
            table: _source,
            column: _source.columns.last,
            selected: const ['first', 'second'],
            onSelected: (ids) => selected = ids,
            queryFilter: true,
          ),
          overrides: [
            workspaceReferencesUsecaseProvider('one').overrideWith(
              (ref) async => BrowseWorkspaceReferencesUsecase(repository),
            ),
            workspaceTableProvider(
              'one',
              'target',
            ).overrideWith((ref) async => _target),
          ],
          workspaceId: 'one',
        ),
      );
      await _flush(tester);
      expect(repository.tableRequests, ['target']);
      expect(find.text('Add record'), findsNothing);
      expect(find.byType(AuraRadioListTile<String>), findsOneWidget);
      expect(find.byType(AuraCheckboxListTile), findsNothing);
      await tester.tap(find.text('Apply selection'));
      expect(selected, ['first']);
    },
  );
  testWidgets('picker searches, pages and retains authorized selections', (
    tester,
  ) async {
    final repository = _References();
    List<String>? selected;
    await tester.pumpWidget(
      TestableApp(
        child: WorkspaceReferencePicker(
          workspaceId: 'one',
          table: _source,
          column: _source.columns.last,
          selected: const [],
          onSelected: (ids) => selected = ids,
        ),
        overrides: [
          workspaceReferencesUsecaseProvider('one').overrideWith(
            (ref) async => BrowseWorkspaceReferencesUsecase(repository),
          ),
          workspaceTableProvider(
            'one',
            'target',
          ).overrideWith((ref) async => _target),
        ],
        workspaceId: 'one',
      ),
    );
    await _flush(tester);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.byType(AuraCheckboxListTile), findsOneWidget);
    expect(find.byType(AuraRadioListTile<String>), findsNothing);
    expect(find.textContaining('Email: ada@example.com'), findsOneWidget);
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
    await tester.tap(find.text('Apply selection'));
    expect(selected, ['first', 'second']);
  });
  testWidgets('single selection can be cleared before applying', (
    tester,
  ) async {
    final repository = _References();
    List<String>? selected;
    await tester.pumpWidget(
      TestableApp(
        child: WorkspaceReferencePicker(
          workspaceId: 'one',
          table: _source,
          column: _source.columns.last,
          selected: const ['first'],
          onSelected: (ids) => selected = ids,
          queryFilter: true,
        ),
        overrides: [
          workspaceReferencesUsecaseProvider('one').overrideWith(
            (ref) async => BrowseWorkspaceReferencesUsecase(repository),
          ),
          workspaceTableProvider(
            'one',
            'target',
          ).overrideWith((ref) async => _target),
        ],
        workspaceId: 'one',
      ),
    );
    await _flush(tester);
    await tester.tap(find.text('Clear selection'));
    await tester.tap(find.text('Apply selection'));
    expect(selected, isEmpty);
  });
  testWidgets('picker identifies records without labels by short ID', (
    tester,
  ) async {
    final repository = _References()..emptyLabel = true;
    await tester.pumpWidget(
      TestableApp(
        child: WorkspaceReferencePicker(
          workspaceId: 'one',
          table: _source,
          column: _source.columns.last,
          selected: const [],
          onSelected: ignoreSelection,
        ),
        overrides: [
          workspaceReferencesUsecaseProvider('one').overrideWith(
            (ref) async => BrowseWorkspaceReferencesUsecase(repository),
          ),
          workspaceTableProvider(
            'one',
            'target',
          ).overrideWith((ref) async => _target),
        ],
        workspaceId: 'one',
      ),
    );
    await _flush(tester);
    expect(find.textContaining('Untitled record'), findsOneWidget);
  });
  testWidgets('reference picker opens in a narrow viewport', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _References();
    await tester.pumpWidget(
      TestableApp(
        child: WorkspaceReferenceField(
          workspaceId: 'one',
          table: _source,
          column: _source.columns.last,
          value: null,
          disabled: false,
          restricted: false,
          onChanged: (_) => fail('Picker has not applied a selection'),
          onUnset: () => fail('Empty field must not be unset'),
        ),
        overrides: [
          workspaceReferencesUsecaseProvider('one').overrideWith(
            (ref) async => BrowseWorkspaceReferencesUsecase(repository),
          ),
          workspaceTableProvider(
            'one',
            'target',
          ).overrideWith((ref) async => _target),
        ],
        workspaceId: 'one',
      ),
    );
    await _flush(tester);
    await tester.tap(find.text('Choose records'));
    await _flush(tester);
    expect(find.text('Choose records from People'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
        child: WorkspaceReferencePicker(
          workspaceId: 'one',
          table: _source,
          column: _source.columns.last,
          selected: const [],
          onSelected: (ids) => selected = ids,
        ),
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
        workspaceId: 'one',
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
    await tester.tap(find.text('Apply selection'));
    expect(selected, ['created']);
  });
  testWidgets(
    'mounted label refreshes a rename and hides revoked target access',
    (tester) async {
      final repository = _References();
      await tester.pumpWidget(
        TestableApp(
          child: const WorkspaceReferenceLabel(
            workspaceId: 'one',
            targetTableId: 'target',
            recordId: 'first',
          ),
          overrides: [
            workspaceReferencesUsecaseProvider('one').overrideWith(
              (ref) async => BrowseWorkspaceReferencesUsecase(repository),
            ),
            workspaceTableProvider(
              'one',
              'target',
            ).overrideWith((ref) async => _target),
          ],
          workspaceId: 'one',
        ),
      );
      await _flush(tester);
      expect(find.text('Ada'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceReferenceLabel)),
      );
      repository.label = 'Renamed Ada';
      container.invalidate(workspaceReferencesUsecaseProvider('one'));
      await _flush(tester);
      expect(find.text('Ada'), findsNothing);
      expect(find.text('Renamed Ada'), findsOneWidget);
      repository.denyTables = true;
      container.invalidate(workspaceReferencesUsecaseProvider('one'));
      await _flush(tester);
      expect(find.text('Renamed Ada'), findsNothing);
      expect(
        find.text('Linked records are unavailable with your current access.'),
        findsOneWidget,
      );
    },
  );
  for (final denied in [false, true]) {
    testWidgets(
      denied
          ? 'unsaved reference default hides denied targets'
          : 'unsaved reference default selects authorized target IDs',
      (tester) async {
        final repository = _References()..denyTables = denied;
        List<String>? selected;
        await tester.pumpWidget(
          TestableApp(
            child: WorkspaceReferencePicker(
              workspaceId: 'one',
              table: _source,
              column: const WorkspaceColumn(
                id: '',
                name: 'Unsaved link',
                type: .reference,
                targetTableId: 'target',
              ),
              selected: const ['first', 'second'],
              onSelected: (ids) => selected = ids,
              schemaDefault: true,
            ),
            overrides: [
              workspaceReferencesUsecaseProvider('one').overrideWith(
                (ref) async => BrowseWorkspaceReferencesUsecase(repository),
              ),
              workspaceTableProvider(
                'one',
                'target',
              ).overrideWith((ref) async => _target),
            ],
            workspaceId: 'one',
          ),
        );
        await _flush(tester);
        expect(repository.tableRequests, ['target']);
        if (denied) {
          expect(find.text('Ada'), findsNothing);
          expect(
            find.text(
              'Linked records are unavailable with your current access.',
            ),
            findsOneWidget,
          );
        } else {
          await tester.tap(find.text('Apply selection'));
          expect(selected, ['first']);
        }
      },
    );
  }
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
  final parents = <String?>[];
  final cursors = <String?>[];
  final searches = <String>[];
  final tableRequests = <String>[];
  bool denyTables = false;
  bool emptyLabel = false;
  String label = 'Ada';
  @override
  Future<WorkspaceReferencePage> tableTargets(
    String tableId, {
    required String search,
    String? afterId,
  }) {
    tableRequests.add(tableId);
    if (denyTables) throw const WorkspaceTableException(denied: true);

    return targets(
      (tableId: 'unsaved', columnId: ''),
      search: search,
      afterId: afterId,
    );
  }

  @override
  Future<WorkspaceRecord> record(String tableId, String id) async {
    if (denyTables) throw const WorkspaceTableException(denied: true);

    return WorkspaceRecord(
      id: id,
      tableId: tableId,
      values: {'name': label},
      revision: 1,
    );
  }

  @override
  Future<WorkspaceReferencePage> targets(
    WorkspaceReferenceSource source, {
    required String search,
    String? afterId,
    String? parentId,
  }) async {
    parents.add(parentId);
    cursors.add(afterId);
    searches.add(search);

    return afterId == null
        ? WorkspaceReferencePage(
            records: [
              WorkspaceRecord(
                id: 'first',
                tableId: 'target',
                values: {
                  'name': _maybeEmpty('Ada'),
                  'email': _maybeEmpty('ada@example.com'),
                },
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

  String _maybeEmpty(String value) => emptyLabel ? '' : value;
}

void ignoreSelection(List<String> ids) => expect(ids, isNotNull);

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
    String? aiConversationId,
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
