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

typedef _ModelProviderInput = ({
  ApiModelProvidersTable? modelProvider,
  String serviceId,
  bool isCodex,
  ModelProvidersType? providerType,
});

typedef _ModelProviderDetails = ({
  String id,
  String name,
  ModelProvidersType? type,
  String url,
  String doc,
});

typedef _ModelCapabilities = ({
  List<String> modalitiesInput,
  List<String> modalitiesOutput,
  bool supportsReasoning,
  bool supportsToolCalls,
});

_ModelCapabilities _modelCapabilities(ApiModelsTable? apiModel) {
  if (apiModel == null) return _emptyModelCapabilities();

  return _modelCapabilitiesFor(apiModel);
}

_ModelCapabilities _emptyModelCapabilities() => (
  modalitiesInput: const [],
  modalitiesOutput: const [],
  supportsReasoning: false,
  supportsToolCalls: false,
);

_ModelCapabilities _modelCapabilitiesFor(ApiModelsTable apiModel) => (
  modalitiesInput: _modelList(apiModel.modalitiesInput),
  modalitiesOutput: _modelList(apiModel.modalitiesOutput),
  supportsReasoning: _modelFlag(apiModel.supportsReasoning),
  supportsToolCalls: _modelFlag(apiModel.supportsToolCalls),
);

List<String> _modelList(List<String>? values) => values ?? const [];

bool _modelFlag(bool value) => value;

String _providerId(_ModelProviderInput data) =>
    data.modelProvider?.id ?? data.serviceId;

String _providerUrl(_ModelProviderInput data) => data.modelProvider?.url ?? '';

String _providerDoc(_ModelProviderInput data) => data.modelProvider?.doc ?? '';

ApiModelProviderEntity _modelProviderDetails(_ModelProviderDetails data) =>
    .new(
      id: data.id,
      name: data.name,
      type: data.type,
      url: data.url,
      doc: data.doc,
    );

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
          .map(_workspaceModelSelectionToCreateToCompanion)
          .toList(),
    );
  }

  Future<List<WorkspaceModelSelectionWithConnectionEntity>>
  getWorkspaceModelSelections(WorkspaceModelSelectionFilter filter) async {
    final tableResults = await _database.workspaceModelSelectionsDao
        .getAllWorkspaceModelSelectionsByWorkspace(
          workspaceIds: filter.workspaces,
        );

    return tableResults.map(_withProviderTableToEntity).toList();
  }

  Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
  watchWorkspaceModelSelections(WorkspaceModelSelectionFilter filter) {
    return _database.workspaceModelSelectionsDao
        .watchAllWorkspaceModelSelectionsByWorkspace(
          workspaceIds: filter.workspaces,
        )
        .map(
          (tableResults) =>
              tableResults.map(_withProviderTableToEntity).toList(),
        );
  }

  Future<WorkspaceModelSelectionWithConnectionEntity?>
  getWorkspaceModelSelectionById(String id) async {
    final workspaceModelSelectionWithConnection = await _database
        .workspaceModelSelectionsDao
        .getWorkspaceModelSelectionById(id);
    if (workspaceModelSelectionWithConnection == null) return null;

    return _withProviderTableToEntity(workspaceModelSelectionWithConnection);
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
    final context = _providerMappingContext(withProvider);

    return _withMappedConnections(
      _modelSelectionEntity(withProvider),
      _modelConnectionEntity(withProvider, context.serviceId),
      _modelProviderEntity((
        modelProvider: withProvider.modelProvider,
        serviceId: context.serviceId,
        isCodex: context.isCodex,
        providerType: context.providerType,
      )),
    );
  }

  ({String serviceId, bool isCodex, ModelProvidersType? providerType})
  _providerMappingContext(WorkspaceModelSelectionWithConnection withProvider) {
    final serviceId = withProvider.modelConnection.serviceId;

    return (
      serviceId: serviceId,
      isCodex: ModelProviderOAuthProfiles.isCodexProvider(serviceId),
      providerType: _mapToTypeTable(withProvider.modelProvider?.type),
    );
  }

  WorkspaceModelSelectionWithConnectionEntity _withMappedConnections(
    WorkspaceModelSelectionEntity workspaceModelSelection,
    ModelConnectionEntity modelConnection,
    ApiModelProviderEntity modelsProvider,
  ) => WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: workspaceModelSelection,
    modelConnection: modelConnection,
    modelsProvider: modelsProvider,
  );

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
  ) {
    final capabilities = _modelCapabilities(apiModel);

    return selection.copyWith(
      modelName: apiModel?.name,
      modalitiesInput: capabilities.modalitiesInput,
      modalitiesOutput: capabilities.modalitiesOutput,
      supportsReasoning: capabilities.supportsReasoning,
      supportsToolCalls: capabilities.supportsToolCalls,
    );
  }

  ModelConnectionEntity _modelConnectionEntity(
    WorkspaceModelSelectionWithConnection withProvider,
    String serviceId,
  ) {
    final connection = withProvider.modelConnection;

    return _withConnectionCredentials(
      _modelConnectionDetails(connection, serviceId),
      connection,
    );
  }

  ModelConnectionEntity _modelConnectionDetails(
    ServiceConnectionTable connection,
    String serviceId,
  ) => ModelConnectionEntity(
    id: connection.id,
    name: connection.name,
    modelId: serviceId,
    createdAt: connection.createdAt,
    updatedAt: connection.updatedAt,
    workspaceId: connection.workspaceId,
    hasKey: connection.encryptedAuthValue?.isNotEmpty == true,
  );

  ModelConnectionEntity _withConnectionCredentials(
    ModelConnectionEntity modelConnection,
    ServiceConnectionTable connection,
  ) => modelConnection.copyWith(
    authMode: _authMode(connection.authenticationType),
    url: connection.url,
    keySuffix: connection.keySuffix,
    oauthMetadata: ServiceConnectionAuthCodec.decodeMetadata(
      connection.metadataJson,
    ),
  );
}

extension on WorkspaceModelSelectionRepository {
  ApiModelProviderEntity _modelProviderEntity(_ModelProviderInput data) =>
      _modelProviderDetails(_modelProviderData(data));

  _ModelProviderDetails _modelProviderData(_ModelProviderInput data) => (
    id: _providerId(data),
    name: _providerName(data.modelProvider, data.serviceId, data.isCodex),
    type: _providerType(data.providerType, data.isCodex),
    url: _providerUrl(data),
    doc: _providerDoc(data),
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
