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
      return CloudAuthTarget._fromQueryValues(query);
    } on FormatException {
      return const CloudAuthTarget(isValid: false);
    }
  }

  factory _fromQueryValues(Map<String, String> query) {
    final values = _compatibleQueryValues(query);
    if (values.accountId != null && values.serverUrl == null) {
      return const CloudAuthTarget(isValid: false);
    }

    return CloudAuthTarget(
      serverUrl: values.serverUrl,
      accountId: values.accountId,
      email: _cloudAuthTargetQueryEmail(query),
    );
  }

  String get origin =>
      _cloudAuthTargetOrigin(serverUrl ?? AppEnvConfig.auravibesServerUrl);
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

  bool matchesAuthenticatedIdentity({
    required String origin,
    required String authenticatedUserId,
    required CloudAccountSession session,
  }) {
    final expectedEmail = email?.trim().toLowerCase();

    return session.serverUrl == origin &&
        session.userId == authenticatedUserId &&
        (accountId == null || session.userId == accountId) &&
        (expectedEmail == null || session.email.toLowerCase() == expectedEmail);
  }

  static ({String? serverUrl, String? accountId}) _compatibleQueryValues(
    Map<String, String> query,
  ) => (
    serverUrl: _compatible(query, (
      legacy: 'serverUrl',
      generated: 'server-url',
      origin: true,
    )),
    accountId: _compatible(query, (
      legacy: 'accountId',
      generated: 'account-id',
      origin: false,
    )),
  );

  static String? _compatible(
    Map<String, String> query,
    ({String legacy, String generated, bool origin}) names,
  ) {
    final first = _cloudAuthTargetNormalize(query[names.legacy], names.origin);
    final second = _cloudAuthTargetNormalize(
      query[names.generated],
      names.origin,
    );
    if (first != null && second != null && first != second) {
      throw const FormatException('Conflicting authentication context');
    }

    return first ?? second;
  }
}

String? _cloudAuthTargetQueryEmail(Map<String, String> query) =>
    query['email']?.isEmpty ?? true ? null : query['email'];

String? _cloudAuthTargetNormalize(String? value, bool origin) {
  if (value == null) return null;

  return origin ? _cloudAuthTargetOrigin(value) : value;
}

String _cloudAuthTargetOrigin(String value) {
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
