import 'package:auravibes_app/domain/enums/chat_models_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_connection_entities.freezed.dart';

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
abstract class ModelConnectionFilter with _$ModelConnectionFilter {
  const factory ModelConnectionFilter({
    List<String>? workspaces,
    List<CredentialsModelType>? types,
  }) = _ModelConnectionFilter;
}
