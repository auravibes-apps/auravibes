// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'dart:convert';

import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([MockSpec<FlutterSecureStorage>()])
import 'secret_manager_service_test.mocks.dart';

void main() {
  group('SecretKeyManager', () {
    late MockFlutterSecureStorage mockStorage;
    late SecretKeyManager manager;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      manager = SecretKeyManager(secureStorage: mockStorage);
    });

    test('clearCache resets cached key', () async {
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => null);
      when(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async {});

      final _ = await manager.getOrCreateSecretKey();
      manager.clearCache();

      final _ = verifyNever(mockStorage.delete(key: anyNamed('key')));
    });

    test('deleteKey removes from storage and clears cache', () async {
      when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});

      await manager.deleteKey();

      verify(mockStorage.delete(key: 'app_encryption_secret_key')).called(1);
    });

    test('getOrCreateSecretKey returns cached key on second call', () async {
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => null);
      when(
        mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async {});

      final key1 = await manager.getOrCreateSecretKey();
      final key2 = await manager.getOrCreateSecretKey();

      expect(identical(key1, key2), true);
      verify(mockStorage.read(key: 'app_encryption_secret_key')).called(1);
    });

    test('getOrCreateSecretKey loads existing key from storage', () async {
      final existingKeyBase64 = base64Encode(
        List<int>.generate(32, (i) => i),
      );
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => existingKeyBase64);

      final key = await manager.getOrCreateSecretKey();
      final bytes = await key.extractBytes();

      expect(bytes, hasLength(32));
      verify(mockStorage.read(key: 'app_encryption_secret_key')).called(1);
      final _ = verifyNever(
        mockStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        ),
      );
    });

    test(
      'getOrCreateSecretKey generates and saves new key when none exists',
      () async {
        when(
          mockStorage.read(key: anyNamed('key')),
        ).thenAnswer((_) async => null);
        when(
          mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
        ).thenAnswer((_) async {});

        final key = await manager.getOrCreateSecretKey();
        final bytes = await key.extractBytes();

        expect(bytes, hasLength(32));
        verify(
          mockStorage.write(
            key: 'app_encryption_secret_key',
            value: anyNamed('value'),
          ),
        ).called(1);
      },
    );
  });
}
