// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/v7.dart';

class EncryptionService(
  final SecretKeyManager _keyManager, {
  FlutterSecureStorage? credentialStorage,
}) {
  static const int _nonceLength = 12;
  static const int _macLength = 16;
  static const int _minimumPayloadLength = _nonceLength + _macLength;
  final AesGcm _algorithm = .with256bits();

  final FlutterSecureStorage _credentialStorage =
      credentialStorage ??
      const FlutterSecureStorage(
        iOptions: .new(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  Future<String> storeCredential(String plaintext) async {
    final reference = 'service-credential:${const UuidV7().generate()}';
    await _credentialStorage.write(key: reference, value: plaintext);

    return reference;
  }

  Future<String> readCredential(String reference) async {
    if (!isCredentialReference(reference)) return await decrypt(reference);
    final value = await _credentialStorage.read(key: reference);
    if (value == null) {
      throw const FormatException('Service credential is unavailable.');
    }

    return value;
  }

  Future<void> deleteCredential(String? reference) async {
    if (reference != null && isCredentialReference(reference)) {
      await _credentialStorage.delete(key: reference);
    }
  }

  bool isCredentialReference(String value) =>
      value.startsWith('service-credential:');

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

    return _encodeSecretBox(secretBox);
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
      mac: .new(combined.sublist(combined.length - _macLength)),
    );
  }
}

String _encodeSecretBox(SecretBox secretBox) => base64Encode(
  Uint8List.fromList([
    ...secretBox.nonce,
    ...secretBox.cipherText,
    ...secretBox.mac.bytes,
  ]),
);

final Provider<EncryptionService> encryptionServiceProvider =
    Provider<EncryptionService>((ref) {
      final keyManager = ref.read(secretKeyManagerProvider);

      return EncryptionService(keyManager);
    });
