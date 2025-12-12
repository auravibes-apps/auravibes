import 'package:auravibes_app/utils/json.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_server.freezed.dart';
part 'mcp_server.g.dart';

sealed class McpTransportType {
  const McpTransportType();

  factory McpTransportType.fromJson(Map<String, dynamic> json) {
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

class McpTransportTypeSSE extends McpTransportType {
  const McpTransportTypeSSE();

  factory McpTransportTypeSSE.fromJson(Map<String, dynamic> _) {
    return const McpTransportTypeSSE();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'sse',
    };
  }
}

class McpTransportTypeStreamableHttp extends McpTransportType {
  const McpTransportTypeStreamableHttp({
    this.useHttp2 = false,
  });

  factory McpTransportTypeStreamableHttp.fromJson(Map<String, dynamic> json) {
    return McpTransportTypeStreamableHttp(
      useHttp2: json.get('useHttp2'),
    );
  }

  final bool useHttp2;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'streamableHttp',
      'useHttp2': useHttp2,
    };
  }
}

@freezed
abstract class OAutTokenModel with _$OAutTokenModel {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: .snake)
  const factory OAutTokenModel({
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
    String? tokenType,
    String? scope,
  }) = _OAutTokenModel;

  factory OAutTokenModel.fromJson(Map<String, dynamic> json) =>
      _$OAutTokenModelFromJson(json);
  const OAutTokenModel._();

  OAutTokenEntity toEntity() {
    return OAutTokenEntity(
      accessToken: accessToken,
      issuedAt: DateTime.now(),
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      tokenType: tokenType,
      scopes: scope?.split(' '),
    );
  }
}

@freezed
abstract class OAutTokenEntity with _$OAutTokenEntity {
  const factory OAutTokenEntity({
    required String accessToken,
    required DateTime issuedAt,
    String? refreshToken,
    int? expiresIn,
    String? tokenType,
    List<String>? scopes,
  }) = _OAutTokenEntity;

  const OAutTokenEntity._();

  factory OAutTokenEntity.fromJson(Map<String, dynamic> json) =>
      _$OAutTokenEntityFromJson(json);

  /// Returns true if the stored OAuth token is expired or unavailable.
  bool get isOAuthTokenExpired {
    if (expiresIn == null) return true;
    final expiresAt = issuedAt.add(Duration(seconds: expiresIn!));
    // Consider expired if within 5 minutes of expiry (buffer for refresh)
    return DateTime.now().isAfter(
      expiresAt.subtract(const Duration(minutes: 5)),
    );
  }

  /// Returns true if OAuth token needs refresh
  /// (has token but it's expired or about to expire)
  bool get needsOAuthTokenRefresh =>
      isOAuthTokenExpired && refreshToken != null;

  Future<OAutTokenEntity> copyCryptor(
    Future<String> Function(String) encryptor,
  ) async {
    return OAutTokenEntity(
      accessToken: await encryptor(accessToken),
      issuedAt: issuedAt,
      refreshToken: refreshToken != null
          ? await encryptor(refreshToken!)
          : null,
      expiresIn: expiresIn,
      tokenType: tokenType,
      scopes: scopes,
    );
  }
}

@freezed
sealed class McpAuthenticationType with _$McpAuthenticationType {
  const McpAuthenticationType._();
  const factory McpAuthenticationType.none() = McpAuthenticationTypeNone;

  const factory McpAuthenticationType.oauth({
    required OAutTokenEntity token,
    required String clientId,
    required String authorizationEndpoint,
    required String tokenEndpoint,
  }) = McpAuthenticationTypeOAuth;

  const factory McpAuthenticationType.bearerToken({
    required String bearerToken,
  }) = McpAuthenticationTypeBearerToken;

  factory McpAuthenticationType.fromJson(Map<String, dynamic> json) =>
      _$McpAuthenticationTypeFromJson(json);

  Future<McpAuthenticationType> copyCryptor(
    Future<String> Function(String) encryptor,
  ) async {
    switch (this) {
      case McpAuthenticationTypeNone():
        return this;
      case McpAuthenticationTypeOAuth(token: final token):
        return (this as McpAuthenticationTypeOAuth).copyWith(
          token: await token.copyCryptor(encryptor),
        );
      case McpAuthenticationTypeBearerToken(bearerToken: final bearerToken):
        return McpAuthenticationType.bearerToken(
          bearerToken: await encryptor(bearerToken),
        );
    }
  }
}

/// Entity for creating/updating MCP server configurations
@freezed
abstract class McpServerToCreate with _$McpServerToCreate {
  /// Creates a new McpServerToCreate instance
  const factory McpServerToCreate({
    /// User-friendly name for the MCP server
    required String name,

    /// URL endpoint for the MCP server
    required String url,

    /// Transport type used for communication
    required McpTransportType transport,

    /// Authentication type for the MCP server
    required McpAuthenticationType authenticationType,

    /// Optional description of what this MCP server provides
    String? description,
  }) = _McpServerToCreate;
  const McpServerToCreate._();

  String get slugServerName {
    return name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
  }
}

/// Entity representing an MCP (Model Context Protocol) server configuration.
///
/// This represents user-configured MCP servers that can be connected to
/// for extending AI capabilities with external tools and resources.
@freezed
abstract class McpServerEntity extends McpServerToCreate
    with _$McpServerEntity {
  /// Creates a new McpServerEntity instance
  const factory McpServerEntity({
    /// Unique ID of this MCP server record in the database
    required String id,

    /// ID of the workspace this MCP server belongs to
    required String workspaceId,

    /// User-friendly name for the MCP server
    required String name,

    /// URL endpoint for the MCP server
    required String url,

    /// Transport type used for communication
    required McpTransportType transport,

    /// Authentication type for the MCP server
    required McpAuthenticationType authenticationType,

    /// Timestamp when this configuration was created
    required DateTime createdAt,

    /// Timestamp when this configuration was last updated
    required DateTime updatedAt,

    /// Optional description of what this MCP server provides
    String? description,

    /// Whether the MCP server is enabled
    @Default(true) bool isEnabled,
  }) = _McpServerEntity;
  const McpServerEntity._() : super._();
}

enum McpAuthenticationTypeOptions {
  none,
  oauth,
  bearerToken,
}

enum McpTransportTypeOptions {
  streamableHttp,
  sse,
}

@freezed
abstract class McpServerFormToCreate with _$McpServerFormToCreate {
  const factory McpServerFormToCreate({
    required String name,

    required String url,

    required McpTransportType transport,

    required McpAuthenticationTypeOptions authenticationType,

    required String? bearerToken,

    String? description,
  }) = _McpServerFormToCreate;
  const McpServerFormToCreate._();

  bool get isValid {
    if (name.isEmpty || url.isEmpty) {
      return false;
    }

    switch (authenticationType) {
      case McpAuthenticationTypeOptions.none:
        return true;
      case McpAuthenticationTypeOptions.oauth:
        // OAuth requires no additional fields here
        return true;
      case McpAuthenticationTypeOptions.bearerToken:
        return bearerToken != null && bearerToken!.isNotEmpty;
    }
  }

  List<String> get validationErrors {
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('Name is required.');
    }
    if (url.isEmpty) {
      errors.add('URL is required.');
    }

    switch (authenticationType) {
      case McpAuthenticationTypeOptions.none:
        break;
      case McpAuthenticationTypeOptions.oauth:
        // No additional fields to validate here
        break;
      case McpAuthenticationTypeOptions.bearerToken:
        if (bearerToken == null || bearerToken!.isEmpty) {
          errors.add(
            'Bearer token is required for Bearer Token authentication.',
          );
        }
    }

    return errors;
  }
}
