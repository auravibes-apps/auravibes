import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:logging/logging.dart';

final _logger = Logger('cloud_app_exception');

enum CloudOperationContext {
  workspace,
  state,
  conversation,
  object,
  mcp,
  model,
  oauth,
  resource,
}

final class CloudAppException implements Exception {
  const CloudAppException({
    required this.localizationKey,
    required this.context,
    this.code,
  });

  final String localizationKey;
  final CloudOperationContext context;
  final String? code;

  @override
  String toString() => 'CloudAppException($context, $code)';
}

Future<T> guardCloudCall<T>(
  CloudOperationContext context,
  Future<T> Function() call,
) async {
  try {
    return await call();
  } on Object catch (error, stackTrace) {
    _logger.severe('Cloud $context operation failed', error, stackTrace);
    translateCloudException(error, context);
  }
}

String cloudErrorLocalizationKey(Object error) => switch (error) {
  CloudAppException(:final localizationKey) => localizationKey,
  UnsupportedWorkspaceCapabilityException(:final localizationKey) =>
    localizationKey,
  _ => LocaleKeys.cloud_errors_unavailable,
};

Never translateCloudException(Object error, CloudOperationContext context) {
  if (error is CloudAppException) throw error;
  final translated = switch (error) {
    CloudWorkspaceException(:final code) => (
      localizationKey: _workspaceKey(code),
      code: code.name,
    ),
    ConversationException(:final code) => (
      localizationKey: _conversationKey(code),
      code: code.name,
    ),
    ObjectException(:final code) => (
      localizationKey: _objectKey(code),
      code: code.name,
    ),
    UnsupportedWorkspaceCapabilityException() => (
      localizationKey: LocaleKeys.workspace_capabilities_unsupported_error,
      code: 'unsupportedCapability',
    ),
    TypeError() || FormatException() || StateError() || UnsupportedError() => (
      localizationKey: LocaleKeys.cloud_errors_malformed_resource,
      code: error.runtimeType.toString(),
    ),
    _ => (localizationKey: LocaleKeys.cloud_errors_unavailable, code: null),
  };
  throw CloudAppException(
    localizationKey: translated.localizationKey,
    context: context,
    code: translated.code,
  );
}

String _workspaceKey(CloudWorkspaceErrorCode code) => switch (code) {
  .authenticationRequired ||
  .emailAccountRequired => LocaleKeys.cloud_errors_authentication_required,
  .workspaceNotFound || .inviteNotFound => LocaleKeys.cloud_errors_not_found,
  .membershipRequired ||
  .permissionDenied ||
  .ownerRequired => LocaleKeys.cloud_errors_permission_denied,
  .validationFailed ||
  .invalidRole ||
  .confirmationNameMismatch ||
  .invalidCursor => LocaleKeys.cloud_errors_validation,
  .ownerCannotLeave ||
  .ownerCannotBeRemoved ||
  .ownershipTransferRequired ||
  .inviteExpired ||
  .inviteRevoked ||
  .inviteEmailMismatch ||
  .duplicateInvite ||
  .duplicateMembership ||
  .staleRevision ||
  .idempotencyConflict ||
  .conflict => LocaleKeys.cloud_errors_conflict,
};

String _conversationKey(ConversationErrorCode code) => switch (code) {
  .authenticationRequired => LocaleKeys.cloud_errors_authentication_required,
  .permissionDenied => LocaleKeys.cloud_errors_permission_denied,
  .notFound => LocaleKeys.cloud_errors_not_found,
  .validationFailed => LocaleKeys.cloud_errors_validation,
  .staleRevision ||
  .idempotencyConflict ||
  .turnConflict ||
  .toolDecisionConflict => LocaleKeys.cloud_errors_conflict,
};

String _objectKey(ObjectErrorCode code) => switch (code) {
  .objectNotFound => LocaleKeys.cloud_errors_not_found,
  .invalidRequest ||
  .unsupportedMediaType ||
  .sizeLimitExceeded ||
  .uploadExpired ||
  .uploadMismatch ||
  .scanInfected => LocaleKeys.cloud_errors_validation,
  .staleRevision ||
  .idempotencyConflict ||
  .objectReferenced => LocaleKeys.cloud_errors_conflict,
  .configurationMissing || .scanFailed => LocaleKeys.cloud_errors_unavailable,
};
