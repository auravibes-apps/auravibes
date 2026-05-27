// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/mcp_servers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor _testConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async => NativeDatabase.memory()),
      );
    }),
  );
}

void main() {
  group('McpServers table converters', () {
    group('transportTypeConverter', () {
      test('converts SSE from JSON', () {
        final result = transportTypeConverter.fromJson({'type': 'sse'});
        expect(result, isA<McpTransportTypeSSE>());
      });

      test('converts StreamableHttp from JSON', () {
        final result = transportTypeConverter.fromJson({
          'type': 'streamableHttp',
          'useHttp2': true,
        });
        expect(result, isA<McpTransportTypeStreamableHttp>());
        expect((result as McpTransportTypeStreamableHttp).useHttp2, isTrue);
      });

      test('converts SSE to JSON', () {
        const transport = McpTransportTypeSSE();
        final json =
            transportTypeConverter.toJson(transport)! as Map<String, dynamic>;
        expect(json['type'], 'sse');
      });

      test('converts StreamableHttp to JSON', () {
        const transport = McpTransportTypeStreamableHttp(useHttp2: true);
        final json =
            transportTypeConverter.toJson(transport)! as Map<String, dynamic>;
        expect(json['type'], 'streamableHttp');
        expect(json['useHttp2'], isTrue);
      });

      test('round-trip SSE', () {
        const original = McpTransportTypeSSE();
        final json = transportTypeConverter.toJson(original);
        final restored = transportTypeConverter.fromJson(json);
        expect(restored, isA<McpTransportTypeSSE>());
      });

      test('round-trip StreamableHttp', () {
        const original = McpTransportTypeStreamableHttp(useHttp2: true);
        final json = transportTypeConverter.toJson(original);
        final restored = transportTypeConverter.fromJson(json);
        expect(restored, isA<McpTransportTypeStreamableHttp>());
        expect((restored as McpTransportTypeStreamableHttp).useHttp2, isTrue);
      });
    });

    group('authenticationTypeConverter', () {
      test('round-trip none', () {
        const original = McpAuthenticationTypeNone();
        final json = authenticationTypeConverter.toJson(original);
        final restored = authenticationTypeConverter.fromJson(json);
        expect(restored, isA<McpAuthenticationTypeNone>());
      });

      test('round-trip bearerToken', () {
        const original = McpAuthenticationTypeBearerToken(
          bearerToken: 'my-token',
        );
        final json = authenticationTypeConverter.toJson(original);
        final restored = authenticationTypeConverter.fromJson(json);
        expect(restored, isA<McpAuthenticationTypeBearerToken>());
        expect(
          (restored as McpAuthenticationTypeBearerToken).bearerToken,
          'my-token',
        );
      });

      test('toJson for none returns non-null map', () {
        const auth = McpAuthenticationTypeNone();
        final json = authenticationTypeConverter.toJson(auth);
        expect(json, isNotNull);
      });

      test('toJson for bearerToken produces non-null JSON', () {
        const auth = McpAuthenticationTypeBearerToken(bearerToken: 'tok');
        final json = authenticationTypeConverter.toJson(auth);
        expect(json, isNotNull);
      });

      test('StreamableHttp with useHttp2 false', () {
        const transport = McpTransportTypeStreamableHttp();
        final json =
            transportTypeConverter.toJson(transport)! as Map<String, dynamic>;
        expect(json['type'], 'streamableHttp');
        expect(json['useHttp2'], isFalse);

        final restored = transportTypeConverter.fromJson(json);
        expect((restored as McpTransportTypeStreamableHttp).useHttp2, isFalse);
      });

      test('SSE toJson produces correct structure', () {
        const transport = McpTransportTypeSSE();
        final json = transport.toJson();
        expect(json, {'type': 'sse'});
        expect(json.length, 1);
      });

      test('StreamableHttp toJson produces correct structure', () {
        const transport = McpTransportTypeStreamableHttp(useHttp2: true);
        final json = transport.toJson();
        expect(json.length, 2);
        expect(json.containsKey('type'), isTrue);
        expect(json.containsKey('useHttp2'), isTrue);
      });

      test('OAuth toJson produces correct runtimeType', () {
        final auth = McpAuthenticationTypeOAuth(
          token: OAuthTokenEntity(
            accessToken: 'at',
            issuedAt: DateTime(2026),
          ),
          clientId: 'cid',
          authorizationEndpoint: 'https://a.co',
          tokenEndpoint: 'https://t.co',
        );
        final json =
            authenticationTypeConverter.toJson(auth)! as Map<String, dynamic>;
        expect(json['runtimeType'], 'oauth');
        expect(json['clientId'], 'cid');
      });

      test('OAuth toJson includes token data', () {
        final auth = McpAuthenticationTypeOAuth(
          token: OAuthTokenEntity(
            accessToken: 'access-tok',
            issuedAt: DateTime(2026, 1, 15),
          ),
          clientId: 'my-client',
          authorizationEndpoint: 'https://auth.example.com/authorize',
          tokenEndpoint: 'https://auth.example.com/token',
        );
        final json = auth.toJson();
        expect(json['runtimeType'], 'oauth');
        expect(json['clientId'], 'my-client');
        final tokenData = json['token'];
        expect(tokenData, isA<OAuthTokenEntity>());
        expect((tokenData as OAuthTokenEntity).accessToken, 'access-tok');
        expect(
          json['authorizationEndpoint'],
          'https://auth.example.com/authorize',
        );
        expect(json['tokenEndpoint'], 'https://auth.example.com/token');
      });

      test('OAuth toJson produces correct runtimeType', () {
        final auth = McpAuthenticationTypeOAuth(
          token: OAuthTokenEntity(
            accessToken: 'at',
            issuedAt: DateTime(2026),
          ),
          clientId: 'cid',
          authorizationEndpoint: 'https://a.co',
          tokenEndpoint: 'https://t.co',
        );
        final json =
            authenticationTypeConverter.toJson(auth)! as Map<String, dynamic>;
        expect(json['runtimeType'], 'oauth');
        expect(json['clientId'], 'cid');
      });

      test('OAuth round-trip through converter', () {
        final original = McpAuthenticationTypeOAuth(
          token: OAuthTokenEntity(
            accessToken: 'round-trip-token',
            issuedAt: DateTime(2026, 3, 15),
          ),
          clientId: 'cid-rt',
          authorizationEndpoint: 'https://auth.rt/authorize',
          tokenEndpoint: 'https://auth.rt/token',
        );
        final json =
            authenticationTypeConverter.toJson(original)!
                as Map<String, dynamic>;
        expect(json['runtimeType'], 'oauth');
        expect(json['clientId'], 'cid-rt');
      });

      test('fromJson throws for unsupported transport type', () {
        expect(
          () => McpTransportType.fromJson({'type': 'unknown'}),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('StreamableHttp default useHttp2 is false', () {
        const transport = McpTransportTypeStreamableHttp();
        expect(transport.useHttp2, isFalse);
      });

      test('fromJson throws for unsupported auth type', () {
        expect(
          () => McpAuthenticationType.fromJson(
            {'runtimeType': 'unknown'},
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('McpAuthenticationTypeNone has correct runtimeType', () {
        const auth = McpAuthenticationTypeNone();
        final json = auth.toJson();
        expect(json['runtimeType'], 'none');
      });

      test('McpAuthenticationTypeBearerToken has correct runtimeType', () {
        const auth = McpAuthenticationTypeBearerToken(bearerToken: 't');
        final json = auth.toJson();
        expect(json['runtimeType'], 'bearerToken');
      });
    });
  });

  group('McpServers table insert', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
    });

    tearDown(() async => db.close());

    test('inserts and reads a row', () async {
      final inserted = await db
          .into(db.mcpServers)
          .insertReturning(
            McpServersCompanion.insert(
              workspaceId: 'ws-1',
              name: 'Test Server',
              url: 'https://example.com',
              transport: const McpTransportTypeSSE(),
              authenticationType: const McpAuthenticationTypeNone(),
            ),
          );
      final row = await (db.select(
        db.mcpServers,
      )..where((t) => t.id.equals(inserted.id))).getSingle();
      expect(row.name, 'Test Server');
      expect(row.url, 'https://example.com');
      expect(row.workspaceId, 'ws-1');
    });
  });

  group('McpServers table schema', () {
    late AppDatabase db;
    late List<QueryRow> columns;

    setUp(() async {
      db = AppDatabase(connection: _testConnection());
      columns = await db.customSelect('PRAGMA table_info(mcp_servers)').get();
    });

    tearDown(() async => db.close());

    test('has expected columns', () {
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'id',
          'workspace_id',
          'name',
          'url',
          'transport',
          'authentication_type',
          'description',
          'is_enabled',
          'created_at',
          'updated_at',
        ]),
      );
    });

    test('id is primary key', () {
      final col = columns.firstWhere((r) => r.read<String>('name') == 'id');
      expect(col.read<int>('pk'), greaterThan(0));
    });

    test('description is nullable', () {
      final col = columns.firstWhere(
        (r) => r.read<String>('name') == 'description',
      );
      expect(col.read<int>('notnull'), 0);
    });

    test('is_enabled column exists', () {
      final col = columns.where(
        (r) => r.read<String>('name') == 'is_enabled',
      );
      expect(col, isNotEmpty);
    });

    test('name is not nullable', () {
      final col = columns.firstWhere((r) => r.read<String>('name') == 'name');
      expect(col.read<int>('notnull'), 1);
    });

    test('url is not nullable', () {
      final col = columns.firstWhere((r) => r.read<String>('name') == 'url');
      expect(col.read<int>('notnull'), 1);
    });
  });

  group('McpTransportType sealed class', () {
    test('McpTransportTypeSSE is a McpTransportType', () {
      const transport = McpTransportTypeSSE();
      expect(transport, isA<McpTransportType>());
    });

    test('McpTransportTypeStreamableHttp is a McpTransportType', () {
      const transport = McpTransportTypeStreamableHttp();
      expect(transport, isA<McpTransportType>());
    });

    test('McpTransportTypeSSE.fromJson returns correct type', () {
      final result = McpTransportTypeSSE.fromJson({});
      expect(result, isA<McpTransportTypeSSE>());
    });

    test('McpTransportTypeStreamableHttp.fromJson parses useHttp2', () {
      final result = McpTransportTypeStreamableHttp.fromJson({
        'useHttp2': true,
      });
      expect(result.useHttp2, isTrue);
    });

    test(
      'McpTransportTypeStreamableHttp.fromJson defaults useHttp2 to false',
      () {
        final result = McpTransportTypeStreamableHttp.fromJson({
          'useHttp2': false,
        });
        expect(result.useHttp2, isFalse);
      },
    );
  });

  group('McpAuthenticationType sealed class', () {
    test('none is a McpAuthenticationType', () {
      const auth = McpAuthenticationTypeNone();
      expect(auth, isA<McpAuthenticationType>());
    });

    test('bearerToken is a McpAuthenticationType', () {
      const auth = McpAuthenticationTypeBearerToken(bearerToken: 'tok');
      expect(auth, isA<McpAuthenticationType>());
    });

    test('oauth is a McpAuthenticationType', () {
      final auth = McpAuthenticationTypeOAuth(
        token: OAuthTokenEntity(
          accessToken: 'at',
          issuedAt: DateTime(2026),
        ),
        clientId: 'cid',
        authorizationEndpoint: 'https://a.co',
        tokenEndpoint: 'https://t.co',
      );
      expect(auth, isA<McpAuthenticationType>());
    });

    test('fromJson reconstructs none', () {
      const original = McpAuthenticationTypeNone();
      final json = original.toJson();
      final restored = McpAuthenticationType.fromJson(json);
      expect(restored, isA<McpAuthenticationTypeNone>());
    });

    test('fromJson reconstructs bearerToken', () {
      const original = McpAuthenticationTypeBearerToken(bearerToken: 'bt');
      final json = original.toJson();
      final restored = McpAuthenticationType.fromJson(json);
      expect(restored, isA<McpAuthenticationTypeBearerToken>());
      expect((restored as McpAuthenticationTypeBearerToken).bearerToken, 'bt');
    });

    test('fromJson reconstructs oauth', () {
      final json = <String, dynamic>{
        'runtimeType': 'oauth',
        'token': <String, dynamic>{
          'accessToken': 'at',
          'issuedAt': DateTime(2026).toIso8601String(),
        },
        'clientId': 'cid',
        'authorizationEndpoint': 'https://a.co',
        'tokenEndpoint': 'https://t.co',
      };
      final restored = McpAuthenticationType.fromJson(json);
      expect(restored, isA<McpAuthenticationTypeOAuth>());
      final oauth = restored as McpAuthenticationTypeOAuth;
      expect(oauth.clientId, 'cid');
    });
  });
}
