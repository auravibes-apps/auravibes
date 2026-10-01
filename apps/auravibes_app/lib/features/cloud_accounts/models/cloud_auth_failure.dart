import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart';

class const CloudAuthFailure(final String localizationKey)
    implements Exception {
  static String key(Object error) => switch (error) {
    CloudAuthFailure(:final localizationKey) => localizationKey,
    EmailAccountLoginException(reason: .tooManyAttempts) =>
      LocaleKeys.cloud_accounts_too_many_attempts_error,
    EmailAccountLoginException() =>
      LocaleKeys.cloud_accounts_login_failed_error,
    EmailAccountRequestException(reason: .expired) ||
    EmailAccountPasswordResetException(
      reason: .expired,
    ) => LocaleKeys.cloud_accounts_code_expired_error,
    EmailAccountRequestException(reason: .invalid) ||
    EmailAccountPasswordResetException(
      reason: .invalid,
    ) => LocaleKeys.cloud_accounts_code_invalid_error,
    EmailAccountRequestException(reason: .policyViolation) ||
    EmailAccountPasswordResetException(
      reason: .policyViolation,
    ) => LocaleKeys.cloud_accounts_password_policy_error,
    EmailAccountRequestException(reason: .tooManyAttempts) ||
    EmailAccountPasswordResetException(
      reason: .tooManyAttempts,
    ) => LocaleKeys.cloud_accounts_too_many_attempts_error,
    _ => LocaleKeys.cloud_accounts_request_failed,
  };
}
