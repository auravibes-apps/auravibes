import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/connector_http_client_adapter.dart';
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

  ({ConnectorDefinition connector, ConnectorToolDefinition tool}) _resolve(
    String connectorId,
    String toolSlug,
  ) {
    final connector = connectorDefinitions
        .where((item) => item.identifier == connectorId)
        .firstOrNull;
    final tool = connector?.tools
        .where((item) => item.slug == toolSlug && item.urlTemplate != null)
        .firstOrNull;
    if (connector == null || tool == null) {
      throw UnsupportedError('Unknown Connector tool: $connectorId/$toolSlug');
    }

    return (connector: connector, tool: tool);
  }

  Future<_ConnectorToolCredential> _resolveCredential(
    _ConnectorToolRequest request,
  ) async {
    final target = _resolve(request.connectorId, request.toolSlug);
    final tool = target.tool;
    if (!tool.requiresConnection) {
      return (
        connector: target.connector,
        tool: tool,
        attributes: const <String, String>{},
      );
    }
    final candidates = await _connectionCandidates.forConnector(
      workspaceId: request.workspaceId,
      connector: target.connector,
    );
    final selectedId = _selectConnectionId(
      request.arguments['connectionId'],
      candidates,
    );
    if (!candidates.any((candidate) => candidate.id == selectedId)) {
      throw StateError('Connection is not available for this Connector tool.');
    }

    final connectionId = selectedId.replaceFirst(
      RegExp('^(service|model):'),
      '',
    );
    final connection = await _connectionRepository.getById(connectionId);
    if (connection == null || !connection.isEnabled) {
      throw StateError('Connection is not available for this Connector tool.');
    }
    final secret = await _connectionRepository.readSecret(connectionId);
    final metadata = ServiceConnectionAuthCodec.decodeMetadata(
      connection.metadataJson,
    );

    return (
      connector: target.connector,
      tool: tool,
      attributes: await _secretAttributes(
        connector: target.connector,
        connectionId: connectionId,
        secret: secret,
        metadata: metadata,
      ),
    );
  }

  String _selectConnectionId(
    Object? requestedId,
    List<ConnectorConnectionCandidate> candidates,
  ) => switch (requestedId) {
    final String id when id.trim().isNotEmpty => id.trim(),
    _ when candidates.length == 1 => candidates.single.id,
    _ => throw StateError('Connector tool requires a connectionId.'),
  };

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
      final operation = _usecase._templateExecutor.call(
        definition: resolved.tool.definition,
        inputs: _toolInputs(_request.arguments),
        credentials: resolved.attributes,
        schema: resolved.tool.inputJsonSchema,
      );
      _httpOperation = operation;
      final response = await operation.valueOrCancellation();
      if (!completer.isCanceled) completer.complete(response?.body);
    } on Object catch (error, stackTrace) {
      if (!completer.isCanceled) completer.completeError(error, stackTrace);
    }
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
    ConnectorToolTemplateExecutor(
      const ResolveConnectorRequestTemplate(),
      httpClient.execute,
    ),
    ref.watch(oauthCredentialServiceProvider),
  );
});
