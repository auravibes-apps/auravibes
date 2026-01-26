import 'package:auravibes_app/domain/enums/chat_models_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'credentials_entities.freezed.dart';

@freezed
abstract class CredentialsEntity with _$CredentialsEntity {
  const factory CredentialsEntity({
    required String id,
    required String name,
    required String key,
    required String modelId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String workspaceId,
    String? url,
    String? keySuffix,
  }) = _CredentialsEntity;
}

@freezed
abstract class CredentialsToCreate with _$CredentialsToCreate {
  const factory CredentialsToCreate({
    required String name,
    required String key,
    required String workspaceId,
    required String modelId,
    String? url,
  }) = _CredentialsToCreate;
}

@freezed
abstract class ModelProviderFilter with _$ModelProviderFilter {
  const factory ModelProviderFilter({
    List<String>? workspaces,
    List<CredentialsModelType>? types,
  }) = _ModelProviderFilter;
}
