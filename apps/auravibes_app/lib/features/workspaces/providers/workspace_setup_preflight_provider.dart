import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
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
  final workspaceRead = await _capture(
    () => ref.watch(workspaceByIdProvider(workspaceId).future),
  );
  final workspace = workspaceRead.value;
  final workspaceSessionRead = workspace == null
      ? const _ReadResult<WorkspaceSession>.unavailable()
      : await _capture(
          () => ref.watch(workspaceSessionForRouteProvider(workspaceId).future),
        );

  final workspaceIsRemote = workspace?.type == WorkspaceType.remote;
  final remoteRefreshReady = !workspaceIsRemote || refreshRequested;
  final session = workspaceSessionRead.value;
  final cloudStorageRead = workspaceIsRemote && refreshRequested && session != null
      ? await _capture(() async {
          await ref.watch(cloudWorkspaceConfigurationProvider(session).future);

          return true;
        })
      : const _ReadResult<bool>.unavailable();
  final sourceAllowed = workspace != null &&
      workspaceSessionRead.available &&
      remoteRefreshReady;
  final providerRead = sourceAllowed
      ? await _capture(
          () => ref.watch(chatModelConnectionsProvider(workspaceId).future),
        )
      : const _ReadResult<List<ModelConnectionEntity>>.unavailable();
  final selectedModelId = ref.watch(
    newChatProvider(workspaceId).select((state) => state.modelId),
  );
  final modelRead = selectedModelId == null
      ? const _ReadResult<WorkspaceSetupModelSnapshot?>.available(null)
      : sourceAllowed
      ? await _capture(
          () => ref
              .watch(
                workspaceModelSelectionByIdProvider(
                  workspaceId,
                  selectedModelId,
                ).future,
              )
              .then((model) => _modelSnapshot(ref, model, workspaceId)),
        )
      : const _ReadResult<WorkspaceSetupModelSnapshot?>.unavailable();
  final mcpRead = sourceAllowed
      ? await _capture(() async {
          final connections = await ref.watch(
            serviceConnectionsProvider(workspaceId).future,
          );

          return [
            for (final connection in connections)
              if (connection.workspaceId == workspaceId &&
                  connection.kind == ServiceConnectionListItemKind.mcpServer)
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
              ),
          ];
        })
      : const _ReadResult<List<WorkspaceSetupMcpSnapshot>>.unavailable();

  final storageAvailable = _storageAvailable(
    workspaceRead: workspaceRead,
    workspace: workspace,
    sessionAvailable: workspaceSessionRead.available,
    isRemote: workspaceIsRemote,
    cloudStorageAvailable: cloudStorageRead.value,
  );
  final providerSnapshots = providerRead.value
      ?.where((connection) => connection.workspaceId == workspaceId)
      .map(_providerSnapshot)
      .toList();

  return const BuildWorkspaceSetupPreflightUsecase().call(
    WorkspaceSetupPreflightSnapshot(
      storageAvailable: storageAvailable,
      selectedModelId: selectedModelId,
      selectedModelSourceAvailable: modelRead.available,
      providerSourceAvailable: providerRead.available,
      mcpSourceAvailable: mcpRead.available,
      providers: providerSnapshots,
      selectedModel: modelRead.value,
      mcpConnections: mcpRead.value,
    ),
  );
}

bool? _storageAvailable({
  required _ReadResult<WorkspaceEntity?> workspaceRead,
  required WorkspaceEntity? workspace,
  required bool sessionAvailable,
  required bool isRemote,
  required bool? cloudStorageAvailable,
}) {
  if (!workspaceRead.available) return null;
  if (workspace == null || !sessionAvailable) return false;
  if (!isRemote) return true;

  return cloudStorageAvailable;
}

WorkspaceSetupProviderSnapshot _providerSnapshot(
  ModelConnectionEntity connection,
) => WorkspaceSetupProviderSnapshot(
  connectionId: connection.id,
  hasCredential: connection.hasKey,
);

Future<WorkspaceSetupModelSnapshot?> _modelSnapshot(
  Ref ref,
  WorkspaceModelSelectionWithConnectionEntity? model,
  String workspaceId,
) async {
  if (model == null ||
      model.modelConnection.workspaceId != workspaceId ||
      model.workspaceModelSelection.modelConnectionId !=
          model.modelConnection.id) {
    return null;
  }
  final selection = model.workspaceModelSelection;
  final catalogProviderId = ModelProviderOAuthProfiles.isCodexProvider(
    model.modelConnection.modelId,
  )
      ? 'openai'
      : model.modelsProvider.id;
  final catalogModel = await ref.watch(
    getModelByProviderAndModelIdProvider(
      workspaceId: workspaceId,
      providerId: catalogProviderId,
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

Future<_ReadResult<T>> _capture<T>(Future<T> Function() read) async {
  try {
    return _ReadResult<T>.available(await read());
  } on Object {
    return const _ReadResult<T>.unavailable();
  }
}

class const _ReadResult<T>({required this.available, this.value}) {
  const _ReadResult.available(T? value) : this(available: true, value: value);

  const _ReadResult.unavailable() : this(available: false);

  final bool available;
  final T? value;
}
