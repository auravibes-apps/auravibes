import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

Future<WorkspaceMember?> findActiveWorkspaceMember(
  Session session, {
  required int workspaceId,
  required String userId,
  Transaction? transaction,
  bool lock = false,
}) => WorkspaceMember.db.findFirstRow(
  session,
  where: (table) =>
      table.workspaceId.equals(workspaceId) &
      table.userId.equals(userId) &
      table.removedAt.equals(null),
  transaction: transaction,
  lockMode: lock ? LockMode.forUpdate : null,
);
