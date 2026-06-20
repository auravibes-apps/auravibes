import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:riverpod/riverpod.dart';

class ServiceConnectionsActionUsecase {
  const ServiceConnectionsActionUsecase(
    this._reconnectMcpServer,
    this._forceRefresh,
  );

  final Future<void> Function(String mcpServerId) _reconnectMcpServer;
  final Future<OAuthTokenEntity> Function(String connectionId) _forceRefresh;

  Future<void> reconnectMcpServer(String mcpServerId) {
    return _reconnectMcpServer(mcpServerId);
  }

  Future<void> refreshMcpCredential({
    required String connectionId,
    required String mcpServerId,
  }) async {
    final _ = await _forceRefresh(connectionId);
    await reconnectMcpServer(mcpServerId);
  }
}

// coverage:ignore-start
// Required: Riverpod provider wiring is exercised through widget tests.
final serviceConnectionsActionUsecaseProvider =
    Provider<ServiceConnectionsActionUsecase>((ref) {
      return ServiceConnectionsActionUsecase(
        ref.watch(mcpConnectionProvider.notifier).reconnectMcpServer,
        ref.watch(oauthCredentialServiceProvider).forceRefresh,
      );
    });
// coverage:ignore-end
