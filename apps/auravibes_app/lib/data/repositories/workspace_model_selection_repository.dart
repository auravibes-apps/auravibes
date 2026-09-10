// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_model_selection_with_connection.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';

/// Implementation of the [WorkspaceModelSelectionRepository] interface.
///
/// This class provides a concrete implementation of workspace model selection
/// data operations using the Drift database. It handles the mapping between
/// domain entities and database records, and provides proper error handling
/// using exceptions.
class WorkspaceModelSelectionRepository(final AppDatabase _database)
    implements ModelSelectionStore {
  Future<void> createWorkspaceModelSelections(
    List<WorkspaceModelSelectionToCreate> workspaceModelSelections,
  ) async {
    await _database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
      workspaceModelSelections
          .map(this._workspaceModelSelectionToCreateToCompanion)
          .toList(),
    );
  }

  Future<List<WorkspaceModelSelectionWithConnectionEntity>>
  getWorkspaceModelSelections(WorkspaceModelSelectionFilter filter) async {
    final tableResults = await _database.workspaceModelSelectionsDao
        .getAllWorkspaceModelSelectionsByWorkspace(
          workspaceIds: filter.workspaces,
        );

    return tableResults.map(this._withProviderTableToEntity).toList();
  }

  Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
  watchWorkspaceModelSelections(WorkspaceModelSelectionFilter filter) {
    return _database.workspaceModelSelectionsDao
        .watchAllWorkspaceModelSelectionsByWorkspace(
          workspaceIds: filter.workspaces,
        )
        .map(
          (tableResults) =>
              tableResults.map(this._withProviderTableToEntity).toList(),
        );
  }

  Future<WorkspaceModelSelectionWithConnectionEntity?>
  getWorkspaceModelSelectionById(String id) async {
    final workspaceModelSelectionWithConnection = await _database
        .workspaceModelSelectionsDao
        .getWorkspaceModelSelectionById(id);
    if (workspaceModelSelectionWithConnection == null) return null;

    return this._withProviderTableToEntity(
      workspaceModelSelectionWithConnection,
    );
  }

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?> getById(String id) =>
      getWorkspaceModelSelectionById(id);

  @override
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> watch(
    String workspaceId,
  ) => watchWorkspaceModelSelections(.new(workspaces: [workspaceId]));
}

extension on WorkspaceModelSelectionRepository {
  WorkspaceModelSelectionsCompanion _workspaceModelSelectionToCreateToCompanion(
    WorkspaceModelSelectionToCreate workspaceModelSelection,
  ) {
    return WorkspaceModelSelectionsCompanion(
      modelId: .new(workspaceModelSelection.modelId),
      modelConnectionId: .new(workspaceModelSelection.modelConnectionId),
    );
  }

  WorkspaceModelSelectionWithConnectionEntity _withProviderTableToEntity(
    WorkspaceModelSelectionWithConnection withProvider,
  ) {
    final modelProvider = withProvider.modelProvider;
    final serviceId = withProvider.modelConnection.serviceId;
    final isCodex = ModelProviderOAuthProfiles.isCodexProvider(serviceId);
    final providerType = _mapToTypeTable(modelProvider?.type);

    final workspaceModelSelection = _modelSelectionEntity(withProvider);
    final modelConnection = _modelConnectionEntity(withProvider, serviceId);
    final modelsProvider = _modelProviderEntity(
      withProvider.modelProvider,
      serviceId: serviceId,
      isCodex: isCodex,
      providerType: providerType,
    );

    return WorkspaceModelSelectionWithConnectionEntity(
      workspaceModelSelection: workspaceModelSelection,
      modelConnection: modelConnection,
      modelsProvider: modelsProvider,
    );
  }

  WorkspaceModelSelectionEntity _modelSelectionEntity(
    WorkspaceModelSelectionWithConnection withProvider,
  ) {
    final apiModel = withProvider.apiModel;

    final selection = WorkspaceModelSelectionEntity(
      id: withProvider.model.id,
      modelId: withProvider.model.modelId,
      createdAt: withProvider.model.createdAt,
      updatedAt: withProvider.model.updatedAt,
      modelConnectionId: withProvider.model.modelConnectionId,
    );

    return _withModelCapabilities(selection, apiModel);
  }

  WorkspaceModelSelectionEntity _withModelCapabilities(
    WorkspaceModelSelectionEntity selection,
    ApiModelsTable? apiModel,
  ) => selection.copyWith(
    modelName: apiModel?.name,
    modalitiesInput: apiModel?.modalitiesInput ?? [],
    modalitiesOutput: apiModel?.modalitiesOutput ?? [],
    supportsReasoning: apiModel?.supportsReasoning ?? false,
    supportsToolCalls: apiModel?.supportsToolCalls ?? false,
  );

  ModelConnectionEntity _modelConnectionEntity(
    WorkspaceModelSelectionWithConnection withProvider,
    String serviceId,
  ) {
    final connection = withProvider.modelConnection;

    final modelConnection = ModelConnectionEntity(
      id: connection.id,
      name: connection.name,
      modelId: serviceId,
      createdAt: connection.createdAt,
      updatedAt: connection.updatedAt,
      workspaceId: connection.workspaceId,
      hasKey: connection.encryptedAuthValue?.isNotEmpty == true,
    );

    return _withConnectionCredentials(modelConnection, connection);
  }

  ModelConnectionEntity _withConnectionCredentials(
    ModelConnectionEntity modelConnection,
    ServiceConnectionsTable connection,
  ) => modelConnection.copyWith(
    authMode: _authMode(connection.authenticationType),
    url: connection.url,
    keySuffix: connection.keySuffix,
    oauthMetadata: ServiceConnectionAuthCodec.decodeMetadata(
      connection.metadataJson,
    ),
  );

  ApiModelProviderEntity _modelProviderEntity(
    ApiModelProvidersTable? modelProvider, {
    required String serviceId,
    required bool isCodex,
    required ModelProvidersType? providerType,
  }) => .new(
    id: modelProvider?.id ?? serviceId,
    name: _providerName(modelProvider, serviceId, isCodex),
    type: _providerType(providerType, isCodex),
    url: modelProvider?.url ?? '',
    doc: modelProvider?.doc ?? '',
  );

  String _providerName(
    ApiModelProvidersTable? provider,
    String serviceId,
    bool isCodex,
  ) {
    final name = provider?.name;
    if (name != null) return name;
    if (isCodex) return ModelProviderOAuthProfiles.displayName;

    return serviceId;
  }

  ModelProvidersType? _providerType(
    ModelProvidersType? providerType,
    bool isCodex,
  ) {
    if (providerType != null) return providerType;
    if (isCodex) return ModelProvidersType.openai;

    return null;
  }

  ModelProviderAuthMode _authMode(ServiceAuthenticationTypeTable type) {
    return switch (type) {
      .oauth2 => ModelProviderAuthMode.oauth2,
      _ => ModelProviderAuthMode.apiKey,
    };
  }

  ModelProvidersType? _mapToTypeTable(ModelProvidersTableType? type) {
    if (type == null) return null;

    return switch (type) {
      .openai => .openai,
      .anthropic => .anthropic,
      .openrouter => .openrouter,
    };
  }
}
