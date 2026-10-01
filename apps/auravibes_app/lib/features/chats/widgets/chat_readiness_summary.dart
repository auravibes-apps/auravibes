import 'dart:async';

import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Reports configured prerequisites without claiming a live remote check.
class const ChatReadinessSummary({
  required final String workspaceId,
  final bool isSetupHandoff = false,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(chatModelConnectionsProvider(workspaceId));
    final models = ref.watch(
      listModelsGroupedByProviderProvider(workspaceId: workspaceId),
    );
    final selectedId = ref.watch(
      newChatProvider(workspaceId).select((state) => state.modelId),
    );
    String state;
    if (connections.hasError || models.hasError) {
      state = 'attention';
    } else if (connections.isLoading || models.isLoading) {
      state = 'loading';
    } else {
      final providers = connections.requireValue;
      final available = models.requireValue.values
          .expand((items) => items)
          .where(
            (item) => providers.any(
              (connection) =>
                  connection.id == item.modelConnection.id && connection.hasKey,
            ),
          )
          .toList();
      if (providers.isEmpty) {
        state = 'no_provider';
      } else if (providers.every((item) => !item.hasKey)) {
        state = 'authorization';
      } else if (selectedId != null &&
          !available.any(
            (item) => item.workspaceModelSelection.id == selectedId,
          )) {
        state = 'unavailable';
      } else if (available.isEmpty) {
        state = 'no_models';
      } else {
        state = selectedId == null ? 'choose_model' : 'selected';
      }
    }

    return AuraColumn(
      children: [
        TextLocale('chat_readiness.$state'),
        if (state == 'no_provider')
          AuraButton(
            onPressed: () => unawaited(
              ServiceConnectionCreateRoute(
                workspaceId: workspaceId,
                returnPath: NewChatRoute(workspaceId: workspaceId).location,
                type: 'modelProvider',
              ).push<void>(context),
            ),
            child: const TextLocale('models_screens.add_provider.open_button'),
            key: const ValueKey('workspace_add_model_provider'),
          ),
        if (state == 'authorization' ||
            state == 'no_models' ||
            state == 'attention')
          AuraButton(
            onPressed: () => unawaited(
              ServiceConnectionsRoute(workspaceId: workspaceId)
                  .push<void>(context),
            ),
            child: const TextLocale('chat_readiness.review_connections'),
          ),
        if (state == 'attention' ||
            state == 'authorization' ||
            state == 'no_models')
          AuraButton(
            onPressed: () => _retry(ref),
            child: const TextLocale('route_state.retry'),
            variant: .outlined,
          ),
        if (state == 'choose_model' || state == 'unavailable')
          TextLocale(
            isSetupHandoff
                ? 'chat_readiness.select_in_chat'
                : 'chat_readiness.select_below',
          ),
      ],
      mainAxisSize: .min,
    );
  }

  void _retry(WidgetRef ref) {
    ref
      ..invalidate(chatModelConnectionsProvider(workspaceId))
      ..invalidate(
        listModelsGroupedByProviderProvider(workspaceId: workspaceId),
      );
  }
}
