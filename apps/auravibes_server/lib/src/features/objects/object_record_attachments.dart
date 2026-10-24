import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_attachment_projection.dart';
import 'object_file_mutation.dart';
import 'object_item_access.dart';
import 'object_repository.dart';

class const ObjectRecordAttachments(
  final Session session,
  final WorkspaceMember member,
  final Transaction transaction,
) {
  Future<void> validate({
    required Map<String, Object?> schema,
    required Map<String, Object?> values,
    required Map<String, Object?> previous,
    required String recordId,
    required String tableId,
    bool sharingApproved = false,
  }) async {
    final columns = (schema['columns'] as List).whereType<Map>();
    final access = ObjectItemAccess(
      session,
      member,
      transaction: transaction,
      excludedRecordId: recordId,
      excludedTableId: recordId.isEmpty ? tableId : null,
    );
    for (final column in columns.where(
      (column) => column['type'] == 'attachment',
    )) {
      final old = previous[column['id']];
      if (await _preserve(column['id'] as String, values, old)) continue;
      final current = values[column['id']];
      if (current is! List) continue;
      for (final value in current.cast<String>()) {
        final id = int.tryParse(value);
        if (id == null) throw const FormatException();
        await _active(id);
        if (old is List && old.contains(value)) continue;
        if (await access.canReuseInTable(id, tableId)) continue;
        await ObjectFileMutation(
          session,
          member.workspaceId,
          member.userId,
          transaction,
          excludedRecordId: recordId,
          excludedTableId: recordId.isEmpty ? tableId : null,
        ).validate(
          {
            'assetId': value,
            'sharingApproved': sharingApproved,
          },
          null,
        );
      }
    }
  }

  Future<bool> _preserve(
    String columnId,
    Map<String, Object?> values,
    Object? old,
  ) async {
    if (old is! List || old.isEmpty) return false;
    final projection = ObjectAttachmentProjection(session, member, transaction);
    for (final id in old) {
      if (await projection.readable(id)) continue;
      if (values.containsKey(columnId) &&
          jsonEncode(values[columnId]) != jsonEncode(old)) {
        throw CloudWorkspaceException(code: .permissionDenied);
      }
      values[columnId] = old;

      return true;
    }

    return false;
  }

  Future<void> _active(int id) async {
    final object = await ObjectRepository().findObject(
      session,
      workspaceId: member.workspaceId,
      objectId: id,
      transaction: transaction,
      lock: true,
    );
    if (object == null ||
        object.status != 'active' ||
        object.deletedAt != null) {
      throw CloudWorkspaceException(code: .permissionDenied);
    }
  }
}
