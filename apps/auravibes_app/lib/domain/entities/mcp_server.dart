import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcp_server.freezed.dart';

/// Transport type for MCP server connections
enum McpTransportType {
  /// Server-Sent Events transport
  sse('sse'),

  /// Streamable HTTP transport
  streamableHttp('streamable_http')
  ;

  const McpTransportType(this.value);

  /// The string value of the transport type
  final String value;
}

/// Authentication type for MCP server connections
enum McpAuthenticationType {
  /// No authentication required
  none('none'),

  /// OAuth 2.0 authentication
  oauth('oauth'),

  /// Bearer token authentication (only available for SSE transport)
  bearerToken('bearer_token')
  ;

  const McpAuthenticationType(this.value);

  /// The string value of the authentication type
  final String value;
}

/// Entity representing an MCP (Model Context Protocol) server configuration.
///
/// This represents user-configured MCP servers that can be connected to
/// for extending AI capabilities with external tools and resources.
@freezed
abstract class McpServerEntity with _$McpServerEntity {
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

    /// OAuth client ID (required when authenticationType is oauth)
    String? clientId,

    /// OAuth token endpoint URL (required when authenticationType is oauth)
    String? tokenEndpoint,

    /// OAuth authorization endpoint URL
    /// (required when authenticationType is oauth)
    String? authorizationEndpoint,

    /// Bearer token (required when authenticationType is bearerToken)
    String? bearerToken,

    /// Whether to use HTTP/2 (only applicable for streamableHttp transport)
    @Default(false) bool useHttp2,

    /// Whether the MCP server is enabled
    @Default(true) bool isEnabled,
  }) = _McpServerEntity;
  const McpServerEntity._();

  /// Returns true if the server uses OAuth authentication
  bool get usesOAuth => authenticationType == McpAuthenticationType.oauth;

  /// Returns true if the server uses bearer token authentication
  bool get usesBearerToken =>
      authenticationType == McpAuthenticationType.bearerToken;

  /// Returns true if OAuth configuration is complete
  bool get hasCompleteOAuthConfig =>
      usesOAuth &&
      clientId != null &&
      clientId!.isNotEmpty &&
      tokenEndpoint != null &&
      tokenEndpoint!.isNotEmpty &&
      authorizationEndpoint != null &&
      authorizationEndpoint!.isNotEmpty;

  /// Returns true if bearer token is configured
  bool get hasBearerToken =>
      usesBearerToken && bearerToken != null && bearerToken!.isNotEmpty;

  /// Returns true if the server configuration is valid for connection
  bool get isValidConfiguration {
    if (name.isEmpty || url.isEmpty) return false;

    switch (authenticationType) {
      case McpAuthenticationType.none:
        return true;
      case McpAuthenticationType.oauth:
        return hasCompleteOAuthConfig;
      case McpAuthenticationType.bearerToken:
        return hasBearerToken;
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

    /// OAuth client ID (required when authenticationType is oauth)
    String? clientId,

    /// OAuth token endpoint URL (required when authenticationType is oauth)
    String? tokenEndpoint,

    /// OAuth authorization endpoint URL
    /// (required when authenticationType is oauth)
    String? authorizationEndpoint,

    /// Bearer token (required when authenticationType is bearerToken)
    String? bearerToken,

    /// Whether to use HTTP/2 (only applicable for streamableHttp transport)
    @Default(false) bool useHttp2,
  }) = _McpServerToCreate;
  const McpServerToCreate._();

  /// Returns true if the name is valid
  bool get hasValidName => name.isNotEmpty;

  /// Returns true if the URL is valid
  bool get hasValidUrl => url.isNotEmpty && Uri.tryParse(url) != null;

  /// Returns true if OAuth configuration is complete
  bool get hasCompleteOAuthConfig =>
      authenticationType == McpAuthenticationType.oauth &&
      clientId != null &&
      clientId!.isNotEmpty &&
      tokenEndpoint != null &&
      tokenEndpoint!.isNotEmpty &&
      authorizationEndpoint != null &&
      authorizationEndpoint!.isNotEmpty;

  /// Returns true if bearer token is configured
  bool get hasBearerToken =>
      authenticationType == McpAuthenticationType.bearerToken &&
      bearerToken != null &&
      bearerToken!.isNotEmpty;

  /// Returns true if the configuration is valid for saving
  bool get isValid {
    if (!hasValidName || !hasValidUrl) return false;

    switch (authenticationType) {
      case McpAuthenticationType.none:
        return true;
      case McpAuthenticationType.oauth:
        return hasCompleteOAuthConfig;
      case McpAuthenticationType.bearerToken:
        return hasBearerToken;
    }
  }

  /// Returns a list of validation error messages
  List<String> get validationErrors {
    final errors = <String>[];

    if (!hasValidName) {
      errors.add('Name is required');
    }

    if (!hasValidUrl) {
      errors.add('Valid URL is required');
    }

    if (authenticationType == McpAuthenticationType.oauth) {
      if (clientId == null || clientId!.isEmpty) {
        errors.add('Client ID is required for OAuth');
      }
      if (tokenEndpoint == null || tokenEndpoint!.isEmpty) {
        errors.add('Token endpoint is required for OAuth');
      }
      if (authorizationEndpoint == null || authorizationEndpoint!.isEmpty) {
        errors.add('Authorization endpoint is required for OAuth');
      }
    }

    if (authenticationType == McpAuthenticationType.bearerToken) {
      if (bearerToken == null || bearerToken!.isEmpty) {
        errors.add('Bearer token is required');
      }
    }

    return errors;
  }
}
