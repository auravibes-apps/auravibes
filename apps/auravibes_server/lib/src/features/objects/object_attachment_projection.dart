import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'object_repository.dart';

/// A whole unavailable field is hidden, including its IDs and attachment count.
class const ObjectAttachmentProjection(
  final Session session,
  final WorkspaceMember member,
  final Transaction? transaction,
) {
  Future<List<String>> restricted(
    Iterable<Map<String, dynamic>> columns,
    Map<String, Object?> values,
  ) async {
    final restricted = <String>[];
    for (final column in columns.where(
      (column) => column['type'] == 'attachment',
    )) {
      final id = column['id'] as String;
      final value = values[id];
      if (value is! List) continue;
      for (final asset in value) {
        if (!await readable(asset)) {
          restricted.add(id);
          break;
        }
      }
    }

    return restricted;
  }

  Future<bool> readable(Object? value) async {
    if (value is! String) return false;
    final id = int.tryParse(value);
    if (id == null) return false;
    final object = await ObjectRepository().findObject(
      session,
      workspaceId: member.workspaceId,
      objectId: id,
      transaction: transaction,
    );

    return object != null &&
        object.deletedAt == null &&
        object.status == 'active';
  }
}
