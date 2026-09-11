import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/domain/entities/service_connection_entity.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/app_skill_http_client_adapter.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';

typedef _RunRequest = ({
  String workspaceId,
  String skillSlug,
  String toolSlug,
  Map<String, dynamic> arguments,
});

typedef _ResolvedTool = ({
  AppSkillDefinition skill,
  Map<String, String> credentials,
});

typedef _CredentialRequest = ({
  String workspaceId,
  AppSkillDefinition skill,
  AppSkillToolDefinition tool,
  Object? credentialId,
});

typedef _ConnectionRequest = ({
  String workspaceId,
  String connectionId,
  AppSkillDefinition skill,
});

typedef _SecretAttributesRequest = ({
  _ConnectionRequest request,
  ServiceConnectionSecret secret,
  ServiceConnectionMetadata metadata,
});

class RunAppSkillToolUsecase(
  final AppSkillRegistry _appSkillRegistry,
  final ServiceConnectionRepository _serviceConnectionRepository,
  final SkillCredentialsRepository _skillCredentialsRepository,
  final ListAppSkillCredentialCandidatesUsecase
  _listAppSkillCredentialCandidatesUsecase,
  final AppSkillExecutor _appSkillExecutor,
  final OAuthCredentialService? _oauthCredentialService,
) {
  Future<Object?> call({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) => callCancelable(
    workspaceId: workspaceId,
    skillSlug: skillSlug,
    toolSlug: toolSlug,
    arguments: arguments,
  ).valueOrCancellation();

  CancelableOperation<Object?> callCancelable({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) => _startCancelable(this, (
    workspaceId: workspaceId,
    skillSlug: skillSlug,
    toolSlug: toolSlug,
    arguments: arguments,
  ));
}

extension _RunAppSkillCredentialOperations on RunAppSkillToolUsecase {
  Future<_ResolvedTool> _resolveCredentialForTool(_RunRequest request) async {
    final target = _requiredTool(request.skillSlug, request.toolSlug);
    final skill = target.skill;

    return (
      skill: skill,
      credentials: await _resolveCredential((
        workspaceId: request.workspaceId,
        skill: skill,
        tool: target.tool,
        credentialId: request.arguments['credentialId'],
      )),
    );
  }

  ({AppSkillDefinition skill, AppSkillToolDefinition tool}) _requiredTool(
    String skillSlug,
    String toolSlug,
  ) {
    final skill = _appSkillRegistry.getBySlug(skillSlug);
    final tool = _findTool(skill, toolSlug);
    if (skill == null || tool == null) {
      throw UnsupportedError('Unknown app skill tool: $skillSlug/$toolSlug');
    }

    return (skill: skill, tool: tool);
  }

  AppSkillToolDefinition? _findTool(
    AppSkillDefinition? skill,
    String toolSlug,
  ) => skill?.nativeTools.where((tool) => tool.slug == toolSlug).firstOrNull;

  Future<Map<String, String>> _resolveCredential(
    _CredentialRequest request,
  ) async {
    final tool = request.tool;
    if (!tool.requiresCredential) return const {};
    final candidates = await _listAppSkillCredentialCandidatesUsecase.call(
      workspaceId: request.workspaceId,
      skill: request.skill,
    );
    final credentialId = _credentialId(request.credentialId, candidates);
    _validateCredential(candidates, credentialId);

    return _credentialAttributes(request, credentialId);
  }

  String _credentialId(
    Object? credentialId,
    List<AppSkillCredentialCandidate> candidates,
  ) => switch (credentialId) {
    final String value when value.trim().isNotEmpty => value.trim(),
    _ when candidates.length == 1 => candidates.single.id,
    _ => throw StateError('App skill tool requires a credentialId argument.'),
  };

  void _validateCredential(
    List<AppSkillCredentialCandidate> candidates,
    String credentialId,
  ) {
    if (!candidates.any((candidate) => candidate.id == credentialId)) {
      throw StateError('Credential is not available for this app skill tool.');
    }
  }
}

extension on RunAppSkillToolUsecase {
  Future<Map<String, String>> _credentialAttributes(
    _CredentialRequest request,
    String credentialId,
  ) {
    if (credentialId.startsWith('skill:')) {
      return _skillCredentialsRepository.readCredentialAttributes(
        credentialId.replaceFirst('skill:', ''),
      );
    }

    return _externalCredentialAttributes(request, credentialId);
  }

  Future<Map<String, String>> _externalCredentialAttributes(
    _CredentialRequest request,
    String credentialId,
  ) {
    final isServiceCredential = credentialId.startsWith('service:');
    final isModelCredential = credentialId.startsWith('model:');
    if (isServiceCredential || isModelCredential) {
      final prefix = isServiceCredential ? 'service:' : 'model:';
      return _serviceConnectionAttributes((
        workspaceId: request.workspaceId,
        connectionId: credentialId.replaceFirst(prefix, ''),
        skill: request.skill,
      ));
    }

    throw StateError('Unsupported app skill credentialId: $credentialId');
  }

  Future<Map<String, String>> _serviceConnectionAttributes(
    _ConnectionRequest request,
  ) async {
    final connection = await _availableConnection(request);
    return await _connectionAttributes(request, connection);
  }

  Future<ServiceConnectionEntity> _availableConnection(
    _ConnectionRequest request,
  ) async {
    final connection = await _serviceConnectionRepository.getById(
      request.connectionId,
    );
    if (connection == null ||
        connection.workspaceId != request.workspaceId ||
        !connection.isEnabled) {
      throw StateError('Service connection is not available for this tool.');
    }

    return connection;
  }

  Future<Map<String, String>> _connectionAttributes(
    _ConnectionRequest request,
    ServiceConnectionEntity connection,
  ) async {
    final secret = await _serviceConnectionRepository.readSecret(
      request.connectionId,
    );

    final metadata = ServiceConnectionAuthCodec.decodeMetadata(
      connection.metadataJson,
    );

    return await _secretAttributes((
      request: request,
      secret: secret,
      metadata: metadata,
    ));
  }
}

extension _RunAppSkillSecretOperations on RunAppSkillToolUsecase {
  Future<Map<String, String>> _secretAttributes(
    _SecretAttributesRequest request,
  ) async {
    return switch (request.secret) {
      ServiceConnectionSecretApiKey(:final apiKey) => _apiKeyAttributes(
        request.request.skill,
        apiKey,
      ),
      ServiceConnectionSecretBearerToken(:final bearerToken) =>
        _bearerAttributes(bearerToken),
      ServiceConnectionSecretOAuth2(:final accessToken) =>
        _oauthSecretAttributes(request, accessToken),
    };
  }

  Future<Map<String, String>> _oauthSecretAttributes(
    _SecretAttributesRequest request,
    String accessToken,
  ) => _oauthAttributes(
    request.request.connectionId,
    accessToken,
    request.metadata,
  );

  Map<String, String> _apiKeyAttributes(
    AppSkillDefinition skill,
    String apiKey,
  ) => {'apiKey': apiKey, if (skill.slug == 'searxng') 'baseUrl': apiKey};

  Map<String, String> _bearerAttributes(String bearerToken) => {
    'apiKey': bearerToken,
    'bearerToken': bearerToken,
  };

  Future<Map<String, String>> _oauthAttributes(
    String connectionId,
    String fallbackAccessToken,
    ServiceConnectionMetadata metadata,
  ) async {
    final accessToken = await _oauthAccessToken(
      connectionId,
      fallbackAccessToken,
    );

    return {
      'apiKey': accessToken,
      'accessToken': accessToken,
      if (metadata.accountId case final accountId? when accountId.isNotEmpty)
        'accountId': accountId,
      if (metadata.provider case final provider? when provider.isNotEmpty)
        'providerId': provider,
    };
  }

  Future<String> _oauthAccessToken(
    String connectionId,
    String fallbackAccessToken,
  ) async {
    final service = _oauthCredentialService;
    if (service == null) return fallbackAccessToken;

    return await service.getValidAccessToken(connectionId);
  }
}

CancelableOperation<Object?> _startCancelable(
  RunAppSkillToolUsecase usecase,
  _RunRequest request,
) => _CancelableToolOperation(usecase, request).start();

class _CancelableToolOperation {
  new(this._usecase, this._request);

  final RunAppSkillToolUsecase _usecase;
  final _RunRequest _request;
  CancelableOperation<Object?>? _innerOperation;

  CancelableOperation<Object?> start() {
    final completer = CancelableCompleter<Object?>(
      onCancel: () => _innerOperation?.cancel(),
    );
    _run(completer);

    return completer.operation;
  }

  Future<void> _run(CancelableCompleter<Object?> completer) async {
    try {
      await _completeSuccess(completer);
    } on Object catch (error, stackTrace) {
      _completeError(completer, error, stackTrace);
    }
  }

  void _completeError(
    CancelableCompleter<Object?> completer,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!completer.isCanceled) completer.completeError(error, stackTrace);
  }

  Future<void> _completeSuccess(CancelableCompleter<Object?> completer) async {
    final resolved = await _usecase._resolveCredentialForTool(_request);
    if (completer.isCanceled) return;

    final result = await _execute(resolved);
    if (!completer.isCanceled) completer.complete(result);
  }

  Future<Object?> _execute(_ResolvedTool resolved) {
    final operation = _usecase._appSkillExecutor.run(
      skill: resolved.skill,
      toolSlug: _request.toolSlug,
      input: _request.arguments,
      credentials: resolved.credentials,
    );
    _innerOperation = operation;

    return operation.valueOrCancellation();
  }
}

final runAppSkillToolUsecaseProvider = Provider<RunAppSkillToolUsecase>((ref) {
  final urlService = UrlService();
  final httpClient = AppSkillHttpClientAdapter(urlService);

  return RunAppSkillToolUsecase(
    ref.watch(appSkillRegistryProvider),
    ref.watch(serviceConnectionRepositoryProvider),
    ref.watch(skillCredentialsRepositoryProvider),
    ref.watch(listAppSkillCredentialCandidatesUsecaseProvider),
    .new(
      .new(const ResolveSkillUrlTemplate(), httpClient.execute),
      httpClient.execute,
    ),
    ref.watch(oauthCredentialServiceProvider),
  );
});
