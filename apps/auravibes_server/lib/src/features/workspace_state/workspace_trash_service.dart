import 'package:serverpod/serverpod.dart';

import 'workspace_trash_context.dart';
import 'workspace_trash_reader.dart';
import 'workspace_trash_selection.dart';
import 'workspace_trash_writer.dart';

class const WorkspaceTrashService(
  final Session session,
  final int workspaceId,
  final String userId,
) {
  Future<String> deletedReference(String tableId, String recordId) =>
      session.db.transaction(
        (transaction) async =>
            await WorkspaceTrashReader(await _context(transaction))
                .deletedReference(tableId, recordId),
      );
  Future<String> preview(String targetJson) =>
      session.db.transaction((transaction) async {
        final selection = await WorkspaceTrashSelection.load(
          await _context(transaction),
          targetJson,
        );
        return await selection.preview();
      });
  Future<String> trash(String requestId, String targetJson, String planToken) =>
      session.db.transaction(
        (transaction) async =>
            await WorkspaceTrashWriter(await _context(transaction))
                .trash(requestId, targetJson, planToken),
      );
  Future<List<String>> list() => session.db.transaction(
    (transaction) async =>
        await WorkspaceTrashReader(await _context(transaction)).list(),
  );
  Future<String> restore(String batchId) => session.db.transaction(
    (transaction) async =>
        await WorkspaceTrashWriter(await _context(transaction))
            .restore(batchId),
  );
  Future<WorkspaceTrashContext> _context(Transaction transaction) =>
      WorkspaceTrashContext.load(session, workspaceId, userId, transaction);
}
