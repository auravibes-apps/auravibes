import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/service_connections/usecases/service_connections_action_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

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
      );

      await usecase.refreshMcpCredential(
        connectionId: 'connection-1',
        mcpServerId: 'server-1',
      );

      expect(calls, ['refresh:connection-1', 'reconnect:server-1']);
    });
  });
}
