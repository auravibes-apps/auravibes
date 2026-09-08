import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_login_form.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verification errors retain precedence and login distinction', () {
    const cases = {
      'policyViolation expired':
          LocaleKeys.cloud_accounts_password_policy_error,
      'expired tooManyAttempts': LocaleKeys.cloud_accounts_code_expired_error,
      'tooManyAttempts invalid':
          LocaleKeys.cloud_accounts_too_many_attempts_error,
      'invalid SocketException': LocaleKeys.cloud_accounts_code_invalid_error,
    };
    for (final entry in cases.entries) {
      expect(cloudAccountCodeErrorKey(StateError(entry.key)), entry.value);
    }
    expect(
      cloudAccountErrorKey(StateError('invalid')),
      LocaleKeys.cloud_accounts_login_failed_error,
    );
  });

  test('verification errors reuse network and generic fallbacks', () {
    const cases = {
      'SocketException': LocaleKeys.cloud_accounts_server_unreachable_error,
      'Connection refused': LocaleKeys.cloud_accounts_server_unreachable_error,
      'Failed host lookup': LocaleKeys.cloud_accounts_server_unreachable_error,
      'server is not configured':
          LocaleKeys.cloud_accounts_server_unreachable_error,
      'Unauthorized': LocaleKeys.cloud_accounts_login_failed_error,
      'unauthorized': LocaleKeys.cloud_accounts_login_failed_error,
      'authentication': LocaleKeys.cloud_accounts_login_failed_error,
      'unknown': LocaleKeys.cloud_accounts_request_failed,
    };
    for (final entry in cases.entries) {
      final error = StateError(entry.key);
      expect(cloudAccountCodeErrorKey(error), entry.value);
      expect(cloudAccountErrorKey(error), entry.value);
    }
  });
}
