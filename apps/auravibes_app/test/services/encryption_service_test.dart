import 'dart:convert';

import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSecretKeyManager extends SecretKeyManager {
  MockSecretKeyManager() : super();

  @override
  Future<SecretKey> getOrCreateSecretKey() async {
    return SecretKey(List<int>.generate(32, (i) => i));
  }
}

void main() {
  group('EncryptionService', () {
    late EncryptionService service;

    setUp(() {
      service = EncryptionService(MockSecretKeyManager());
    });

    test('encrypt and decrypt round-trip', () async {
      const plaintext = 'Hello, World!';
      final encrypted = await service.encrypt(plaintext);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(plaintext));

      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('encrypt produces different output for different input', () async {
      final one = await service.encrypt('plaintext one');
      final two = await service.encrypt('plaintext two');
      expect(one, isNot(two));
    });

    test(
      'encrypt produces different output for same input (different nonce)',
      () async {
        final one = await service.encrypt('same');
        final two = await service.encrypt('same');
        expect(one, isNot(two));
        // Both should decrypt to the same value
        expect(await service.decrypt(one), 'same');
        expect(await service.decrypt(two), 'same');
      },
    );

    test('encrypt handles empty string', () async {
      const plaintext = '';
      final encrypted = await service.encrypt(plaintext);
      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('encrypt handles special characters', () async {
      const plaintext = '!@#\$%^&*()_+{}|:"<>?~`-=[];\',./';
      final encrypted = await service.encrypt(plaintext);
      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('encrypt handles unicode', () async {
      const plaintext = '你好世界 🌍 مرحبا';
      final encrypted = await service.encrypt(plaintext);
      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('encrypt handles long text', () async {
      final plaintext = 'x' * 10000;
      final encrypted = await service.encrypt(plaintext);
      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('decrypt rejects payloads shorter than nonce plus mac', () async {
      final shortPayload = List<int>.filled(27, 0);

      expect(
        service.decrypt(base64Encode(shortPayload)),
        throwsA(isA<FormatException>()),
      );
      expect(
        service.decrypt(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('decrypt rejects malformed base64 payloads', () async {
      expect(
        service.decrypt('not-valid-base64%%%'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('EncryptionService nullable methods', () {
    late EncryptionService service;

    setUp(() {
      service = EncryptionService(MockSecretKeyManager());
    });

    test('encryptNullable returns null for null input', () async {
      expect(await service.encryptNullable(null), isNull);
    });

    test('encryptNullable encrypts non-null input', () async {
      const plaintext = 'test';
      final encrypted = await service.encryptNullable(plaintext);
      expect(encrypted, isNotNull);
      expect(encrypted, isNot(plaintext));
      final decrypted = await service.decrypt(encrypted!);
      expect(decrypted, plaintext);
    });

    test('decryptNullable returns null for null input', () async {
      expect(await service.decryptNullable(null), isNull);
    });

    test('decryptNullable decrypts non-null input', () async {
      const plaintext = 'nullable test';
      final encrypted = await service.encrypt(plaintext);
      final decrypted = await service.decryptNullable(encrypted);
      expect(decrypted, plaintext);
    });
  });
}
