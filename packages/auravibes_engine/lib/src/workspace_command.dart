import 'package:auravibes_engine/src/tool_spec.dart';

const workspaceCommandToolName = 'workspace_item';
const workspaceCommandTableId = 'host.workspace.item';
const workspaceContextMetadataKey = 'workspaceContextSelection';

/// Commands carry IDs and expected revisions; hosts own grants and execution.
ToolSpec workspaceCommandToolSpec() => ToolSpec(
  name: workspaceCommandToolName,
  description:
      'Read or edit explicitly shared workspace items by stable ID. '
      'Never infer access from another Conversation. '
      'Read only selected records. '
      'Use current revisions; refresh after conflicts. '
      'Structural edits require '
      'approval in default mode. Opening an item does not share its data.',
  inputJsonSchema: const {
    'type': 'object',
    'properties': {
      'action': {
        'type': 'string',
        'enum': [
          'read',
          'createFolder',
          'renameFolder',
          'createTable',
          'renameTable',
          'createRecord',
          'updateRecord',
          'saveColumn',
          'createView',
          'saveView',
        ],
      },
      'id': {'type': 'string'},
      'tableId': {'type': 'string'},
      'parentId': {
        'type': ['string', 'null'],
      },
      'revision': {'type': 'integer', 'minimum': 1},
      'schemaRevision': {'type': 'integer', 'minimum': 1},
      'name': {'type': 'string'},
      'labelName': {'type': 'string'},
      'values': {'type': 'object'},
      'column': {'type': 'object'},
      'columnIds': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'definition': {'type': 'object'},
      'bindings': {'type': 'object'},
    },
    'required': ['action'],
    'additionalProperties': false,
  },
);

bool workspaceCommandNeedsApproval(Map<String, dynamic> arguments) =>
    !{'read', 'createRecord', 'updateRecord'}.contains(arguments['action']);

/// A user selection event never grants data in a copied/forked Conversation.
class WorkspaceContextSelection {
  new({
    required this.workspaceId,
    required this.conversationId,
    required this.itemId,
    required this.kind,
    this.parentId,
    List<String> recordIds = const [],
  }) : recordIds = List.unmodifiable(recordIds);
  final String workspaceId;
  final String conversationId;
  final String itemId;
  final String kind;
  final String? parentId;
  final List<String> recordIds;

  Map<String, Object?> toJson() => {
    'workspaceId': workspaceId,
    'conversationId': conversationId,
    'itemId': itemId,
    'kind': kind,
    'parentId': parentId,
    'recordIds': recordIds,
  };
  static WorkspaceContextSelection? decode(
    Object? value,
    String workspaceId,
    String conversationId,
  ) {
    if (value is! Map<String, dynamic> ||
        value['workspaceId'] != workspaceId ||
        value['conversationId'] != conversationId ||
        value['itemId'] is! String ||
        value['kind'] is! String ||
        value['recordIds'] is! List<Object?>) {
      return null;
    }
    if (value['parentId'] != null && value['parentId'] is! String) return null;
    if (value['kind'] != 'directory' && (value['itemId'] as String).isEmpty) {
      return null;
    }
    final records = value['recordIds'] as List<Object?>;
    if (records.length > 50 ||
        records.any((id) => id is! String || id.isEmpty) ||
        records.toSet().length != records.length ||
        !{'directory', 'folder', 'table', 'view'}.contains(value['kind'])) {
      return null;
    }
    if (value['kind'] == 'directory' &&
        ((value['itemId'] as String).isNotEmpty || records.isNotEmpty)) {
      return null;
    }
    if (value['kind'] == 'folder' && records.isNotEmpty) return null;

    return WorkspaceContextSelection(
      workspaceId: workspaceId,
      conversationId: conversationId,
      itemId: value['itemId'] as String,
      kind: value['kind'] as String,
      parentId: value['parentId'] as String?,
      recordIds: records.cast<String>(),
    );
  }
}

/// Hosts supply only verified creations from the active selection epoch.
WorkspaceContextSelection workspaceCreatedContext(
  WorkspaceContextSelection selection,
  List<Map<String, Object?>> created,
  Map<String, dynamic> arguments,
) {
  final target =
      arguments['tableId'] ?? arguments['parentId'] ?? arguments['id'];
  final owned = created
      .where((resource) => resource['id'] == target)
      .firstOrNull;
  final id = owned?['id'] as String? ?? selection.itemId;
  final kind = owned?['kind'] as String? ?? selection.kind;
  final records = <String>{
    if (owned == null) ...selection.recordIds,
    for (final resource in created)
      if (resource['kind'] == 'record' && resource['tableId'] == id)
        if (resource['id'] case final String recordId) recordId,
  };

  return WorkspaceContextSelection(
    workspaceId: selection.workspaceId,
    conversationId: selection.conversationId,
    itemId: id,
    kind: kind,
    parentId: owned?['parentId'] as String? ?? selection.parentId,
    recordIds: records.toList(),
  );
}

const workspaceContextUnavailable =
    'Workspace content is unavailable in the current shared scope.';

/// Hosts reauthorize this read before replaying a stored workspace tool result.
Map<String, dynamic> workspaceContextReadArguments(
  Map<String, dynamic> input,
  Object? output,
) {
  final result = output is Map<String, dynamic>
      ? output
      : const <String, dynamic>{};
  final created = (input['action'] as String? ?? '').startsWith('create');

  return {
    'action': 'read',
    'id': created ? result['id'] : input['id'],
    'tableId': created && result['kind'] == 'table'
        ? result['id']
        : input['tableId'],
  };
}
