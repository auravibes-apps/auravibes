// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/usecases/delete_agent_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/list_agents_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const AgentsScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider(workspaceId));

    return AuraScreen(
      child: switch (agentsAsync) {
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
      },
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.agents_title),
        actions: [
          AuraIconButton(
            icon: Icons.add,
            onPressed: () => _openCreate(context),
            tooltip: LocaleKeys.agents_create.tr(context: context),
          ),
        ],
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    final _ = context.push('/workspaces/$workspaceId/more/agents/new');
  }
}

class const _AgentsList({
  required final List<AgentEntity> agents,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (agents.isEmpty) {
      return Center(
        child: AuraColumn(
          children: [
            const Icon(Icons.smart_toy_outlined, size: 48),
            const AuraText(
              child: TextLocale(LocaleKeys.agents_empty_title),
              style: AuraTextStyle.heading4,
            ),
            const AuraText(child: TextLocale(LocaleKeys.agents_empty_subtitle)),
            AuraButton(
              onPressed: () => _openCreate(context),
              child: const TextLocale(LocaleKeys.agents_create),
            ),
          ],
          mainAxisSize: MainAxisSize.min,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final agent = agents[index];

        return AuraTile(
          child: AuraColumn(
            children: [
              Row(
                children: [
                  Expanded(child: Text(agent.name)),
                  if (!agent.isEnabled)
                    AuraBadge.text(
                      child: const TextLocale(LocaleKeys.agents_disabled_label),
                      variant: AuraBadgeVariant.neutral,
                    ),
                ],
              ),
              AuraText(
                child: Text(
                  LocaleKeys.agents_skill_count.plural(
                    agent.skills.length,
                    context: context,
                  ),
                ),
                style: AuraTextStyle.bodySmall,
              ),
              AuraText(
                child: Text(agent.visibility.localizedLabel(context)),
                style: AuraTextStyle.bodySmall,
              ),
            ],
            spacing: .xs,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
          onTap: () => _openAgent(context, agent.id),
          variant: AuraTileVariant.ghost,
          leading: const AuraIcon(Icons.smart_toy_outlined),
          trailing: PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(LocaleKeys.common_edit.tr(context: context)),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(LocaleKeys.common_delete.tr(context: context)),
              ),
            ],
            onSelected: (value) =>
                _handleSelection(context, ref, value, agent.id),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemCount: agents.length,
    );
  }

  void _openCreate(BuildContext context) {
    final _ = context.push('/workspaces/$workspaceId/more/agents/new');
  }

  void _openAgent(BuildContext context, String agentId) {
    final _ = context.push('/workspaces/$workspaceId/more/agents/$agentId');
  }

  void _handleSelection(
    BuildContext context,
    WidgetRef ref,
    String value,
    String agentId,
  ) {
    if (value == 'edit') {
      _openAgent(context, agentId);

      return;
    }
    unawaited(_confirmDelete(context, ref, agentId));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String agentId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AuraConfirmDialog(
        title: const TextLocale(LocaleKeys.agents_delete_title),
        message: const TextLocale(LocaleKeys.agents_delete_message),
        confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
        cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
        isDestructive: true,
      ),
    );
    if (shouldDelete != true) return;

    final _ = await ref
        .read(deleteAgentUsecaseProvider(workspaceId))
        .call(agentId);
    final _ = ref.invalidate(agentsProvider(workspaceId));
  }
}

extension _AgentVisibilityLabel on AgentVisibility {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      AgentVisibility.chatSelector =>
        LocaleKeys.agents_visibility_chat_selector.tr(context: context),
      AgentVisibility.subAgentList =>
        LocaleKeys.agents_visibility_sub_agent_list.tr(context: context),
      AgentVisibility.both => LocaleKeys.agents_visibility_both.tr(
        context: context,
      ),
    };
  }
}
