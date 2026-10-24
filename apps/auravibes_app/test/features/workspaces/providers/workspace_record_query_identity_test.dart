import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('equivalent saved page queries reuse the same provider family', () {
    const query = WorkspaceRecordQuery(
      search: 'Ada',
      filterColumnId: 'team',
      filterValue: 'record-one',
      filterOperator: .contains,
      sortColumnId: 'name',
      descending: true,
      offset: 50,
      limit: 25,
    );
    final restored = WorkspaceRecordQuery.fromJson(query.toJson());
    final observed = restored.change(offset: query.offset);
    expect(observed, query);
    expect(observed.hashCode, query.hashCode);
    expect(
      workspaceRecordQueryProvider('one', 'contacts', observed),
      workspaceRecordQueryProvider('one', 'contacts', query),
    );
  });

  test('every query input remains part of provider identity', () {
    const query = WorkspaceRecordQuery();
    final key = workspaceRecordQueryProvider('one', 'contacts', query);
    final changes = <WorkspaceRecordQuery>[
      query.change(search: 'Ada'),
      query.filter('team', 'record-one'),
      const WorkspaceRecordQuery(filterColumnId: 'team'),
      const WorkspaceRecordQuery(filterValue: 'record-one'),
      const WorkspaceRecordQuery(filterOperator: .contains),
      query.change(sort: 'name'),
      query.change(descending: true),
      query.change(offset: 50),
      const WorkspaceRecordQuery(limit: 25),
    ];
    for (final changed in changes) {
      expect(changed, isNot(query));
      expect(
        workspaceRecordQueryProvider('one', 'contacts', changed),
        isNot(key),
      );
    }
  });
}
