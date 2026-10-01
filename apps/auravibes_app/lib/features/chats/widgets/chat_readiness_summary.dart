import 'dart:async';

import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Reports configured prerequisites without claiming a live remote check.
class ChatReadinessSummary extends ConsumerWidget {
  const new({
    required this._workspaceId,
    this._isSetupHandoff = false,
    super.key,
  });

  final String _workspaceId;
  final bool _isSetupHandoff;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _ChatReadinessContent(
    workspaceId: _workspaceId,
    state: _watchChatReadinessState(ref, _workspaceId),
    isSetupHandoff: _isSetupHandoff,
  );
}

_ChatReadinessState _watchChatReadinessState(
  WidgetRef ref,
  String workspaceId,
) => _readinessState(
  ref.watch(chatModelConnectionsProvider(workspaceId)),
  ref.watch(listModelsGroupedByProviderProvider(workspaceId: workspaceId)),
  ref.watch(newChatProvider(workspaceId).select((state) => state.modelId)),
);

class const _ChatReadinessContent({
  required final String workspaceId,
  required final _ChatReadinessState state,
  required final bool isSetupHandoff,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      TextLocale('chat_readiness.${state.localeKey()}'),
      if (state == _ChatReadinessState.noProvider)
        _ChatAddProviderButton(workspaceId: workspaceId),
      _ChatReadinessActions(workspaceId: workspaceId, state: state),
      if (_needsSelectionHint(state))
        TextLocale(
          isSetupHandoff
              ? 'chat_readiness.select_in_chat'
              : 'chat_readiness.select_below',
        ),
    ],
    mainAxisSize: .min,
  );
}

class const _ChatReadinessActions({
  required final String workspaceId,
  required final _ChatReadinessState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final showConnections = _showsConnectionActions(state);
    final showRetry = _showsRetry(state);
    if (!showConnections && !showRetry) return const SizedBox.shrink();

    return Column(
      mainAxisSize: .min,
      children: [
        if (showConnections)
          _ChatReviewConnectionsButton(workspaceId: workspaceId),
        if (showRetry) _ChatReadinessRetryButton(workspaceId: workspaceId),
      ],
    );
  }
}

enum _ChatReadinessState {
  attention,
  loading,
  noProvider,
  authorization,
  unavailable,
  noModels,
  chooseModel,
  selected,
}

extension on _ChatReadinessState {
  String localeKey() => switch (this) {
    .noProvider => 'no_provider',
    .chooseModel => 'choose_model',
    .noModels => 'no_models',
    _ => name,
  };
}

typedef _ChatReadinessConnections = AsyncValue<List<ModelConnectionEntity>>;
typedef _ChatReadinessModels =
    AsyncValue<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>;

_ChatReadinessState _readinessState(
  _ChatReadinessConnections connections,
  _ChatReadinessModels models,
  String? selectedId,
) {
  if (connections.hasError || models.hasError) {
    return _ChatReadinessState.attention;
  }
  if (connections.isLoading || models.isLoading) {
    return _ChatReadinessState.loading;
  }

  return _readyReadinessState(
    connections.requireValue,
    models.requireValue,
    selectedId,
  );
}

_ChatReadinessState _readyReadinessState(
  List<ModelConnectionEntity> providers,
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> models,
  String? selectedId,
) {
  final available = _availableModels(providers, models);
  if (providers.isEmpty) return _ChatReadinessState.noProvider;
  if (providers.every((item) => !item.hasKey)) {
    return _ChatReadinessState.authorization;
  }

  return _selectedModelReadinessState(available, selectedId);
}

_ChatReadinessState _selectedModelReadinessState(
  List<WorkspaceModelSelectionWithConnectionEntity> available,
  String? selectedId,
) {
  if (selectedId != null && !_containsSelection(available, selectedId)) {
    return _ChatReadinessState.unavailable;
  }
  if (available.isEmpty) return _ChatReadinessState.noModels;

  return selectedId == null
      ? _ChatReadinessState.chooseModel
      : _ChatReadinessState.selected;
}

List<WorkspaceModelSelectionWithConnectionEntity> _availableModels(
  List<ModelConnectionEntity> providers,
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> models,
) => models.values
    .expand((items) => items)
    .where((item) => _hasAuthorizedProvider(providers, item))
    .toList();

bool _hasAuthorizedProvider(
  List<ModelConnectionEntity> providers,
  WorkspaceModelSelectionWithConnectionEntity item,
) => providers.any(
  (connection) => connection.id == item.modelConnection.id && connection.hasKey,
);

bool _containsSelection(
  List<WorkspaceModelSelectionWithConnectionEntity> models,
  String selectedId,
) => models.any((item) => item.workspaceModelSelection.id == selectedId);

class const _ChatAddProviderButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(
      ServiceConnectionCreateRoute(
        workspaceId: workspaceId,
        returnPath: NewChatRoute(workspaceId: workspaceId).location,
        type: 'modelProvider',
      ).push<void>(context),
    ),
    child: const TextLocale('models_screens.add_provider.open_button'),
    key: const ValueKey('workspace_add_model_provider'),
  );
}

class const _ChatReviewConnectionsButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(
      ServiceConnectionsRoute(workspaceId: workspaceId).push<void>(context),
    ),
    child: const TextLocale('chat_readiness.review_connections'),
  );
}

bool _showsConnectionActions(_ChatReadinessState state) =>
    state == _ChatReadinessState.authorization ||
    state == _ChatReadinessState.noModels ||
    state == _ChatReadinessState.attention;

bool _showsRetry(_ChatReadinessState state) =>
    state == _ChatReadinessState.attention ||
    state == _ChatReadinessState.authorization ||
    state == _ChatReadinessState.noModels;

void _retryReadiness(WidgetRef ref, String workspaceId) {
  ref
    ..invalidate(chatModelConnectionsProvider(workspaceId))
    ..invalidate(listModelsGroupedByProviderProvider(workspaceId: workspaceId));
}

class const _ChatReadinessRetryButton({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraButton(
    onPressed: () => _retryReadiness(ref, workspaceId),
    child: const TextLocale('route_state.retry'),
    variant: .outlined,
  );
}

bool _needsSelectionHint(_ChatReadinessState state) =>
    state == _ChatReadinessState.chooseModel ||
    state == _ChatReadinessState.unavailable;
