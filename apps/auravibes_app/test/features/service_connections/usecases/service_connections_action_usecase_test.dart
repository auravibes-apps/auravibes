import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/usecases/delete_service_connection_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/service_connections_action_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('ServiceConnectionsActionUsecase', () {
    test('reconnectMcpServer delegates reconnect', () async {
      final calls = <String>[];
      final usecase = ServiceConnectionsActionUsecase(
        (serverId) {
          calls.add('reconnect:$serverId');

          return Future<void>.value();
        },
        (_) async => OAuthTokenEntity(
          accessToken: 'access',
          issuedAt: DateTime(2026),
        ),
        MockDeleteServiceConnectionUsecase(),
      );

      await usecase.reconnectMcpServer('server-1');

      expect(calls, ['reconnect:server-1']);
    });

    test('refreshMcpCredential refreshes before reconnecting', () async {
      final calls = <String>[];
      final usecase = ServiceConnectionsActionUsecase(
        (serverId) {
          calls.add('reconnect:$serverId');

          return Future<void>.value();
        },
        (connectionId) async {
          calls.add('refresh:$connectionId');

          return OAuthTokenEntity(
            accessToken: 'access',
            issuedAt: DateTime(2026),
          );
        },
        MockDeleteServiceConnectionUsecase(),
      );

      await usecase.refreshMcpCredential(
        connectionId: 'connection-1',
        mcpServerId: 'server-1',
      );

      expect(calls, ['refresh:connection-1', 'reconnect:server-1']);
    });

    test('deleteConnection delegates delete usecase', () async {
      final deleteUsecase = MockDeleteServiceConnectionUsecase();
      when(
        () => deleteUsecase(
          connectionId: 'connection-1',
          kind: ServiceConnectionListItemKind.skillCredential,
        ),
      ).thenAnswer((_) => Future<void>.value());
      final usecase = ServiceConnectionsActionUsecase(
        (_) => Future<void>.value(),
        (_) async => OAuthTokenEntity(
          accessToken: 'access',
          issuedAt: DateTime(2026),
        ),
        deleteUsecase,
      );

      await expectLater(
        usecase.deleteConnection(
          connectionId: 'connection-1',
          kind: ServiceConnectionListItemKind.skillCredential,
        ),
        completes,
      );

      verify(
        () => deleteUsecase(
          connectionId: 'connection-1',
          kind: ServiceConnectionListItemKind.skillCredential,
        ),
      ).called(1);
    });
  });
}

class MockDeleteServiceConnectionUsecase extends Mock
    implements DeleteServiceConnectionUsecase {}
