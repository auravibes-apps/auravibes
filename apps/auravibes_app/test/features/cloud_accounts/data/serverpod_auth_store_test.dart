import 'dart:convert';

import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  test(
    'keeps equal account IDs on different server origins distinct',
    () async {
      final values = <String, String>{};
      final storage = _MockSecureStorage();
      when(() => storage.read(key: any(named: 'key'))).thenAnswer(
        (invocation) async => values[invocation.namedArguments[#key] as String],
      );
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) {
        values[invocation.namedArguments[#key] as String] =
            invocation.namedArguments[#value] as String;

        return Future<void>.value();
      });
      when(() => storage.delete(key: any(named: 'key'))).thenAnswer(
        (invocation) async => values.remove(
          invocation.namedArguments[#key] as String,
        ),
      );
      final store = ServerpodAuthStore(secureStorage: storage);

      await store.saveAccount(
        const CloudAccountSession(
          serverUrl: 'https://one.example/api',
          userId: 'same-id',
          email: 'one@example.com',
        ),
      );
      await store.saveAccount(
        const CloudAccountSession(
          serverUrl: 'https://two.example/',
          userId: 'same-id',
          email: 'two@example.com',
        ),
      );

      final accounts = await store.listAccounts();
      expect(accounts, hasLength(2));
      expect(
        accounts.map((account) => account.serverUrl),
        containsAll(['https://one.example', 'https://two.example']),
      );
      expect(
        jsonDecode(values['serverpod_cloud_accounts_v2']!),
        hasLength(2),
      );
    },
  );

  test(
    'hashed namespace ignores unprefixed account and auth storage',
    () async {
      final values = <String, String>{
        'serverpod_cloud_accounts_v2': '[]',
        'serverpod_cloud_accounts_v1': '[]',
        'serverpod_preferred_account_v2': 'legacy-user',
        'serverpod_preferred_account_v1': 'legacy-user',
        'serverpod_auth_success_v1_user.serverpod_auth_success_key': 'legacy',
      };
      final reads = <String>[];
      final storage = _MockSecureStorage();
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((call) async {
        final key = call.namedArguments[#key] as String;
        reads.add(key);

        return values[key];
      });
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) => Future<void>.value());
      when(
        () => storage.delete(key: any(named: 'key')),
      ).thenAnswer((_) => Future<void>.value());
      final store = ServerpodAuthStore(
        secureStorage: storage,
        storageNamespace: 'auravibes_app_0123456789abcdef',
      );

      expect(
        await store.listAccounts(legacyServerUrl: 'https://legacy.example'),
        isEmpty,
      );
      expect(await store.preferredAccountIdentity(), isNull);
      expect(
        await store
            .authSuccessStorage(
              serverUrl: 'https://legacy.example',
              userId: 'user',
            )
            .get(),
        isNull,
      );

      for (final legacyKey in [
        'serverpod_cloud_accounts_v2',
        'serverpod_cloud_accounts_v1',
        'serverpod_preferred_account_v2',
        'serverpod_preferred_account_v1',
        'serverpod_auth_success_v1_user.serverpod_auth_success_key',
      ]) {
        expect(reads, isNot(contains(legacyKey)));
      }
    },
  );
  test(
    'default namespace migrates v1 account and preferred keys',
    () async {
      final values = <String, String>{
        'serverpod_cloud_accounts_v1': jsonEncode([
          {'userId': 'user', 'email': 'user@example.com'},
        ]),
        'serverpod_preferred_account_v1': 'user',
      };
      final storage = _MockSecureStorage();
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer(
        (call) => Future.value(values[call.namedArguments[#key] as String]),
      );
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((call) {
        values[call.namedArguments[#key] as String] =
            call.namedArguments[#value] as String;

        return Future<void>.value();
      });
      when(() => storage.delete(key: any(named: 'key'))).thenAnswer(
        (call) {
          final _ = values.remove(call.namedArguments[#key] as String);

          return Future<void>.value();
        },
      );
      final store = ServerpodAuthStore(secureStorage: storage);
      final accounts = await store.listAccounts(
        legacyServerUrl: 'https://legacy.example/api',
      );
      expect(accounts.single.serverUrl, 'https://legacy.example');
      expect(
        await store.preferredAccountIdentity(),
        accountIdentity('https://legacy.example', 'user'),
      );
      expect(values, contains('serverpod_cloud_accounts_v2'));
      expect(values, isNot(contains('serverpod_cloud_accounts_v1')));
      expect(values, isNot(contains('serverpod_preferred_account_v1')));
    },
  );

  test('stores account index under namespace', () async {
    final values = <String, String>{};
    final storage = _MockSecureStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer(
      (call) => Future.value(values[call.namedArguments[#key] as String]),
    );
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((call) {
      values[call.namedArguments[#key] as String] =
          call.namedArguments[#value] as String;

      return Future<void>.value();
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer(
      (call) {
        final _ = values.remove(call.namedArguments[#key] as String);

        return Future<void>.value();
      },
    );
    final store = ServerpodAuthStore(
      secureStorage: storage,
      storageNamespace: 'auravibes_app_0123456789abcdef',
    );

    await store.saveAccount(
      const CloudAccountSession(
        serverUrl: 'https://one.example',
        userId: 'user',
        email: 'one@example.com',
      ),
    );

    expect(
      values,
      contains('auravibes_app_0123456789abcdef.serverpod_cloud_accounts_v2'),
    );
    expect(values, isNot(contains('serverpod_cloud_accounts_v2')));
  });
}
