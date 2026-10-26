import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

class CodexOAuthRepository {
  Future<CodexOAuthTransaction?> findByState(
    Session session,
    String stateHash,
  ) => CodexOAuthTransaction.db.findFirstRow(
    session,
    where: (table) => table.stateHash.equals(stateHash),
  );

  Future<WorkspaceMember?> findMember(
    Session session, {
    required int workspaceId,
    required String userId,
    Transaction? transaction,
  }) => WorkspaceMember.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.userId.equals(userId) &
        table.removedAt.equals(null),
    transaction: transaction,
  );

  Future<CloudWorkspace?> lockWorkspace(
    Session session,
    int workspaceId,
    Transaction transaction,
  ) => CloudWorkspace.db.findFirstRow(
    session,
    where: (table) => table.id.equals(workspaceId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<CodexOAuthTransaction?> findByTransactionId(
    Session session,
    String transactionId,
    Transaction? transaction,
  ) => CodexOAuthTransaction.db.findFirstRow(
    session,
    where: (table) => table.transactionId.equals(transactionId),
    transaction: transaction,
  );

  Future<CodexOAuthTransaction> insertTransaction(
    Session session,
    CodexOAuthTransaction transaction,
    Transaction databaseTransaction,
  ) => CodexOAuthTransaction.db.insertRow(
    session,
    transaction,
    transaction: databaseTransaction,
  );

  Future<CodexOAuthTransaction?> lockTransaction(
    Session session,
    String transactionId,
    Transaction transaction,
  ) => CodexOAuthTransaction.db.findFirstRow(
    session,
    where: (table) => table.transactionId.equals(transactionId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<void> consume(
    Session session,
    CodexOAuthTransaction row,
    DateTime now,
    Transaction transaction,
  ) async {
    await CodexOAuthTransaction.db.updateRow(
      session,
      row.copyWith(consumedAt: now),
      transaction: transaction,
    );
  }

  Future<WorkspaceSecret?> findTokenSecret(
    Session session,
    CodexOAuthTransaction oauth,
    Transaction transaction,
  ) => WorkspaceSecret.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(oauth.workspaceId) &
        table.secretKind.equals(WorkspaceSecretKind.provider) &
        table.scope.equals(WorkspaceSecretScope.user) &
        table.ownerUserId.equals(oauth.userId) &
        table.resourceId.equals(oauth.connectionId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<void> saveTokenSecret(
    Session session,
    WorkspaceSecret secret,
    Transaction transaction,
  ) async {
    if (secret.id == null) {
      await WorkspaceSecret.db.insertRow(
        session,
        secret,
        transaction: transaction,
      );
    } else {
      await WorkspaceSecret.db.updateRow(
        session,
        secret,
        transaction: transaction,
      );
    }
  }
}
