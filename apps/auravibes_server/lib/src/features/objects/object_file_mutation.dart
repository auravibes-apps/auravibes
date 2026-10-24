import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspaces/repositories/cloud_workspace_repository.dart'
    as workspace_repo;
import 'object_item_access.dart';
import 'object_repository.dart';

class const ObjectFileMutation(
  final Session session,
  final int workspaceId,
  final String userId,
  final Transaction transaction, {
  final String? excludedRecordId,
  final String? excludedTableId,
}) {
  Future<void> validate(
    Map<String, Object?> data,
    WorkspaceResource? previous,
  ) async {
    final id = int.tryParse(data['assetId'] as String? ?? '');
    if (id == null) throw const FormatException();
    if (previous != null &&
        (jsonDecode(previous.data) as Map)['assetId'] == '$id') {
      data.remove('sharingApproved');
      return;
    }
    final repository = ObjectRepository();
    final object = await repository.findObject(
      session,
      workspaceId: workspaceId,
      objectId: id,
      transaction: transaction,
      lock: true,
    );
    if (object == null ||
        object.status != 'active' ||
        object.deletedAt != null) {
      _denied();
    }
    final member = await workspace_repo.CloudWorkspaceRepository()
        .findActiveMember(
          session,
          workspaceId: workspaceId,
          userId: userId,
          transaction: transaction,
        );
    if (member == null) _denied();
    final items = ObjectItemAccess(
      session,
      member,
      transaction: transaction,
      excludedRecordId: excludedRecordId,
      excludedTableId: excludedTableId,
    );
    final upload = await repository.findUpload(
      session,
      workspaceId: workspaceId,
      objectId: id,
      transaction: transaction,
    );
    final retainedMessage = await repository.hasLiveReference(
      session,
      workspaceId: workspaceId,
      objectId: id,
      transaction: transaction,
    );
    final initialUpload =
        upload?.actorUserId == userId &&
        !retainedMessage &&
        !await items.retained(id);
    final shared =
        await items.publiclyReadable(id) ||
        await repository.hasReadableMessageReference(
          session,
          workspaceId: workspaceId,
          objectId: id,
        );
    final explicitSharing =
        member.role == 'owner' &&
        data['sharingApproved'] == true &&
        await items.canRead(id);
    if (!initialUpload && !shared && !explicitSharing) _denied();
    data.remove('sharingApproved');
  }
}

Never _denied() => throw CloudWorkspaceException(code: .permissionDenied);
