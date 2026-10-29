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
  Future<void> validate(ObjectAttachmentValues request) async {
    final validation = _ColumnAttachments(this, request, _access(request));
    final columns = (request.schema['columns'] as List)
        .whereType<Map<String, dynamic>>()
        .where(_attachment);
    for (final column in columns) {
      await validation.column(column);
    }
  }

  ObjectItemAccess _access(ObjectAttachmentValues request) => ObjectItemAccess(
    session,
    member,
    transaction: transaction,
    excludedRecordId: request.recordId,
    excludedTableId: _excludedTable(request),
  );

  ObjectFileMutation _sharing(ObjectAttachmentValues request) =>
      ObjectFileMutation(
        session,
        member.workspaceId,
        member.userId,
        transaction,
        excludedRecordId: request.recordId,
        excludedTableId: _excludedTable(request),
      );

  Future<bool> _preserve(
    String id,
    Map<String, Object?> values,
    Object? old,
  ) async {
    if (old is! List || old.isEmpty) return false;
    if (!await _unavailable(old)) return false;
    _keep(id, values, old);

    return true;
  }

  Future<bool> _unavailable(List<dynamic> ids) async {
    final projection = ObjectAttachmentProjection(session, member, transaction);
    for (final id in ids) {
      if (!await projection.readable(id)) return true;
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

  static void _keep(String id, Map<String, Object?> values, List<dynamic> old) {
    if (values.containsKey(id) && jsonEncode(values[id]) != jsonEncode(old)) {
      throw CloudWorkspaceException(code: .permissionDenied);
    }
    values[id] = old;
  }

  static bool _attachment(Map<String, dynamic> column) =>
      column['type'] == 'attachment';
  static String? _excludedTable(ObjectAttachmentValues request) =>
      request.recordId.isEmpty ? request.tableId : null;
}

class const ObjectAttachmentValues({
  required final Map<String, Object?> schema,
  required final Map<String, Object?> values,
  required final Map<String, Object?> previous,
  required final String recordId,
  required final String tableId,
  final bool sharingApproved = false,
});

class const _ColumnAttachments(
  final ObjectRecordAttachments owner,
  final ObjectAttachmentValues request,
  final ObjectItemAccess access,
) {
  Future<void> column(Map<String, dynamic> column) async {
    final id = column['id'] as String;
    final old = request.previous[id];
    if (await owner._preserve(id, request.values, old)) return;
    await _values(request.values[id], old);
  }

  Future<void> _values(Object? values, Object? old) async {
    if (values is! List) return;
    for (final value in values.cast<String>()) {
      await _value(value, old);
    }
  }

  Future<void> _value(String value, Object? old) async {
    final id = int.tryParse(value);
    if (id == null) throw const FormatException();
    await owner._active(id);
    if (old is List && old.contains(value)) return;
    if (await access.canReuseInTable(id, request.tableId)) return;
    await owner._sharing(request).validate({
      'assetId': value,
      'sharingApproved': request.sharingApproved,
    }, null);
  }
}
