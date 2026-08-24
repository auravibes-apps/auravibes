import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';

export 'cloud_account_session.dart';

class ServerpodAuthStore {
  static const _accountIndexKey = 'serverpod_cloud_accounts_v2';
  static const _legacyAccountIndexKey = 'serverpod_cloud_accounts_v1';
  static const _preferredAccountKey = 'serverpod_preferred_account_v2';
  static const _legacyPreferredAccountKey = 'serverpod_preferred_account_v1';
  static const _authPrefix = 'serverpod_auth_success_v2_';
  static const _legacyAuthPrefix = 'serverpod_auth_success_v1_';
  static const _defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  ServerpodAuthStore({
    FlutterSecureStorage? secureStorage,
    this.storageNamespace = 'auravibes_app',
  }) : _secureStorage = secureStorage ?? _defaultStorage;
  final String storageNamespace;

  final FlutterSecureStorage _secureStorage;
  Future<void> _indexMutation = Future.value();

  bool get _usesLegacyKeys => storageNamespace == 'auravibes_app';

  Future<List<CloudAccountSession>> listAccounts({
    String? legacyServerUrl,
  }) async {
    var raw = await _secureStorage.read(key: _key(_accountIndexKey));
    if (_usesLegacyKeys &&
        (raw == null || raw.isEmpty) &&
        legacyServerUrl != null) {
      final legacy = await _secureStorage.read(key: _legacyAccountIndexKey);
      if (legacy != null && legacy.isNotEmpty) {
        final decoded = jsonDecode(legacy) as List<dynamic>;
        final migrated = [
          for (final item in decoded)
            CloudAccountSession(
              serverUrl: CloudAccountIdentity.canonicalServerOrigin(
                legacyServerUrl,
              ),
              userId: (item as Map)['userId'] as String,
              email: item['email'] as String,
            ),
        ];
        raw = jsonEncode([for (final item in migrated) item.toJson()]);
        await _secureStorage.write(key: _accountIndexKey, value: raw);
        await _secureStorage.delete(key: _legacyAccountIndexKey);
        final preferred = await _secureStorage.read(
          key: _legacyPreferredAccountKey,
        );
        if (preferred != null) {
          await setPreferredAccountIdentity(
            serverUrl: legacyServerUrl,
            userId: preferred,
          );
          await _secureStorage.delete(key: _legacyPreferredAccountKey);
        }
      }
    }
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;

    return [
      for (final item in decoded)
        CloudAccountSession.fromJson((item as Map).cast<String, Object?>()),
    ];
  }

  Future<void> saveAccount(CloudAccountSession account) async {
    await _mutateIndex(() async {
      final accounts = await listAccounts();
      final next = [
        for (final existing in accounts)
          if (existing.userId != account.userId ||
              existing.serverUrl != account.serverUrl)
            existing,
        CloudAccountSession(
          serverUrl: CloudAccountIdentity.canonicalServerOrigin(
            account.serverUrl,
          ),
          userId: account.userId,
          email: account.email,
        ),
      ];
      await _secureStorage.write(
        key: _key(_accountIndexKey),
        value: jsonEncode([for (final item in next) item.toJson()]),
      );
    });
  }

  Future<void> removeAccount({
    required String serverUrl,
    required String userId,
  }) async {
    final origin = CloudAccountIdentity.canonicalServerOrigin(serverUrl);
    await authSuccessStorage(serverUrl: origin, userId: userId).set(null);
    await _mutateIndex(() async {
      final accounts = await listAccounts();
      await _secureStorage.write(
        key: _key(_accountIndexKey),
        value: jsonEncode([
          for (final account in accounts)
            if (account.userId != userId || account.serverUrl != origin)
              account.toJson(),
        ]),
      );
    });
    if (await preferredAccountIdentity() ==
        CloudAccountIdentity.accountIdentity(origin, userId)) {
      await _secureStorage.delete(key: _key(_preferredAccountKey));
    }
  }

  Future<String?> preferredAccountIdentity() {
    return _secureStorage.read(key: _key(_preferredAccountKey));
  }

  Future<void> setPreferredAccountIdentity({
    required String serverUrl,
    required String userId,
  }) {
    return _secureStorage.write(
      key: _key(_preferredAccountKey),
      value: CloudAccountIdentity.accountIdentity(serverUrl, userId),
    );
  }

  KeyValueClientAuthSuccessStorage authSuccessStorage({
    required String serverUrl,
    required String userId,
  }) {
    return KeyValueClientAuthSuccessStorage(
      keyValueStorage: _SecureKeyValueStorage(
        secureStorage: _secureStorage,
        keyPrefix: _key(_authKey(serverUrl, userId)),
        legacyKeyPrefix: _usesLegacyKeys ? '$_legacyAuthPrefix$userId' : null,
      ),
    );
  }

  String _key(String key) => _usesLegacyKeys ? key : '$storageNamespace.$key';

  static String _authKey(String serverUrl, String userId) =>
      '$_authPrefix${CloudAccountIdentity.accountIdentity(serverUrl, userId)}';

  Future<void> _mutateIndex(Future<void> Function() mutation) async {
    final previousMutation = _indexMutation;
    final result = () async {
      await previousMutation;
      await mutation();
    }();
    _indexMutation = _completeMutation(result);

    await result;
  }

  static Future<void> _completeMutation(Future<void> result) async {
    try {
      await result;
    } on Object {
      // Keep the queue usable after a failed mutation.
    }
  }
}

class _SecureKeyValueStorage implements KeyValueStorage {
  const _SecureKeyValueStorage({
    required this._secureStorage,
    required this._keyPrefix,
    this._legacyKeyPrefix,
  });

  final FlutterSecureStorage _secureStorage;
  final String _keyPrefix;
  final String? _legacyKeyPrefix;

  @override
  Future<String?> get(String key) async {
    final storageKey = '$_keyPrefix.$key';
    final value = await _secureStorage.read(key: storageKey);
    final legacyPrefix = _legacyKeyPrefix;
    if (value != null || legacyPrefix == null) return value;

    final legacyKey = '$legacyPrefix.$key';
    final legacyValue = await _secureStorage.read(key: legacyKey);
    if (legacyValue == null) return null;
    await _secureStorage.write(key: storageKey, value: legacyValue);
    await _secureStorage.delete(key: legacyKey);

    return legacyValue;
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
