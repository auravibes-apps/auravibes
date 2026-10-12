import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkflowsScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflows = ref.watch(workflowsProvider(workspaceId));

    return AuraScreen(
      child: _WorkflowsList(workspaceId: workspaceId, workflows: workflows),
      appBar: AuraAppBarWithDrawer(
        title: const TextLocale(LocaleKeys.workflows_screen_title),
        actions: [
          AuraIconButton(
            icon: Icons.add,
            onPressed: () => _openWorkflow(context, workspaceId),
            tooltip: LocaleKeys.workflows_screen_create.tr(context: context),
          ),
        ],
      ),
    );
  }
}

class const _WorkflowsList({
  required final String workspaceId,
  required final AsyncValue<List<WorkflowDefinition>> workflows,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (workflows) {
    AsyncData(:final value) when value.isEmpty => _WorkflowEmptyState(
      onCreate: () => _openWorkflow(context, workspaceId),
    ),
    AsyncData(:final value) => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) =>
          _WorkflowListTile(workflow: value[index], workspaceId: workspaceId),
      itemCount: value.length,
    ),
    AsyncLoading(:final value?) => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) =>
          _WorkflowListTile(workflow: value[index], workspaceId: workspaceId),
      itemCount: value.length,
    ),
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncError() => const Center(
      child: AuraText(
        child: TextLocale(LocaleKeys.workflows_screen_load_error),
      ),
    ),
  };
}

class const _WorkflowEmptyState({required final VoidCallback onCreate})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: .min,
        children: [
          const Icon(Icons.account_tree_outlined, size: 52),
          const SizedBox(height: 16),
          const TextLocale(LocaleKeys.workflows_screen_empty_title),
          const SizedBox(height: 8),
          const TextLocale(LocaleKeys.workflows_screen_empty_subtitle),
          const SizedBox(height: 16),
          AuraButton(
            onPressed: onCreate,
            child: const TextLocale(LocaleKeys.workflows_screen_create),
          ),
        ],
      ),
    ),
  );
}

class const _WorkflowListTile({
  required final WorkflowDefinition workflow,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.account_tree_outlined),
      title: Text(workflow.name),
      subtitle: Text(
        workflow.description.isNotEmpty
            ? workflow.description
            : LocaleKeys.workflows_screen_summary.tr(
                context: context,
                namedArgs: {
                  'steps': '${workflow.nodes.length}',
                  'inputs': '${workflow.inputs.length}',
                  'outputs': '${workflow.outputs.length}',
                },
              ),
        overflow: .ellipsis,
        maxLines: 2,
      ),
      onTap: () => WorkflowEditRoute(
        workspaceId: workspaceId,
        workflowId: workflow.id,
      ).go(context),
    ),
  );
}

void _openWorkflow(BuildContext context, String workspaceId) {
  WorkflowCreateRoute(workspaceId: workspaceId).go(context);
}
