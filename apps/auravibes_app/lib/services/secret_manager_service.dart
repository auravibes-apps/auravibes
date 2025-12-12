import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';

class SecretKeyManager {
  SecretKeyManager({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );
  static const _keyStorageKey = 'app_encryption_secret_key';

  final FlutterSecureStorage _secureStorage;
  SecretKey? _cachedKey;

  /// Loads existing key or generates a new one
  Future<SecretKey> getOrCreateSecretKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final existingKey = await _loadKey();
    if (existingKey != null) {
      _cachedKey = existingKey;
      return existingKey;
    }

    // Generate a new 256-bit key for AES-GCM
    final algorithm = AesGcm.with256bits();
    final newKey = await algorithm.newSecretKey();
    await _saveKey(newKey);
    _cachedKey = newKey;
    return newKey;
  }

  Future<SecretKey?> _loadKey() async {
    final keyBase64 = await _secureStorage.read(key: _keyStorageKey);
    if (keyBase64 == null) return null;

    final keyBytes = base64Decode(keyBase64);
    return SecretKey(keyBytes);
  }

  Future<void> _saveKey(SecretKey key) async {
    final keyBytes = await key.extractBytes();
    final keyBase64 = base64Encode(keyBytes);
    await _secureStorage.write(key: _keyStorageKey, value: keyBase64);
  }

  /// Clears the cached key (useful for logout)
  void clearCache() {
    _cachedKey = null;
  }

  /// Deletes the key entirely (use with caution - data will be unrecoverable)
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
    _cachedKey = null;
  }
}

Provider<SecretKeyManager> secretKeyManagerProvider =
    Provider<SecretKeyManager>((ref) {
      return SecretKeyManager();
    });
