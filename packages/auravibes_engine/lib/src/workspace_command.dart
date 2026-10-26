import 'package:auravibes_engine/src/tool_spec.dart';
import 'package:auravibes_engine/src/workspace_context_selection.dart';
import 'package:auravibes_engine/src/workspace_created_context.dart';

export 'package:auravibes_engine/src/workspace_context_selection.dart';

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

/// Hosts supply only verified creations from the active selection epoch.
WorkspaceContextSelection workspaceCreatedContext(
  WorkspaceContextSelection selection,
  List<Map<String, Object?>> created,
  Map<String, dynamic> arguments,
) {
  return WorkspaceCreatedContext(selection, created).resolve(arguments);
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
