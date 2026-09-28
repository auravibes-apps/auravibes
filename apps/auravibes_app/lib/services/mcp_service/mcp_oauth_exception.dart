import 'package:auravibes_app/i18n/locale_keys.dart';

class const McpOAuthException(
  final String localizationKey, [
  final String? message,
]) implements Exception {
  bool get tokenExpired =>
      localizationKey == LocaleKeys.mcp_modal_oauth_expired;

  @override
  String toString() => message ?? localizationKey;
}

class const McpOAuthDeviceCode({
  required final String verificationUrl,
  required final String userCode,
});
