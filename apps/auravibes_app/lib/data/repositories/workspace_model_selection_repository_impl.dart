import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_model_selections_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/api_model_provider_table.dart';
import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';

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
          workspaceIds: filter.workspaces ?? [],
        );
    return tableResults.map(_withProviderTableToEntity).toList();
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
    return WorkspaceModelSelectionWithConnectionEntity(
      workspaceModelSelection: WorkspaceModelSelectionEntity(
        id: withProvider.model.id,
        modelId: withProvider.model.modelId,
        modelConnectionId: withProvider.model.modelConnectionId,
        createdAt: withProvider.model.createdAt,
        updatedAt: withProvider.model.updatedAt,
      ),
      modelConnection: ModelConnectionEntity(
        id: withProvider.modelConnection.id,
        name: withProvider.modelConnection.name,
        key: withProvider.modelConnection.keyValue,
        createdAt: withProvider.modelConnection.createdAt,
        updatedAt: withProvider.modelConnection.updatedAt,
        workspaceId: withProvider.modelConnection.workspaceId,
        url: withProvider.modelConnection.url,
        modelId: withProvider.modelConnection.modelId,
      ),
      modelsProvider: ApiModelProviderEntity(
        id: withProvider.modelProvider.id,
        name: withProvider.modelProvider.name,
        type: _mapToTypeTable(withProvider.modelProvider.type),
        doc: withProvider.modelProvider.doc,
        url: withProvider.modelProvider.url,
      ),
    );
  }

  ModelProvidersType? _mapToTypeTable(ModelProvidersTableType? type) {
    if (type == null) return null;
    return switch (type) {
      .openai => .openai,
      .anthropic => .anthropic,
    };
  }
}
