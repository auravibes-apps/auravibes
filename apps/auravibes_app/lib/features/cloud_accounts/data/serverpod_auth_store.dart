import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

class CloudAccountSession {
  const CloudAccountSession({required this.userId, required this.email});

  factory CloudAccountSession.fromJson(Map<String, Object?> json) {
    return CloudAccountSession(
      userId: json['userId']! as String,
      email: json['email']! as String,
    );
  }

  final String userId;
  final String email;

  Map<String, Object?> toJson() {
    return {'userId': userId, 'email': email};
  }
}

class ServerpodAuthStore {
  ServerpodAuthStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? _defaultStorage;

  static const _accountIndexKey = 'serverpod_cloud_accounts_v1';
  static const _preferredAccountKey = 'serverpod_preferred_account_v1';
  static const _authPrefix = 'serverpod_auth_success_v1_';
  static const _defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _secureStorage;
  Future<void> _indexMutation = Future.value();

  Future<List<CloudAccountSession>> listAccounts() async {
    final raw = await _secureStorage.read(key: _accountIndexKey);
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
          if (existing.userId != account.userId) existing,
        account,
      ];
      await _secureStorage.write(
        key: _accountIndexKey,
        value: jsonEncode([for (final item in next) item.toJson()]),
      );
    });
  }

  Future<void> removeAccount(String userId) async {
    await authSuccessStorage(userId).set(null);
    await _mutateIndex(() async {
      final accounts = await listAccounts();
      await _secureStorage.write(
        key: _accountIndexKey,
        value: jsonEncode([
          for (final account in accounts)
            if (account.userId != userId) account.toJson(),
        ]),
      );
    });
    if (await preferredAccountId() == userId) {
      await _secureStorage.delete(key: _preferredAccountKey);
    }
  }

  Future<String?> preferredAccountId() {
    return _secureStorage.read(key: _preferredAccountKey);
  }

  Future<void> setPreferredAccountId(String userId) {
    return _secureStorage.write(key: _preferredAccountKey, value: userId);
  }

  KeyValueClientAuthSuccessStorage authSuccessStorage(String userId) {
    return KeyValueClientAuthSuccessStorage(
      keyValueStorage: _SecureKeyValueStorage(
        secureStorage: _secureStorage,
        keyPrefix: _authKey(userId),
      ),
    );
  }

  static String _authKey(String userId) => '$_authPrefix$userId';

  Future<void> _mutateIndex(Future<void> Function() mutation) {
    final result = _indexMutation.then((_) => mutation());
    _indexMutation = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }
}

class _SecureKeyValueStorage implements KeyValueStorage {
  const _SecureKeyValueStorage({
    required this._secureStorage,
    required this._keyPrefix,
  });

  final FlutterSecureStorage _secureStorage;
  final String _keyPrefix;

  @override
  Future<String?> get(String key) {
    return _secureStorage.read(key: '$_keyPrefix.$key');
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
