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

final class _DatabaseFixture {
  _DatabaseFixture(this.createConnection);

  final QueryExecutor Function() createConnection;
  AppDatabase? _database;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  void reset() {
    _database = AppDatabase(connection: createConnection());
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
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
            (transportTypeConverter.toJson(transport) ??
                    fail('Expected converter JSON'))
                as Map<String, dynamic>;
        expect(json['type'], 'sse');
      });

      test('converts StreamableHttp to JSON', () {
        const transport = McpTransportTypeStreamableHttp(useHttp2: true);
        final json =
            (transportTypeConverter.toJson(transport) ??
                    fail('Expected converter JSON'))
                as Map<String, dynamic>;
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
  });

  group('McpServers table insert', () {
    final fixture = _DatabaseFixture(_testConnection);

    setUp(fixture.reset);

    tearDown(fixture.close);

    test('inserts and reads a row', () async {
      final inserted = await fixture.database
          .into(fixture.database.mcpServers)
          .insertReturning(
            McpServersCompanion.insert(
              workspaceId: 'ws-1',
              name: 'Test Server',
              url: 'https://example.com',
              transport: const McpTransportTypeSSE(),
            ),
          );
      final row = await (fixture.database.select(
        fixture.database.mcpServers,
      )..where((t) => t.id.equals(inserted.id))).getSingle();
      expect(row.name, 'Test Server');
      expect(row.url, 'https://example.com');
      expect(row.workspaceId, 'ws-1');
    });
  });

  group('McpServers table schema', () {
    final fixture = _DatabaseFixture(_testConnection);
    var columns = <QueryRow>[];

    setUp(() async {
      fixture.reset();
      columns = await fixture.database
          .customSelect('PRAGMA table_info(mcp_servers)')
          .get();
    });

    tearDown(fixture.close);

    test('has expected columns', () {
      final names = columns.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        {
          'id',
          'workspace_id',
          'name',
          'url',
          'transport',
          'service_connection_id',
          'description',
          'is_enabled',
          'created_at',
          'updated_at',
        },
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
