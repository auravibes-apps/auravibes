import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const WorkspaceCsvRecords(final WorkspaceCsvRepository repository) {
  Stream<WorkspaceRecord> call(String tableId) async* {
    var offset = 0;
    while (true) {
      final page = await repository.query(
        tableId,
        .new(offset: offset, limit: 100),
      );
      yield* Stream.fromIterable(page.records);
      if (!page.hasMore) return;
      offset += page.records.length;
    }
  }
}
