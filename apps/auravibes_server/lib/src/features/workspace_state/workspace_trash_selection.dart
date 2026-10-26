import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../generated/protocol.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_context.dart';
import 'workspace_trash_store.dart';

class const WorkspaceTrashSelection(
  final String encodedTarget,
  final WorkspaceResource root,
  final List<WorkspaceResource> members,
) {
  String get name => trashData(root)['name'] as String? ?? '';

  static Future<WorkspaceTrashSelection> load(
    WorkspaceTrashContext context,
    String encoded,
  ) async {
    final target = _target(encoded);
    final rows = await context.store.resources();
    final root = _root(rows, target);
    await context.require(root);
    _current(root, target);

    return .new(encoded, root, await _members(context, root, rows));
  }

  Future<String> token() async {
    final rows = members.map((row) => jsonEncode(trashMember(row))).toList()
      ..sort();
    final hash = await Sha256().hash(utf8.encode(jsonEncode(rows)));

    return base64UrlEncode(hash.bytes);
  }

  Future<String> preview() async => jsonEncode({
    'id': '',
    'target': jsonDecode(encodedTarget),
    'name': name,
    'affectedCount': members.length,
    'planToken': await token(),
  });
  List<WorkspaceResource> tombstones(DateTime now) =>
      members.map((row) => _deleted(row, now)).toList();
}

const _maximumTargetLength = 2000;
Map<String, dynamic> _target(String encoded) {
  if (encoded.length > _maximumTargetLength) trashInvalid();
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic> || !_validIdentity(decoded)) {
      trashInvalid();
    }

    return decoded;
  } on FormatException {
    trashInvalid();
  }
}

bool _validIdentity(Map<String, dynamic> value) =>
    value['id'] is String &&
    (value['id'] as String).isNotEmpty &&
    value['revision'] is int &&
    (value['revision'] as int) > 0;
WorkspaceResource _root(
  List<WorkspaceResource> rows,
  Map<String, dynamic> target,
) {
  final kind = _kind(target['kind']);

  return rows
          .where(
            (row) => row.resourceId == target['id'] && row.resourceKind == kind,
          )
          .firstOrNull ??
      trashDenied();
}

void _current(WorkspaceResource root, Map<String, dynamic> target) {
  if (root.deletedAt != null || root.revision != target['revision']) {
    trashConflict();
  }
  if (root.resourceKind == .tableRecord &&
      trashData(root)['tableId'] != target['tableId']) {
    trashInvalid();
  }
}

WorkspaceResourceKind _kind(Object? kind) => switch (kind) {
  'folder' => .folder,
  'table' => .table,
  'record' => .tableRecord,
  'view' => .view,
  'file' => .file,
  _ => trashInvalid(),
};
WorkspaceResource _deleted(WorkspaceResource row, DateTime now) =>
    row.copyWith(deletedAt: now, updatedAt: now, revision: row.revision + 1);

Future<List<WorkspaceResource>> _members(
  WorkspaceTrashContext context,
  WorkspaceResource root,
  List<WorkspaceResource> rows,
) async {
  final members = trashDescendants(root, rows);
  for (final row in members) {
    await context.require(row);
  }

  return members;
}
