import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_model_selection_entity.freezed.dart';

@freezed
abstract class WorkspaceModelSelectionEntity
    with _$WorkspaceModelSelectionEntity {
  const factory WorkspaceModelSelectionEntity({
    required String id,
    required String modelId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String modelConnectionId,
    String? modelName,
    @Default(false) bool supportsReasoning,
    @Default(true) bool supportsToolCalls,
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
    @Default([]) List<String> workspaces,
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
