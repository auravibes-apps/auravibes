import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/usecases/delete_service_connection_usecase.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:riverpod/riverpod.dart';

class ServiceConnectionsController {
  const ServiceConnectionsController(
    this._reconnectMcpServer,
    this._forceRefresh,
    this._deleteServiceConnection,
  );

  final Future<void> Function(String mcpServerId) _reconnectMcpServer;
  final Future<OAuthTokenEntity> Function(String connectionId) _forceRefresh;
  final DeleteServiceConnectionUsecase _deleteServiceConnection;

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

  Future<void> deleteConnection({
    required String connectionId,
    required ServiceConnectionListItemKind kind,
  }) {
    return _deleteServiceConnection(connectionId: connectionId, kind: kind);
  }
}

// coverage:ignore-start
// Required: Riverpod provider wiring is exercised through widget tests.
final serviceConnectionsControllerProvider =
    Provider<ServiceConnectionsController>((ref) {
      return ServiceConnectionsController(
        ref.watch(mcpConnectionProvider.notifier).reconnectMcpServer,
        ref.watch(oauthCredentialServiceProvider).forceRefresh,
        ref.watch(deleteServiceConnectionUsecaseProvider),
      );
    });
// coverage:ignore-end
