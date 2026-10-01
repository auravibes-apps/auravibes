import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart';

class const CloudAuthFailure(final String localizationKey)
    implements Exception {
  static String key(Object error) => switch (error) {
    CloudAuthFailure(:final localizationKey) => localizationKey,
    EmailAccountLoginException() => _loginFailureKey(error),
    EmailAccountRequestException() ||
    EmailAccountPasswordResetException() => _verificationFailureKey(error),
    _ => LocaleKeys.cloud_accounts_request_failed,
  };

  static String _loginFailureKey(Object error) => switch (error) {
    EmailAccountLoginException(reason: .tooManyAttempts) =>
      LocaleKeys.cloud_accounts_too_many_attempts_error,
    _ => LocaleKeys.cloud_accounts_login_failed_error,
  };

  static String _verificationFailureKey(Object error) => switch (error) {
    EmailAccountRequestException() => _registrationFailureKey(error),
    EmailAccountPasswordResetException() => _passwordResetFailureKey(error),
    _ => LocaleKeys.cloud_accounts_request_failed,
  };

  static String _registrationFailureKey(EmailAccountRequestException error) =>
      switch (error.reason) {
        .expired => LocaleKeys.cloud_accounts_code_expired_error,
        .invalid => LocaleKeys.cloud_accounts_code_invalid_error,
        .policyViolation => LocaleKeys.cloud_accounts_password_policy_error,
        .tooManyAttempts => LocaleKeys.cloud_accounts_too_many_attempts_error,
        _ => LocaleKeys.cloud_accounts_request_failed,
      };

  static String _passwordResetFailureKey(
    EmailAccountPasswordResetException error,
  ) => switch (error.reason) {
    .expired => LocaleKeys.cloud_accounts_code_expired_error,
    .invalid => LocaleKeys.cloud_accounts_code_invalid_error,
    .policyViolation => LocaleKeys.cloud_accounts_password_policy_error,
    .tooManyAttempts => LocaleKeys.cloud_accounts_too_many_attempts_error,
    _ => LocaleKeys.cloud_accounts_request_failed,
  };
}
