import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_operation_context.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:logging/logging.dart';

export 'cloud_operation_context.dart';

final _logger = Logger('cloud_app_exception');

final class const CloudAppException({
  required final String localizationKey,
  required final CloudOperationContext context,
  final String? code,
}) implements Exception {
  @override
  String toString() => 'CloudAppException($context, $code)';
}

abstract final class CloudAppErrors {
  static Future<T> guardCall<T>(
    CloudOperationContext context,
    Future<T> Function() call,
  ) async {
    try {
      return await call();
    } on Object catch (error, stackTrace) {
      _logger.severe('Cloud $context operation failed', error, stackTrace);
      translateException(error, context);
    }
  }

  static String localizationKey(Object error) => switch (error) {
    CloudAppException(:final localizationKey) => localizationKey,
    UnsupportedWorkspaceCapabilityException(:final localizationKey) =>
      localizationKey,
    _ => LocaleKeys.cloud_errors_unavailable,
  };

  static Never translateException(Object error, CloudOperationContext context) {
    if (error is CloudAppException) throw error;
    final translated = _translatedException(error);
    throw CloudAppException(
      localizationKey: translated.localizationKey,
      context: context,
      code: translated.code,
    );
  }

  static ({String localizationKey, String? code}) _translatedException(
    Object error,
  ) => switch (error) {
    CloudWorkspaceException(:final code) => _workspaceTranslation(code),
    ConversationException(:final code) => _conversationTranslation(code),
    ObjectException(:final code) => _objectTranslation(code),
    UnsupportedWorkspaceCapabilityException() => (
      localizationKey: LocaleKeys.workspace_capabilities_unsupported_error,
      code: 'unsupportedCapability',
    ),
    TypeError() ||
    FormatException() ||
    StateError() ||
    UnsupportedError() => _malformedTranslation(error),
    _ => (localizationKey: LocaleKeys.cloud_errors_unavailable, code: null),
  };

  static ({String localizationKey, String? code}) _workspaceTranslation(
    CloudWorkspaceErrorCode code,
  ) => (localizationKey: _workspaceKey(code), code: code.name);

  static ({String localizationKey, String? code}) _conversationTranslation(
    ConversationErrorCode code,
  ) => (localizationKey: _conversationKey(code), code: code.name);

  static ({String localizationKey, String? code}) _objectTranslation(
    ObjectErrorCode code,
  ) => (localizationKey: _objectKey(code), code: code.name);

  static ({String localizationKey, String? code}) _malformedTranslation(
    Object error,
  ) => (
    localizationKey: LocaleKeys.cloud_errors_malformed_resource,
    code: error.runtimeType.toString(),
  );
}

const _workspaceLocalizationKeys = <CloudWorkspaceErrorCode, String>{
  .authenticationRequired: LocaleKeys.cloud_errors_authentication_required,
  .emailAccountRequired: LocaleKeys.cloud_errors_authentication_required,
  .workspaceNotFound: LocaleKeys.cloud_errors_not_found,
  .inviteNotFound: LocaleKeys.cloud_errors_not_found,
  .membershipRequired: LocaleKeys.cloud_errors_permission_denied,
  .permissionDenied: LocaleKeys.cloud_errors_permission_denied,
  .ownerRequired: LocaleKeys.cloud_errors_permission_denied,
  .validationFailed: LocaleKeys.cloud_errors_validation,
  .invalidRole: LocaleKeys.cloud_errors_validation,
  .confirmationNameMismatch: LocaleKeys.cloud_errors_validation,
  .invalidCursor: LocaleKeys.cloud_errors_validation,
  .ownerCannotLeave: LocaleKeys.cloud_errors_conflict,
  .ownerCannotBeRemoved: LocaleKeys.cloud_errors_conflict,
  .ownershipTransferRequired: LocaleKeys.cloud_errors_conflict,
  .inviteExpired: LocaleKeys.cloud_errors_conflict,
  .inviteRevoked: LocaleKeys.cloud_errors_conflict,
  .inviteEmailMismatch: LocaleKeys.cloud_errors_conflict,
  .duplicateInvite: LocaleKeys.cloud_errors_conflict,
  .duplicateMembership: LocaleKeys.cloud_errors_conflict,
  .staleRevision: LocaleKeys.cloud_errors_conflict,
  .idempotencyConflict: LocaleKeys.cloud_errors_conflict,
  .conflict: LocaleKeys.cloud_errors_conflict,
};

String _workspaceKey(CloudWorkspaceErrorCode code) =>
    _workspaceLocalizationKeys[code]!;

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

const _objectLocalizationKeys = <ObjectErrorCode, String>{
  .objectNotFound: LocaleKeys.cloud_errors_not_found,
  .invalidRequest: LocaleKeys.cloud_errors_validation,
  .unsupportedMediaType: LocaleKeys.cloud_errors_validation,
  .sizeLimitExceeded: LocaleKeys.cloud_errors_validation,
  .uploadExpired: LocaleKeys.cloud_errors_validation,
  .uploadMismatch: LocaleKeys.cloud_errors_validation,
  .scanInfected: LocaleKeys.cloud_errors_validation,
  .staleRevision: LocaleKeys.cloud_errors_conflict,
  .idempotencyConflict: LocaleKeys.cloud_errors_conflict,
  .objectReferenced: LocaleKeys.cloud_errors_conflict,
  .configurationMissing: LocaleKeys.cloud_errors_unavailable,
  .scanFailed: LocaleKeys.cloud_errors_unavailable,
};

String _objectKey(ObjectErrorCode code) => _objectLocalizationKeys[code]!;
