import 'dart:async';

import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/models/workflow_field_schema_codec.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_connection_text.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_connector_tool_sample.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_port_group.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_value_binding_field.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:collection/collection.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

class const WorkflowInspectorPanel({
  required final WorkspaceWorkflow workflow,
  required final WorkflowEditorState editorState,
  required final WorkflowEditorNotifier editor,
  this.canEdit = true,
  this.isWide = false,
  super.key,
}) extends ConsumerWidget {
  final bool canEdit;
  final bool isWide;

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
                isWide: isWide,
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
        AuraIconButton(
          onPressed: onClose,
          tooltip: LocaleKeys.workflow_editor_close_node_menu.tr(
            context: context,
          ),
          semanticLabel: LocaleKeys.workflow_editor_close_node_menu.tr(
            context: context,
          ),
          icon: Icons.close,
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
  required final bool isWide,
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
        _WorkflowInputBindings(
          workflow: workflow,
          node: node,
          editor: editor,
          isWide: isWide,
        ),
      if (node.kind == .condition)
        _WorkflowConditionEditor(
          workflow: workflow,
          node: node,
          editor: editor,
          canEdit: canEdit,
          isWide: isWide,
        ),
      if (node.kind == .transform)
        _WorkflowTransformEditor(
          workflow: workflow,
          node: node,
          editor: editor,
          canEdit: canEdit,
          isWide: isWide,
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
        AuraIconButton(
          onPressed: () => _confirmDelete(context),
          tooltip: LocaleKeys.workflow_editor_delete_node.tr(context: context),
          semanticLabel: LocaleKeys.workflow_editor_delete_node.tr(
            context: context,
          ),
          tint: .error,
          icon: Icons.delete_outline,
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
    final confirmed = await AuraDialogs.confirm(
      context: context,
      title: Text(
        LocaleKeys.workflow_editor_delete_confirm_title.tr(
          context: context,
          namedArgs: {'name': node.label},
        ),
      ),
      message: Text(
        LocaleKeys.workflow_editor_delete_confirm_message.tr(
          context: context,
          namedArgs: {
            'links': links.isEmpty
                ? LocaleKeys.workflow_editor_no_links.tr(context: context)
                : links.join(', '),
          },
        ),
      ),
      actions: AuraConfirmDialogActions(
        cancelLabel: Text(
          LocaleKeys.workflow_editor_cancel.tr(context: context),
        ),
        confirmLabel: Text(
          LocaleKeys.workflow_editor_confirm_delete.tr(context: context),
        ),
      ),
      isDestructive: true,
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
  Widget build(BuildContext context) => AuraInput(
    key: ValueKey('workflow-node-name-${node.id}'),
    initialValue: node.label,
    readOnly: !canEdit,
    size: .small,
    label: Text(LocaleKeys.workflow_editor_node_label.tr(context: context)),
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
              AuraButton(
                onPressed: () => unawaited(_saveShared(context, ref)),
                disabled: tool == null || tools.isLoading,
                variant: .outlined,
                size: .small,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public),
                    const SizedBox(width: 8),
                    const TextLocale(
                      LocaleKeys.workflow_editor_schema_save_shared,
                    ),
                  ],
                ),
              ),
              AuraButton(
                onPressed: () => unawaited(_useShared(context, sharedSchema!)),
                disabled: sharedSchema == null,
                variant: .outlined,
                size: .small,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restart_alt),
                    const SizedBox(width: 8),
                    const TextLocale(
                      LocaleKeys.workflow_editor_schema_use_shared,
                    ),
                  ],
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
      final _ = AuraSnackBars.show(
        context: context,
        content: const TextLocale(
          LocaleKeys.workflow_editor_schema_shared_saved,
        ),
        variant: .success,
      );
    } on Object {
      if (!context.mounted) return;
      final _ = AuraSnackBars.show(
        context: context,
        content: const TextLocale(
          LocaleKeys.workflow_editor_schema_save_failed,
        ),
        variant: .error,
      );
    }
  }

  Future<void> _useShared(
    BuildContext context,
    List<WorkflowField> fields,
  ) async {
    final confirmed = await AuraDialogs.confirm(
      context: context,
      title: const TextLocale(
        LocaleKeys.workflow_editor_schema_use_shared_title,
      ),
      message: const TextLocale(
        LocaleKeys.workflow_editor_schema_use_shared_message,
      ),
      actions: const AuraConfirmDialogActions(
        cancelLabel: TextLocale(LocaleKeys.workflow_editor_cancel),
        confirmLabel: TextLocale(LocaleKeys.workflow_editor_schema_use_shared),
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
  required final bool isWide,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const AuraDivider(),
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
          isWide: isWide,
        ),
    ],
  );
}

class const _WorkflowBindingField({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowField field,
  required final WorkflowEditorNotifier editor,
  required final bool isWide,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final binding = node.inputBindings[field.id];
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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AuraCard(
        padding: .small,
        style: .border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${field.name} · ${WorkflowValueTypeLabel.text(field.type, context)}',
                  ),
                ),
                if (field.isRequired)
                  AuraBadge.text(
                    size: .small,
                    variant: .outlined,
                    child: const TextLocale(
                      LocaleKeys.workflow_editor_required,
                    ),
                  ),
              ],
            ),
            if (field.description.isNotEmpty) Text(field.description),
            if (bindingUnavailable)
              TextLocale(LocaleKeys.workflow_editor_binding_unavailable),
            if (boundTypeMismatch)
              Text(
                LocaleKeys.workflow_editor_binding_incompatible.tr(
                  context: context,
                  namedArgs: {
                    'source': WorkflowValueTypeLabel.text(
                      boundField.type,
                      context,
                    ),
                    'target': WorkflowValueTypeLabel.text(field.type, context),
                  },
                ),
                style: TextStyle(color: context.auraColors.error),
              ),
            WorkflowValueBindingField(
              field: field,
              binding: binding,
              sources: sources,
              isWide: isWide,
              onChanged: (value) => editor.commands().nodes.setInputBinding(
                nodeId: node.id,
                fieldId: field.id,
                binding: value,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

String _escapePointer(String value) =>
    value.replaceAll('~', '~0').replaceAll('/', '~1');

bool _workflowBindingTypesMatch(WorkflowField source, WorkflowField target) =>
    WorkflowGraphValidation.workflowFieldsCompatible(source, target);

class const _WorkflowConditionEditor({
  required final WorkspaceWorkflow workflow,
  required final WorkflowNode node,
  required final WorkflowEditorNotifier editor,
  required final bool canEdit,
  required final bool isWide,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const AuraDivider(),
      AuraDropdownSelector<WorkflowConditionMode>(
        value: node.conditionMode,
        isEnabled: canEdit,
        options: [
          AuraDropdownOption<WorkflowConditionMode>(
            value: WorkflowConditionMode.all,
            child: Text(
              LocaleKeys.workflow_editor_condition_mode_all.tr(
                context: context,
              ),
            ),
          ),
          AuraDropdownOption<WorkflowConditionMode>(
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
          isWide: isWide,
        ),
      if (canEdit)
        AuraButton(
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
          variant: .text,
          size: .small,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.workflow_editor_add_condition.tr(context: context),
              ),
            ],
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
  required final bool isWide,
}) extends StatelessWidget {
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
    final comparisonSources = _eligibleSources(workflow, node);
    final comparisonSource = comparisonSources
        .where((item) => item.id == rule.comparison.sourceNodeId)
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
        !rule.comparison.isStatic &&
        rule.operator != WorkflowConditionOperator.exists &&
        rule.operator != WorkflowConditionOperator.isEmpty &&
        comparisonField != null &&
        !_workflowBindingTypesMatch(comparisonField, sourceField);
    return AuraCard(
      padding: .small,
      style: .border,
      child: Column(
        children: [
          WorkflowSourceFieldPicker(
            label: LocaleKeys.workflow_editor_condition_source.tr(
              context: context,
            ),
            sources: sources,
            selectedNodeId: rule.sourceNodeId,
            selectedPointer: rule.jsonPointer,
            isWide: isWide,
            enabled: canEdit,
            onSelected: (binding) => _replace(
              rule.copyWithSource(
                sourceNodeId: binding.sourceNodeId!,
                jsonPointer: binding.jsonPointer!,
              ),
            ),
          ),
          if (source == null || sourceField == null)
            TextLocale(LocaleKeys.workflow_editor_binding_unavailable),
          AuraDropdownSelector<WorkflowConditionOperator>(
            value: operators.contains(rule.operator) ? rule.operator : null,
            isEnabled: canEdit,
            options: [
              for (final operator in operators)
                AuraDropdownOption<WorkflowConditionOperator>(
                  value: operator,
                  child: Text(_conditionOperatorText(operator, context)),
                ),
            ],
            onChanged: canEdit
                ? (value) =>
                      _replace(rule.copyWithOperator(value ?? rule.operator))
                : null,
            label: Text(
              LocaleKeys.workflow_editor_condition_operator.tr(
                context: context,
              ),
            ),
          ),
          if (rule.operator != WorkflowConditionOperator.exists &&
              rule.operator != WorkflowConditionOperator.isEmpty)
            WorkflowValueBindingField(
              key: ValueKey('workflow-condition-comparison-${rule.id}'),
              field:
                  sourceField ??
                  WorkflowField(
                    id: 'condition-${rule.id}',
                    name: LocaleKeys.workflow_editor_comparison_value.tr(
                      context: context,
                    ),
                    type: .any,
                    isRequired: false,
                    nullable: true,
                  ),
              binding: rule.comparison,
              sources: comparisonSources,
              isWide: isWide,
              enabled: canEdit,
              onChanged: (value) => _replace(rule.copyWithComparison(value)),
            ),
          if (comparisonIncompatible)
            Text(
              LocaleKeys.workflow_editor_binding_incompatible.tr(
                context: context,
                namedArgs: {
                  'source': WorkflowValueTypeLabel.text(
                    comparisonField.type,
                    context,
                  ),
                  'target': WorkflowValueTypeLabel.text(
                    sourceField.type,
                    context,
                  ),
                },
              ),
              style: TextStyle(color: context.auraColors.error),
            ),
          if (canEdit)
            Align(
              alignment: Alignment.centerRight,
              child: AuraIconButton(
                onPressed: () => _save(
                  node.conditionRules
                      .where((item) => item.id != rule.id)
                      .toList(),
                ),
                tooltip: LocaleKeys.workflow_editor_remove.tr(context: context),
                semanticLabel: LocaleKeys.workflow_editor_remove.tr(
                  context: context,
                ),
                icon: Icons.close,
              ),
            ),
        ],
      ),
    );
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
  required final bool isWide,
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
        const AuraDivider(),
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
            isWide: isWide,
            isValid: !invalidOutputIds.contains(output.id),
          ),
        if (canEdit)
          AuraButton(
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
            variant: .text,
            size: .small,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.workflow_editor_add_transform_output.tr(
                    context: context,
                  ),
                ),
              ],
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
  required final bool isWide,
  required final bool isValid,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    padding: .small,
    style: .border,
    child: Column(
      children: [
        AuraInput(
          initialValue: output.name,
          readOnly: !canEdit,
          size: .small,
          label: Text(
            LocaleKeys.workflow_editor_field_name.tr(context: context),
          ),
          onChanged: (value) => _replace(_copy(name: value)),
        ),
        AuraDropdownSelector<WorkflowValueType>(
          value: output.type,
          isEnabled: canEdit,
          options: [
            for (final type in WorkflowValueType.values)
              AuraDropdownOption<WorkflowValueType>(
                value: type,
                child: Text(WorkflowValueTypeLabel.text(type, context)),
              ),
          ],
          onChanged: canEdit
              ? (value) => _replace(_copy(type: value ?? output.type))
              : null,
          label: Text(
            LocaleKeys.workflow_editor_field_type.tr(context: context),
          ),
        ),
        AuraDropdownSelector<WorkflowTransformOperation>(
          value: output.operation,
          isEnabled: canEdit,
          options: [
            for (final operation in WorkflowTransformOperation.values)
              AuraDropdownOption<WorkflowTransformOperation>(
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
          label: Text(
            LocaleKeys.workflow_editor_operation.tr(context: context),
          ),
        ),
        Text(
          _transformOperationHelp(output.operation, context),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (!isValid)
          TextLocale(LocaleKeys.workflow_editor_transform_output_invalid),
        if (output.operation == .stringTemplate)
          AuraInput(
            initialValue: output.template ?? '',
            readOnly: !canEdit,
            size: .small,
            label: Text(
              LocaleKeys.workflow_editor_operation_template.tr(
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
            isWide: isWide,
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
          AuraButton(
            onPressed: () => _replace(
              _copy(
                operands: [
                  ...output.operands,
                  WorkflowTransformOperand(
                    id: const UuidV7().generate(),
                    name: 'value${output.operands.length + 1}',
                    binding: const WorkflowBinding.staticValue(
                      null,
                      hasValue: false,
                    ),
                  ),
                ],
              ),
            ),
            variant: .text,
            size: .small,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.workflow_editor_add_transform_operand.tr(
                    context: context,
                  ),
                ),
              ],
            ),
          ),
        if (canEdit)
          AuraIconButton(
            onPressed: () => editor.commands().nodes.setTransformOutputs(
              node.id,
              node.transformOutputs
                  .where((item) => item.id != output.id)
                  .toList(),
            ),
            tooltip: LocaleKeys.workflow_editor_remove.tr(context: context),
            semanticLabel: LocaleKeys.workflow_editor_remove.tr(
              context: context,
            ),
            icon: Icons.close,
          ),
      ],
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
  required final bool isWide,
  required final ValueChanged<WorkflowTransformOperand> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sources = _eligibleSources(workflow, node);
    final source = sources
        .where((item) => item.id == operand.binding.sourceNodeId)
        .firstOrNull;
    final operandUnavailable =
        !operand.binding.isStatic &&
        (source == null ||
            _workflowFieldAt(
                  source.outputFields,
                  operand.binding.jsonPointer ?? '',
                ) ==
                null);
    final targetType = switch (output.operation) {
      .selectField => output.type,
      .add || .subtract || .multiply || .divide => output.type,
      .stringTemplate => WorkflowValueType.string,
      .buildObject ||
      .buildArray ||
      .castString ||
      .castInteger ||
      .castNumber ||
      .castBoolean => WorkflowValueType.any,
    };

    return AuraCard(
      padding: .small,
      style: .border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraInput(
            key: ValueKey('workflow-transform-operand-${operand.id}'),
            initialValue: operand.name,
            readOnly: !canEdit,
            size: .small,
            label: Text(
              LocaleKeys.workflow_editor_operand_name.tr(context: context),
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
          WorkflowValueBindingField(
            key: ValueKey('workflow-transform-value-${operand.id}'),
            field: WorkflowField(
              id: 'transform-${operand.id}',
              name: operand.name,
              type: targetType,
              isRequired: false,
              nullable: true,
            ),
            binding: operand.binding,
            sources: sources,
            isWide: isWide,
            enabled: canEdit,
            onChanged: _setBinding,
          ),
          if (operandUnavailable)
            TextLocale(LocaleKeys.workflow_editor_binding_unavailable),
          if (canEdit)
            Align(
              alignment: Alignment.centerRight,
              child: AuraIconButton(
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
                tooltip: LocaleKeys.workflow_editor_remove.tr(context: context),
                semanticLabel: LocaleKeys.workflow_editor_remove.tr(
                  context: context,
                ),
                icon: Icons.close,
              ),
            ),
        ],
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
          AuraTile(
            variant: .ghost,
            size: .small,
            semanticLabel: WorkflowConnectionText.description(
              workflow,
              connection,
              context,
            ),
            child: Text(
              WorkflowConnectionText.description(workflow, connection, context),
            ),
            trailing: canEdit
                ? AuraIconButton(
                    onPressed: () =>
                        editor.commands().connections.remove(connection),
                    tooltip: LocaleKeys.workflow_editor_remove.tr(
                      context: context,
                    ),
                    semanticLabel: LocaleKeys.workflow_editor_remove.tr(
                      context: context,
                    ),
                    icon: Icons.link_off,
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
