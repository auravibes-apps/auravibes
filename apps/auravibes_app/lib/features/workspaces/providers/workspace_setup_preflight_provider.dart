import 'package:auravibes_app/domain/entities/api_model_entity.dart';
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
  final scope = await _readWorkspaceScope(ref, workspaceId);

  return await _buildPreflight(ref, workspaceId, scope);
}

Future<WorkspaceSetupPreflight> _buildPreflight(
  Ref ref,
  String workspaceId,
  _WorkspaceScope scope,
) async {
  final selectedModelId = ref.watch(newChatProvider(workspaceId)).modelId;
  final sources = await _readSources(ref, scope, selectedModelId);

  return const BuildWorkspaceSetupPreflightUsecase().call(
    _preflightSnapshot(scope, sources, selectedModelId),
  );
}

WorkspaceSetupPreflightSnapshot _preflightSnapshot(
  _WorkspaceScope scope,
  _SourceReads sources,
  String? selectedModelId,
) {
  final availability = _readAvailability(sources);
  final providers = _providerSnapshots(
    sources.providerRead.value,
    scope.workspaceId,
  );

  return .new(
    storageAvailable: _storageAvailable(scope, sources.cloudStorageAvailable),
    selectedModelId: selectedModelId,
    selectedModelSourceAvailable: availability.model,
    providerSourceAvailable: availability.provider,
    mcpSourceAvailable: availability.mcp,
    providers: providers,
    selectedModel: sources.modelRead.value,
    mcpConnections: sources.mcpRead.value,
  );
}

typedef _ReadResult<T> = ({bool available, T? value});

typedef _ReadAvailability = ({bool model, bool provider, bool mcp});

typedef _WorkspaceScope = ({
  String workspaceId,
  bool refreshRequested,
  _ReadResult<WorkspaceEntity?> workspaceRead,
  _ReadResult<WorkspaceSession> sessionRead,
});

extension _WorkspaceScopeValues on _WorkspaceScope {
  WorkspaceEntity? get workspace => workspaceRead.value;

  WorkspaceSession? get session => sessionRead.value;

  bool get isRemote => workspace?.type == WorkspaceType.remote;

  bool get sourceAllowed => _canReadSources(
    workspace,
    sessionRead,
    isRemote,
    refreshRequested,
  );
}

typedef _SourceReads = ({
  bool? cloudStorageAvailable,
  _ReadResult<List<ModelConnectionEntity>> providerRead,
  _ReadResult<WorkspaceSetupModelSnapshot?> modelRead,
  _ReadResult<List<WorkspaceSetupMcpSnapshot>> mcpRead,
});

Future<_WorkspaceScope> _readWorkspaceScope(Ref ref, String workspaceId) async {
  final refreshRequested = ref.watch(
    workspaceSetupPreflightRefreshProvider(workspaceId),
  );
  final workspaceRead = await _readWorkspace(ref, workspaceId);
  final workspace = workspaceRead.value;
  final sessionRead = await _readSession(ref, workspaceId, workspace);

  return (
    workspaceId: workspaceId,
    refreshRequested: refreshRequested,
    workspaceRead: workspaceRead,
    sessionRead: sessionRead,
  );
}

Future<_ReadResult<WorkspaceEntity?>> _readWorkspace(
  Ref ref,
  String workspaceId,
) => _capture<WorkspaceEntity?>(
  () => ref.watch(workspaceByIdProvider(workspaceId).future),
);

Future<_ReadResult<WorkspaceSession>> _readSession(
  Ref ref,
  String workspaceId,
  WorkspaceEntity? workspace,
) {
  if (workspace == null) {
    return Future.value(_unavailable<WorkspaceSession>());
  }

  return _capture(
    () => ref.watch(workspaceSessionForRouteProvider(workspaceId).future),
  );
}

_ReadAvailability _readAvailability(_SourceReads sources) => (
  model: sources.modelRead.available,
  provider: sources.providerRead.available,
  mcp: sources.mcpRead.available,
);

bool _canReadSources(
  WorkspaceEntity? workspace,
  _ReadResult<WorkspaceSession> sessionRead,
  bool isRemote,
  bool refreshRequested,
) =>
    workspace != null &&
    sessionRead.available &&
    (!isRemote || refreshRequested);

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

Future<bool?> _readCloudStorage(Ref ref, _WorkspaceScope scope) {
  final session = _cloudStorageSession(scope);
  if (session == null) return Future<bool?>.value();

  return _readCloudConfiguration(ref, session);
}

WorkspaceSession? _cloudStorageSession(_WorkspaceScope scope) {
  if (!scope.isRemote || !scope.refreshRequested) return null;

  return scope.session;
}

Future<bool?> _readCloudConfiguration(
  Ref ref,
  WorkspaceSession session,
) async =>
    (await _capture(() => _cloudWorkspaceConfiguration(ref, session))).value;

Future<bool> _cloudWorkspaceConfiguration(
  Ref ref,
  WorkspaceSession session,
) async {
  final _ = await ref.watch(
    cloudWorkspaceConfigurationProvider(session).future,
  );

  return true;
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
) {
  if (!scope.sourceAllowed) {
    return Future.value(_unavailable());
  }

  return _readMcpSnapshots(ref, scope.workspaceId);
}

Future<_ReadResult<List<WorkspaceSetupMcpSnapshot>>> _readMcpSnapshots(
  Ref ref,
  String workspaceId,
) async {
  final connections = (await _capture(
    () => ref.watch(serviceConnectionsProvider(workspaceId).future),
  )).value;
  if (connections == null) return _unavailable();

  return _available(_mcpSnapshots(connections, workspaceId));
}

List<WorkspaceSetupMcpSnapshot> _mcpSnapshots(
  List<ServiceConnectionListItem> connections,
  String workspaceId,
) => [
  for (final connection in connections)
    if (connection.workspaceId == workspaceId &&
        connection.kind == ServiceConnectionListItemKind.mcpServer)
      _mcpSnapshot(connection),
];

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
) {
  if (selectedModelId == null) {
    return Future.value(_noSelectedModel());
  }
  if (!scope.sourceAllowed) {
    return Future.value(_unavailable());
  }

  return _readSelectedModelSnapshot(ref, selectedModelId, scope.workspaceId);
}

_ReadResult<WorkspaceSetupModelSnapshot?> _noSelectedModel() =>
    _available<WorkspaceSetupModelSnapshot?>(null);

Future<_ReadResult<WorkspaceSetupModelSnapshot?>> _readSelectedModelSnapshot(
  Ref ref,
  String selectedModelId,
  String workspaceId,
) => _capture<WorkspaceSetupModelSnapshot?>(
  () => _selectedModelSnapshot(ref, selectedModelId, workspaceId),
);

Future<WorkspaceSetupModelSnapshot?> _selectedModelSnapshot(
  Ref ref,
  String selectedModelId,
  String workspaceId,
) async {
  final selections = await ref.watch(
    modelSelectionStoreProvider(workspaceId).future,
  );
  final model = await selections.getById(selectedModelId);

  return await _modelSnapshot(ref, model, workspaceId);
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
) =>
    model.modelConnection.workspaceId == workspaceId &&
    model.workspaceModelSelection.modelConnectionId == model.modelConnection.id;

Future<WorkspaceSetupModelSnapshot> _readModelMetadata(
  Ref ref,
  WorkspaceModelSelectionWithConnectionEntity model,
) async {
  final selection = model.workspaceModelSelection;
  final catalogModel = await _readCatalogModel(ref, model, selection);

  return _modelSnapshotFromCatalog(model, selection, catalogModel);
}

Future<ApiModelEntity?> _readCatalogModel(
  Ref ref,
  WorkspaceModelSelectionWithConnectionEntity model,
  WorkspaceModelSelectionEntity selection,
) => ref.watch(
  getModelByProviderAndModelIdProvider(
    workspaceId: model.modelConnection.workspaceId,
    providerId: _providerId(model),
    modelId: selection.modelId,
  ).future,
);

String _providerId(WorkspaceModelSelectionWithConnectionEntity model) {
  if (ModelProviderOAuthProfiles.isCodexProvider(
    model.modelConnection.modelId,
  )) {
    return 'openai';
  }

  return model.modelsProvider.id;
}

WorkspaceSetupModelSnapshot _modelSnapshotFromCatalog(
  WorkspaceModelSelectionWithConnectionEntity model,
  WorkspaceModelSelectionEntity selection,
  ApiModelEntity? catalogModel,
) {
  final capabilities = _catalogCapabilities(catalogModel);

  return WorkspaceSetupModelSnapshot(
    selectionId: selection.id,
    providerConnectionId: model.modelConnection.id,
    modelName: catalogModel?.name ?? selection.modelName,
    capabilityMetadataAvailable: capabilities.available,
    inputModalities: capabilities.inputModalities,
    outputModalities: capabilities.outputModalities,
    supportsReasoning: capabilities.supportsReasoning,
    supportsToolCalls: capabilities.supportsToolCalls,
  );
}

typedef _CatalogCapabilities = ({
  bool available,
  List<String> inputModalities,
  List<String> outputModalities,
  bool supportsReasoning,
  bool supportsToolCalls,
});

_CatalogCapabilities _catalogCapabilities(ApiModelEntity? model) => (
  available: model != null,
  inputModalities: model?.modalitiesInput ?? const [],
  outputModalities: model?.modalitiesOutput ?? const [],
  supportsReasoning: model?.supportsReasoning ?? false,
  supportsToolCalls: model?.supportsToolCalls ?? false,
);

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
