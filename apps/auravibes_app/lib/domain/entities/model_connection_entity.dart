import 'package:auravibes_app/domain/enums/credentials_model_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_connection_entity.freezed.dart';

@freezed
abstract class ModelConnectionEntity with _$ModelConnectionEntity {
  const factory ModelConnectionEntity({
    required String id,
    required String name,
    required String key,
    required String modelId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String workspaceId,
    String? url,
    String? keySuffix,
  }) = _ModelConnectionEntity;
}

@freezed
abstract class ModelConnectionToCreate with _$ModelConnectionToCreate {
  const factory ModelConnectionToCreate({
    required String name,
    required String key,
    required String workspaceId,
    required String modelId,
    String? url,
  }) = _ModelConnectionToCreate;
}

@freezed
abstract class ModelConnectionForEdit with _$ModelConnectionForEdit {
  const factory ModelConnectionForEdit({
    required String id,
    required String name,
    required String modelId,
    required String workspaceId,
    required bool hasKey,
    String? url,
    String? keySuffix,
  }) = _ModelConnectionForEdit;
}

@freezed
abstract class ModelConnectionToUpdate with _$ModelConnectionToUpdate {
  // Null means preserve the existing persisted value for that field.
  // ignore: unnecessary-nullable
  const factory ModelConnectionToUpdate({
    String? name,
    String? key,
    String? url,
  }) = _ModelConnectionToUpdate;
}

@freezed
abstract class ModelConnectionFilter with _$ModelConnectionFilter {
  const factory ModelConnectionFilter({
    @Default([]) List<String> workspaces,
    List<CredentialsModelType>? types,
  }) = _ModelConnectionFilter;
}
