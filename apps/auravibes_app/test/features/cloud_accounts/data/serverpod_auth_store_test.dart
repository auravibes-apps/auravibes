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
}
