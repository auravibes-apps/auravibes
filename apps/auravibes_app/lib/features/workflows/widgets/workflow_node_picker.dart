import 'dart:convert';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/service_connections/models/connector_connection_candidate.dart';
import 'package:auravibes_app/features/service_connections/models/connector_tool_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/providers/connector_tool_catalog_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_field_schema_codec.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:auravibes_app/features/workflows/models/workflow_node_draft.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

abstract final class WorkflowNodePicker {
  static const _sheetHeightFactor = 0.82;

  static Future<WorkflowNodeDraft?> show({
    required BuildContext context,
    required String workspaceId,
    required String? currentWorkflowId,
    String? sourceNodeId,
    WorkflowConditionBranch? conditionBranch,
  }) async {
    final draft = await showModalBottomSheet<WorkflowNodeDraft>(
      context: context,
      builder: (context) => _WorkflowNodePicker(
        workspaceId: workspaceId,
        currentWorkflowId: currentWorkflowId,
      ),
      isScrollControlled: true,
    );
    return draft?.copyWith(
      sourceNodeId: sourceNodeId,
      conditionBranch: conditionBranch,
    );
  }
}

typedef _WorkflowNodePickerItems = ({
  List<ConnectorToolCatalogItem> connectorTools,
  List<WorkspaceWorkflow> workflows,
  bool isLoading,
});

typedef _WorkflowNodePickerSources = ({
  List<ConnectorToolCatalogItem> connectorTools,
  AsyncValue<List<WorkspaceWorkflow>> workflows,
  String? currentWorkflowId,
});

typedef _WorkflowNodeDraftFields = ({
  WorkflowNodeKind kind,
  String targetId,
  String label,
  List<WorkflowPort>? inputs,
  List<WorkflowPort>? outputs,
});

class const _WorkflowNodePicker({
  required final String workspaceId,
  required final String? currentWorkflowId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = WorkflowNodePickerCatalog.fromStates((
      connectorTools: ref.watch(connectorToolCatalogProvider),
      workflows: ref.watch(workflowsProvider(workspaceId)),
      currentWorkflowId: currentWorkflowId,
    ));

    return _WorkflowNodePickerContent(
      workspaceId: workspaceId,
      catalog: catalog,
    );
  }
}

abstract final class WorkflowNodePickerCatalog {
  static _WorkflowNodePickerItems fromStates(
    _WorkflowNodePickerSources sources,
  ) {
    final workflows = _values(sources.workflows, (_) => true);

    return (
      connectorTools: sources.connectorTools,
      workflows: _eligibleWorkflows(workflows, sources.currentWorkflowId),
      isLoading: _anyLoading(sources),
    );
  }

  static WorkflowNodeDraft draft(
    BuildContext context,
    _WorkflowNodeDraftFields fields,
  ) => WorkflowNodeDraft(
    kind: fields.kind,
    targetId: fields.targetId,
    canonicalName: fields.label,
    label: fields.label,
    defaultInputLabel: LocaleKeys.workflow_editor_input.tr(context: context),
    defaultOutputLabel: LocaleKeys.workflow_editor_result.tr(context: context),
    inputs: fields.inputs,
    outputs: fields.outputs,
  );

  static List<WorkflowField> copyFields(List<WorkflowField> fields) => [
    for (final field in fields) _copyField(field),
  ];

  static WorkflowField _copyField(WorkflowField field) => field.copyWith(
    id: const UuidV7().generate(),
    properties: copyFields(field.properties),
    items: field.items == null ? null : _copyField(field.items!),
  );

  static bool _anyLoading(_WorkflowNodePickerSources sources) =>
      sources.workflows.isLoading;

  static List<T> _values<T>(
    AsyncValue<List<T>> state,
    bool Function(T) include,
  ) {
    final candidates = switch (state) {
      AsyncData(:final value) => value,
      AsyncLoading(:final value?) => value,
      AsyncLoading() || AsyncError() => <T>[],
    };

    return candidates.where(include).toList();
  }

  static List<WorkspaceWorkflow> _eligibleWorkflows(
    List<WorkspaceWorkflow> workflows,
    String? currentWorkflowId,
  ) {
    if (currentWorkflowId == null) return workflows;
    final dependencyGraph = WorkflowDependencyGraph.fromWorkflows(workflows);

    return [
      for (final workflow in workflows)
        if (!dependencyGraph.dependsOn(workflow.id, currentWorkflowId))
          workflow,
    ];
  }
}

class const _WorkflowNodePickerContent({
  required final String workspaceId,
  required final _WorkflowNodePickerItems catalog,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final query = useState('');
    final filtered = _filterPickerItems(catalog, query.value);

    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context).height *
            WorkflowNodePicker._sheetHeightFactor,
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            const _WorkflowPickerHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (value) => query.value = value,
                decoration: InputDecoration(
                  hintText: LocaleKeys.workflow_editor_picker_search.tr(),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            _WorkflowPickerBody(
              workspaceId: workspaceId,
              catalog: filtered,
              noResults:
                  query.value.trim().isNotEmpty && _pickerIsEmpty(filtered),
            ),
          ],
        ),
      ),
    );
  }
}

_WorkflowNodePickerItems _filterPickerItems(
  _WorkflowNodePickerItems catalog,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return catalog;
  bool matches(Iterable<String?> values) =>
      values.any((value) => value?.toLowerCase().contains(normalized) ?? false);

  return (
    connectorTools: catalog.connectorTools
        .where(
          (item) => matches([
            item.connectorName,
            item.title,
            item.description,
            item.toolId,
          ]),
        )
        .toList(),
    workflows: catalog.workflows
        .where((item) => matches([item.name, item.description]))
        .toList(),
    isLoading: catalog.isLoading,
  );
}

bool _pickerIsEmpty(_WorkflowNodePickerItems items) =>
    items.connectorTools.isEmpty && items.workflows.isEmpty;

class const _WorkflowPickerHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
    child: Row(
      children: [
        const Expanded(child: _WorkflowPickerTitle()),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

class const _WorkflowPickerTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.workflow_editor_add_node.tr(context: context),
    style: Theme.of(context).textTheme.titleLarge,
  );
}

class const _WorkflowPickerBody({
  required final String workspaceId,
  required final _WorkflowNodePickerItems catalog,
  required final bool noResults,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (catalog.isLoading && _pickerIsEmpty(catalog)) {
      return const Expanded(child: Center(child: AuraSpinner()));
    }

    return Expanded(
      child: noResults
          ? const Center(
              child: TextLocale(LocaleKeys.workflow_editor_picker_no_results),
            )
          : _WorkflowPickerList(workspaceId: workspaceId, catalog: catalog),
    );
  }
}

class const _WorkflowPickerList({
  required final String workspaceId,
  required final _WorkflowNodePickerItems catalog,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
    children: [
      const _WorkflowBuiltinNodeSection(),
      _WorkflowConnectorToolSection(
        workspaceId: workspaceId,
        connectorTools: catalog.connectorTools,
      ),
      _WorkflowDefinitionSection(workflows: catalog.workflows),
    ],
  );
}

class const _WorkflowBuiltinNodeSection() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowLibrarySection(
    titleKey: LocaleKeys.workflow_editor_nodes,
    isEmpty: false,
    children: [
      _WorkflowLibraryTile(
        title: LocaleKeys.workflow_editor_add_output.tr(context: context),
        icon: Icons.output_outlined,
        draft: WorkflowNodePickerCatalog.draft(context, (
          kind: .outputs,
          targetId: 'outputs',
          label: LocaleKeys.workflow_editor_add_output.tr(context: context),
          inputs: const [],
          outputs: const [],
        )),
      ),
      _WorkflowLibraryTile(
        title: LocaleKeys.workflow_editor_condition.tr(context: context),
        icon: Icons.call_split_outlined,
        draft: WorkflowNodePickerCatalog.draft(context, (
          kind: .condition,
          targetId: 'condition',
          label: LocaleKeys.workflow_editor_condition.tr(context: context),
          inputs: const [],
          outputs: const [],
        )),
      ),
      _WorkflowLibraryTile(
        title: LocaleKeys.workflow_editor_transform.tr(context: context),
        icon: Icons.transform_outlined,
        draft: WorkflowNodePickerCatalog.draft(context, (
          kind: .transform,
          targetId: 'transform',
          label: LocaleKeys.workflow_editor_transform.tr(context: context),
          inputs: const [],
          outputs: const [],
        )),
      ),
    ],
  );
}

class const _WorkflowConnectorToolSection({
  required final String workspaceId,
  required final List<ConnectorToolCatalogItem> connectorTools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        const _WorkflowLibraryHeading(
          titleKey: LocaleKeys.workflow_editor_available_connector_tools,
        ),
        if (connectorTools.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: TextLocale(LocaleKeys.workflow_editor_no_connector_tools),
          )
        else
          ..._groups(),
      ],
    ),
  );

  List<Widget> _groups() {
    final grouped = <String, List<ConnectorToolCatalogItem>>{};
    for (final tool in connectorTools) {
      grouped.putIfAbsent(tool.connectorName, () => []).add(tool);
    }
    final names = grouped.keys.toList()..sort();

    return [
      for (final name in names)
        _WorkflowConnectorGroup(
          workspaceId: workspaceId,
          name: name,
          tools: grouped[name]!,
        ),
    ];
  }
}

class const _WorkflowConnectorGroup({
  required final String workspaceId,
  required final String name,
  required final List<ConnectorToolCatalogItem> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(name, style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final tool in tools)
            _WorkflowConnectorToolPickerItem(
              workspaceId: workspaceId,
              connectorTool: tool,
            ),
        ],
      ),
    ),
  );
}

class const _WorkflowConnectorToolPickerItem({
  required final String workspaceId,
  required final ConnectorToolCatalogItem connectorTool,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = connectorTool.title;
    final tools = ref.watch(workspaceToolsProvider(workspaceId));
    final sharedSchema = switch (tools) {
      AsyncData(:final value) =>
        value
            .where((item) => item.toolId == connectorTool.toolId)
            .firstOrNull
            ?.outputSchemaJson,
      AsyncLoading(:final value?) =>
        value
            .where((item) => item.toolId == connectorTool.toolId)
            .firstOrNull
            ?.outputSchemaJson,
      AsyncLoading() || AsyncError() => null,
    };
    final connectorId = connectorTool.connectorId;
    final connections = connectorTool.requiresConnection && connectorId != null
        ? ref.watch(
            workspaceConnectedConnectionsProvider(workspaceId, connectorId),
          )
        : null;

    return _WorkflowLibraryTile(
      title: label,
      icon: Icons.extension_outlined,
      draft: WorkflowNodePickerCatalog.draft(context, (
        kind: .connectorTool,
        targetId: connectorTool.toolId,
        label: label,
        inputs: WorkflowSchemaPortParser.parse(
          jsonEncode(connectorTool.inputJsonSchema),
          isInput: true,
        ),
        outputs: WorkflowSchemaPortParser.parse(sharedSchema, isInput: false),
      )),
      subtitle: _subtitle(
        context,
        tools,
        connections,
        requiresConnection: connectorTool.requiresConnection,
      ),
    );
  }

  String _subtitle(
    BuildContext context,
    AsyncValue<List<WorkspaceToolEntity>> tools,
    AsyncValue<List<ConnectorConnectionCandidate>>? connections, {
    required bool requiresConnection,
  }) {
    final description = connectorTool.description;
    final definition = connectorTool.toolDefinition;
    final operation = (definition != null && connectorToolWrites(definition))
        ? LocaleKeys.workflow_editor_write_operation.tr(context: context)
        : LocaleKeys.workflow_editor_read_operation.tr(context: context);
    final requirements = [
      operation,
      _accessStatus(context, tools),
      _connectionStatus(context, connections, requiresConnection),
    ].join(' · ');

    return description.isEmpty ? requirements : '$description\n$requirements';
  }

  String _accessStatus(
    BuildContext context,
    AsyncValue<List<WorkspaceToolEntity>> tools,
  ) => switch (tools) {
    AsyncData(:final value) => _workspaceToolAccess(context, value),
    AsyncLoading() =>
      LocaleKeys.workflow_editor_connector_tool_access_checking.tr(
        context: context,
      ),
    AsyncError() =>
      LocaleKeys.workflow_editor_connector_tool_access_unavailable.tr(
        context: context,
      ),
  };

  String _workspaceToolAccess(
    BuildContext context,
    List<WorkspaceToolEntity> tools,
  ) {
    final workspaceTool = tools
        .where((tool) => tool.toolId == connectorTool.toolId)
        .firstOrNull;
    if (workspaceTool == null || !workspaceTool.isEnabled) {
      return LocaleKeys.workflow_editor_connector_tool_access_disabled.tr(
        context: context,
      );
    }
    if (workspaceTool.permissionMode == ToolPermissionMode.alwaysDeny) {
      return LocaleKeys.workflow_editor_connector_tool_access_denied.tr(
        context: context,
      );
    }

    return LocaleKeys.workflow_editor_connector_tool_access_enabled.tr(
      context: context,
    );
  }

  String _connectionStatus(
    BuildContext context,
    AsyncValue<List<ConnectorConnectionCandidate>>? connections,
    bool requiresConnection,
  ) {
    if (connections == null) {
      if (requiresConnection) {
        return LocaleKeys.workflow_editor_connector_tool_connection_unavailable
            .tr(context: context);
      }

      return LocaleKeys.workflow_editor_connector_tool_no_connection_required
          .tr(context: context);
    }

    return switch (connections) {
      AsyncData(:final value) =>
        value.isEmpty
            ? LocaleKeys.workflow_editor_connector_tool_connection_missing.tr(
                context: context,
              )
            : LocaleKeys.workflow_editor_connector_tool_connection_available.tr(
                context: context,
              ),
      AsyncLoading() =>
        LocaleKeys.workflow_editor_connector_tool_connection_checking.tr(
          context: context,
        ),
      AsyncError() =>
        LocaleKeys.workflow_editor_connector_tool_connection_unavailable.tr(
          context: context,
        ),
    };
  }
}

class const _WorkflowDefinitionSection({
  required final List<WorkspaceWorkflow> workflows,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowLibrarySection(
    titleKey: LocaleKeys.workflow_editor_available_workflows,
    isEmpty: workflows.isEmpty,
    children: [
      for (final workflow in workflows)
        _WorkflowDefinitionPickerItem(workflow: workflow),
    ],
  );
}

class const _WorkflowDefinitionPickerItem({
  required final WorkspaceWorkflow workflow,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowLibraryTile(
    title: workflow.name,
    icon: Icons.account_tree_outlined,
    draft: WorkflowNodePickerCatalog.draft(context, (
      kind: .workflow,
      targetId: workflow.id,
      label: workflow.name,
      inputs: WorkflowNodePickerCatalog.copyFields(workflow.inputs),
      outputs: WorkflowNodePickerCatalog.copyFields(workflow.outputs),
    )),
    subtitle: workflow.description,
  );
}

class const _WorkflowLibrarySection({
  required final String titleKey,
  required final bool isEmpty,
  required final List<Widget> children,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        _WorkflowLibraryHeading(titleKey: titleKey),
        _WorkflowLibraryContents(isEmpty: isEmpty, children: children),
      ],
    ),
  );
}

class const _WorkflowLibraryHeading({required final String titleKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextLocale(titleKey),
  );
}

class const _WorkflowLibraryContents({
  required final bool isEmpty,
  required final List<Widget> children,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isEmpty
      ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: TextLocale(LocaleKeys.workflow_editor_empty_group),
        )
      : Column(crossAxisAlignment: .stretch, children: children);
}

class const _WorkflowLibraryTile({
  required final String title,
  required final IconData icon,
  required final WorkflowNodeDraft draft,
  final String? subtitle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: _WorkflowLibraryTileContents(
      title: title,
      icon: icon,
      draft: draft,
      subtitle: subtitle,
    ),
  );
}

class const _WorkflowLibraryTileContents({
  required final String title,
  required final IconData icon,
  required final WorkflowNodeDraft draft,
  final String? subtitle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
      onTap: () => Navigator.of(context).pop(draft),
    );
  }
}

abstract final class WorkflowSchemaFieldParser {
  static List<WorkflowField>? parse(
    String? rawSchema, {
    required bool isInput,
  }) => WorkflowFieldSchemaCodec.parse(rawSchema);
}

typedef WorkflowSchemaPortParser = WorkflowSchemaFieldParser;
