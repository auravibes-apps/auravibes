import 'dart:convert';

import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('McpCatalogEndpoint', (sessionBuilder, endpoints) {
    test('requires an authenticated email account', () async {
      await expectLater(
        endpoints.mcpCatalog.list(sessionBuilder),
        throwsA(
          isA<CloudWorkspaceException>().having(
            (error) => error.code,
            'code',
            CloudWorkspaceErrorCode.authenticationRequired,
          ),
        ),
      );
    });

    test(
      'returns enabled definitions and sees database edits on next read',
      () async {
        final userId = const Uuid().v4().toString();
        final authenticated = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            userId,
            const {},
          ),
        );
        final databaseSession = authenticated.build();
        final authUserId = UuidValue.fromString(userId);
        await AuthUser.db.insertRow(
          databaseSession,
          AuthUser(id: authUserId, scopeNames: const {}),
        );
        await EmailAccount.db.insertRow(
          databaseSession,
          EmailAccount(
            authUserId: authUserId,
            email: 'catalog@example.com',
            passwordHash: 'unused',
          ),
        );
        final enabled = await McpCatalogEntry.db.insertRow(
          databaseSession,
          _entry('alpha', name: 'Alpha'),
        );
        await McpCatalogEntry.db.insertRow(
          databaseSession,
          _entry('hidden', name: 'Hidden', isEnabled: false),
        );
        await McpCatalogEntry.db.insertRow(
          databaseSession,
          _entry('invalid', name: 'Invalid').copyWith(
            optionsJson: '[{"key":"personal","name":"Personal","authType":"apiKey","fields":[{"key":"apiKey","isSecret":true,"isRequired":true,"value":"actual-secret"}]}]',
          ),
        );

        final first = await endpoints.mcpCatalog.list(authenticated);
        expect(first.map((listing) => listing.id), ['alpha']);
        expect(first.single.options.single.fields.single.key, 'apiKey');
        final responseJson = jsonEncode(first.single.toJson());
        expect(responseJson, contains('isSecret'));
        expect(responseJson, isNot(contains('submittedValue')));
        expect(responseJson, isNot(contains('workspaceId')));
        expect(responseJson, isNot(contains('actual-secret')));

        await McpCatalogEntry.db.updateRow(
          databaseSession,
          enabled.copyWith(name: 'Renamed'),
        );
        final second = await endpoints.mcpCatalog.list(authenticated);
        expect(second.single.name, 'Renamed');
      },
    );
  });
}

McpCatalogEntry _entry(
  String id, {
  required String name,
  bool isEnabled = true,
}) => McpCatalogEntry(
  catalogId: id,
  name: name,
  description: 'Tools for $name',
  url: 'https://example.com/mcp',
  transport: 'streamableHttp',
  isEnabled: isEnabled,
  optionsJson: '''[{"key":"personal","name":"Personal","authType":"apiKey","fields":[{"key":"apiKey","isSecret":true,"isRequired":true,"label":"API key"}]}]''',
);
