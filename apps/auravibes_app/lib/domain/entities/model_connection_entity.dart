import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_connection_entity.freezed.dart';

@immutable
@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ModelConnectionEntity with _$ModelConnectionEntity {
  const factory({
    required String id,
    required String name,
    required String modelId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String workspaceId,
    required bool hasKey,
    @Default(ModelProviderAuthMode.apiKey) ModelProviderAuthMode authMode,
    String? url,
    String? keySuffix,
    ServiceConnectionMetadata? oauthMetadata,
  }) = _ModelConnectionEntity;
}

@immutable
@Freezed(toStringOverride: false)
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ModelConnectionToCreate with _$ModelConnectionToCreate {
  @Assert(
    'authMode == ModelProviderAuthMode.oauth2 || key != ""',
    'API-key connections require a non-empty key.',
  )
  const factory({
    required String name,
    required String workspaceId,
    required String modelId,
    @Default(ModelProviderAuthMode.apiKey) ModelProviderAuthMode authMode,
    @Default('') String key,
    String? url,
    OAuthTokenEntity? oauthToken,
    ServiceConnectionMetadata? oauthMetadata,
    @Default([]) List<String> modelIds,
  }) = _ModelConnectionToCreate;
}

@immutable
@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ModelConnectionForEdit with _$ModelConnectionForEdit {
  const factory({
    required String id,
    required String name,
    required String modelId,
    required String workspaceId,
    required bool hasKey,
    @Default(ModelProviderAuthMode.apiKey) ModelProviderAuthMode authMode,
    String? url,
    String? keySuffix,
  }) = _ModelConnectionForEdit;
}

@immutable
@Freezed(toStringOverride: false)
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ModelConnectionToUpdate with _$ModelConnectionToUpdate {
  // Null means preserve the existing persisted value for that field.
  // ignore: unnecessary-nullable
  const factory({String? name, String? key, String? url}) =
      _ModelConnectionToUpdate;
}

@immutable
@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class ModelConnectionFilter with _$ModelConnectionFilter {
  const factory({@Default([]) List<String> workspaces}) =
      _ModelConnectionFilter;
}
