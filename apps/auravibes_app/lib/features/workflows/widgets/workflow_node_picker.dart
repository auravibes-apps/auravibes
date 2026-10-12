import 'dart:convert';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

typedef WorkflowNodeDraft = ({
  WorkflowNodeKind kind,
  String targetId,
  String? targetSource,
  String label,
  List<WorkflowPort>? inputs,
  List<WorkflowPort>? outputs,
});

Future<WorkflowNodeDraft?> showWorkflowNodePicker({
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

class const _WorkflowNodePicker({
  required final String workspaceId,
  required final String? currentWorkflowId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsState = ref.watch(workspaceToolsProvider(workspaceId));
    final agentsState = ref.watch(agentsProvider(workspaceId));
    final skillsState = ref.watch(workspaceSkillsProvider(workspaceId));
    final workflowsState = ref.watch(workflowsProvider(workspaceId));
    final tools = switch (toolsState) {
      AsyncData(:final value) => value.where((tool) => tool.isEnabled).toList(),
      AsyncLoading(:final value?) =>
        value.where((tool) => tool.isEnabled).toList(),
      AsyncLoading() || AsyncError() => const <WorkspaceToolEntity>[],
    };
    final agents = switch (agentsState) {
      AsyncData(:final value) =>
        value.where((agent) => agent.isEnabled).toList(),
      AsyncLoading(:final value?) =>
        value.where((agent) => agent.isEnabled).toList(),
      AsyncLoading() || AsyncError() => const <AgentEntity>[],
    };
    final skills = switch (skillsState) {
      AsyncData(:final value) =>
        value.where((skill) => skill.isEnabled).toList(),
      AsyncLoading(:final value?) =>
        value.where((skill) => skill.isEnabled).toList(),
      AsyncLoading() || AsyncError() => const <WorkspaceSkill>[],
    };
    final workflows = switch (workflowsState) {
      AsyncData(:final value) =>
        value
            .where(
              (workflow) =>
                  !_workflowDependsOn(workflow, currentWorkflowId, value),
            )
            .toList(),
      AsyncLoading(:final value?) =>
        value
            .where(
              (workflow) =>
                  !_workflowDependsOn(workflow, currentWorkflowId, value),
            )
            .toList(),
      AsyncLoading() || AsyncError() => const <WorkflowDefinition>[],
    };
    final isLoading =
        toolsState.isLoading ||
        agentsState.isLoading ||
        skillsState.isLoading ||
        workflowsState.isLoading;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      LocaleKeys.workflow_editor_add_node.tr(context: context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (isLoading && tools.isEmpty && agents.isEmpty && skills.isEmpty)
              const Expanded(child: Center(child: AuraSpinner()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    _WorkflowLibrarySection(
                      titleKey: LocaleKeys.workflow_editor_available_tools,
                      isEmpty: tools.isEmpty,
                      children: [
                        for (final tool in tools)
                          _WorkflowLibraryTile(
                            title: tool.toolId,
                            icon: Icons.build_outlined,
                            onTap: () => _select(context, (
                              kind: .systemTool,
                              targetId: tool.id,
                              targetSource: null,
                              label: tool.toolId,
                              inputs: _schemaPorts(
                                tool.inputSchema,
                                isInput: true,
                              ),
                              outputs: _schemaPorts(
                                tool.outputSchemaJson,
                                isInput: false,
                              ),
                            )),
                            subtitle: tool.description,
                          ),
                      ],
                    ),
                    _WorkflowLibrarySection(
                      titleKey: LocaleKeys.workflow_editor_available_agents,
                      isEmpty: agents.isEmpty,
                      children: [
                        for (final agent in agents)
                          _WorkflowLibraryTile(
                            title: agent.name,
                            icon: Icons.smart_toy_outlined,
                            onTap: () => _select(context, (
                              kind: .agent,
                              targetId: agent.id,
                              targetSource: null,
                              label: agent.name,
                              inputs: null,
                              outputs: null,
                            )),
                            subtitle: agent.description,
                          ),
                      ],
                    ),
                    _WorkflowLibrarySection(
                      titleKey: LocaleKeys.workflow_editor_available_skills,
                      isEmpty: skills.isEmpty,
                      children: [
                        for (final skill in skills)
                          _WorkflowLibraryTile(
                            title: skill.title,
                            icon: Icons.psychology_alt_outlined,
                            onTap: () => _select(context, (
                              kind: .skill,
                              targetId: skill.id,
                              targetSource: skill.source.name,
                              label: skill.title,
                              inputs: null,
                              outputs: null,
                            )),
                            subtitle: skill.description,
                          ),
                      ],
                    ),
                    _WorkflowLibrarySection(
                      titleKey: LocaleKeys.workflow_editor_available_workflows,
                      isEmpty: workflows.isEmpty,
                      children: [
                        for (final workflow in workflows)
                          _WorkflowLibraryTile(
                            title: workflow.name,
                            icon: Icons.account_tree_outlined,
                            onTap: () => _select(context, (
                              kind: .workflow,
                              targetId: workflow.id,
                              targetSource: null,
                              label: workflow.name,
                              inputs: _copyPorts(workflow.inputs),
                              outputs: _copyPorts(workflow.outputs),
                            )),
                            subtitle: workflow.description,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, WorkflowNodeDraft draft) =>
      Navigator.of(context).pop(draft);
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextLocale(titleKey),
        ),
        if (isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: TextLocale(LocaleKeys.workflow_editor_empty_group),
          )
        else
          ...children,
      ],
    ),
  );
}

class const _WorkflowLibraryTile({
  required final String title,
  required final IconData icon,
  required final VoidCallback onTap,
  final String? subtitle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}

List<WorkflowPort>? _schemaPorts(String? rawSchema, {required bool isInput}) {
  if (rawSchema == null || rawSchema.isEmpty) return null;
  try {
    final schema = jsonDecode(rawSchema);
    if (schema is! Map) return null;
    final properties = schema['properties'];
    if (properties is! Map) return null;
    final requiredNames = schema['required'] is List
        ? (schema['required'] as List).whereType<String>().toSet()
        : const <String>{};
    final ports = <WorkflowPort>[];
    for (final entry in properties.entries) {
      final name = entry.key;
      if (name is! String) continue;
      final property = entry.value;
      final type = property is Map
          ? _schemaValueType(property['type'])
          : WorkflowValueType.any;
      ports.add(
        WorkflowPort(
          id: const UuidV7().generate(),
          name: name,
          type: type,
          isRequired: isInput && requiredNames.contains(name),
        ),
      );
    }

    return ports;
  } on Object {
    return null;
  }
}

WorkflowValueType _schemaValueType(Object? value) => switch (value) {
  'string' => .string,
  'integer' => .integer,
  'number' => .number,
  'boolean' => .boolean,
  'object' => .object,
  'array' => .array,
  _ => .any,
};

List<WorkflowPort> _copyPorts(List<WorkflowPort> ports) => [
  for (final port in ports)
    WorkflowPort(
      id: const UuidV7().generate(),
      name: port.name,
      type: port.type,
      isRequired: port.isRequired,
    ),
];

bool _workflowDependsOn(
  WorkflowDefinition workflow,
  String? targetWorkflowId,
  List<WorkflowDefinition> workflows,
) {
  if (workflow.id == targetWorkflowId) return true;
  if (targetWorkflowId == null) return false;
  final visited = <String>{};

  bool visit(WorkflowDefinition candidate) {
    if (!visited.add(candidate.id)) return false;
    for (final node in candidate.nodes) {
      if (node.kind != WorkflowNodeKind.workflow) continue;
      if (node.targetId == targetWorkflowId) return true;
      final nested = workflows.where((item) => item.id == node.targetId);
      final nestedWorkflow = nested.firstOrNull;
      if (nestedWorkflow != null && visit(nestedWorkflow)) return true;
    }

    return false;
  }

  return visit(workflow);
}
