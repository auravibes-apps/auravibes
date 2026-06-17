// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_model_selection_with_connection.dart';
import 'package:auravibes_app/data/database/drift/tables/model_providers_table_type.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';

/// Implementation of the [WorkspaceModelSelectionRepository] interface.
///
/// This class provides a concrete implementation of workspace model selection
/// data operations using the Drift database. It handles the mapping between
/// domain entities and database records, and provides proper error handling
/// using exceptions.
class WorkspaceModelSelectionRepositoryImpl
    implements WorkspaceModelSelectionRepository {
  WorkspaceModelSelectionRepositoryImpl(this._database);
  final AppDatabase _database;

  @override
  Future<void> createWorkspaceModelSelections(
    List<WorkspaceModelSelectionToCreate> workspaceModelSelections,
  ) async {
    await _database.workspaceModelSelectionsDao.insertWorkspaceModelSelections(
      workspaceModelSelections
          .map(_workspaceModelSelectionToCreateToCompanion)
          .toList(),
    );
  }

  @override
  Future<List<WorkspaceModelSelectionWithConnectionEntity>>
  getWorkspaceModelSelections(
    WorkspaceModelSelectionFilter filter,
  ) async {
    final tableResults = await _database.workspaceModelSelectionsDao
        .getAllWorkspaceModelSelectionsByWorkspace(
          workspaceIds: filter.workspaces,
        );

    return tableResults.map(_withProviderTableToEntity).toList();
  }

  @override
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
  watchWorkspaceModelSelections(
    WorkspaceModelSelectionFilter filter,
  ) {
    return _database.workspaceModelSelectionsDao
        .watchAllWorkspaceModelSelectionsByWorkspace(
          workspaceIds: filter.workspaces,
        )
        .map(
          (tableResults) => tableResults
              .map(_withProviderTableToEntity)
              .toList(),
        );
  }

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?>
  getWorkspaceModelSelectionById(
    String id,
  ) async {
    final workspaceModelSelectionWithConnection = await _database
        .workspaceModelSelectionsDao
        .getWorkspaceModelSelectionById(id);
    if (workspaceModelSelectionWithConnection == null) return null;

    return _withProviderTableToEntity(workspaceModelSelectionWithConnection);
  }

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
    final isCodex = isOpenAICodexProvider(
      withProvider.modelConnection.serviceId,
    );
    final providerType = _mapToTypeTable(modelProvider?.type);

    return WorkspaceModelSelectionWithConnectionEntity(
      workspaceModelSelection: WorkspaceModelSelectionEntity(
        id: withProvider.model.id,
        modelId: withProvider.model.modelId,
        createdAt: withProvider.model.createdAt,
        updatedAt: withProvider.model.updatedAt,
        modelConnectionId: withProvider.model.modelConnectionId,
        modelName: withProvider.apiModel?.name,
        supportsReasoning: withProvider.apiModel?.supportsReasoning ?? false,
        supportsToolCalls: withProvider.apiModel?.supportsToolCalls ?? true,
      ),
      modelConnection: ModelConnectionEntity(
        id: withProvider.modelConnection.id,
        name: withProvider.modelConnection.name,
        key: withProvider.modelConnection.encryptedAuthValue ?? '',
        modelId: withProvider.modelConnection.serviceId,
        createdAt: withProvider.modelConnection.createdAt,
        updatedAt: withProvider.modelConnection.updatedAt,
        workspaceId: withProvider.modelConnection.workspaceId,
        authMode: _authMode(withProvider.modelConnection.authenticationType),
        url: withProvider.modelConnection.url,
        keySuffix: withProvider.modelConnection.keySuffix,
        oauthMetadata: ServiceConnectionAuthCodec.decodeMetadata(
          withProvider.modelConnection.metadataJson,
        ),
      ),
      modelsProvider: ApiModelProviderEntity(
        id: modelProvider?.id ?? withProvider.modelConnection.serviceId,
        name:
            modelProvider?.name ??
            (isCodex ? openAICodexDisplayName : null) ??
            withProvider.modelConnection.serviceId,
        type: providerType ?? (isCodex ? ModelProvidersType.openai : null),
        url: modelProvider?.url ?? '',
        doc: modelProvider?.doc ?? '',
      ),
    );
  }

  ModelProviderAuthMode _authMode(ServiceAuthenticationTypeTable type) {
    return switch (type) {
      ServiceAuthenticationTypeTable.oauth2 => ModelProviderAuthMode.oauth2,
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
