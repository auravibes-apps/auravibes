// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/utils/map_exception.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_transport_type.freezed.dart';
part 'mcp_transport_type.g.dart';

sealed class const McpTransportType() {
  factory fromJson(Map<String, dynamic> json) {
    final type = json.get<String>('type');
    switch (type) {
      case 'sse':
        return McpTransportTypeSSE.fromJson(json);
      case 'streamableHttp':
        return McpTransportTypeStreamableHttp.fromJson(json);
      default:
        throw UnsupportedError('Unsupported MCP transport type: $type');
    }
  }

  Map<String, dynamic> toJson();
}

class const McpTransportTypeSSE() extends McpTransportType {
  factory fromJson(Map<String, dynamic> _) {
    return const McpTransportTypeSSE();
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'sse'};
  }
}

class const McpTransportTypeStreamableHttp({final bool useHttp2 = false})
    extends McpTransportType {
  factory fromJson(Map<String, dynamic> json) {
    return McpTransportTypeStreamableHttp(useHttp2: json.get('useHttp2'));
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'streamableHttp', 'useHttp2': useHttp2};
  }
}

@immutable
@Freezed(toStringOverride: false)
abstract class const OAuthTokenModel._() with _$OAuthTokenModel {
  // ignore: invalid_annotation_target - Required for Freezed JSON annotation.
  @JsonSerializable(fieldRename: .snake)
  const factory({
    required String accessToken,
    String? refreshToken,
    String? idToken,
    int? expiresIn,
    String? tokenType,
    String? scope,
  }) = _OAuthTokenModel;

  factory fromJson(Map<String, dynamic> json) =>
      _$OAuthTokenModelFromJson(json);

  @override
  Map<String, dynamic> toJson();

  OAuthTokenEntity toEntity() {
    return OAuthTokenEntity(
      accessToken: accessToken,
      issuedAt: .now(),
      refreshToken: refreshToken,
      idToken: idToken,
      expiresIn: expiresIn,
      tokenType: tokenType,
      scopes: scope?.split(' '),
    );
  }
}

@immutable
@Freezed(toStringOverride: false)
abstract class const OAuthTokenEntity._() with _$OAuthTokenEntity {
  const factory({
    required String accessToken,
    required DateTime issuedAt,
    String? refreshToken,
    String? idToken,
    int? expiresIn,
    String? tokenType,
    List<String>? scopes,
  }) = _OAuthTokenEntity;

  factory fromJson(Map<String, dynamic> json) =>
      _$OAuthTokenEntityFromJson(json);

  /// Returns true if the stored OAuth token is expired or unavailable.
  bool get isOAuthTokenExpired {
    final expiresIn = this.expiresIn;
    if (expiresIn == null) return true;

    final expiresAt = issuedAt.add(.new(seconds: expiresIn));

    // Consider expired if within 5 minutes of expiry (buffer for refresh).
    return DateTime.now().isAfter(
      expiresAt.subtract(const Duration(minutes: 5)),
    );
  }

  /// Returns true if the OAuth token needs refresh (has a token but it is
  /// expired or about to expire).
  bool get needsOAuthTokenRefresh =>
      isOAuthTokenExpired && refreshToken != null;

  bool hasRefreshToken() => refreshToken != null;

  Future<OAuthTokenEntity> copyCryptor(
    Future<String> Function(String) encryptor,
  ) async {
    return OAuthTokenEntity(
      accessToken: await encryptor(accessToken),
      issuedAt: issuedAt,
      refreshToken: await _encryptNullable(refreshToken, encryptor),
      idToken: await _encryptNullable(idToken, encryptor),
      expiresIn: expiresIn,
      tokenType: tokenType,
      scopes: scopes,
    );
  }
}

Future<String?> _encryptNullable(
  String? value,
  Future<String> Function(String) encryptor,
) async {
  if (value == null) return null;

  return await encryptor(value);
}

@immutable
@Freezed(toStringOverride: false)
sealed class const McpAuthenticationType._() with _$McpAuthenticationType {
  const factory none() = McpAuthenticationTypeNone;

  const factory oauth({
    required OAuthTokenEntity token,
    required String clientId,
    required String authorizationEndpoint,
    required String tokenEndpoint,
  }) = McpAuthenticationTypeOAuth;

  const factory bearerToken({required String bearerToken}) =
      McpAuthenticationTypeBearerToken;

  factory fromJson(Map<String, dynamic> json) =>
      _$McpAuthenticationTypeFromJson(json);

  @override
  Map<String, dynamic> toJson();

  Future<McpAuthenticationType> copyCryptor(
    Future<String> Function(String) encryptor,
  ) async {
    switch (this) {
      case McpAuthenticationTypeNone():
        return this;
      case McpAuthenticationTypeOAuth(:final token):
        return (this as McpAuthenticationTypeOAuth).copyWith(
          token: await token.copyCryptor(encryptor),
        );
      case McpAuthenticationTypeBearerToken(:final bearerToken):
        return McpAuthenticationType.bearerToken(
          bearerToken: await encryptor(bearerToken),
        );
    }
  }
}

/// Entity for creating/updating MCP server configurations.
@immutable
@freezed
abstract class const McpServerToCreate._() with _$McpServerToCreate {
  /// Creates a new McpServerToCreate instance.
  const factory({
    /// User-friendly name for the MCP server.
    required String name,

    /// URL endpoint for the MCP server.
    required String url,

    /// Transport type used for communication.
    required McpTransportType transport,

    /// Transient authentication config used only while connecting.
    required McpAuthenticationType authenticationType,

    /// Optional credential record used to authenticate this MCP server.
    String? serviceConnectionId,

    /// Optional description of what this MCP server provides.
    String? description,
  }) = _McpServerToCreate;

  String get slugServerName {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return slug.isEmpty ? 'server' : slug;
  }

  bool hasDescription() => description?.isNotEmpty == true;
}

/// Entity representing an MCP (Model Context Protocol) server configuration.
///
/// This represents user-configured MCP servers that can be connected to
/// for extending AI capabilities with external tools and resources.
@immutable
@freezed
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class const McpServerEntity._()
    extends McpServerToCreate
    with _$McpServerEntity {
  /// Creates a new McpServerEntity instance.
  const factory({
    /// Unique ID of this MCP server record in the database.
    required String id,

    /// ID of the workspace this MCP server belongs to.
    required String workspaceId,

    /// User-friendly name for the MCP server.
    required String name,

    /// URL endpoint for the MCP server.
    required String url,

    /// Transport type used for communication.
    required McpTransportType transport,

    /// Transient authentication config used only while connecting.
    required McpAuthenticationType authenticationType,

    /// Timestamp when this configuration was created.
    required DateTime createdAt,

    /// Timestamp when this configuration was last updated.
    required DateTime updatedAt,

    /// Optional credential record used to authenticate this MCP server.
    String? serviceConnectionId,

    /// Optional description of what this MCP server provides.
    String? description,

    /// Whether the MCP server is enabled.
    @Default(true) bool isEnabled,
  }) = _McpServerEntity;
  this : super._();
}

enum McpAuthenticationTypeOptions { none, oauth, bearerToken }

enum McpTransportTypeOptions { streamableHttp, sse }

@immutable
@Freezed(toStringOverride: false)
// DCL cannot see Freezed-generated members in the part file.
// ignore: weight-of-class
abstract class const McpServerFormToCreate._() with _$McpServerFormToCreate {
  const factory({
    required String name,

    required String url,

    required McpTransportType transport,

    required McpAuthenticationTypeOptions authenticationType,

    required String? bearerToken,

    String? description,
  }) = _McpServerFormToCreate;

  bool get isValid {
    if (name.isEmpty || url.isEmpty) {
      return false;
    }

    switch (authenticationType) {
      case .none:
        return true;
      case .oauth:
        // OAuth requires no additional fields here.
        return true;
      case .bearerToken:
        return hasValidAuthentication();
    }
  }

  List<String> get validationErrors => [
    if (name.isEmpty) 'Name is required.',
    if (url.isEmpty) 'URL is required.',
    if (authenticationType == .bearerToken && bearerToken?.isNotEmpty != true)
      'Bearer token is required for Bearer Token authentication.',
  ];

  bool hasValidAuthentication() =>
      authenticationType != .bearerToken || bearerToken?.isNotEmpty == true;
}
