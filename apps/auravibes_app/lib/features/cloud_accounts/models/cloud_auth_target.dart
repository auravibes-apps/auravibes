import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';

/// Immutable owner of ephemeral authentication inputs.
class const CloudAuthTarget({
  final String? serverUrl,
  final String? accountId,
  final String? email,
  final bool isValid = true,
}) {
  factory fromQuery(Map<String, String> query) {
    try {
      final server = _compatible(
        query,
        'serverUrl',
        'server-url',
        origin: true,
      );
      final account = _compatible(query, 'accountId', 'account-id');
      if (account != null && server == null) {
        return const CloudAuthTarget(isValid: false);
      }

      return CloudAuthTarget(
        serverUrl: server,
        accountId: account,
        email: query['email']?.isEmpty ?? true ? null : query['email'],
      );
    } on FormatException {
      return const CloudAuthTarget(isValid: false);
    }
  }

  String get origin => _origin(serverUrl ?? AppEnvConfig.auravibesServerUrl);
  ({String? serverUrl, String? accountId, String? email, bool isValid})
  get owner => (
    serverUrl: serverUrl,
    accountId: accountId,
    email: email,
    isValid: isValid,
  );

  String? get configuredOrigin {
    try {
      return origin;
    } on FormatException {
      return null;
    }
  }

  CloudAuthTarget withEmail(String value) => CloudAuthTarget(
    serverUrl: serverUrl,
    accountId: accountId,
    email: value,
    isValid: isValid,
  );

  static String? _compatible(
    Map<String, String> query,
    String legacy,
    String generated, {
    bool origin = false,
  }) {
    String? normalize(String? value) {
      if (value == null) return null;

      return origin ? _origin(value) : value;
    }

    final first = normalize(query[legacy]);
    final second = normalize(query[generated]);
    if (first != null && second != null && first != second) {
      throw const FormatException('Conflicting authentication context');
    }

    return first ?? second;
  }

  static String _origin(String value) {
    final uri = Uri.parse(value);
    if (!['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Invalid authentication origin');
    }

    return CloudAccountIdentity.canonicalServerOrigin(value);
  }
}
