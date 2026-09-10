// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod/riverpod.dart';

class EncryptionService(final SecretKeyManager _keyManager) {
  static const int _nonceLength = 12;
  static const int _macLength = 16;
  static const int _minimumPayloadLength = _nonceLength + _macLength;
  final AesGcm _algorithm = .with256bits();

  /// Encrypts a string and returns base64-encoded ciphertext.
  /// Format: [12-byte nonce][ciphertext][16-byte MAC].
  Future<String> encrypt(String plaintext) async {
    final key = await _keyManager.getOrCreateSecretKey();
    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    // Combine nonce + ciphertext + mac for storage.
    final combined = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return base64Encode(combined);
  }

  /// Decrypts a base64-encoded ciphertext.
  Future<String> decrypt(String encryptedBase64) async {
    final secretBox = _decodeSecretBox(encryptedBase64);
    final key = await _keyManager.getOrCreateSecretKey();
    final decrypted = await _algorithm.decrypt(secretBox, secretKey: key);

    return utf8.decode(decrypted);
  }

  SecretBox _decodeSecretBox(String encryptedBase64) {
    final combined = base64Decode(encryptedBase64);
    if (combined.length < _minimumPayloadLength) {
      throw const FormatException(
        'Encrypted payload is shorter than the AES-GCM nonce and MAC.',
      );
    }

    return SecretBox(
      combined.sublist(_nonceLength, combined.length - _macLength),
      nonce: combined.sublist(0, _nonceLength),
      mac: Mac(combined.sublist(combined.length - _macLength)),
    );
  }
}

final Provider<EncryptionService> encryptionServiceProvider =
    Provider<EncryptionService>((ref) {
      final keyManager = ref.read(secretKeyManagerProvider);

      return EncryptionService(keyManager);
    });
