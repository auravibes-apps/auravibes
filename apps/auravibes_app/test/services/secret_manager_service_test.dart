import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('SecretKeyManager', () {
    var mockStorage = MockFlutterSecureStorage();
    var manager = SecretKeyManager(secureStorage: mockStorage);

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      manager = SecretKeyManager(secureStorage: mockStorage);
    });

    test('clearCache resets cached key', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) {
        return Future<void>.value();
      });

      final _ = await manager.getOrCreateSecretKey();
      manager.clearCache();

      expect(
        () => verifyNever(() => mockStorage.delete(key: any(named: 'key'))),
        returnsNormally,
      );
    });

    test('getOrCreateSecretKey returns cached key on second call', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) {
        return Future<void>.value();
      });

      final key1 = await manager.getOrCreateSecretKey();
      final key2 = await manager.getOrCreateSecretKey();

      expect(identical(key1, key2), true);
      verify(
        () => mockStorage.read(key: 'app_encryption_secret_key'),
      ).called(1);
    });

    test('getOrCreateSecretKey loads existing key from storage', () async {
      final existingKeyBase64 = base64Encode(
        List<int>.generate(32, (i) => i),
      );
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => existingKeyBase64);

      final key = await manager.getOrCreateSecretKey();
      final bytes = await key.extractBytes();

      expect(bytes, hasLength(32));
      verify(
        () => mockStorage.read(key: 'app_encryption_secret_key'),
      ).called(1);
      final _ = verifyNever(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test(
      'getOrCreateSecretKey generates and saves new key when none exists',
      () async {
        when(
          () => mockStorage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) {
          return Future<void>.value();
        });

        final key = await manager.getOrCreateSecretKey();
        final bytes = await key.extractBytes();

        expect(bytes, hasLength(32));
        verify(
          () => mockStorage.write(
            key: 'app_encryption_secret_key',
            value: any(named: 'value'),
          ),
        ).called(1);
      },
    );

    test('getOrCreateSecretKey shares concurrent key creation', () async {
      final readCompleter = Completer<String?>();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) => readCompleter.future);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) {
        return Future<void>.value();
      });

      final first = manager.getOrCreateSecretKey();
      final second = manager.getOrCreateSecretKey();
      readCompleter.complete(null);
      final keys = await Future.wait([first, second]);

      expect(identical(keys.firstOrNull, keys.lastOrNull), isTrue);
      verify(
        () => mockStorage.read(key: 'app_encryption_secret_key'),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'app_encryption_secret_key',
          value: any(named: 'value'),
        ),
      ).called(1);
    });
  });
}
