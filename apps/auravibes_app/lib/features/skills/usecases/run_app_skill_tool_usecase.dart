import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/app_skill_http_client_adapter.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:auravibes_app/services/skills/app_skill_registry.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_skills/auravibes_skills.dart';
import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';

class RunAppSkillToolUsecase {
  RunAppSkillToolUsecase(
    this._appSkillRegistry,
    this._serviceConnectionRepository,
    this._skillCredentialsRepository,
    this._listAppSkillCredentialCandidatesUsecase,
    this._appSkillExecutor,
    this._oauthCredentialService,
  );

  final AppSkillRegistry _appSkillRegistry;
  final ServiceConnectionRepository _serviceConnectionRepository;
  final SkillCredentialsRepository _skillCredentialsRepository;
  final ListAppSkillCredentialCandidatesUsecase
  _listAppSkillCredentialCandidatesUsecase;
  final AppSkillExecutor _appSkillExecutor;
  final OAuthCredentialService? _oauthCredentialService;

  Future<Object?> call({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) {
    final operation = callCancelable(
      workspaceId: workspaceId,
      skillSlug: skillSlug,
      toolSlug: toolSlug,
      arguments: arguments,
    );

    return operation.valueOrCancellation();
  }

  CancelableOperation<Object?> callCancelable({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) {
    CancelableOperation<Object?>? innerOperation;
    final completer = CancelableCompleter<Object?>(
      onCancel: () => innerOperation?.cancel(),
    );

    () async {
      try {
        final resolved = await _resolveCredentialForTool(
          workspaceId: workspaceId,
          skillSlug: skillSlug,
          toolSlug: toolSlug,
          arguments: arguments,
        );
        if (completer.isCanceled) return;
        innerOperation = _appSkillExecutor.run(
          skill: resolved.skill,
          toolSlug: toolSlug,
          input: arguments,
          credentials: resolved.credentials,
        );
        final result = await innerOperation?.valueOrCancellation();
        if (!completer.isCanceled) completer.complete(result);
      } on Object catch (error, stackTrace) {
        if (!completer.isCanceled) {
          completer.completeError(error, stackTrace);
        }
      }
    }();

    return completer.operation;
  }

  Future<({AppSkillDefinition skill, Map<String, String> credentials})>
  _resolveCredentialForTool({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) async {
    final skill = _appSkillRegistry.getBySlug(skillSlug);
    final tool = skill?.nativeTools
        .where((tool) => tool.slug == toolSlug)
        .firstOrNull;
    if (skill == null || tool == null) {
      throw UnsupportedError('Unknown app skill tool: $skillSlug/$toolSlug');
    }

    return (
      skill: skill,
      credentials: await _resolveCredential(
        workspaceId: workspaceId,
        skill: skill,
        tool: tool,
        credentialId: arguments['credentialId'],
      ),
    );
  }

  Future<Map<String, String>> _resolveCredential({
    required String workspaceId,
    required AppSkillDefinition skill,
    required AppSkillToolDefinition tool,
    required Object? credentialId,
  }) async {
    if (!tool.requiresCredential) return const {};
    final candidates = await _listAppSkillCredentialCandidatesUsecase.call(
      workspaceId: workspaceId,
      skill: skill,
    );
    final trimmed = switch (credentialId) {
      final String value when value.trim().isNotEmpty => value.trim(),
      _ when candidates.length == 1 => candidates.single.id,
      _ => throw StateError('App skill tool requires a credentialId argument.'),
    };
    if (!candidates.any((candidate) => candidate.id == trimmed)) {
      throw StateError('Credential is not available for this app skill tool.');
    }
    if (trimmed.startsWith('skill:')) {
      return _skillCredentialsRepository.readCredentialAttributes(
        trimmed.replaceFirst('skill:', ''),
      );
    }
    if (trimmed.startsWith('service:')) {
      return _serviceConnectionAttributes(
        workspaceId: workspaceId,
        connectionId: trimmed.replaceFirst('service:', ''),
        skill: skill,
      );
    }
    if (trimmed.startsWith('model:')) {
      return _serviceConnectionAttributes(
        workspaceId: workspaceId,
        connectionId: trimmed.replaceFirst('model:', ''),
        skill: skill,
      );
    }

    throw StateError('Unsupported app skill credentialId: $trimmed');
  }

  Future<Map<String, String>> _serviceConnectionAttributes({
    required String workspaceId,
    required String connectionId,
    required AppSkillDefinition skill,
  }) async {
    final connection = await _serviceConnectionRepository.getById(
      connectionId,
    );
    if (connection == null ||
        connection.workspaceId != workspaceId ||
        !connection.isEnabled) {
      throw StateError('Service connection is not available for this tool.');
    }

    final secret = await _serviceConnectionRepository.readSecret(connectionId);

    final metadata = ServiceConnectionAuthCodec.decodeMetadata(
      connection.metadataJson,
    );

    return switch (secret) {
      ServiceConnectionSecretApiKey(:final apiKey) => {
        'apiKey': apiKey,
        if (skill.slug == 'searxng') 'baseUrl': apiKey,
      },
      ServiceConnectionSecretBearerToken(:final bearerToken) => {
        'apiKey': bearerToken,
        'bearerToken': bearerToken,
      },
      ServiceConnectionSecretOAuth2(:final accessToken) =>
        await _oauthAttributes(connectionId, accessToken, metadata),
    };
  }

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

    return service.getValidAccessToken(connectionId);
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
    AppSkillExecutor(
      RunSkillUrlTemplate(const ResolveSkillUrlTemplate(), httpClient.execute),
      httpClient.execute,
    ),
    ref.watch(oauthCredentialServiceProvider),
  );
});
