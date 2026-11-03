import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_setup_preflight.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/build_workspace_setup_preflight_usecase.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_setup_preflight_provider.g.dart';

@riverpod
// The refresh notifier is colocated with the provider it invalidates.
// ignore: prefer-match-file-name
class WorkspaceSetupPreflightRefresh extends _$WorkspaceSetupPreflightRefresh {
  @override
  bool build(String workspaceId) => false;

  void requestSavedConfigurationRefresh() {
    if (!state) {
      state = true;
    } else {
      ref.invalidate(workspaceSetupPreflightProvider(workspaceId));
    }
  }
}

@riverpod
Future<WorkspaceSetupPreflight> workspaceSetupPreflight(
  Ref ref,
  String workspaceId,
) async {
  final refreshRequested = ref.watch(
    workspaceSetupPreflightRefreshProvider(workspaceId),
  );
  final scope = await _readWorkspaceScope(ref, workspaceId, refreshRequested);
  final selectedModelId = ref.watch(newChatProvider(workspaceId)).modelId;
  final sources = await _readSources(ref, scope, selectedModelId);
  final providers = _providerSnapshots(
    sources.providerRead.value,
    scope.workspaceId,
  );

  return const BuildWorkspaceSetupPreflightUsecase().call(
    .new(
      storageAvailable: _storageAvailable(scope, sources.cloudStorageAvailable),
      selectedModelId: selectedModelId,
      selectedModelSourceAvailable: sources.modelRead.available,
      providerSourceAvailable: sources.providerRead.available,
      mcpSourceAvailable: sources.mcpRead.available,
      providers: providers,
      selectedModel: sources.modelRead.value,
      mcpConnections: sources.mcpRead.value,
    ),
  );
}

typedef _ReadResult<T> = ({bool available, T? value});

typedef _WorkspaceScope = ({
  String workspaceId,
  bool refreshRequested,
  _ReadResult<WorkspaceEntity?> workspaceRead,
  WorkspaceEntity? workspace,
  _ReadResult<WorkspaceSession> sessionRead,
  WorkspaceSession? session,
  bool isRemote,
  bool sourceAllowed,
});

typedef _SourceReads = ({
  bool? cloudStorageAvailable,
  _ReadResult<List<ModelConnectionEntity>> providerRead,
  _ReadResult<WorkspaceSetupModelSnapshot?> modelRead,
  _ReadResult<List<WorkspaceSetupMcpSnapshot>> mcpRead,
});

Future<_WorkspaceScope> _readWorkspaceScope(
  Ref ref,
  String workspaceId,
  bool refreshRequested,
) async {
  final workspaceRead = await _capture(
    () => ref.watch(workspaceByIdProvider(workspaceId).future),
  );
  final workspace = workspaceRead.value;
  final sessionRead = workspace == null
      ? _unavailable<WorkspaceSession>()
      : await _capture(
          () => ref.watch(workspaceSessionForRouteProvider(workspaceId).future),
        );
  final isRemote = workspace?.type == WorkspaceType.remote;

  return (
    workspaceId: workspaceId,
    refreshRequested: refreshRequested,
    workspaceRead: workspaceRead,
    workspace: workspace,
    sessionRead: sessionRead,
    session: sessionRead.value,
    isRemote: isRemote,
    sourceAllowed:
        workspace != null &&
        sessionRead.available &&
        (!isRemote || refreshRequested),
  );
}

Future<_SourceReads> _readSources(
  Ref ref,
  _WorkspaceScope scope,
  String? selectedModelId,
) async => (
  cloudStorageAvailable: await _readCloudStorage(ref, scope),
  providerRead: await _readProviderConnections(ref, scope),
  modelRead: await _readSelectedModel(ref, selectedModelId, scope),
  mcpRead: await _readMcpConnections(ref, scope),
);

Future<bool?> _readCloudStorage(Ref ref, _WorkspaceScope scope) async {
  final session = scope.session;
  if (!scope.isRemote || !scope.refreshRequested || session == null) {
    return null;
  }

  final result = await _capture(() async {
    final _ = await ref.watch(
      cloudWorkspaceConfigurationProvider(session).future,
    );

    return true;
  });

  return result.value;
}

Future<_ReadResult<List<ModelConnectionEntity>>> _readProviderConnections(
  Ref ref,
  _WorkspaceScope scope,
) async {
  if (!scope.sourceAllowed) return _unavailable();

  return await _capture(
    () => ref.watch(chatModelConnectionsProvider(scope.workspaceId).future),
  );
}

Future<_ReadResult<List<WorkspaceSetupMcpSnapshot>>> _readMcpConnections(
  Ref ref,
  _WorkspaceScope scope,
) async {
  if (!scope.sourceAllowed) return _unavailable();
  final result = await _capture(
    () => ref.watch(serviceConnectionsProvider(scope.workspaceId).future),
  );
  final connections = result.value;
  if (connections == null) return _unavailable();

  return _available([
    for (final connection in connections)
      if (connection.workspaceId == scope.workspaceId &&
          connection.kind == ServiceConnectionListItemKind.mcpServer)
        _mcpSnapshot(connection),
  ]);
}

WorkspaceSetupMcpSnapshot _mcpSnapshot(ServiceConnectionListItem connection) =>
    WorkspaceSetupMcpSnapshot(
      isEnabled: connection.isEnabled,
      lastTestStatus: connection.lastTestSummary?.status,
      connectionNeedsAttention: switch (connection.displayStatus) {
        ServiceConnectionDisplayStatus.needsReauth ||
        ServiceConnectionDisplayStatus.expired ||
        ServiceConnectionDisplayStatus.expiringSoon ||
        ServiceConnectionDisplayStatus.failed => true,
        _ => false,
      },
    );

Future<_ReadResult<WorkspaceSetupModelSnapshot?>> _readSelectedModel(
  Ref ref,
  String? selectedModelId,
  _WorkspaceScope scope,
) async {
  if (selectedModelId == null) {
    return _available<WorkspaceSetupModelSnapshot?>(null);
  }
  if (!scope.sourceAllowed) return _unavailable();

  return await _capture<WorkspaceSetupModelSnapshot?>(() async {
    final selections = await ref.watch(
      modelSelectionStoreProvider(scope.workspaceId).future,
    );
    final model = await selections.getById(selectedModelId);

    return await _modelSnapshot(ref, model, scope.workspaceId);
  });
}

Future<WorkspaceSetupModelSnapshot?> _modelSnapshot(
  Ref ref,
  WorkspaceModelSelectionWithConnectionEntity? model,
  String workspaceId,
) async {
  if (model == null || !_matchesWorkspace(model, workspaceId)) return null;

  return await _readModelMetadata(ref, model);
}

bool _matchesWorkspace(
  WorkspaceModelSelectionWithConnectionEntity model,
  String workspaceId,
) => model.modelConnection.workspaceId == workspaceId &&
    model.workspaceModelSelection.modelConnectionId == model.modelConnection.id;

Future<WorkspaceSetupModelSnapshot> _readModelMetadata(
  Ref ref,
  WorkspaceModelSelectionWithConnectionEntity model,
) async {
  final selection = model.workspaceModelSelection;
  final providerId =
      ModelProviderOAuthProfiles.isCodexProvider(model.modelConnection.modelId)
      ? 'openai'
      : model.modelsProvider.id;
  final catalogModel = await ref.watch(
    getModelByProviderAndModelIdProvider(
      workspaceId: model.modelConnection.workspaceId,
      providerId: providerId,
      modelId: selection.modelId,
    ).future,
  );

  return WorkspaceSetupModelSnapshot(
    selectionId: selection.id,
    providerConnectionId: model.modelConnection.id,
    modelName: catalogModel?.name ?? selection.modelName,
    capabilityMetadataAvailable: catalogModel != null,
    inputModalities: catalogModel?.modalitiesInput ?? const [],
    outputModalities: catalogModel?.modalitiesOutput ?? const [],
    supportsReasoning: catalogModel?.supportsReasoning ?? false,
    supportsToolCalls: catalogModel?.supportsToolCalls ?? false,
  );
}

bool? _storageAvailable(_WorkspaceScope scope, bool? cloudStorageAvailable) {
  if (!scope.workspaceRead.available) return null;
  if (scope.workspace == null || !scope.sessionRead.available) return false;
  if (!scope.isRemote) return true;

  return cloudStorageAvailable;
}

List<WorkspaceSetupProviderSnapshot>? _providerSnapshots(
  List<ModelConnectionEntity>? connections,
  String workspaceId,
) => connections
    ?.where((connection) => connection.workspaceId == workspaceId)
    .map(_providerSnapshot)
    .toList();

WorkspaceSetupProviderSnapshot _providerSnapshot(
  ModelConnectionEntity connection,
) => WorkspaceSetupProviderSnapshot(
  connectionId: connection.id,
  hasCredential: connection.hasKey,
);

Future<_ReadResult<T>> _capture<T>(Future<T> Function() read) async {
  try {
    return _available(await read());
  } on Object {
    return _unavailable();
  }
}

_ReadResult<T> _available<T>(T value) => (available: true, value: value);

_ReadResult<T> _unavailable<T>() => (available: false, value: null);
