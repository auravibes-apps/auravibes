// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_form_state.freezed.dart';
part 'mcp_form_state.g.dart';

final _logger = Logger('mcp_form');

/// State for the MCP form.
@Freezed(toStringOverride: false)
abstract class const McpFormState._() with _$McpFormState {
  const factory({
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

  /// Whether to show bearer token field.
  bool get showBearerTokenField => authenticationType == .bearerToken;

  /// Check if the form is valid.
  bool get isValid => toCreateEntity().isValid;

  /// Get validation errors.
  List<String> get validationErrors => toCreateEntity().validationErrors;

  /// Convert to McpServerToCreate for validation and saving.
  McpServerFormToCreate toCreateEntity() {
    return McpServerFormToCreate(
      name: name.trim(),
      url: url.trim(),
      transport: toTransportType(),
      authenticationType: authenticationType,
      bearerToken: normalizedBearerToken(),
      description: normalizedDescription(),
    );
  }

  /// Return the bearer token with surrounding whitespace removed.
  String? normalizedBearerToken() =>
      bearerToken.trim().isEmpty ? null : bearerToken.trim();

  /// Return the description with surrounding whitespace removed.
  String? normalizedDescription() =>
      description.trim().isEmpty ? null : description.trim();
}

extension McpFormStateExtensions on McpFormState {
  /// Get available authentication types based on current transport.
  List<McpAuthenticationTypeOptions> get availableAuthTypes {
    switch (transport) {
      case .sse:
        // SSE supports: none, oauth, bearer token.
        return McpAuthenticationTypeOptions.values;
      case .streamableHttp:
        // Streamable HTTP supports: none, oauth (no bearer token).
        return [
          McpAuthenticationTypeOptions.none,
          McpAuthenticationTypeOptions.oauth,
        ];
    }
  }

  /// Whether to show OAuth fields.
  bool get showOAuthFields => authenticationType == .oauth;

  /// Convert the selected transport option to its entity type.
  McpTransportType toTransportType() {
    switch (transport) {
      case .streamableHttp:
        return const McpTransportTypeStreamableHttp();
      case .sse:
        return const McpTransportTypeSSE();
    }
  }

  /// Whether the selected authentication type is available for this transport.
  bool isAuthenticationTypeAvailable(McpAuthenticationTypeOptions value) =>
      availableAuthTypes.contains(value);
}

/// Notifier for managing MCP form state.
@riverpod
class McpFormNotifier extends _$McpFormNotifier {
  String _workspaceId = '';

  McpFormState get _formState => state;

  WorkspaceCapabilities get _capabilities => ref
      .read(workspaceSessionForRouteProvider(_workspaceId))
      .requireValue
      .capabilities;

  set _formState(McpFormState value) => state = value;

  @override
  McpFormState build(String workspaceId) {
    _workspaceId = workspaceId;

    return const McpFormState();
  }

  Future<bool> submit() => _submitMcpForm(this);

  Future<void> _addMcpServer() => ref
      .read(mcpConnectionProvider.notifier)
      .addMcpServer(_formState.toCreateEntity(), workspaceId: _workspaceId);
}

extension McpFormNotifierConnectionActions on McpFormNotifier {
  /// Update the transport type.
  void setTransport(McpTransportTypeOptions? value) {
    if (value == null) return;
    _requireTransportCapability(value);
    _formState = _nextTransportState(value);
  }

  /// Update the authentication type.
  void setAuthenticationType(McpAuthenticationTypeOptions value) {
    _requireAuthenticationCapability(value);
    _formState = _formState.copyWith(authenticationType: value);
  }
}

extension McpFormNotifierFieldActions on McpFormNotifier {
  /// Update the name field.
  void setName(String value) => _formState = _formState.copyWith(name: value);

  /// Update the description field.
  void setDescription(String value) =>
      _formState = _formState.copyWith(description: value);

  /// Update the URL field.
  void setUrl(String value) => _formState = _formState.copyWith(url: value);

  /// Update the bearer token field.
  void setBearerToken(String value) =>
      _formState = _formState.copyWith(bearerToken: value);

  /// Update the HTTP/2 toggle.
  void setUseHttp2({required bool value}) =>
      _formState = _formState.copyWith(useHttp2: value);

  /// Set submitting state.
  void setSubmitting({required bool value}) =>
      _formState = _formState.copyWith(isSubmitting: value);

  /// Set error message.
  void setError(String message) {
    _logger.warning(
      'MCP form error workspace=$_workspaceId '
      'transport=${_formState.transport.name} '
      'auth=${_formState.authenticationType.name}',
    );
    _formState = _formState.copyWith(errorMessage: message);
  }

  /// Clear the error message.
  void clearError() => _formState = _formState.copyWith(errorMessage: null);
}

Future<bool> _submitMcpForm(McpFormNotifier notifier) async {
  notifier._requireCapabilities();
  if (!notifier._formState.isValid) {
    return notifier._rejectInvalidForm();
  }

  notifier
    ..setSubmitting(value: true)
    ..clearError();
  try {
    await notifier._addMcpServer();

    return notifier._completeSubmission();
  } on Exception catch (error, stackTrace) {
    return notifier._rejectSubmission(error, stackTrace);
  }
}

extension McpFormNotifierCapabilityChecks on McpFormNotifier {
  void _requireCapabilities() {
    _requireTransportCapability();
    _requireAuthenticationCapability();
  }

  void _requireTransportCapability([McpTransportTypeOptions? value]) {
    final capabilities = _capabilities;
    capabilities.require(
      supported: capabilities.mcpTransports.contains(
        _mcpTransportCapability(value ?? _formState.transport),
      ),
    );
  }

  void _requireAuthenticationCapability([McpAuthenticationTypeOptions? value]) {
    final capabilities = _capabilities;
    capabilities.require(
      supported: capabilities.mcpAuthentication.contains(
        _mcpAuthenticationCapability(value ?? _formState.authenticationType),
      ),
    );
  }

  McpFormState _nextTransportState(McpTransportTypeOptions value) {
    var newState = _formState.copyWith(transport: value);
    if (value != .streamableHttp) {
      newState = newState.copyWith(useHttp2: false);
    }
    if (!newState.isAuthenticationTypeAvailable(newState.authenticationType)) {
      newState = newState.copyWith(authenticationType: .none);
    }

    return newState;
  }
}

extension McpFormNotifierSubmitFailureActions on McpFormNotifier {
  bool _rejectInvalidForm() {
    setError(_formState.validationErrors.join('\n'));

    return false;
  }

  bool _completeSubmission() {
    setSubmitting(value: false);

    return true;
  }

  bool _rejectSubmission(Exception error, StackTrace stackTrace) {
    _logSubmissionFailure(error, stackTrace);
    setError(LocaleKeys.tools_screen_mcp_error);
    setSubmitting(value: false);

    return false;
  }

  void _logSubmissionFailure(Exception error, StackTrace stackTrace) {
    _logger.severe(
      'MCP form submit failed workspace=$_workspaceId '
      'transport=${_formState.transport.name} '
      'auth=${_formState.authenticationType.name}',
      error,
      stackTrace,
    );
  }
}

WorkspaceMcpTransport _mcpTransportCapability(McpTransportTypeOptions value) =>
    switch (value) {
      .streamableHttp => .streamableHttp,
      .sse => .sse,
    };

WorkspaceMcpAuthentication _mcpAuthenticationCapability(
  McpAuthenticationTypeOptions value,
) => switch (value) {
  .none => .none,
  .bearerToken => .bearerToken,
  .oauth => .oauth,
};
