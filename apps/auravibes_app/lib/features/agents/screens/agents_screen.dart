// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/usecases/delete_agent_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef _AgentSelection = ({
  BuildContext context,
  WidgetRef ref,
  String value,
  String agentId,
});

class const AgentsScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider(workspaceId));

    return AuraScreen(
      child: _AgentsContent(agentsAsync: agentsAsync, workspaceId: workspaceId),
      appBar: _AgentsAppBar(onCreate: () => _openCreate(context)),
    );
  }

  void _openCreate(BuildContext context) {
    final _ = context.push('/workspaces/$workspaceId/more/agents/new');
  }
}

class _AgentsContent extends StatelessWidget {
  new({required this.agentsAsync, required this.workspaceId})
    : _child = switch (agentsAsync) {
        AsyncData(:final value) => _AgentsList(
          agents: value,
          workspaceId: workspaceId,
        ),
        AsyncLoading(:final value?) => _AgentsList(
          agents: value,
          workspaceId: workspaceId,
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => const Center(
          child: AuraText(child: TextLocale(LocaleKeys.agents_load_error)),
        ),
      };

  final AsyncValue<List<AgentEntity>> agentsAsync;
  final String workspaceId;
  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class const _AgentsAppBar({required final VoidCallback onCreate})
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: const TextLocale(LocaleKeys.agents_title),
      actions: [
        AuraIconButton(
          icon: Icons.add,
          onPressed: onCreate,
          tooltip: LocaleKeys.agents_create.tr(context: context),
        ),
      ],
      leading: const _AgentsBackButton(),
    );
  }
}

class const _AgentsBackButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class const _AgentsList({
  required final List<AgentEntity> agents,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (agents.isEmpty) {
      return _AgentsEmptyState(onCreate: () => _openCreate(context));
    }

    return _AgentsListView(
      agents: agents,
      onTap: _openAgentCallback(context),
      onSelection: _selectionCallback(context, ref),
    );
  }

  ValueChanged<AgentEntity> _openAgentCallback(BuildContext context) {
    return (agent) => _openAgent(context, agent.id);
  }

  void Function(String value, AgentEntity agent) _selectionCallback(
    BuildContext context,
    WidgetRef ref,
  ) {
    return (value, agent) => _handleSelection((
      context: context,
      ref: ref,
      value: value,
      agentId: agent.id,
    ));
  }

  void _openCreate(BuildContext context) {
    final _ = context.push('/workspaces/$workspaceId/more/agents/new');
  }

  void _openAgent(BuildContext context, String agentId) {
    final _ = context.push('/workspaces/$workspaceId/more/agents/$agentId');
  }

  void _handleSelection(_AgentSelection selection) {
    if (selection.value == 'edit') {
      _openAgent(selection.context, selection.agentId);

      return;
    }
    unawaited(
      _confirmDelete(selection.context, selection.ref, selection.agentId),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String agentId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAgentDialog(),
    );
    if (shouldDelete != true) return;

    await _deleteAgent(ref, agentId);
  }

  Future<void> _deleteAgent(WidgetRef ref, String agentId) async {
    final _ = await ref
        .read(deleteAgentUsecaseProvider(workspaceId))
        .call(agentId);
    final _ = ref.invalidate(agentsProvider(workspaceId));
  }
}

class const _AgentsListView({
  required final List<AgentEntity> agents,
  required final ValueChanged<AgentEntity> onTap,
  required final void Function(String value, AgentEntity agent) onSelection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemBuilder: _itemBuilder,
      separatorBuilder: _separatorBuilder,
      itemCount: agents.length,
    );
  }

  Widget _itemBuilder(BuildContext _, int index) {
    return _AgentListItemBuilder(
      agent: agents[index],
      onTap: onTap,
      onSelection: onSelection,
    );
  }

  Widget _separatorBuilder(BuildContext _, _) {
    return const SizedBox(height: 8);
  }
}

class _AgentsEmptyState extends StatelessWidget {
  const new({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext _) =>
      Center(child: _AgentsEmptyContent(onCreate: onCreate));
}

class _AgentsEmptyContent extends StatelessWidget {
  new({required this.onCreate})
    : _child = AuraColumn(
        children: [
          const Icon(Icons.smart_toy_outlined, size: 48),
          const AuraText(
            child: TextLocale(LocaleKeys.agents_empty_title),
            style: .heading4,
          ),
          const AuraText(child: TextLocale(LocaleKeys.agents_empty_subtitle)),
          AuraButton(
            onPressed: onCreate,
            child: const TextLocale(LocaleKeys.agents_create),
          ),
        ],
        mainAxisSize: .min,
      );

  final VoidCallback onCreate;
  final Widget _child;

  @override
  Widget build(BuildContext _) => _child;
}

class const _AgentListItem({
  required final AgentEntity agent,
  required final VoidCallback onTap,
  required final ValueChanged<String> onSelection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: _AgentListItemDetails(agent: agent),
      onTap: onTap,
      variant: .ghost,
      leading: const AuraIcon(Icons.smart_toy_outlined),
      trailing: _AgentMenu(onSelected: onSelection),
    );
  }
}

class const _AgentListItemDetails({required final AgentEntity agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _AgentNameRow(agent: agent),
        _AgentSkillCount(agent: agent),
        _AgentVisibility(agent: agent),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _AgentNameRow({required final AgentEntity agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Row(
      children: [
        Expanded(child: Text(agent.name)),
        if (!agent.isEnabled)
          AuraBadge.text(
            child: const TextLocale(LocaleKeys.agents_disabled_label),
            variant: .neutral,
          ),
      ],
    );
  }
}

class const _AgentSkillCount({required final AgentEntity agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: Text(
        LocaleKeys.agents_skill_count.plural(
          agent.skills.length,
          context: context,
        ),
      ),
      style: .bodySmall,
    );
  }
}

class const _AgentVisibility({required final AgentEntity agent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: Text(agent.visibility.localizedLabel(context)),
      style: .bodySmall,
    );
  }
}

class const _AgentMenu({required final ValueChanged<String> onSelected})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return PopupMenuButton<String>(itemBuilder: _items, onSelected: onSelected);
  }

  List<PopupMenuEntry<String>> _items(BuildContext _) => const [
    PopupMenuItem(value: 'edit', child: TextLocale(LocaleKeys.common_edit)),
    PopupMenuItem(value: 'delete', child: TextLocale(LocaleKeys.common_delete)),
  ];
}

class const _AgentListItemBuilder({
  required final AgentEntity agent,
  required final ValueChanged<AgentEntity> onTap,
  required final void Function(String value, AgentEntity agent) onSelection,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return _AgentListItem(
      agent: agent,
      onTap: () => onTap(agent),
      onSelection: (value) => onSelection(value, agent),
    );
  }
}

class const _DeleteAgentDialog() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraConfirmDialog(
      title: const TextLocale(LocaleKeys.agents_delete_title),
      message: const TextLocale(LocaleKeys.agents_delete_message),
      confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
      cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
      isDestructive: true,
    );
  }
}

extension _AgentVisibilityLabel on AgentVisibility {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      .chatSelector => LocaleKeys.agents_visibility_chat_selector.tr(
        context: context,
      ),
      .subAgentList => LocaleKeys.agents_visibility_sub_agent_list.tr(
        context: context,
      ),
      .both => LocaleKeys.agents_visibility_both.tr(context: context),
    };
  }
}
