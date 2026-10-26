import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../generated/protocol.dart';
import '../workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'authenticated_account_resolver.dart';
import 'auth_user_lock.dart';

class AccountEndpoint extends Endpoint {
  Future<AccountSummary> currentUser(Session session) {
    return const AuthenticatedAccountResolver()(session);
  }

  Future<void> deleteCurrentUser(Session session) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final userId = account.userId;
    await session.db.transaction((transaction) async {
      final authUser = await const AuthUserLock().lock(
        session,
        userId: userId,
        transaction: transaction,
      );
      if (authUser == null) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.authenticationRequired,
        );
      }
      await workspace_repo.CloudWorkspaceRepository().lockWorkspaceCreation(
        session,
        ownerUserId: userId,
        transaction: transaction,
      );
      final ownedWorkspaces = await CloudWorkspace.db.find(
        session,
        where: (table) => table.ownerUserId.equals(userId),
        orderBy: (table) => table.id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (ownedWorkspaces.any(
        (workspace) => workspace.erasureRequestedAt != null,
      )) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.workspaceErasurePending,
        );
      }
      if (ownedWorkspaces.isNotEmpty) {
        throw CloudWorkspaceException(
          code: CloudWorkspaceErrorCode.ownershipTransferRequired,
        );
      }

      final _ = await WorkspaceMember.db.deleteWhere(
        session,
        where: (table) => table.userId.equals(userId),
        transaction: transaction,
      );
      final _ = await MessageBookmark.db.deleteWhere(
        session,
        where: (table) => table.userId.equals(userId),
        transaction: transaction,
      );
      final _ = await WorkspaceSecret.db.deleteWhere(
        session,
        where: (table) => table.ownerUserId.equals(userId),
        transaction: transaction,
      );
      final _ = await RecentModelSelection.db.deleteWhere(
        session,
        where: (table) => table.userId.equals(userId),
        transaction: transaction,
      );
      final _ = await CodexOAuthTransaction.db.deleteWhere(
        session,
        where: (table) => table.userId.equals(userId),
        transaction: transaction,
      );
      final _ = await WorkspaceMutationReceipt.db.deleteWhere(
        session,
        where: (table) => table.actorUserId.equals(userId),
        transaction: transaction,
      );
      final _ = await WorkspaceErasureRequest.db.deleteWhere(
        session,
        where: (table) => table.ownerUserId.equals(userId),
        transaction: transaction,
      );
      await AuthServices.instance.authUsers.delete(
        session,
        authUserId: UuidValue.fromString(userId),
        transaction: transaction,
      );
    });
    final _ = await session.messages.authenticationRevoked(
      userId,
      RevokedAuthenticationUser(),
    );
  }
}
