import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/preview_workspace_reference_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explicit null dependent references do not violate preview', () async {
    const parent = WorkspaceColumn(
      id: 'parent',
      name: 'Parent',
      type: .reference,
      targetTableId: 'parentTable',
    );
    const child = WorkspaceColumn(
      id: 'child',
      name: 'Child',
      type: .reference,
      targetTableId: 'target',
      dependsOnColumnId: 'parent',
      targetMatchColumnId: 'match',
    );
    const source = WorkspaceTable(
      id: 'source',
      name: 'Source',
      labelColumnId: 'label',
      columns: [
        WorkspaceColumn(id: 'label', name: 'Title'),
        parent,
        child,
      ],
      revision: 1,
      schemaRevision: 1,
    );
    final result = await PreviewWorkspaceReferenceUsecase(_Tables())
        .call(source, child, const [
          WorkspaceRecord(
            id: 'row',
            tableId: 'source',
            values: {'parent': null, 'child': null},
            revision: 1,
          ),
        ]);
    expect(result, isEmpty);
  });
}

class _Tables extends Fake implements OrganizeWorkspaceTablesUsecase {
  @override
  Future<WorkspaceTable> table(String id) async => WorkspaceTable(
    id: id,
    name: id,
    labelColumnId: 'label',
    columns: [
      const WorkspaceColumn(id: 'label', name: 'Title'),
      if (id == 'target')
        const WorkspaceColumn(
          id: 'match',
          name: 'Match',
          type: .reference,
          targetTableId: 'parentTable',
        ),
    ],
    revision: 1,
    schemaRevision: 1,
  );
  @override
  Future<List<WorkspaceRecord>> records(String id) async => [];
}
