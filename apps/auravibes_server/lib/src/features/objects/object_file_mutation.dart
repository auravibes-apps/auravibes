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
  ObjectRepository get _repository => ObjectRepository();

  Future<void> validate(
    Map<String, Object?> data,
    WorkspaceResource? previous,
  ) async {
    final id = _assetId(data);
    if (_sameAsset(id, previous)) {
      data.remove('sharingApproved');
      return;
    }
    await _newAsset(id, data['sharingApproved'] == true);
    data.remove('sharingApproved');
  }

  Future<void> _newAsset(int id, bool sharingApproved) async {
    await _active(id);
    final member = await _member();
    final policy = _FileAssetPolicy(this, member, _items(member));
    if (!await policy.allows(id, sharingApproved)) _denied();
  }

  Future<void> _active(int id) async {
    final object = await _repository.findObject(
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
  }

  Future<WorkspaceMember> _member() async {
    final member = await workspace_repo.CloudWorkspaceRepository()
        .findActiveMember(
          session,
          workspaceId: workspaceId,
          userId: userId,
          transaction: transaction,
        );

    return member ?? _denied();
  }

  ObjectItemAccess _items(WorkspaceMember member) => ObjectItemAccess(
    session,
    member,
    transaction: transaction,
    excludedRecordId: excludedRecordId,
    excludedTableId: excludedTableId,
  );

  static int _assetId(Map<String, Object?> data) =>
      int.tryParse(data['assetId'] as String? ?? '') ??
      (throw const FormatException());

  static bool _sameAsset(int id, WorkspaceResource? previous) =>
      previous != null &&
      (jsonDecode(previous.data) as Map)['assetId'] == '$id';
}

class const _FileAssetPolicy(
  final ObjectFileMutation owner,
  final WorkspaceMember member,
  final ObjectItemAccess items,
) {
  Future<bool> allows(int id, bool sharingApproved) async {
    final initial = await _initial(id);
    final shared = await _shared(id);
    final explicit = await _explicit(id, sharingApproved);

    return initial || shared || explicit;
  }

  Future<bool> _initial(int id) async {
    final owned = await _ownedUpload(id);
    final message = await _liveReference(id);

    return owned && !message && !await items.retained(id);
  }

  Future<bool> _ownedUpload(int id) async {
    final upload = await owner._repository.findUpload(
      owner.session,
      workspaceId: owner.workspaceId,
      objectId: id,
      transaction: owner.transaction,
    );

    return upload?.actorUserId == owner.userId;
  }

  Future<bool> _liveReference(int id) => owner._repository.hasLiveReference(
    owner.session,
    workspaceId: owner.workspaceId,
    objectId: id,
    transaction: owner.transaction,
  );

  Future<bool> _shared(int id) async =>
      await items.publiclyReadable(id) ||
      await owner._repository.hasReadableMessageReference(
        owner.session,
        workspaceId: owner.workspaceId,
        objectId: id,
      );

  Future<bool> _explicit(int id, bool approved) async =>
      member.role == 'owner' && approved && await items.canRead(id);
}

Never _denied() => throw CloudWorkspaceException(code: .permissionDenied);
