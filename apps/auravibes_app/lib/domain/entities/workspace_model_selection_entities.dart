import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/domain/enums/chat_models_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_model_selection_entities.freezed.dart';

@freezed
abstract class WorkspaceModelSelectionEntity
    with _$WorkspaceModelSelectionEntity {
  const factory WorkspaceModelSelectionEntity({
    required String id,
    required String modelId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String modelConnectionId,
  }) = _WorkspaceModelSelectionEntity;
}

@freezed
abstract class WorkspaceModelSelectionWithConnectionEntity
    with _$WorkspaceModelSelectionWithConnectionEntity {
  const factory WorkspaceModelSelectionWithConnectionEntity({
    required WorkspaceModelSelectionEntity workspaceModelSelection,
    required ModelConnectionEntity modelConnection,
    required ApiModelProviderEntity modelsProvider,
  }) = _WorkspaceModelSelectionWithConnectionEntity;
}

@freezed
abstract class WorkspaceModelSelectionFilter
    with _$WorkspaceModelSelectionFilter {
  const factory WorkspaceModelSelectionFilter({
    List<String>? workspaces,
    List<CredentialsModelType>? types,
  }) = _WorkspaceModelSelectionFilter;
}

@freezed
abstract class WorkspaceModelSelectionToCreate
    with _$WorkspaceModelSelectionToCreate {
  const factory WorkspaceModelSelectionToCreate({
    required String modelId,
    required String modelConnectionId,
  }) = _WorkspaceModelSelectionToCreate;
}
