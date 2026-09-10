import 'dart:convert';

import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

export 'cloud_account_session.dart';

class ServerpodAuthStore {
  static const _accountIndexKey = 'serverpod_cloud_accounts_v2';
  static const _legacyAccountIndexKey = 'serverpod_cloud_accounts_v1';
  static const _preferredAccountKey = 'serverpod_preferred_account_v2';
  static const _legacyPreferredAccountKey = 'serverpod_preferred_account_v1';
  static const _authPrefix = 'serverpod_auth_success_v2_';
  static const _legacyAuthPrefix = 'serverpod_auth_success_v1_';
  static const _defaultStorage = FlutterSecureStorage(
    iOptions: .new(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  new({
    FlutterSecureStorage? secureStorage,
    this.storageNamespace = 'auravibes_app',
  }) : _secureStorage = secureStorage ?? _defaultStorage;
  final String storageNamespace;

  final FlutterSecureStorage _secureStorage;
  Future<void> _indexMutation = .value();

  bool get _usesLegacyKeys => storageNamespace == 'auravibes_app';

  KeyValueClientAuthSuccessStorage authSuccessStorage({
    required String serverUrl,
    required String userId,
  }) {
    return KeyValueClientAuthSuccessStorage(
      keyValueStorage: _SecureKeyValueStorage(
        secureStorage: _secureStorage,
        keyPrefix: _usesLegacyKeys
            ? _authKey(serverUrl, userId)
            : '$storageNamespace.${_authKey(serverUrl, userId)}',
        legacyKeyPrefix: _usesLegacyKeys
            ? '${ServerpodAuthStore._legacyAuthPrefix}$userId'
            : null,
      ),
    );
  }

  Future<List<CloudAccountSession>> listAccounts({
    String? legacyServerUrl,
  }) async {
    var raw = await _secureStorage.read(
      key: _key(ServerpodAuthStore._accountIndexKey),
    );
    raw = await _migrateLegacyAccounts(raw, legacyServerUrl);
    if (raw == null || raw.isEmpty) return const [];

    return _decodeAccounts(raw);
  }

  Future<void> saveAccount(CloudAccountSession account) =>
      _mutateIndex(() => _saveAccountMutation(account));

  Future<void> removeAccount({
    required String serverUrl,
    required String userId,
  }) async {
    final origin = CloudAccountIdentity.canonicalServerOrigin(serverUrl);
    await authSuccessStorage(serverUrl: origin, userId: userId).set(null);
    await _mutateIndex(() => _removeAccountMutation(origin, userId));
    await _clearPreferredAccount(origin, userId);
  }

  Future<String?> preferredAccountIdentity() =>
      _secureStorage.read(key: _key(ServerpodAuthStore._preferredAccountKey));

  Future<void> setPreferredAccountIdentity({
    required String serverUrl,
    required String userId,
  }) => _secureStorage.write(
    key: _key(ServerpodAuthStore._preferredAccountKey),
    value: CloudAccountIdentity.accountIdentity(serverUrl, userId),
  );
}

extension _ServerpodAuthStoreAccountReads on ServerpodAuthStore {
  Future<String?> _migrateLegacyAccounts(
    String? raw,
    String? legacyServerUrl,
  ) async {
    if (!_shouldMigrateLegacyAccounts(raw, legacyServerUrl)) return raw;
    final legacy = await _legacyAccountIndex();
    if (legacy == null) return raw;

    return _migrateAccountIndex(legacy, legacyServerUrl!);
  }

  bool _shouldMigrateLegacyAccounts(String? raw, String? legacyServerUrl) =>
      _usesLegacyKeys &&
      (raw == null || raw.isEmpty) &&
      legacyServerUrl != null;

  List<CloudAccountSession> _decodeAccounts(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;

    return [
      for (final item in decoded)
        CloudAccountSession.fromJson((item as Map).cast<String, Object?>()),
    ];
  }

  Future<void> _saveAccountMutation(CloudAccountSession account) async {
    final accounts = await listAccounts();
    final next = _nextAccounts(accounts, account);
    await _secureStorage.write(
      key: _key(ServerpodAuthStore._accountIndexKey),
      value: jsonEncode([for (final item in next) item.toJson()]),
    );
  }

  Future<void> _removeAccountMutation(String origin, String userId) async {
    final accounts = await listAccounts();
    await _secureStorage.write(
      key: _key(ServerpodAuthStore._accountIndexKey),
      value: jsonEncode(_remainingAccounts(accounts, origin, userId)),
    );
  }

  Future<String?> _legacyAccountIndex() async {
    final legacy = await _secureStorage.read(
      key: ServerpodAuthStore._legacyAccountIndexKey,
    );
    if (legacy == null || legacy.isEmpty) return null;

    return legacy;
  }
}

extension _ServerpodAuthStoreAccountWrites on ServerpodAuthStore {
  Future<String> _migrateAccountIndex(String legacy, String serverUrl) async {
    final migrated = _decodeLegacyAccounts(legacy, serverUrl);
    final raw = jsonEncode([for (final item in migrated) item.toJson()]);
    await _secureStorage.write(
      key: ServerpodAuthStore._accountIndexKey,
      value: raw,
    );
    await _secureStorage.delete(key: ServerpodAuthStore._legacyAccountIndexKey);
    await _migrateLegacyPreferredAccount(serverUrl);
    return raw;
  }

  Future<void> _migrateLegacyPreferredAccount(String serverUrl) async {
    final preferred = await _secureStorage.read(
      key: ServerpodAuthStore._legacyPreferredAccountKey,
    );
    if (preferred == null) return;
    await setPreferredAccountIdentity(serverUrl: serverUrl, userId: preferred);
    await _secureStorage.delete(
      key: ServerpodAuthStore._legacyPreferredAccountKey,
    );
  }

  List<CloudAccountSession> _decodeLegacyAccounts(
    String raw,
    String serverUrl,
  ) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        CloudAccountSession(
          serverUrl: CloudAccountIdentity.canonicalServerOrigin(serverUrl),
          userId: (item as Map)['userId'] as String,
          email: item['email'] as String,
        ),
    ];
  }

  List<CloudAccountSession> _nextAccounts(
    List<CloudAccountSession> accounts,
    CloudAccountSession account,
  ) => [
    for (final existing in accounts)
      if (existing.userId != account.userId ||
          existing.serverUrl != account.serverUrl)
        existing,
    CloudAccountSession(
      serverUrl: CloudAccountIdentity.canonicalServerOrigin(account.serverUrl),
      userId: account.userId,
      email: account.email,
    ),
  ];

  List<Map<String, dynamic>> _remainingAccounts(
    List<CloudAccountSession> accounts,
    String origin,
    String userId,
  ) => [
    for (final account in accounts)
      if (account.userId != userId || account.serverUrl != origin)
        account.toJson(),
  ];
}

extension _ServerpodAuthStoreAccountPreferences on ServerpodAuthStore {
  Future<void> _clearPreferredAccount(String origin, String userId) async {
    if (await preferredAccountIdentity() ==
        CloudAccountIdentity.accountIdentity(origin, userId)) {
      await _secureStorage.delete(
        key: _key(ServerpodAuthStore._preferredAccountKey),
      );
    }
  }

  String _key(String key) => _usesLegacyKeys ? key : '$storageNamespace.$key';

  Future<void> _mutateIndex(Future<void> Function() mutation) async {
    final previousMutation = _indexMutation;
    final result = () async {
      await previousMutation;
      await mutation();
    }();
    _indexMutation = _completeMutation(result);

    await result;
  }
}

String _authKey(String serverUrl, String userId) =>
    '${ServerpodAuthStore._authPrefix}'
    '${CloudAccountIdentity.accountIdentity(serverUrl, userId)}';

Future<void> _completeMutation(Future<void> result) =>
    _completeIndexMutation(result);

Future<void> _completeIndexMutation(Future<void> result) async {
  try {
    await result;
  } on Object {
    // Keep the queue usable after a failed mutation.
  }
}

class const _SecureKeyValueStorage({
  required final FlutterSecureStorage _secureStorage,
  required final String _keyPrefix,
  final String? _legacyKeyPrefix,
}) implements KeyValueStorage {
  @override
  Future<String?> get(String key) async {
    final storageKey = '$_keyPrefix.$key';
    final value = await _secureStorage.read(key: storageKey);
    if (value != null) return value;

    return _readLegacy(key, storageKey);
  }

  @override
  Future<void> set(String key, String? value) async {
    final storageKey = '$_keyPrefix.$key';
    if (value == null) {
      await _secureStorage.delete(key: storageKey);

      return;
    }

    await _secureStorage.write(key: storageKey, value: value);
  }

  Future<String?> _readLegacy(String key, String storageKey) async {
    final legacyPrefix = _legacyKeyPrefix;
    if (legacyPrefix == null) return null;
    final legacyKey = '$legacyPrefix.$key';
    final legacyValue = await _secureStorage.read(key: legacyKey);
    if (legacyValue == null) return null;
    await _secureStorage.write(key: storageKey, value: legacyValue);
    await _secureStorage.delete(key: legacyKey);
    return legacyValue;
  }
}

abstract final class CloudAccountIdentity {
  static String canonicalServerOrigin(String serverUrl) {
    final uri = Uri.parse(serverUrl);
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('Invalid server URL', serverUrl);
    }

    return uri.replace(path: '').toString();
  }

  static String accountIdentity(String serverUrl, String userId) =>
      '${Uri.encodeComponent(canonicalServerOrigin(serverUrl))}:$userId';
}
// Top-level API/provider declarations are required by their consumers.
