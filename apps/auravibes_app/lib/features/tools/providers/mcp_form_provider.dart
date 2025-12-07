import 'package:auravibes_app/domain/entities/mcp_server.dart';
import 'package:auravibes_app/providers/mcp_manager_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_form_provider.freezed.dart';
part 'mcp_form_provider.g.dart';

/// State for the MCP form
@freezed
abstract class McpFormState with _$McpFormState {
  const factory McpFormState({
    @Default('') String name,
    @Default('') String description,
    @Default('') String url,
    @Default(McpTransportType.sse) McpTransportType transport,
    @Default(McpAuthenticationType.none)
    McpAuthenticationType authenticationType,
    @Default('') String clientId,
    @Default('') String tokenEndpoint,
    @Default('') String authorizationEndpoint,
    @Default('') String bearerToken,
    @Default(false) bool useHttp2,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _McpFormState;

  const McpFormState._();

  /// Get available authentication types based on current transport
  List<McpAuthenticationType> get availableAuthTypes {
    switch (transport) {
      case McpTransportType.sse:
        // SSE supports: none, oauth, bearer token
        return McpAuthenticationType.values;
      case McpTransportType.streamableHttp:
        // Streamable HTTP supports: none, oauth (no bearer token)
        return [
          McpAuthenticationType.none,
          McpAuthenticationType.oauth,
        ];
    }
  }

  /// Whether to show OAuth fields
  bool get showOAuthFields => authenticationType == McpAuthenticationType.oauth;

  /// Whether to show bearer token field
  bool get showBearerTokenField =>
      authenticationType == McpAuthenticationType.bearerToken;

  /// Whether to show HTTP/2 toggle
  bool get showHttp2Toggle => transport == McpTransportType.streamableHttp;

  /// Convert to McpServerToCreate for validation and saving
  McpServerToCreate toCreateEntity() {
    return McpServerToCreate(
      name: name.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      url: url.trim(),
      transport: transport,
      authenticationType: authenticationType,
      clientId: clientId.trim().isEmpty ? null : clientId.trim(),
      tokenEndpoint: tokenEndpoint.trim().isEmpty ? null : tokenEndpoint.trim(),
      authorizationEndpoint: authorizationEndpoint.trim().isEmpty
          ? null
          : authorizationEndpoint.trim(),
      bearerToken: bearerToken.trim().isEmpty ? null : bearerToken.trim(),
      useHttp2: useHttp2,
    );
  }

  /// Check if the form is valid
  bool get isValid => toCreateEntity().isValid;

  /// Get validation errors
  List<String> get validationErrors => toCreateEntity().validationErrors;
}

/// Notifier for managing MCP form state
@riverpod
class McpFormNotifier extends _$McpFormNotifier {
  @override
  McpFormState build() {
    return const McpFormState();
  }

  /// Update the name field
  void setName(String value) {
    state = state.copyWith(name: value);
  }

  /// Update the description field
  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  /// Update the URL field
  void setUrl(String value) {
    state = state.copyWith(url: value);
  }

  /// Update the transport type
  void setTransport(McpTransportType value) {
    var newState = state.copyWith(transport: value);

    // Reset HTTP/2 when switching away from streamableHttp
    if (value != McpTransportType.streamableHttp) {
      newState = newState.copyWith(useHttp2: false);
    }

    // Reset auth type if current selection is not available for new transport
    final availableTypes = newState.availableAuthTypes;
    if (!availableTypes.contains(newState.authenticationType)) {
      newState = newState.copyWith(
        authenticationType: McpAuthenticationType.none,
      );
    }

    state = newState;
  }

  /// Update the authentication type
  void setAuthenticationType(McpAuthenticationType value) {
    state = state.copyWith(authenticationType: value);
  }

  /// Update the client ID field
  void setClientId(String value) {
    state = state.copyWith(clientId: value);
  }

  /// Update the token endpoint field
  void setTokenEndpoint(String value) {
    state = state.copyWith(tokenEndpoint: value);
  }

  /// Update the authorization endpoint field
  void setAuthorizationEndpoint(String value) {
    state = state.copyWith(authorizationEndpoint: value);
  }

  /// Update the bearer token field
  void setBearerToken(String value) {
    state = state.copyWith(bearerToken: value);
  }

  /// Update the HTTP/2 toggle
  void setUseHttp2({required bool value}) {
    state = state.copyWith(useHttp2: value);
  }

  /// Set submitting state
  void setSubmitting({required bool value}) {
    state = state.copyWith(isSubmitting: value);
  }

  /// Set error message
  void setError(String? message) {
    state = state.copyWith(errorMessage: message);
  }

  /// Clear the error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset the form to initial state
  void reset() {
    state = const McpFormState();
  }

  /// Submit the form
  ///
  /// Validates the form and submits to the MCP manager to:
  /// 1. Save the MCP server to the database (TODO)
  /// 2. Connect to the MCP server
  /// 3. Load and register the MCP's tools
  Future<bool> submit() async {
    if (!state.isValid) {
      setError(state.validationErrors.join('\n'));
      return false;
    }

    setSubmitting(value: true);
    clearError();

    try {
      final mcpToCreate = state.toCreateEntity();
      await ref.read(mcpManagerProvider.notifier).addMcpServer(mcpToCreate);

      setSubmitting(value: false);
      return true;
    } on Exception catch (e) {
      setError('Error: $e');
      setSubmitting(value: false);
      return false;
    }
  }
}
