import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/service_connection_entity.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/connector_http_client_adapter.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';

typedef _ConnectorToolRequest = ({
  String workspaceId,
  String connectorId,
  String toolSlug,
  Map<String, dynamic> arguments,
});

typedef _ConnectorToolCredential = ({
  ConnectorDefinition connector,
  ConnectorToolDefinition tool,
  Map<String, String> attributes,
});

typedef _ConnectorToolTarget = ({
  ConnectorDefinition connector,
  ConnectorToolDefinition tool,
});

class const RunConnectorToolUsecase(
  final ServiceConnectionRepository _connectionRepository,
  final ListConnectorConnectionCandidatesUsecase _connectionCandidates,
  final ConnectorToolTemplateExecutor _templateExecutor,
  final OAuthCredentialService? _oauthCredentialService,
) {
  Future<Object?> call({
    required String workspaceId,
    required String connectorId,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) => callCancelable(
    workspaceId: workspaceId,
    connectorId: connectorId,
    toolSlug: toolSlug,
    arguments: arguments,
  ).valueOrCancellation();

  CancelableOperation<Object?> callCancelable({
    required String workspaceId,
    required String connectorId,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) => _ConnectorToolCall(this, (
    workspaceId: workspaceId,
    connectorId: connectorId,
    toolSlug: toolSlug,
    arguments: arguments,
  )).start();
}

extension on RunConnectorToolUsecase {
  _ConnectorToolTarget _resolve(String connectorId, String toolSlug) {
    final connector = _connector(connectorId);
    final tool = connector == null ? null : _connectorTool(connector, toolSlug);
    if (connector == null || tool == null) {
      throw UnsupportedError('Unknown Connector tool: $connectorId/$toolSlug');
    }

    return (connector: connector, tool: tool);
  }

  ConnectorDefinition? _connector(String connectorId) => connectorDefinitions
      .where((item) => item.identifier == connectorId)
      .firstOrNull;

  ConnectorToolDefinition? _connectorTool(
    ConnectorDefinition connector,
    String toolSlug,
  ) => connector.tools
      .where((item) => item.slug == toolSlug && item.urlTemplate != null)
      .firstOrNull;

  Future<_ConnectorToolCredential> _resolveCredential(
    _ConnectorToolRequest request,
  ) async {
    final target = _resolve(request.connectorId, request.toolSlug);
    final connector = target.connector;
    final tool = target.tool;
    if (!tool.requiresConnection) {
      return (
        connector: connector,
        tool: tool,
        attributes: const <String, String>{},
      );
    }

    return await _resolveConnectedCredential(request, connector, tool);
  }

  Future<_ConnectorToolCredential> _resolveConnectedCredential(
    _ConnectorToolRequest request,
    ConnectorDefinition connector,
    ConnectorToolDefinition tool,
  ) async {
    final candidates = await _connectionCandidates.forConnector(
      workspaceId: request.workspaceId,
      connector: connector,
    );
    final connectionId = _selectedConnectionId(
      request.arguments['connectionId'],
      candidates,
    );

    return await _resolveEnabledConnectionCredential(
      connector: connector,
      tool: tool,
      connectionId: connectionId,
    );
  }

  Future<_ConnectorToolCredential> _resolveEnabledConnectionCredential({
    required ConnectorDefinition connector,
    required ConnectorToolDefinition tool,
    required String connectionId,
  }) async {
    final connection = await _enabledConnection(connectionId);
    final attributes = await _connectionAttributes(
      connector: connector,
      connectionId: connectionId,
      connection: connection,
    );

    return (connector: connector, tool: tool, attributes: attributes);
  }

  Future<ServiceConnectionEntity> _enabledConnection(
    String connectionId,
  ) async {
    final connection = await _connectionRepository.getById(connectionId);
    if (connection == null || !connection.isEnabled) {
      throw StateError('Connection is not available for this Connector tool.');
    }

    return connection;
  }

  Future<Map<String, String>> _connectionAttributes({
    required ConnectorDefinition connector,
    required String connectionId,
    required ServiceConnectionEntity connection,
  }) async {
    final secret = await _connectionRepository.readSecret(connectionId);
    final metadata = ServiceConnectionAuthCodec.decodeMetadata(
      connection.metadataJson,
    );

    return await _secretAttributes(
      connector: connector,
      connectionId: connectionId,
      secret: secret,
      metadata: metadata,
    );
  }

  Future<Map<String, String>> _secretAttributes({
    required ConnectorDefinition connector,
    required String connectionId,
    required ServiceConnectionSecret secret,
    required ServiceConnectionMetadata metadata,
  }) => switch (secret) {
    ServiceConnectionSecretApiKey(:final apiKey) => Future.value({
      'apiKey': apiKey,
      if (connector.identifier == 'searxng') 'baseUrl': apiKey,
    }),
    ServiceConnectionSecretBearerToken(:final bearerToken) => Future.value({
      'apiKey': bearerToken,
      'bearerToken': bearerToken,
    }),
    ServiceConnectionSecretOAuth2(:final accessToken) => _oauthAttributes(
      connectionId,
      accessToken,
      metadata,
    ),
    ServiceConnectionSecretHttpHeaders() => throw StateError(
      'HTTP header credentials are not supported by Connector tools.',
    ),
  };

  Future<Map<String, String>> _oauthAttributes(
    String connectionId,
    String fallbackAccessToken,
    ServiceConnectionMetadata metadata,
  ) async {
    final service = _oauthCredentialService;
    final accessToken = service == null
        ? fallbackAccessToken
        : await service.getValidAccessToken(connectionId);

    return {
      'apiKey': accessToken,
      'accessToken': accessToken,
      if (metadata.accountId case final id? when id.isNotEmpty) 'accountId': id,
      if (metadata.provider case final provider? when provider.isNotEmpty)
        'providerId': provider,
    };
  }
}

String _selectedConnectionId(
  Object? requestedId,
  List<ConnectorConnectionCandidate> candidates,
) {
  final selectedId = _selectConnectionId(requestedId, candidates);
  if (!candidates.any((candidate) => candidate.id == selectedId)) {
    throw StateError('Connection is not available for this Connector tool.');
  }

  return selectedId.replaceFirst(RegExp('^(service|model):'), '');
}

String _selectConnectionId(
  Object? requestedId,
  List<ConnectorConnectionCandidate> candidates,
) => switch (requestedId) {
  final String id when id.trim().isNotEmpty => id.trim(),
  _ when candidates.length == 1 => candidates.single.id,
  _ => throw StateError('Connector tool requires a connectionId.'),
};

class _ConnectorToolCall(
  final RunConnectorToolUsecase _usecase,
  final _ConnectorToolRequest _request,
) {
  CancelableOperation<UrlResponse>? _httpOperation;

  CancelableOperation<Object?> start() {
    final completer = CancelableCompleter<Object?>(
      onCancel: () => _httpOperation?.cancel(),
    );
    _run(completer);

    return completer.operation;
  }

  Future<void> _run(CancelableCompleter<Object?> completer) async {
    try {
      final resolved = await _usecase._resolveCredential(_request);
      if (completer.isCanceled) return;
      final result = await _execute(resolved);
      if (!completer.isCanceled) completer.complete(result);
    } on Object catch (error, stackTrace) {
      if (!completer.isCanceled) completer.completeError(error, stackTrace);
    }
  }

  Future<Object?> _execute(_ConnectorToolCredential resolved) async {
    final operation = _usecase._templateExecutor.call(
      definition: resolved.tool.definition,
      inputs: _toolInputs(_request.arguments),
      credentials: resolved.attributes,
      schema: resolved.tool.inputJsonSchema,
    );
    _httpOperation = operation;

    return (await operation.valueOrCancellation())?.body;
  }

  Map<String, dynamic> _toolInputs(Map<String, dynamic> arguments) => {
    for (final entry in arguments.entries)
      if (entry.key != 'connectionId') entry.key: entry.value,
  };
}

final runConnectorToolUsecaseProvider = Provider<RunConnectorToolUsecase>((
  ref,
) {
  final urlService = UrlService();
  final httpClient = ConnectorHttpClientAdapter(urlService);

  return RunConnectorToolUsecase(
    ref.watch(serviceConnectionRepositoryProvider),
    ref.watch(listConnectorConnectionCandidatesUsecaseProvider),
    .new(const ResolveConnectorRequestTemplate(), httpClient.execute),
    ref.watch(oauthCredentialServiceProvider),
  );
});
