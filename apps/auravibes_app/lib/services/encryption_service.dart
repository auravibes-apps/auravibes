import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/services/secret_manager_service.dart';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod/riverpod.dart';

class EncryptionService {
  EncryptionService(this._keyManager);
  final SecretKeyManager _keyManager;
  final AesGcm _algorithm = AesGcm.with256bits();

  /// Encrypts a string and returns base64-encoded ciphertext
  /// Format: [12-byte nonce][ciphertext][16-byte MAC]
  Future<String> encrypt(String plaintext) async {
    final key = await _keyManager.getOrCreateSecretKey();
    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    // Combine nonce + ciphertext + mac for storage
    final combined = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return base64Encode(combined);
  }

  /// Decrypts a base64-encoded ciphertext
  Future<String> decrypt(String encryptedBase64) async {
    final key = await _keyManager.getOrCreateSecretKey();
    final combined = base64Decode(encryptedBase64);

    // Extract components (nonce:  12 bytes, mac: 16 bytes)
    final nonce = combined.sublist(0, 12);
    final cipherText = combined.sublist(12, combined.length - 16);
    final mac = Mac(combined.sublist(combined.length - 16));

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

    final decrypted = await _algorithm.decrypt(secretBox, secretKey: key);
    return utf8.decode(decrypted);
  }

  /// Encrypts data, returns null if input is null
  Future<String?> encryptNullable(String? plaintext) async {
    if (plaintext == null) return null;
    return encrypt(plaintext);
  }

  /// Decrypts data, returns null if input is null
  Future<String?> decryptNullable(String? encryptedBase64) async {
    if (encryptedBase64 == null) return null;
    return decrypt(encryptedBase64);
  }
}

Provider<EncryptionService> encryptionServiceProvider =
    Provider<EncryptionService>((ref) {
      final keyManager = ref.read(secretKeyManagerProvider);
      return EncryptionService(keyManager);
    });
