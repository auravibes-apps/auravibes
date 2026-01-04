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
    @Default(McpTransportTypeOptions.streamableHttp)
    McpTransportTypeOptions transport,
    @Default(McpAuthenticationTypeOptions.none)
    McpAuthenticationTypeOptions authenticationType,
    @Default('') String bearerToken,
    @Default(false) bool useHttp2,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _McpFormState;

  const McpFormState._();

  /// Get available authentication types based on current transport
  List<McpAuthenticationTypeOptions> get availableAuthTypes {
    switch (transport) {
      case .sse:
        // SSE supports: none, oauth, bearer token
        return McpAuthenticationTypeOptions.values;
      case .streamableHttp:
        // Streamable HTTP supports: none, oauth (no bearer token)
        return [
          McpAuthenticationTypeOptions.none,
          McpAuthenticationTypeOptions.oauth,
        ];
    }
  }

  /// Whether to show OAuth fields
  bool get showOAuthFields => authenticationType == .oauth;

  /// Whether to show bearer token field
  bool get showBearerTokenField => authenticationType == .bearerToken;

  /// Whether to show HTTP/2 toggle
  bool get showHttp2Toggle => transport == .streamableHttp;

  /// Convert to McpServerToCreate for validation and saving
  McpServerFormToCreate toCreateEntity() {
    return McpServerFormToCreate(
      name: name.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      url: url.trim(),
      transport: _tranport(),
      authenticationType: authenticationType,
      bearerToken: bearerToken.trim().isEmpty ? null : bearerToken.trim(),
    );
  }

  McpTransportType _tranport() {
    switch (transport) {
      case McpTransportTypeOptions.streamableHttp:
        return McpTransportTypeStreamableHttp(useHttp2: useHttp2);
      case McpTransportTypeOptions.sse:
        return const McpTransportTypeSSE();
    }
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
  void setTransport(McpTransportTypeOptions? value) {
    if (value == null) return;
    var newState = state.copyWith(transport: value);

    // Reset HTTP/2 when switching away from streamableHttp
    if (value != .streamableHttp) {
      newState = newState.copyWith(useHttp2: false);
    }

    // Reset auth type if current selection is not available for new transport
    final availableTypes = newState.availableAuthTypes;
    if (!availableTypes.contains(newState.authenticationType)) {
      newState = newState.copyWith(
        authenticationType: .none,
      );
    }

    state = newState;
  }

  /// Update the authentication type
  void setAuthenticationType(McpAuthenticationTypeOptions value) {
    state = state.copyWith(authenticationType: value);
  }

  /// Update the bearer token field
  void setBearerToken(String value) {
    state = state.copyWith(bearerToken: value);
  }

  /// Update the HTTP/2 toggle
  // ignore: avoid_positional_boolean_parameters
  void setUseHttp2(bool value) {
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
