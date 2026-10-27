import 'package:auravibes_engine/src/tool_spec.dart';
import 'package:auravibes_engine/src/workspace_context_selection.dart';
import 'package:auravibes_engine/src/workspace_created_context.dart';

export 'package:auravibes_engine/src/workspace_context_selection.dart';

const workspaceCommandToolName = 'workspace_item';
const workspaceCommandTableId = 'host.workspace.item';
const workspaceCommandActions = <String>[
  'read',
  'listCreated',
  'createFolder',
  'renameFolder',
  'createTable',
  'renameTable',
  'createRecord',
  'updateRecord',
  'saveColumn',
  'createView',
  'saveView',
];

/// Only fixed action names may survive prompt redaction.
String workspaceContextAction(Object? input) {
  final action = input is Map ? input['action'] : null;
  return action is String && workspaceCommandActions.contains(action)
      ? action
      : 'read';
}

/// Commands carry IDs and expected revisions; hosts own grants and execution.
ToolSpec workspaceCommandToolSpec() => ToolSpec(
  name: workspaceCommandToolName,
  description:
      'Read or edit explicitly shared workspace items by stable ID. '
      'Never infer access from another Conversation. '
      'Read only selected records. '
      'Use current revisions; refresh after conflicts. '
      'Structural edits require approval in default mode. '
      'Opening an item does not share its data. '
      'Use listCreated to discover items created in this chat under the '
      'current share; it does not list other items. '
      'For the shared Directory root, read needs only action; it returns '
      'root metadata, not a list of children. '
      'For a folder or view read, provide id. For a table read, provide '
      'tableId. Use IDs and revisions from shared context or tool results. '
      'createFolder requires name and the shared folder parentId '
      '(null or omitted for root). '
      'createTable additionally requires labelName. '
      'renameFolder requires id, revision and name. '
      'renameTable requires tableId, revision, schemaRevision and name. '
      'createRecord requires tableId, revision, schemaRevision and values. '
      'updateRecord requires tableId, record id, record revision, '
      'schemaRevision and values. '
      'saveColumn requires tableId, revision, schemaRevision and column. '
      'createView requires tableId, revision, schemaRevision, name and '
      'columnIds. saveView requires id, revision, schemaRevision, name, '
      'definition and bindings.',
  inputJsonSchema: const {
    'type': 'object',
    'properties': {
      'action': {'type': 'string', 'enum': workspaceCommandActions},
      'id': {
        'type': 'string',
        'description': 'Selected folder, view, or record ID.',
      },
      'tableId': {
        'type': 'string',
        'description': 'Selected or previously created table ID.',
      },
      'cursor': {
        'type': 'string',
        'description': 'Pagination cursor returned by listCreated.',
      },
      'parentId': {
        'type': ['string', 'null'],
        'description': 'Destination folder ID; null or omitted for root.',
      },
      'revision': {
        'type': 'integer',
        'minimum': 1,
        'description': 'Current revision of the table, record, folder or view.',
      },
      'schemaRevision': {
        'type': 'integer',
        'minimum': 1,
        'description': 'Current table schema revision.',
      },
      'name': {'type': 'string', 'description': 'Name of the item or column.'},
      'labelName': {
        'type': 'string',
        'description': 'Name of the new table’s first text column.',
      },
      'values': {
        'type': 'object',
        'description': 'Map column IDs to values; use null for empty cells.',
      },
      'column': {
        'type': 'object',
        'description':
            'Column with id (empty for new), name and type. '
            'For select types include options; for references include '
            'targetTableId. Use only explicitly shared targets.',
      },
      'columnIds': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'definition': {
        'type': 'object',
        'description': 'A2UI view definition with version and components.',
      },
      'bindings': {
        'type': 'object',
        'description': 'Map view binding names to selected table column IDs.',
      },
    },
    'required': ['action'],
    'additionalProperties': false,
  },
);

bool workspaceCommandNeedsApproval(Map<String, dynamic> arguments) => !{
  'read',
  'listCreated',
  'createRecord',
  'updateRecord',
}.contains(arguments['action']);

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
  if (input['action'] == 'listCreated') {
    return {
      'action': 'listCreated',
      if (input.containsKey('cursor')) 'cursor': input['cursor'],
    };
  }
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
