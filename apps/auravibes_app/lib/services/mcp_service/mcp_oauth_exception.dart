class const McpOAuthException(
  final String localizationKey, [
  final String? message,
]) implements Exception {
  @override
  String toString() => message ?? localizationKey;
}

class const McpOAuthDeviceCode({
  required final String verificationUrl,
  required final String userCode,
});
