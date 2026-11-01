import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/models/workflow_field_schema_codec.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_connector_tool_sample.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_connection_text.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_port_group.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

class const WorkflowInspectorPanel({
  required final WorkspaceWorkflow workflow,
  required final WorkflowEditorState editorState,
  required final WorkflowEditorNotifier editor,
  this.canEdit = true,
  super.key,
}) extends ConsumerWidget {
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = canEdit && workflow.canManage;
    final activeWorkflows = ref.watch(workflowsProvider(workflow.workspaceId));
    final activeWorkflowIds = switch (activeWorkflows) {
      AsyncData(:final value) => {for (final item in value) item.id},
      AsyncLoading(:final value?) => {for (final item in value) item.id},
      AsyncLoading() || AsyncError() => const <String>{},
    };
    final node = workflow.nodes
        .where((item) => item.id == editorState.selectedNodeId)
        .firstOrNull;

    if (node == null) {
      return const Center(
        child: TextLocale(LocaleKeys.workflow_editor_select_step),
      );
    }

    void close() => editor.commands().nodes.clearSelection();
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            _WorkflowInspectorHeader(
              workflow: workflow,
              node: node,
              onClose: close,
            ),
            Expanded(
              child: _WorkflowNodeInspector(
                workflow: workflow,
                node: node,
                editor: editor,
                canEdit: canManage,
                unavailable:
                    activeWorkflows.hasValue &&
                    node.kind == .workflow &&
                    !activeWorkflowIds.contains(node.targetId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _WorkflowInspectorHeader({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final VoidCallback onClose,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            node.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: onClose,
          tooltip: LocaleKeys.workflow_editor_close_node_menu.tr(
            context: context,
          ),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

class const _WorkflowNodeInspector({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
  required final bool unavailable,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    children: [
      _WorkflowNodeHeading(
        workflow: workflow,
        node: node,
        editor: editor,
        canEdit: canEdit,
      ),
      Text(
        LocaleKeys.workflow_editor_internal_name.tr(context: context),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      SelectableText(node.canonicalName),
      Text(
        LocaleKeys.workflow_editor_stable_id.tr(context: context),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      SelectableText(node.targetId),
      const SizedBox(height: 12),
      if (unavailable) const _UnavailableWorkflowNotice(),
      _WorkflowNodeLabelField(node: node, editor: editor, canEdit: canEdit),
      const SizedBox(height: 16),
      ..._schemaEditors(context),
      if (node.kind != .inputs && node.kind != .condition && canEdit)
        _WorkflowInputBindings(workflow: workflow, node: node, editor: editor),
      if (node.kind == .condition)
        _WorkflowConditionEditor(
          workflow: workflow,
          node: node,
          editor: editor,
          canEdit: canEdit,
        ),
      if (node.kind == .transform)
        _WorkflowTransformEditor(
          workflow: workflow,
          node: node,
          editor: editor,
          canEdit: canEdit,
        ),
      if (node.kind == .connectorTool && canEdit)
        WorkflowConnectorToolSample(
          workspaceId: workflow.workspaceId,
          workflow: workflow,
          node: node,
          editor: editor,
          key: ValueKey(node.id),
        ),
      const SizedBox(height: 16),
      _WorkflowConnectionList(
        workflow: workflow,
        node: node,
        editor: editor,
        canEdit: canEdit,
      ),
    ],
  );

  List<Widget> _schemaEditors(BuildContext context) => switch (node.kind) {
    .inputs => [
      _WorkflowNodeFieldGroup(
        node: node,
        editor: editor,
        isInput: false,
        titleKey: LocaleKeys.workflow_editor_inputs,
        canEdit: canEdit,
      ),
    ],
    .outputs => [
      _WorkflowNodeFieldGroup(
        node: node,
        editor: editor,
        isInput: true,
        titleKey: LocaleKeys.workflow_editor_outputs,
        canEdit: canEdit,
      ),
    ],
    .connectorTool => [
      _WorkflowNodeFieldGroup(
        node: node,
        editor: editor,
        isInput: true,
        titleKey: LocaleKeys.workflow_editor_input_parameters,
        canEdit: false,
      ),
      const SizedBox(height: 12),
      _WorkflowNodeFieldGroup(
        node: node,
        editor: editor,
        isInput: false,
        titleKey: LocaleKeys.workflow_editor_output_fields,
        canEdit: canEdit,
      ),
      if (canEdit)
        _WorkflowSharedSchemaControls(
          workflow: workflow,
          node: node,
          editor: editor,
        ),
    ],
    .workflow => [
      _WorkflowNodeFieldGroup(
        node: node,
        editor: editor,
        isInput: true,
        titleKey: LocaleKeys.workflow_editor_input_parameters,
        canEdit: false,
      ),
      const SizedBox(height: 12),
      _WorkflowNodeFieldGroup(
        node: node,
        editor: editor,
        isInput: false,
        titleKey: LocaleKeys.workflow_editor_output_fields,
        canEdit: canEdit,
      ),
    ],
    .condition || .transform => const [],
  };
}

class const _WorkflowNodeHeading({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _WorkflowNodeKindLabel(kind: node.kind)),
      if (canEdit && node.kind != .inputs)
        IconButton(
          onPressed: () => _confirmDelete(context),
          tooltip: LocaleKeys.workflow_editor_delete_node.tr(context: context),
          icon: const Icon(Icons.delete_outline),
        ),
    ],
  );

  Future<void> _confirmDelete(BuildContext context) async {
    final links = workflow.connections
        .where(
          (connection) =>
              connection.fromNodeId == node.id ||
              connection.toNodeId == node.id,
        )
        .map(
          (connection) =>
              WorkflowConnectionText.description(workflow, connection, context),
        )
        .toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocaleKeys.workflow_editor_delete_confirm_title.tr(
            context: context,
            namedArgs: {'name': node.label},
          ),
        ),
        content: Text(
          LocaleKeys.workflow_editor_delete_confirm_message.tr(
            context: context,
            namedArgs: {
              'links': links.isEmpty
                  ? LocaleKeys.workflow_editor_no_links.tr(context: context)
                  : links.join(', '),
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocaleKeys.workflow_editor_cancel.tr(context: context)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              LocaleKeys.workflow_editor_confirm_delete.tr(context: context),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) editor.commands().nodes.remove(node.id);
  }
}

class const _WorkflowNodeKindLabel({required final WorkflowNodeKind kind})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.workflow_editor_kind.tr(
      context: context,
      namedArgs: {'kind': WorkflowInspectorText.kind(kind, context)},
    ),
    style: Theme.of(context).textTheme.titleMedium,
  );
}

class const _WorkflowNodeLabelField({
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey('workflow-node-name-${node.id}'),
    initialValue: node.label,
    readOnly: !canEdit,
    decoration: InputDecoration(
      labelText: LocaleKeys.workflow_editor_node_label.tr(context: context),
    ),
    onChanged: canEdit
        ? (value) => editor.commands().nodes.setLabel(node.id, value)
        : null,
  );
}

class const _WorkflowNodeFieldGroup({
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool isInput,
  required final String titleKey,
  required final bool canEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkflowPortGroup(
    titleKey: titleKey,
    ports: isInput ? node.inputFields : node.outputFields,
    onAdd: canEdit
        ? () => editor.commands().ports.addNode(
            nodeId: node.id,
            isInput: isInput,
            name: LocaleKeys.workflow_editor_field_name.tr(context: context),
          )
        : () {},
    onUpdate: (id, field) => editor.commands().ports.updateNode(
      nodeId: node.id,
      isInput: isInput,
      portId: id,
      port: field,
    ),
    onRemove: (id) => editor.commands().ports.removeNode(
      nodeId: node.id,
      isInput: isInput,
      portId: id,
    ),
    readOnly: !canEdit,
  );
}

class const _WorkflowSharedSchemaControls({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = ref.watch(workspaceToolsProvider(workflow.workspaceId));
    final tool = switch (tools) {
      AsyncData(:final value) =>
        value.where((item) => item.toolId == node.targetId).firstOrNull,
      AsyncLoading(:final value?) =>
        value.where((item) => item.toolId == node.targetId).firstOrNull,
      AsyncLoading() || AsyncError() => null,
    };
    final hasLocalSchema = workflow.definition.localConnectorSchemas
        .containsKey(node.targetId);
    final rawSharedSchema = tool?.outputSchemaJson;
    final sharedSchema = rawSharedSchema == null
        ? const <WorkflowField>[]
        : WorkflowFieldSchemaCodec.parse(rawSharedSchema);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TextLocale(LocaleKeys.workflow_editor_schema_local_notice),
        if (hasLocalSchema)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: tool == null || tools.isLoading
                    ? null
                    : () => unawaited(_saveShared(context, ref)),
                icon: const Icon(Icons.public),
                label: const TextLocale(
                  LocaleKeys.workflow_editor_schema_save_shared,
                ),
              ),
              OutlinedButton.icon(
                onPressed: sharedSchema == null
                    ? null
                    : () => unawaited(_useShared(context, sharedSchema)),
                icon: const Icon(Icons.restart_alt),
                label: const TextLocale(
                  LocaleKeys.workflow_editor_schema_use_shared,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _saveShared(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(workspaceToolsProvider(workflow.workspaceId).notifier)
          .updateToolOutputSchema(
            node.targetId,
            WorkflowFieldSchemaCodec.encode(node.outputFields),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const TextLocale(
            LocaleKeys.workflow_editor_schema_shared_saved,
          ),
        ),
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const TextLocale(
            LocaleKeys.workflow_editor_schema_save_failed,
          ),
        ),
      );
    }
  }

  Future<void> _useShared(
    BuildContext context,
    List<WorkflowField> fields,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TextLocale(
          LocaleKeys.workflow_editor_schema_use_shared_title,
        ),
        content: const TextLocale(
          LocaleKeys.workflow_editor_schema_use_shared_message,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TextLocale(LocaleKeys.workflow_editor_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const TextLocale(
              LocaleKeys.workflow_editor_schema_use_shared,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      editor.commands().nodes.useSharedConnectorSchema(node.id, fields);
    }
  }
}

class const _WorkflowInputBindings({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(),
      Text(
        LocaleKeys.workflow_editor_browse_values.tr(context: context),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      for (final field in node.inputFields)
        _WorkflowBindingField(
          workflow: workflow,
          node: node,
          field: field,
          editor: editor,
        ),
    ],
  );
}

class const _WorkflowBindingField({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowField field,
  required final WorkflowEditorNotifier editor,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final binding = node.inputBindings[field.id];
    final mode = useState(binding?.isStatic == false ? 'bound' : 'static');
    final query = useState('');
    final sources = _eligibleSources(workflow, node);
    final bindingSource = workflow.nodes
        .where((item) => item.id == binding?.sourceNodeId)
        .firstOrNull;
    final boundField = bindingSource == null
        ? null
        : _workflowFieldAt(
            bindingSource.outputFields,
            binding?.jsonPointer ?? '',
          );
    final bindingUnavailable =
        binding?.isStatic == false &&
        (bindingSource == null ||
            !sources.any((item) => item.id == bindingSource.id) ||
            boundField == null);
    final boundTypeMismatch =
        binding?.isStatic == false &&
        boundField != null &&
        !_workflowBindingTypesMatch(boundField, field);
    final staticTypeMismatch =
        binding?.isStatic == true &&
        !_workflowValueMatchesField(binding!.value, field);

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${field.name} · ${WorkflowValueTypeLabel.text(field.type, context)}',
            ),
            if (bindingUnavailable)
              TextLocale(LocaleKeys.workflow_editor_binding_unavailable),
            if (boundTypeMismatch || staticTypeMismatch)
              Text(
                LocaleKeys.workflow_editor_binding_incompatible.tr(
                  context: context,
                  namedArgs: {
                    'source': boundField == null
                        ? _workflowValueTypeName(binding!.value, context)
                        : WorkflowValueTypeLabel.text(boundField.type, context),
                    'target': WorkflowValueTypeLabel.text(field.type, context),
                  },
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            DropdownButtonFormField<String>(
              initialValue: mode.value,
              items: [
                DropdownMenuItem(
                  value: 'static',
                  child: Text(
                    LocaleKeys.workflow_editor_static_value.tr(
                      context: context,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'bound',
                  child: Text(
                    LocaleKeys.workflow_editor_bound_value.tr(context: context),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                mode.value = value;
                if (value == 'static') {
                  editor.commands().nodes.setInputBinding(
                    nodeId: node.id,
                    fieldId: field.id,
                    binding: WorkflowBinding.staticValue(field.defaultValue),
                  );
                }
              },
            ),
            if (mode.value == 'static')
              TextFormField(
                key: ValueKey('workflow-static-${field.id}'),
                initialValue: jsonEncode(
                  binding?.isStatic == true
                      ? binding!.value
                      : field.defaultValue,
                ),
                decoration: InputDecoration(
                  labelText: LocaleKeys.workflow_editor_static_value.tr(
                    context: context,
                  ),
                ),
                onChanged: (value) {
                  try {
                    editor.commands().nodes.setInputBinding(
                      nodeId: node.id,
                      fieldId: field.id,
                      binding: WorkflowBinding.staticValue(jsonDecode(value)),
                    );
                  } on FormatException {
                    // Keep invalid edits local until JSON is complete.
                  }
                },
              )
            else ...[
              TextField(
                onChanged: (value) => query.value = value,
                decoration: InputDecoration(
                  labelText: LocaleKeys.workflow_editor_search_values.tr(
                    context: context,
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              if (sources.isEmpty)
                const TextLocale(LocaleKeys.workflow_editor_no_values)
              else
                for (final source in sources)
                  if (_nodeMatches(source, query.value))
                    ExpansionTile(
                      title: Text(source.label),
                      subtitle: Text(source.canonicalName),
                      children: [
                        for (final value in source.outputFields)
                          _WorkflowFieldTree(
                            field: value,
                            pointer: '/${_escapePointer(value.name)}',
                            query: query.value,
                            onSelect: (pointer) {
                              final selected = _workflowFieldAt(
                                source.outputFields,
                                pointer,
                              );
                              if (selected == null) return;
                              if (!_workflowBindingTypesMatch(
                                selected,
                                field,
                              )) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      LocaleKeys
                                          .workflow_editor_binding_incompatible
                                          .tr(
                                            context: context,
                                            namedArgs: {
                                              'source':
                                                  WorkflowValueTypeLabel.text(
                                                    selected.type,
                                                    context,
                                                  ),
                                              'target':
                                                  WorkflowValueTypeLabel.text(
                                                    field.type,
                                                    context,
                                                  ),
                                            },
                                          ),
                                    ),
                                  ),
                                );
                                return;
                              }
                              editor.commands().nodes.setInputBinding(
                                nodeId: node.id,
                                fieldId: field.id,
                                binding: WorkflowBinding.fromNode(
                                  sourceNodeId: source.id,
                                  jsonPointer: pointer,
                                ),
                              );
                            },
                            depth: 0,
                          ),
                      ],
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

class const _WorkflowFieldTree({
  required final WorkflowField field,
  required final String pointer,
  required final String query,
  required final ValueChanged<String> onSelect,
  required final int depth,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final children = field.type == .array
        ? [if (field.items != null) field.items!]
        : field.properties;
    final childPointer = field.type == .array ? '$pointer/0' : pointer;
    final matches =
        query.isEmpty ||
        field.name.toLowerCase().contains(query.toLowerCase()) ||
        pointer.toLowerCase().contains(query.toLowerCase());
    if (!matches && !children.any((child) => _fieldTreeMatches(child, query))) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(left: depth * 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            title: Text(field.name),
            subtitle: Text(WorkflowValueTypeLabel.text(field.type, context)),
            trailing: IconButton(
              onPressed: () => onSelect(pointer),
              tooltip: LocaleKeys.workflow_editor_browse_values.tr(
                context: context,
              ),
              icon: const Icon(Icons.call_made),
            ),
          ),
          for (final child in children)
            _WorkflowFieldTree(
              field: child,
              pointer: '$childPointer/${_escapePointer(child.name)}',
              query: query,
              onSelect: onSelect,
              depth: depth + 1,
            ),
        ],
      ),
    );
  }
}

bool _fieldTreeMatches(WorkflowField field, String query) {
  if (query.isEmpty || field.name.toLowerCase().contains(query.toLowerCase())) {
    return true;
  }
  final children = field.type == .array
      ? [if (field.items != null) field.items!]
      : field.properties;
  return children.any((child) => _fieldTreeMatches(child, query));
}

List<WorkflowNode> _eligibleSources(
  WorkspaceWorkflow workflow,
  WorkflowNode target,
) {
  final available = WorkflowGraphValidation.availableValueSources(
    workflow,
    target.id,
  );

  return [
    for (final node in workflow.nodes)
      if (available.contains(node.id) &&
          node.id != target.id &&
          node.kind != .outputs &&
          node.kind != .condition &&
          node.outputFields.isNotEmpty &&
          !_reachable(workflow, target.id, node.id))
        node,
  ];
}

bool _reachable(WorkspaceWorkflow workflow, String from, String to) {
  final pending = <String>[from];
  final seen = <String>{};
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (current == to) return true;
    if (!seen.add(current)) continue;
    pending.addAll(
      workflow.connections
          .where((connection) => connection.fromNodeId == current)
          .map((connection) => connection.toNodeId),
    );
  }
  return false;
}

bool _nodeMatches(WorkflowNode node, String query) =>
    node.label.toLowerCase().contains(query.toLowerCase()) ||
    node.canonicalName.toLowerCase().contains(query.toLowerCase()) ||
    node.outputFields.any((field) => _fieldTreeMatches(field, query));

String _escapePointer(String value) =>
    value.replaceAll('~', '~0').replaceAll('/', '~1');

bool _workflowBindingTypesMatch(WorkflowField source, WorkflowField target) =>
    WorkflowGraphValidation.workflowValueTypesCompatible(
      source.type,
      target.type,
    ) &&
    (target.nullable || !source.nullable);

bool _workflowValueMatchesField(Object? value, WorkflowField field) {
  if (value == null) return field.nullable;
  final sourceType = _workflowValueType(value);
  return sourceType != null &&
      WorkflowGraphValidation.workflowValueTypesCompatible(
        sourceType,
        field.type,
      );
}

WorkflowValueType? _workflowValueType(Object? value) => switch (value) {
  String() => WorkflowValueType.string,
  int() => WorkflowValueType.integer,
  num() => WorkflowValueType.number,
  bool() => WorkflowValueType.boolean,
  Map() => WorkflowValueType.object,
  List() => WorkflowValueType.array,
  _ => null,
};

String _workflowValueTypeName(Object? value, BuildContext context) =>
    switch (_workflowValueType(value)) {
      null => 'null',
      final type => WorkflowValueTypeLabel.text(type, context),
    };

void _showBindingTypeMismatch(
  BuildContext context,
  WorkflowField source,
  WorkflowField target,
) => ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      LocaleKeys.workflow_editor_binding_incompatible.tr(
        context: context,
        namedArgs: {
          'source': WorkflowValueTypeLabel.text(source.type, context),
          'target': WorkflowValueTypeLabel.text(target.type, context),
        },
      ),
    ),
  ),
);

class const _WorkflowConditionEditor({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(),
      DropdownButtonFormField<WorkflowConditionMode>(
        initialValue: node.conditionMode,
        items: [
          DropdownMenuItem(
            value: WorkflowConditionMode.all,
            child: Text(
              LocaleKeys.workflow_editor_condition_mode_all.tr(
                context: context,
              ),
            ),
          ),
          DropdownMenuItem(
            value: WorkflowConditionMode.any,
            child: Text(
              LocaleKeys.workflow_editor_condition_mode_any.tr(
                context: context,
              ),
            ),
          ),
        ],
        onChanged: canEdit
            ? (mode) => _save(mode ?? node.conditionMode, node.conditionRules)
            : null,
      ),
      for (final rule in node.conditionRules)
        _WorkflowConditionRuleEditor(
          workflow: workflow,
          node: node,
          rule: rule,
          editor: editor,
          canEdit: canEdit,
        ),
      if (canEdit)
        TextButton.icon(
          onPressed: () {
            final source = _eligibleSources(workflow, node).firstOrNull;
            if (source == null || source.outputFields.isEmpty) return;
            _save(node.conditionMode, [
              ...node.conditionRules,
              WorkflowConditionRule(
                id: const UuidV7().generate(),
                sourceNodeId: source.id,
                jsonPointer:
                    '/${_escapePointer(source.outputFields.first.name)}',
                operator: WorkflowConditionOperator.equals,
                comparison: const WorkflowBinding.staticValue(null),
              ),
            ]);
          },
          icon: const Icon(Icons.add),
          label: Text(
            LocaleKeys.workflow_editor_add_condition.tr(context: context),
          ),
        ),
    ],
  );

  void _save(WorkflowConditionMode mode, List<WorkflowConditionRule> rules) =>
      editor.commands().nodes.setCondition(
        nodeId: node.id,
        mode: mode,
        rules: rules,
      );
}

class const _WorkflowConditionRuleEditor({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowConditionRule rule,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final sources = _eligibleSources(workflow, node);
    final source = sources
        .where((item) => item.id == rule.sourceNodeId)
        .firstOrNull;
    final sourceField = source == null
        ? null
        : _workflowFieldAt(source.outputFields, rule.jsonPointer);
    final operators = _conditionOperators(sourceField);
    final comparisonMode = useState(
      rule.comparison.isStatic ? 'static' : 'bound',
    );
    final comparisonSourceId = useState(rule.comparison.sourceNodeId);
    final query = useState('');
    final comparisonSources = _eligibleSources(workflow, node);
    final comparisonSource = comparisonSources
        .where((item) => item.id == comparisonSourceId.value)
        .firstOrNull;
    final comparisonField = comparisonSource == null
        ? null
        : _workflowFieldAt(
            comparisonSource.outputFields,
            rule.comparison.jsonPointer ?? '',
          );
    final comparisonUnavailable =
        !rule.comparison.isStatic && comparisonField == null;
    final comparisonIncompatible =
        sourceField != null &&
        !comparisonUnavailable &&
        rule.operator != WorkflowConditionOperator.exists &&
        rule.operator != WorkflowConditionOperator.isEmpty &&
        (rule.comparison.isStatic
            ? !_workflowValueMatchesField(rule.comparison.value, sourceField)
            : comparisonField != null &&
                  !_workflowBindingTypesMatch(comparisonField, sourceField));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: sources.any((item) => item.id == rule.sourceNodeId)
                  ? rule.sourceNodeId
                  : null,
              items: [
                for (final source in sources)
                  DropdownMenuItem(value: source.id, child: Text(source.label)),
              ],
              onChanged: canEdit
                  ? (sourceId) {
                      if (sourceId == null) return;
                      _replace(
                        rule.copyWithSource(
                          sourceNodeId: sourceId,
                          jsonPointer:
                              '/${_escapePointer(sources.firstWhere((item) => item.id == sourceId).outputFields.first.name)}',
                        ),
                      );
                    }
                  : null,
              decoration: InputDecoration(
                labelText: LocaleKeys.workflow_editor_condition_source.tr(
                  context: context,
                ),
              ),
            ),
            if (source == null || sourceField == null)
              TextLocale(LocaleKeys.workflow_editor_binding_unavailable),
            TextFormField(
              key: ValueKey('workflow-condition-pointer-${rule.id}'),
              initialValue: rule.jsonPointer,
              readOnly: !canEdit,
              decoration: InputDecoration(
                labelText: LocaleKeys.workflow_editor_json_pointer.tr(
                  context: context,
                ),
              ),
              onChanged: (value) => _replace(
                rule.copyWithSource(
                  sourceNodeId: rule.sourceNodeId,
                  jsonPointer: value,
                ),
              ),
            ),
            if (source != null) ...[
              TextField(
                onChanged: (value) => query.value = value,
                decoration: InputDecoration(
                  labelText: LocaleKeys.workflow_editor_search_values.tr(
                    context: context,
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              for (final field in source.outputFields)
                _WorkflowFieldTree(
                  field: field,
                  pointer: '/${_escapePointer(field.name)}',
                  query: query.value,
                  onSelect: (pointer) => _replace(
                    rule.copyWithSource(
                      sourceNodeId: rule.sourceNodeId,
                      jsonPointer: pointer,
                    ),
                  ),
                  depth: 0,
                ),
            ],
            DropdownButtonFormField<WorkflowConditionOperator>(
              initialValue: operators.contains(rule.operator)
                  ? rule.operator
                  : null,
              items: [
                for (final operator in operators)
                  DropdownMenuItem(
                    value: operator,
                    child: Text(_conditionOperatorText(operator, context)),
                  ),
              ],
              onChanged: canEdit
                  ? (value) =>
                        _replace(rule.copyWithOperator(value ?? rule.operator))
                  : null,
              decoration: InputDecoration(
                labelText: LocaleKeys.workflow_editor_condition_operator.tr(
                  context: context,
                ),
              ),
            ),
            if (rule.operator != WorkflowConditionOperator.exists &&
                rule.operator != WorkflowConditionOperator.isEmpty)
              ..._comparisonEditor(
                context,
                comparisonMode,
                comparisonSourceId,
                comparisonSource,
                comparisonSources,
                query,
                comparisonUnavailable,
                sourceField,
              ),
            if (comparisonIncompatible)
              Text(
                LocaleKeys.workflow_editor_binding_incompatible.tr(
                  context: context,
                  namedArgs: {
                    'source': rule.comparison.isStatic
                        ? _workflowValueTypeName(rule.comparison.value, context)
                        : WorkflowValueTypeLabel.text(
                            comparisonField!.type,
                            context,
                          ),
                    'target': WorkflowValueTypeLabel.text(
                      sourceField.type,
                      context,
                    ),
                  },
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (canEdit)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => _save(
                    node.conditionRules
                        .where((item) => item.id != rule.id)
                        .toList(),
                  ),
                  tooltip: LocaleKeys.workflow_editor_remove.tr(
                    context: context,
                  ),
                  icon: const Icon(Icons.close),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _comparisonEditor(
    BuildContext context,
    ValueNotifier<String> mode,
    ValueNotifier<String?> sourceId,
    WorkflowNode? source,
    List<WorkflowNode> sources,
    ValueNotifier<String> query,
    bool bindingUnavailable,
    WorkflowField? expectedField,
  ) {
    final selectedSourceId = sourceId.value;
    return [
      DropdownButtonFormField<String>(
        initialValue: mode.value,
        items: [
          DropdownMenuItem(
            value: 'static',
            child: Text(
              LocaleKeys.workflow_editor_static_value.tr(context: context),
            ),
          ),
          DropdownMenuItem(
            value: 'bound',
            child: Text(
              LocaleKeys.workflow_editor_bound_value.tr(context: context),
            ),
          ),
        ],
        onChanged: canEdit
            ? (value) {
                if (value == null) return;
                mode.value = value;
                if (value == 'static') {
                  _replace(
                    rule.copyWithComparison(
                      WorkflowBinding.staticValue(rule.comparison.value),
                    ),
                  );
                }
              }
            : null,
        decoration: InputDecoration(
          labelText: LocaleKeys.workflow_editor_comparison_value.tr(
            context: context,
          ),
        ),
      ),
      if (bindingUnavailable)
        TextLocale(LocaleKeys.workflow_editor_binding_unavailable),
      if (mode.value == 'static')
        TextFormField(
          key: ValueKey('workflow-condition-static-${rule.id}'),
          initialValue: jsonEncode(
            rule.comparison.isStatic ? rule.comparison.value : null,
          ),
          readOnly: !canEdit,
          decoration: InputDecoration(
            labelText: LocaleKeys.workflow_editor_static_value.tr(
              context: context,
            ),
          ),
          onChanged: canEdit
              ? (value) {
                  try {
                    _replace(
                      rule.copyWithComparison(
                        WorkflowBinding.staticValue(jsonDecode(value)),
                      ),
                    );
                  } on FormatException {
                    // Keep invalid JSON local until input is complete.
                  }
                }
              : null,
        )
      else ...[
        DropdownButtonFormField<String>(
          initialValue: sources.any((item) => item.id == selectedSourceId)
              ? selectedSourceId
              : null,
          items: [
            for (final item in sources)
              DropdownMenuItem(value: item.id, child: Text(item.label)),
          ],
          onChanged: canEdit
              ? (value) {
                  if (value == null) return;
                  sourceId.value = value;
                  final selected = sources.firstWhere(
                    (item) => item.id == value,
                  );
                  final field = selected.outputFields.firstOrNull;
                  if (field != null) {
                    if (expectedField != null &&
                        !_workflowBindingTypesMatch(field, expectedField)) {
                      _showBindingTypeMismatch(context, field, expectedField);
                      return;
                    }
                    _replace(
                      rule.copyWithComparison(
                        WorkflowBinding.fromNode(
                          sourceNodeId: value,
                          jsonPointer: '/${_escapePointer(field.name)}',
                        ),
                      ),
                    );
                  }
                }
              : null,
          decoration: InputDecoration(
            labelText: LocaleKeys.workflow_editor_source_step.tr(
              context: context,
            ),
          ),
        ),
        TextFormField(
          key: ValueKey('workflow-condition-compare-pointer-${rule.id}'),
          initialValue: rule.comparison.jsonPointer ?? '',
          readOnly: !canEdit,
          decoration: InputDecoration(
            labelText: LocaleKeys.workflow_editor_json_pointer.tr(
              context: context,
            ),
          ),
          onChanged: canEdit && selectedSourceId != null
              ? (pointer) => _replace(
                  rule.copyWithComparison(
                    WorkflowBinding.fromNode(
                      sourceNodeId: selectedSourceId,
                      jsonPointer: pointer,
                    ),
                  ),
                )
              : null,
        ),
        if (source != null) ...[
          TextField(
            onChanged: (value) => query.value = value,
            decoration: InputDecoration(
              labelText: LocaleKeys.workflow_editor_search_values.tr(
                context: context,
              ),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          for (final field in source.outputFields)
            _WorkflowFieldTree(
              field: field,
              pointer: '/${_escapePointer(field.name)}',
              query: query.value,
              onSelect: (pointer) {
                final selected = _workflowFieldAt(source.outputFields, pointer);
                if (expectedField == null || selected == null) return;
                if (!_workflowBindingTypesMatch(selected, expectedField)) {
                  _showBindingTypeMismatch(context, selected, expectedField);
                  return;
                }
                _replace(
                  rule.copyWithComparison(
                    WorkflowBinding.fromNode(
                      sourceNodeId: source.id,
                      jsonPointer: pointer,
                    ),
                  ),
                );
              },
              depth: 0,
            ),
        ],
      ],
    ];
  }

  void _replace(WorkflowConditionRule value) => _save([
    for (final item in node.conditionRules)
      if (item.id == rule.id) value else item,
  ]);

  void _save(List<WorkflowConditionRule> rules) => editor
      .commands()
      .nodes
      .setCondition(nodeId: node.id, mode: node.conditionMode, rules: rules);
}

extension on WorkflowConditionRule {
  WorkflowConditionRule copyWithSource({
    required String sourceNodeId,
    required String jsonPointer,
  }) => WorkflowConditionRule(
    id: id,
    sourceNodeId: sourceNodeId,
    jsonPointer: jsonPointer,
    operator: operator,
    comparison: comparison,
  );

  WorkflowConditionRule copyWithOperator(WorkflowConditionOperator operator) =>
      WorkflowConditionRule(
        id: id,
        sourceNodeId: sourceNodeId,
        jsonPointer: jsonPointer,
        operator: operator,
        comparison: comparison,
      );

  WorkflowConditionRule copyWithComparison(WorkflowBinding comparison) =>
      WorkflowConditionRule(
        id: id,
        sourceNodeId: sourceNodeId,
        jsonPointer: jsonPointer,
        operator: operator,
        comparison: comparison,
      );
}

List<WorkflowConditionOperator> _conditionOperators(WorkflowField? field) {
  final operators = <WorkflowConditionOperator>[
    .equals,
    .notEquals,
    .exists,
    .isEmpty,
  ];
  switch (field?.type) {
    case .integer || .number:
      operators.addAll([
        .greaterThan,
        .greaterThanOrEqual,
        .lessThan,
        .lessThanOrEqual,
      ]);
    case .string:
      operators.addAll([.contains, .startsWith, .endsWith]);
    case .array:
      operators.add(.contains);
    case .any:
      operators.addAll(WorkflowConditionOperator.values);
    case .boolean || .object || null:
      break;
  }

  return operators.toSet().toList();
}

String _conditionOperatorText(
  WorkflowConditionOperator operator,
  BuildContext context,
) => switch (operator) {
  .equals => LocaleKeys.workflow_editor_operator_equals.tr(context: context),
  .notEquals => LocaleKeys.workflow_editor_operator_not_equals.tr(
    context: context,
  ),
  .exists => LocaleKeys.workflow_editor_operator_exists.tr(context: context),
  .isEmpty => LocaleKeys.workflow_editor_operator_is_empty.tr(context: context),
  .greaterThan => LocaleKeys.workflow_editor_operator_greater_than.tr(
    context: context,
  ),
  .greaterThanOrEqual =>
    LocaleKeys.workflow_editor_operator_greater_than_or_equal.tr(
      context: context,
    ),
  .lessThan => LocaleKeys.workflow_editor_operator_less_than.tr(
    context: context,
  ),
  .lessThanOrEqual => LocaleKeys.workflow_editor_operator_less_than_or_equal.tr(
    context: context,
  ),
  .contains => LocaleKeys.workflow_editor_operator_contains.tr(
    context: context,
  ),
  .startsWith => LocaleKeys.workflow_editor_operator_starts_with.tr(
    context: context,
  ),
  .endsWith => LocaleKeys.workflow_editor_operator_ends_with.tr(
    context: context,
  ),
};

WorkflowField? _workflowFieldAt(List<WorkflowField> fields, String pointer) {
  if (!pointer.startsWith('/')) return null;
  WorkflowField? current;
  var currentFields = fields;
  for (final segment
      in pointer
          .substring(1)
          .split('/')
          .map((value) => value.replaceAll('~1', '/').replaceAll('~0', '~'))) {
    if (current?.type == .array) {
      if (segment != '0') return null;
      current = current!.items;
      if (current == null) return null;
    } else {
      current = currentFields
          .where((field) => field.name == segment)
          .firstOrNull;
      if (current == null) return null;
    }
    currentFields = current.properties;
  }

  return current;
}

String _transformOperationText(
  WorkflowTransformOperation operation,
  BuildContext context,
) => switch (operation) {
  .selectField => LocaleKeys.workflow_editor_operation_select_field.tr(
    context: context,
  ),
  .buildObject => LocaleKeys.workflow_editor_operation_build_object.tr(
    context: context,
  ),
  .buildArray => LocaleKeys.workflow_editor_operation_build_array.tr(
    context: context,
  ),
  .stringTemplate => LocaleKeys.workflow_editor_operation_string_template.tr(
    context: context,
  ),
  .add => LocaleKeys.workflow_editor_operation_add.tr(context: context),
  .subtract => LocaleKeys.workflow_editor_operation_subtract.tr(
    context: context,
  ),
  .multiply => LocaleKeys.workflow_editor_operation_multiply.tr(
    context: context,
  ),
  .divide => LocaleKeys.workflow_editor_operation_divide.tr(context: context),
  .castString => LocaleKeys.workflow_editor_operation_cast_string.tr(
    context: context,
  ),
  .castInteger => LocaleKeys.workflow_editor_operation_cast_integer.tr(
    context: context,
  ),
  .castNumber => LocaleKeys.workflow_editor_operation_cast_number.tr(
    context: context,
  ),
  .castBoolean => LocaleKeys.workflow_editor_operation_cast_boolean.tr(
    context: context,
  ),
};

String _transformOperationHelp(
  WorkflowTransformOperation operation,
  BuildContext context,
) {
  final key = switch (operation) {
    .selectField => LocaleKeys.workflow_editor_operation_help_select_field,
    .buildObject => LocaleKeys.workflow_editor_operation_help_build_object,
    .buildArray => LocaleKeys.workflow_editor_operation_help_build_array,
    .stringTemplate =>
      LocaleKeys.workflow_editor_operation_help_string_template,
    .add ||
    .subtract ||
    .multiply ||
    .divide => LocaleKeys.workflow_editor_operation_help_arithmetic,
    .castString ||
    .castInteger ||
    .castNumber ||
    .castBoolean => LocaleKeys.workflow_editor_operation_help_cast,
  };

  return key.tr(context: context);
}

WorkflowValueType _suggestedTransformType(
  WorkflowTransformOperation operation,
  WorkflowValueType current,
) => switch (operation) {
  .selectField => current,
  .buildObject => .object,
  .buildArray => .array,
  .stringTemplate || .castString => .string,
  .add ||
  .subtract ||
  .multiply ||
  .divide => current == .integer ? .integer : .number,
  .castInteger => .integer,
  .castNumber => .number,
  .castBoolean => .boolean,
};

class const _WorkflowTransformEditor({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final invalidOutputIds = WorkflowGraphValidation.invalidTransformOutputIds(
      workflow,
      node.id,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Text(LocaleKeys.workflow_editor_transform_fields.tr(context: context)),
        if (invalidOutputIds.isNotEmpty)
          TextLocale(LocaleKeys.workflow_editor_transform_output_invalid),
        for (final output in node.transformOutputs)
          _WorkflowTransformOutputEditor(
            workflow: workflow,
            output: output,
            node: node,
            editor: editor,
            canEdit: canEdit,
            isValid: !invalidOutputIds.contains(output.id),
          ),
        if (canEdit)
          TextButton.icon(
            onPressed: () =>
                editor.commands().nodes.setTransformOutputs(node.id, [
                  ...node.transformOutputs,
                  WorkflowTransformOutput(
                    id: const UuidV7().generate(),
                    name: 'value${node.transformOutputs.length + 1}',
                    type: WorkflowValueType.any,
                    operation: WorkflowTransformOperation.selectField,
                  ),
                ]),
            icon: const Icon(Icons.add),
            label: Text(
              LocaleKeys.workflow_editor_add_transform_output.tr(
                context: context,
              ),
            ),
          ),
      ],
    );
  }
}

class const _WorkflowTransformOutputEditor({
  required final WorkspaceWorkflow workflow,
  required final WorkflowTransformOutput output,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
  required final bool isValid,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextFormField(
            initialValue: output.name,
            readOnly: !canEdit,
            decoration: InputDecoration(
              labelText: LocaleKeys.workflow_editor_field_name.tr(
                context: context,
              ),
            ),
            onChanged: (value) => _replace(_copy(name: value)),
          ),
          DropdownButtonFormField<WorkflowValueType>(
            initialValue: output.type,
            items: [
              for (final type in WorkflowValueType.values)
                DropdownMenuItem(
                  value: type,
                  child: Text(WorkflowValueTypeLabel.text(type, context)),
                ),
            ],
            onChanged: canEdit
                ? (value) => _replace(_copy(type: value ?? output.type))
                : null,
            decoration: InputDecoration(
              labelText: LocaleKeys.workflow_editor_field_type.tr(
                context: context,
              ),
            ),
          ),
          DropdownButtonFormField<WorkflowTransformOperation>(
            initialValue: output.operation,
            items: [
              for (final operation in WorkflowTransformOperation.values)
                DropdownMenuItem(
                  value: operation,
                  child: Text(_transformOperationText(operation, context)),
                ),
            ],
            onChanged: canEdit
                ? (value) {
                    final operation = value ?? output.operation;
                    _replace(
                      _copy(
                        operation: operation,
                        type: _suggestedTransformType(operation, output.type),
                      ),
                    );
                  }
                : null,
            decoration: InputDecoration(
              labelText: LocaleKeys.workflow_editor_operation.tr(
                context: context,
              ),
            ),
          ),
          Text(
            _transformOperationHelp(output.operation, context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!isValid)
            TextLocale(LocaleKeys.workflow_editor_transform_output_invalid),
          if (output.operation == .stringTemplate)
            TextFormField(
              initialValue: output.template ?? '',
              readOnly: !canEdit,
              decoration: InputDecoration(
                labelText: LocaleKeys.workflow_editor_operation_template.tr(
                  context: context,
                ),
              ),
              onChanged: canEdit
                  ? (value) => _replace(_copy(template: value))
                  : null,
            ),
          for (final entry in output.operands.indexed)
            _WorkflowTransformOperandEditor(
              key: ValueKey('${output.id}-${entry.$2.id}'),
              workflow: workflow,
              node: node,
              output: output,
              operand: entry.$2,
              editor: editor,
              canEdit: canEdit,
              onChanged: (operand) => _replace(
                _copy(
                  operands: [
                    for (final item in output.operands)
                      if (item.id == operand.id) operand else item,
                  ],
                ),
              ),
            ),
          if (canEdit)
            TextButton.icon(
              onPressed: () => _replace(
                _copy(
                  operands: [
                    ...output.operands,
                    WorkflowTransformOperand(
                      id: const UuidV7().generate(),
                      name: 'value${output.operands.length + 1}',
                      binding: const WorkflowBinding.staticValue(null),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                LocaleKeys.workflow_editor_add_transform_operand.tr(
                  context: context,
                ),
              ),
            ),
          if (canEdit)
            IconButton(
              onPressed: () => editor.commands().nodes.setTransformOutputs(
                node.id,
                node.transformOutputs
                    .where((item) => item.id != output.id)
                    .toList(),
              ),
              tooltip: LocaleKeys.workflow_editor_remove.tr(context: context),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    ),
  );

  WorkflowTransformOutput _copy({
    String? name,
    WorkflowValueType? type,
    WorkflowTransformOperation? operation,
    String? template,
    List<WorkflowTransformOperand>? operands,
  }) => WorkflowTransformOutput(
    id: output.id,
    name: name ?? output.name,
    type: type ?? output.type,
    operation: operation ?? output.operation,
    operands: operands ?? output.operands,
    template: template ?? output.template,
  );

  void _replace(WorkflowTransformOutput value) =>
      editor.commands().nodes.setTransformOutputs(node.id, [
        for (final item in node.transformOutputs)
          if (item.id == output.id) value else item,
      ]);
}

class const _WorkflowTransformOperandEditor({
  super.key,
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowTransformOutput output,
  required final WorkflowTransformOperand operand,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
  required final ValueChanged<WorkflowTransformOperand> onChanged,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final mode = useState(operand.binding.isStatic ? 'static' : 'bound');
    final sourceId = useState(operand.binding.sourceNodeId);
    final query = useState('');
    final sources = _eligibleSources(workflow, node);
    final selectedSourceId = sourceId.value;
    final source = sources
        .where((item) => item.id == selectedSourceId)
        .firstOrNull;
    final operandUnavailable =
        !operand.binding.isStatic &&
        (source == null ||
            _workflowFieldAt(
                  source.outputFields,
                  operand.binding.jsonPointer ?? '',
                ) ==
                null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: ValueKey('workflow-transform-operand-${operand.id}'),
              initialValue: operand.name,
              readOnly: !canEdit,
              decoration: InputDecoration(
                labelText: LocaleKeys.workflow_editor_operand_name.tr(
                  context: context,
                ),
              ),
              onChanged: canEdit
                  ? (name) => onChanged(
                      WorkflowTransformOperand(
                        id: operand.id,
                        name: name,
                        binding: operand.binding,
                      ),
                    )
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: mode.value,
              items: [
                DropdownMenuItem(
                  value: 'static',
                  child: Text(
                    LocaleKeys.workflow_editor_static_value.tr(
                      context: context,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'bound',
                  child: Text(
                    LocaleKeys.workflow_editor_bound_value.tr(context: context),
                  ),
                ),
              ],
              onChanged: canEdit
                  ? (value) {
                      if (value == null) return;
                      mode.value = value;
                      if (value == 'static') {
                        _setBinding(
                          WorkflowBinding.staticValue(operand.binding.value),
                        );
                      }
                    }
                  : null,
            ),
            if (mode.value == 'static')
              TextFormField(
                key: ValueKey('workflow-transform-static-${operand.id}'),
                initialValue: jsonEncode(
                  operand.binding.isStatic ? operand.binding.value : null,
                ),
                readOnly: !canEdit,
                decoration: InputDecoration(
                  labelText: LocaleKeys.workflow_editor_static_value.tr(
                    context: context,
                  ),
                ),
                onChanged: canEdit
                    ? (value) {
                        try {
                          _setBinding(
                            WorkflowBinding.staticValue(jsonDecode(value)),
                          );
                        } on FormatException {
                          // Keep invalid JSON local until input is complete.
                        }
                      }
                    : null,
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: sources.any((item) => item.id == sourceId.value)
                    ? sourceId.value
                    : null,
                items: [
                  for (final item in sources)
                    DropdownMenuItem(value: item.id, child: Text(item.label)),
                ],
                onChanged: canEdit
                    ? (value) {
                        if (value == null) return;
                        sourceId.value = value;
                        final selected = sources.firstWhere(
                          (item) => item.id == value,
                        );
                        final field = selected.outputFields.firstOrNull;
                        if (field != null) {
                          _setBinding(
                            WorkflowBinding.fromNode(
                              sourceNodeId: value,
                              jsonPointer: '/${_escapePointer(field.name)}',
                            ),
                          );
                        }
                      }
                    : null,
                decoration: InputDecoration(
                  labelText: LocaleKeys.workflow_editor_source_step.tr(
                    context: context,
                  ),
                ),
              ),
              if (operandUnavailable)
                TextLocale(LocaleKeys.workflow_editor_binding_unavailable),
              TextFormField(
                key: ValueKey('workflow-transform-pointer-${operand.id}'),
                initialValue: operand.binding.jsonPointer ?? '',
                readOnly: !canEdit,
                decoration: InputDecoration(
                  labelText: LocaleKeys.workflow_editor_json_pointer.tr(
                    context: context,
                  ),
                ),
                onChanged: canEdit && selectedSourceId != null
                    ? (pointer) => _setBinding(
                        WorkflowBinding.fromNode(
                          sourceNodeId: selectedSourceId,
                          jsonPointer: pointer,
                        ),
                      )
                    : null,
              ),
              if (source != null) ...[
                TextField(
                  onChanged: (value) => query.value = value,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.workflow_editor_search_values.tr(
                      context: context,
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                for (final field in source.outputFields)
                  _WorkflowFieldTree(
                    field: field,
                    pointer: '/${_escapePointer(field.name)}',
                    query: query.value,
                    onSelect: (pointer) => _setBinding(
                      WorkflowBinding.fromNode(
                        sourceNodeId: source.id,
                        jsonPointer: pointer,
                      ),
                    ),
                    depth: 0,
                  ),
              ],
            ],
            if (canEdit)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () =>
                      editor.commands().nodes.setTransformOutputs(node.id, [
                        for (final item in node.transformOutputs)
                          if (item.id == output.id)
                            WorkflowTransformOutput(
                              id: item.id,
                              name: item.name,
                              type: item.type,
                              operation: item.operation,
                              operands: item.operands
                                  .where((item) => item.id != operand.id)
                                  .toList(),
                              template: item.template,
                            )
                          else
                            item,
                      ]),
                  tooltip: LocaleKeys.workflow_editor_remove.tr(
                    context: context,
                  ),
                  icon: const Icon(Icons.close),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _setBinding(WorkflowBinding binding) => onChanged(
    WorkflowTransformOperand(
      id: operand.id,
      name: operand.name,
      binding: binding,
    ),
  );
}

class const _UnavailableWorkflowNotice() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 8),
    child: TextLocale(
      LocaleKeys.workflow_editor_referenced_workflow_unavailable,
    ),
  );
}

class const _WorkflowConnectionList({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connections = workflow.connections
        .where(
          (connection) =>
              connection.fromNodeId == node.id ||
              connection.toNodeId == node.id,
        )
        .toList();
    if (connections.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TextLocale(LocaleKeys.workflow_editor_connections),
        for (final connection in connections)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              WorkflowConnectionText.description(workflow, connection, context),
            ),
            trailing: canEdit
                ? IconButton(
                    onPressed: () =>
                        editor.commands().connections.remove(connection),
                    tooltip: LocaleKeys.workflow_editor_remove.tr(
                      context: context,
                    ),
                    icon: const Icon(Icons.link_off),
                  )
                : null,
          ),
      ],
    );
  }
}

abstract final class WorkflowInspectorText {
  static String kind(WorkflowNodeKind kind, BuildContext context) =>
      switch (kind) {
        .inputs => LocaleKeys.workflow_editor_inputs.tr(context: context),
        .outputs => LocaleKeys.workflow_editor_outputs.tr(context: context),
        .condition => LocaleKeys.workflow_editor_condition.tr(context: context),
        .transform => LocaleKeys.workflow_editor_transform.tr(context: context),
        .connectorTool => LocaleKeys.workflow_editor_connector_tool.tr(
          context: context,
        ),
        .workflow => LocaleKeys.workflow_editor_workflow.tr(context: context),
      };
}

abstract final class WorkflowValueTypeLabel {
  static const _keys = <WorkflowValueType, String>{
    .any: LocaleKeys.workflow_editor_type_any,
    .string: LocaleKeys.workflow_editor_type_string,
    .integer: LocaleKeys.workflow_editor_type_integer,
    .number: LocaleKeys.workflow_editor_type_number,
    .boolean: LocaleKeys.workflow_editor_type_boolean,
    .object: LocaleKeys.workflow_editor_type_object,
    .array: LocaleKeys.workflow_editor_type_array,
  };

  static String text(WorkflowValueType type, BuildContext context) =>
      _keys[type]!.tr(context: context);
}
