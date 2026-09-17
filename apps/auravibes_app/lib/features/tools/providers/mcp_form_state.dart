import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/log_redaction.dart';
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
    @Default(false) bool isTestingConnection,
    @Default(false) bool isConnectionVerified,
    @Default(0) int verifiedToolCount,
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
        return McpTransportTypeStreamableHttp(useHttp2: useHttp2);
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
  String? _verificationId;
  Timer? _verificationExpiryTimer;
  var _connectionVersion = 0;
  var _isDisposed = false;

  McpFormState get _formState => state;

  bool get _hasVerification =>
      _verificationId != null && _formState.isConnectionVerified;

  String? get _currentVerificationId => _verificationId;

  WorkspaceCapabilities get _capabilities => ref
      .read(workspaceSessionForRouteProvider(_workspaceId))
      .requireValue
      .capabilities;

  set _formState(McpFormState value) => state = value;

  @override
  McpFormState build(String workspaceId) {
    _workspaceId = workspaceId;
    _isDisposed = false;
    final _ = ref.onDispose(() => _disposeMcpFormNotifier(this));

    return const McpFormState();
  }

  Future<bool> submit() => _submitMcpForm(this);

  Future<bool> testConnection() => _testMcpFormConnection(this);

  Future<T> _runMcpConnection<T>(
    Future<T> Function(
      McpConnectionNotifier connection,
      McpFormNotifier notifier,
      String? verificationId,
    )
    operation, {
    String? verificationId,
  }) =>
      operation(ref.read(mcpConnectionProvider.notifier), this, verificationId);

  Future<void> _discardPreparedVerification(String verificationId) async {
    try {
      await ref
          .read(mcpConnectionProvider.notifier)
          .discardPreparedMcpConnection(verificationId);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'MCP verification cleanup failed workspace=$_workspaceId',
        LogRedaction.redact(error.toString()),
        stackTrace,
      );
    }
  }
}

extension McpFormNotifierWorkflowActions on McpFormNotifier {
  void _invalidateConnectionVerification() {
    _connectionVersion++;
    _clearVerification();
  }

  void _clearVerification({bool discard = true}) {
    final verificationId = _verificationId;
    _verificationId = null;
    _verificationExpiryTimer?.cancel();
    _verificationExpiryTimer = null;
    if (discard && verificationId != null) {
      unawaited(_discardPreparedVerification(verificationId));
    }
    if (_formState.isConnectionVerified || _formState.verifiedToolCount != 0) {
      _formState = _formState.copyWith(
        isConnectionVerified: false,
        verifiedToolCount: 0,
      );
    }
  }

  void _expireVerification(String verificationId) {
    if (_verificationId != verificationId) return;
    _connectionVersion++;
    _verificationId = null;
    _verificationExpiryTimer?.cancel();
    _verificationExpiryTimer = null;
    unawaited(_discardPreparedVerification(verificationId));
    if (_isDisposed) return;
    _formState = _formState.copyWith(
      isConnectionVerified: false,
      verifiedToolCount: 0,
      errorMessage: LocaleKeys.mcp_modal_verification_expired,
    );
  }
}

extension McpFormNotifierConnectionActions on McpFormNotifier {
  /// Update the transport type.
  void setTransport(McpTransportTypeOptions? value) {
    if (value == null) return;
    _requireTransportCapability(value);
    if (value == _formState.transport) return;
    _formState = _nextTransportState(value);
    _invalidateConnectionVerification();
  }

  /// Update the authentication type.
  void setAuthenticationType(McpAuthenticationTypeOptions value) {
    _requireAuthenticationCapability(value);
    if (value == _formState.authenticationType) return;
    _formState = _formState.copyWith(authenticationType: value);
    _invalidateConnectionVerification();
  }
}

extension McpFormNotifierFieldActions on McpFormNotifier {
  /// Update the name field.
  void setName(String value) => _formState = _formState.copyWith(name: value);

  /// Update the description field.
  void setDescription(String value) =>
      _formState = _formState.copyWith(description: value);

  /// Update the URL field.
  void setUrl(String value) {
    if (value == _formState.url) return;
    _formState = _formState.copyWith(url: value);
    _invalidateConnectionVerification();
  }

  /// Update the bearer token field.
  void setBearerToken(String value) {
    if (value == _formState.bearerToken) return;
    _formState = _formState.copyWith(bearerToken: value);
    _invalidateConnectionVerification();
  }

  /// Update the HTTP/2 toggle.
  void setUseHttp2({required bool value}) {
    if (value == _formState.useHttp2) return;
    _formState = _formState.copyWith(useHttp2: value);
    _invalidateConnectionVerification();
  }
}

void _setMcpSubmitting(McpFormNotifier notifier, {required bool value}) =>
    notifier._formState = notifier._formState.copyWith(isSubmitting: value);

void _setMcpTesting(McpFormNotifier notifier, {required bool value}) =>
    notifier._formState = notifier._formState.copyWith(
      isTestingConnection: value,
    );

void _setMcpError(McpFormNotifier notifier, String message) {
  _logger.warning(
    'MCP form error workspace=${notifier._workspaceId} '
    'transport=${notifier._formState.transport.name} '
    'auth=${notifier._formState.authenticationType.name}',
  );
  notifier._formState = notifier._formState.copyWith(errorMessage: message);
}

void _clearMcpError(McpFormNotifier notifier) =>
    notifier._formState = notifier._formState.copyWith(errorMessage: null);

Future<bool> _submitMcpForm(McpFormNotifier notifier) {
  notifier._requireCapabilities();
  if (_mcpFormBusy(notifier)) return Future.value(false);
  if (!notifier._formState.isValid) {
    return Future.value(notifier._rejectInvalidForm());
  }
  final verificationId = notifier._currentVerificationId;
  if (!notifier._hasVerification || verificationId == null) {
    _setMcpError(notifier, LocaleKeys.mcp_modal_verification_required);

    return Future.value(false);
  }

  return _runMcpFormSubmit(notifier, verificationId);
}

Future<bool> _testMcpFormConnection(McpFormNotifier notifier) {
  notifier._requireCapabilities();
  if (_mcpFormBusy(notifier)) return Future.value(false);
  if (!notifier._formState.isValid) {
    return Future.value(notifier._rejectInvalidForm());
  }

  return _runMcpFormConnectionTest(notifier);
}

bool _mcpFormBusy(McpFormNotifier notifier) =>
    notifier._formState.isSubmitting || notifier._formState.isTestingConnection;

Future<bool> _runMcpFormSubmit(
  McpFormNotifier notifier,
  String verificationId,
) async {
  _setMcpSubmitting(notifier, value: true);
  _clearMcpError(notifier);
  try {
    await notifier._runMcpConnection<void>(
      _commitMcpFormConnection,
      verificationId: verificationId,
    );

    return notifier._completeSubmission();
  } on Exception catch (error, stackTrace) {
    return notifier._rejectSubmission(error, stackTrace);
  }
}

Future<bool> _runMcpFormConnectionTest(McpFormNotifier notifier) async {
  notifier._invalidateConnectionVerification();
  final connectionVersion = notifier._connectionVersion;
  _setMcpTesting(notifier, value: true);
  _clearMcpError(notifier);
  try {
    final verification = await notifier
        ._runMcpConnection<McpConnectionVerification>(
          _prepareMcpFormConnection,
        );

    return await _finishMcpFormConnectionTest(
      notifier,
      verification,
      connectionVersion,
    );
  } on Object catch (error, stackTrace) {
    return notifier._rejectConnectionTest(error, stackTrace);
  }
}

Future<void> _commitMcpFormConnection(
  McpConnectionNotifier connection,
  McpFormNotifier notifier,
  String? verificationId,
) async {
  if (verificationId == null) {
    throw const McpVerificationRequiredException();
  }
  await connection.commitPreparedMcpConnection(
    notifier._formState.toCreateEntity(),
    workspaceId: notifier._workspaceId,
    verificationId: verificationId,
  );
}

Future<McpConnectionVerification> _prepareMcpFormConnection(
  McpConnectionNotifier connection,
  McpFormNotifier notifier,
  String? _,
) => connection.prepareMcpConnection(
  notifier._formState.toCreateEntity(),
  workspaceId: notifier._workspaceId,
);

Future<bool> _finishMcpFormConnectionTest(
  McpFormNotifier notifier,
  McpConnectionVerification verification,
  int connectionVersion,
) async {
  if (notifier._isDisposed ||
      connectionVersion != notifier._connectionVersion) {
    await notifier._discardPreparedVerification(verification.id);
    _setMcpTesting(notifier, value: false);

    return false;
  }

  final verified = _setMcpVerification(notifier, verification);
  _setMcpTesting(notifier, value: false);

  return verified;
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
    _setMcpError(this, _formState.validationErrors.join('\n'));

    return false;
  }

  bool _completeSubmission() {
    _clearVerification(discard: false);
    _setMcpSubmitting(this, value: false);

    return true;
  }

  bool _rejectSubmission(Exception error, StackTrace stackTrace) {
    _logSubmissionFailure(error, stackTrace);
    if (error is McpVerificationRequiredException) {
      _clearVerification(discard: false);
      _setMcpError(this, LocaleKeys.mcp_modal_verification_required);
    } else {
      _setMcpError(this, LocaleKeys.tools_screen_mcp_error);
    }
    _setMcpSubmitting(this, value: false);

    return false;
  }

  void _logSubmissionFailure(Exception error, StackTrace stackTrace) {
    _logger.severe(
      'MCP form submit failed workspace=$_workspaceId '
      'transport=${_formState.transport.name} '
      'auth=${_formState.authenticationType.name}',
      LogRedaction.redact(error.toString()),
      stackTrace,
    );
  }
}

extension McpFormNotifierConnectionTestActions on McpFormNotifier {
  bool _rejectConnectionTest(Object error, StackTrace stackTrace) {
    if (_isDisposed) return false;
    _logger.warning(
      'MCP form connection test failed workspace=$_workspaceId '
      'transport=${_formState.transport.name} '
      'auth=${_formState.authenticationType.name}',
      LogRedaction.redact(error.toString()),
      stackTrace,
    );
    _clearVerification(discard: false);
    _setMcpError(this, _redactedConnectionTestError(error));
    _setMcpTesting(this, value: false);

    return false;
  }
}

void _disposeMcpFormNotifier(McpFormNotifier notifier) {
  notifier._isDisposed = true;
  notifier._verificationExpiryTimer?.cancel();
  notifier._verificationExpiryTimer = null;
  final verificationId = notifier._verificationId;
  notifier._verificationId = null;
  if (verificationId != null) {
    unawaited(notifier._discardPreparedVerification(verificationId));
  }
}

bool _setMcpVerification(
  McpFormNotifier notifier,
  McpConnectionVerification verification,
) {
  final remaining = verification.expiresAt.difference(DateTime.now().toUtc());
  notifier._verificationId = verification.id;
  if (remaining <= .zero) {
    notifier._expireVerification(verification.id);

    return false;
  }
  _scheduleMcpVerificationExpiry(notifier, verification.id, remaining);
  _markMcpVerification(notifier, verification.toolCount);

  return true;
}

void _scheduleMcpVerificationExpiry(
  McpFormNotifier notifier,
  String verificationId,
  Duration remaining,
) {
  notifier._verificationExpiryTimer?.cancel();
  notifier._verificationExpiryTimer = .new(
    remaining,
    () => notifier._expireVerification(verificationId),
  );
}

void _markMcpVerification(McpFormNotifier notifier, int toolCount) {
  notifier._formState = notifier._formState.copyWith(
    isConnectionVerified: true,
    verifiedToolCount: toolCount,
  );
}

String _redactedConnectionTestError(Object error) {
  final message = LogRedaction.redact(error.toString()).trim();
  if (message.isEmpty || message == 'Exception') {
    return LocaleKeys.tools_screen_mcp_error;
  }

  return message;
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
