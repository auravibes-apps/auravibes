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
  Widget build(BuildContext context, WidgetRef ref) => AuraScreen(
    child: _WorkflowsList(
      workspaceId: workspaceId,
      workflows: ref.watch(workflowsProvider(workspaceId)),
    ),
    appBar: _WorkflowsAppBar(workspaceId: workspaceId),
  );
}

class const _WorkflowsAppBar({required final String workspaceId})
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AuraAppBarWithDrawer(
    title: const TextLocale(LocaleKeys.workflows_screen_title),
    actions: [
      AuraIconButton(
        icon: Icons.add,
        onPressed: () => _openWorkflow(context, workspaceId),
        tooltip: LocaleKeys.workflows_screen_create.tr(context: context),
      ),
    ],
  );
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
    AsyncData(:final value) => _WorkflowListItems(
      workflows: value,
      workspaceId: workspaceId,
    ),
    AsyncLoading(:final value?) => _WorkflowListItems(
      workflows: value,
      workspaceId: workspaceId,
    ),
    AsyncLoading() => const _WorkflowListLoading(),
    AsyncError() => const _WorkflowListFailure(),
  };
}

class const _WorkflowListItems({
  required final List<WorkflowDefinition> workflows,
  required final String workspaceId,
}) extends StatelessWidget {
  static const _listPadding = 16.0;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(_listPadding),
    itemBuilder: (context, index) =>
        _WorkflowListTile(workflow: workflows[index], workspaceId: workspaceId),
    itemCount: workflows.length,
  );
}

class const _WorkflowListLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(child: AuraSpinner());
}

class const _WorkflowListFailure() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: AuraText(child: TextLocale(LocaleKeys.workflows_screen_load_error)),
  );
}

class const _WorkflowEmptyState({required final VoidCallback onCreate})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Center(child: _WorkflowEmptyContents(onCreate: onCreate));
}

class const _WorkflowEmptyContents({required final VoidCallback onCreate})
    extends StatelessWidget {
  static const _contentPadding = 24.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(_contentPadding),
    child: Column(
      mainAxisSize: .min,
      children: [
        const _WorkflowEmptyIcon(),
        const _WorkflowEmptyMessage(),
        _WorkflowCreateButton(onPressed: onCreate),
      ],
    ),
  );
}

class const _WorkflowEmptyIcon() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Icon(Icons.account_tree_outlined, size: 52),
  );
}

class const _WorkflowEmptyMessage() extends StatelessWidget {
  static const _titleBottomSpacing = 8.0;
  static const _subtitleBottomSpacing = 16.0;

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      TextLocale(LocaleKeys.workflows_screen_empty_title),
      SizedBox(height: _titleBottomSpacing),
      TextLocale(LocaleKeys.workflows_screen_empty_subtitle),
      SizedBox(height: _subtitleBottomSpacing),
    ],
  );
}

class const _WorkflowCreateButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.workflows_screen_create),
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
      subtitle: _WorkflowSummary(workflow: workflow),
      onTap: () => WorkflowEditRoute(
        workspaceId: workspaceId,
        workflowId: workflow.id,
      ).go(context),
    ),
  );
}

class const _WorkflowSummary({required final WorkflowDefinition workflow})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    WorkflowSummaryText.forWorkflow(workflow, context),
    overflow: .ellipsis,
    maxLines: 2,
  );
}

abstract final class WorkflowSummaryText {
  static String forWorkflow(
    WorkflowDefinition workflow,
    BuildContext context,
  ) => workflow.description.isNotEmpty
      ? workflow.description
      : LocaleKeys.workflows_screen_summary.tr(
          context: context,
          namedArgs: {
            'steps': '${workflow.nodes.length}',
            'inputs': '${workflow.inputs.length}',
            'outputs': '${workflow.outputs.length}',
          },
        );
}

void _openWorkflow(BuildContext context, String workspaceId) {
  WorkflowCreateRoute(workspaceId: workspaceId).go(context);
}
