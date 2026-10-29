import 'dart:convert';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/service_connections/models/connector_connection_candidate.dart';
import 'package:auravibes_app/features/service_connections/models/connector_tool_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/providers/connector_tool_catalog_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
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
  }) => showModalBottomSheet<WorkflowNodeDraft>(
    context: context,
    builder: (context) => _WorkflowNodePicker(
      workspaceId: workspaceId,
      currentWorkflowId: currentWorkflowId,
    ),
    isScrollControlled: true,
  );
}

typedef _WorkflowNodePickerItems = ({
  List<WorkspaceToolEntity> tools,
  List<AgentEntity> agents,
  List<ConnectorToolCatalogItem> connectorTools,
  List<WorkspaceWorkflow> workflows,
  bool isLoading,
});

typedef _WorkflowNodePickerSources = ({
  AsyncValue<List<WorkspaceToolEntity>> tools,
  AsyncValue<List<AgentEntity>> agents,
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
      tools: ref.watch(workspaceToolsProvider(workspaceId)),
      agents: ref.watch(agentsProvider(workspaceId)),
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
      tools: _enabledTools(sources.tools),
      agents: _enabledAgents(sources.agents),
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
    label: fields.label,
    defaultInputLabel: LocaleKeys.workflow_editor_input.tr(context: context),
    defaultOutputLabel: LocaleKeys.workflow_editor_result.tr(context: context),
    inputs: fields.inputs,
    outputs: fields.outputs,
  );

  static List<WorkflowPort> copyPorts(List<WorkflowPort> ports) => [
    for (final port in ports)
      WorkflowPort(
        id: const UuidV7().generate(),
        name: port.name,
        type: port.type,
        isRequired: port.isRequired,
      ),
  ];

  static List<WorkspaceToolEntity> _enabledTools(
    AsyncValue<List<WorkspaceToolEntity>> state,
  ) => _values(state, (tool) => tool.isEnabled);

  static List<AgentEntity> _enabledAgents(
    AsyncValue<List<AgentEntity>> state,
  ) => _values(state, (agent) => agent.isEnabled);

  static bool _anyLoading(_WorkflowNodePickerSources sources) =>
      sources.tools.isLoading ||
      sources.agents.isLoading ||
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
    tools: catalog.tools
        .where((item) => matches([item.toolId, item.description]))
        .toList(),
    agents: catalog.agents
        .where((item) => matches([item.name, item.description]))
        .toList(),
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
    items.tools.isEmpty &&
    items.agents.isEmpty &&
    items.connectorTools.isEmpty &&
    items.workflows.isEmpty;

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
    if (catalog.isLoading && _hasNoSimpleItems(catalog)) {
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

  bool _hasNoSimpleItems(_WorkflowNodePickerItems items) =>
      items.tools.isEmpty &&
      items.agents.isEmpty &&
      items.connectorTools.isEmpty;
}

class const _WorkflowPickerList({
  required final String workspaceId,
  required final _WorkflowNodePickerItems catalog,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
    children: [
      _WorkflowToolSection(tools: catalog.tools),
      _WorkflowAgentSection(agents: catalog.agents),
      _WorkflowConnectorToolSection(
        workspaceId: workspaceId,
        connectorTools: catalog.connectorTools,
      ),
      _WorkflowDefinitionSection(workflows: catalog.workflows),
    ],
  );
}

class const _WorkflowToolSection({
  required final List<WorkspaceToolEntity> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowLibrarySection(
    titleKey: LocaleKeys.workflow_editor_available_tools,
    isEmpty: tools.isEmpty,
    children: [for (final tool in tools) _WorkflowToolPickerItem(tool: tool)],
  );
}

class const _WorkflowToolPickerItem({required final WorkspaceToolEntity tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowLibraryTile(
    title: tool.toolId,
    icon: Icons.build_outlined,
    draft: _draft(context),
    subtitle: tool.description,
  );

  WorkflowNodeDraft _draft(BuildContext context) =>
      WorkflowNodePickerCatalog.draft(context, (
        kind: .systemTool,
        targetId: tool.id,
        label: tool.toolId,
        inputs: WorkflowSchemaPortParser.parse(tool.inputSchema, isInput: true),
        outputs: WorkflowSchemaPortParser.parse(
          tool.outputSchemaJson,
          isInput: false,
        ),
      ));
}

class const _WorkflowAgentSection({required final List<AgentEntity> agents})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowLibrarySection(
    titleKey: LocaleKeys.workflow_editor_available_agents,
    isEmpty: agents.isEmpty,
    children: [
      for (final agent in agents) _WorkflowAgentPickerItem(agent: agent),
    ],
  );
}

class const _WorkflowAgentPickerItem({required final AgentEntity agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowLibraryTile(
    title: agent.name,
    icon: Icons.smart_toy_outlined,
    draft: WorkflowNodePickerCatalog.draft(context, (
      kind: .agent,
      targetId: agent.id,
      label: agent.name,
      inputs: null,
      outputs: null,
    )),
    subtitle: agent.description,
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
        outputs: null,
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
      inputs: WorkflowNodePickerCatalog.copyPorts(workflow.inputs),
      outputs: WorkflowNodePickerCatalog.copyPorts(workflow.outputs),
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

abstract final class WorkflowSchemaPortParser {
  static List<WorkflowPort>? parse(String? rawSchema, {required bool isInput}) {
    if (rawSchema == null || rawSchema.isEmpty) return null;
    try {
      return _parseDecoded(jsonDecode(rawSchema), isInput);
    } on Object {
      return null;
    }
  }

  static List<WorkflowPort>? _parseDecoded(Object? decoded, bool isInput) {
    final properties = _properties(decoded);
    if (properties == null) return null;
    final requiredNames = _requiredNames(decoded);

    return [
      for (final entry in properties.entries)
        if (entry.key case final String name)
          _port(name, entry.value, requiredNames, isInput),
    ];
  }

  static Map<Object?, Object?>? _properties(Object? decoded) {
    if (decoded is! Map<Object?, Object?>) return null;
    final properties = decoded['properties'];

    return properties is Map<Object?, Object?> ? properties : null;
  }

  static Set<String> _requiredNames(Object? decoded) {
    if (decoded is! Map<Object?, Object?>) {
      return const <String>{};
    }
    final requiredValues = decoded['required'];
    if (requiredValues is! List<Object?>) return const <String>{};

    return requiredValues.whereType<String>().toSet();
  }

  static WorkflowPort _port(
    String name,
    Object? property,
    Set<String> requiredNames,
    bool isInput,
  ) {
    final schemaType = property is Map<Object?, Object?>
        ? property['type']
        : null;

    return WorkflowPort(
      id: const UuidV7().generate(),
      name: name,
      type: _valueType(schemaType),
      isRequired: isInput && requiredNames.contains(name),
    );
  }

  static WorkflowValueType _valueType(Object? value) => switch (value) {
    'string' => .string,
    'integer' => .integer,
    'number' => .number,
    'boolean' => .boolean,
    'object' => .object,
    'array' => .array,
    _ => .any,
  };
}
