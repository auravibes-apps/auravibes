import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';

abstract interface class ModelConnectionStore {
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate connection,
  );
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(String id);
  Future<ModelConnectionEntity> updateModelConnection(
    String id,
    ModelConnectionToUpdate connection,
  );
  Future<void> deleteModelConnection(String id);
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  );
}

abstract interface class ModelSelectionStore {
  Future<WorkspaceModelSelectionWithConnectionEntity?> getById(String id);
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> watch(
    String workspaceId,
  );
}

abstract interface class ModelCatalogStore {
  Future<List<ApiModelProviderEntity>> getAllProviders();
  Future<List<ApiModelEntity>> getAllModels();
  Future<List<ApiModelEntity>> getModelsByProvider(String providerId);
  Future<ApiModelEntity?> getModelByProviderAndModelId(
    String providerId,
    String modelId,
  );
  Stream<List<ApiModelProviderEntity>> watchAllProviders();
  Stream<List<ApiModelEntity>> watchModelsByProvider(String providerId);
}
