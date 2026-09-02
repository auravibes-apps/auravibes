// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'dart:convert';

import 'package:auravibes_app/providers/app_providers.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';

class SecretKeyManager {
  static const _keyStorageKey = 'app_encryption_secret_key';
  new({
    FlutterSecureStorage? secureStorage,
    this.storageNamespace = 'auravibes_app',
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );
  final String storageNamespace;

  final FlutterSecureStorage _secureStorage;
  SecretKey? _cachedKey;
  Future<SecretKey>? _pendingKey;

  String get _storageKey => storageNamespace == 'auravibes_app'
      ? _keyStorageKey
      : '$storageNamespace.$_keyStorageKey';

  /// Loads existing key or generates a new one.
  Future<SecretKey> getOrCreateSecretKey() async {
    final cachedKey = _cachedKey;
    if (cachedKey != null) return cachedKey;

    final pendingKey = _pendingKey;
    if (pendingKey != null) return await pendingKey;

    final newPendingKey = _loadOrCreateSecretKey();
    _pendingKey = newPendingKey;

    try {
      return await newPendingKey;
    } finally {
      if (identical(_pendingKey, newPendingKey)) {
        _pendingKey = null;
      }
    }
  }

  /// Clears the cached key (useful for logout).
  void clearCache() {
    _cachedKey = null;
    _pendingKey = null;
  }

  Future<SecretKey> _loadOrCreateSecretKey() async {
    final existingKey = await _loadKey();
    if (existingKey != null) {
      _cachedKey = existingKey;

      return existingKey;
    }

    // Generate a new 256-bit key for AES-GCM.
    final algorithm = AesGcm.with256bits();
    final newKey = await algorithm.newSecretKey();
    await _saveKey(newKey);
    _cachedKey = newKey;

    return newKey;
  }

  Future<SecretKey?> _loadKey() async {
    final keyBase64 = await _secureStorage.read(key: _storageKey);
    if (keyBase64 == null) return null;

    final keyBytes = base64Decode(keyBase64);

    return SecretKey(keyBytes);
  }

  Future<void> _saveKey(SecretKey key) async {
    final keyBytes = await key.extractBytes();
    final keyBase64 = base64Encode(keyBytes);
    await _secureStorage.write(key: _storageKey, value: keyBase64);
  }
}

final Provider<SecretKeyManager> secretKeyManagerProvider =
    Provider<SecretKeyManager>((ref) {
      return SecretKeyManager(
        storageNamespace: ref.watch(appStorageNamespaceProvider),
      );
    });
