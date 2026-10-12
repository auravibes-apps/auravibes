import 'dart:async';

import 'package:async/async.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_url_template_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        SkillCredentialAttributeDefinition,
        SkillTemplateInputDefinition,
        SkillUrlTemplate,
        UrlResponse;
import 'package:auravibes_engine/auravibes_engine.dart' as package_skills;
import 'package:riverpod/riverpod.dart';

typedef _TemplateExecutionRequest = ({
  package_skills.SkillTemplateDefinition definition,
  SkillUrlTemplate template,
  Map<String, dynamic> inputs,
  Map<String, String> credentials,
  Map<String, SkillTemplateInputDefinition> inputDefinitions,
  Map<String, SkillCredentialAttributeDefinition> credentialDefinitions,
});

typedef _TemplateToolRequest = ({
  String workspaceId,
  SkillEntity skill,
  SkillTemplateToolEntity tool,
  Map<String, dynamic> arguments,
});

typedef _TemplateInvocationRequest = ({
  String workspaceId,
  String skillSlug,
  String toolSlug,
  Map<String, dynamic> arguments,
});

typedef _CredentialResolutionRequest = ({
  String workspaceId,
  String? credentialDefinitionId,
  String? credentialId,
  bool requiresCredential,
});

typedef _TemplateInputRequest = ({
  package_skills.SkillTemplateDefinition definition,
  SkillTemplateToolEntity tool,
  Map<String, dynamic> arguments,
  Map<String, String> credentials,
  Map<String, SkillCredentialAttributeDefinition> credentialDefinitions,
});

class const RunSkillTemplateToolUsecase(
  final SkillTemplateToolsRepository _skillTemplateToolsRepository,
  final SkillsRepository _skillsRepository,
  final SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepository,
  final SkillCredentialsRepository _skillCredentialsRepository,
  final package_skills.SkillTemplateExecutor _templateExecutor,
  final Future<WorkspaceSession> Function(String workspaceId) _workspaceSession,
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
  }) => _CancelableTemplateToolCall(this, (
    workspaceId: workspaceId,
    skillSlug: skillSlug,
    toolSlug: toolSlug,
    arguments: arguments,
  )).start();
}

class _CancelableTemplateToolCall(
  final RunSkillTemplateToolUsecase _usecase,
  final _TemplateInvocationRequest _request,
) {
  CancelableOperation<UrlResponse>? _httpOperation;

  CancelableOperation<Object?> start() {
    final completer = CancelableCompleter<Object?>(
      onCancel: _cancelHttpOperation,
    );
    unawaited(_run(completer));

    return completer.operation;
  }

  Future<void> _cancelHttpOperation() async {
    final httpOperation = _httpOperation;
    if (httpOperation != null) {
      final _ = await httpOperation.cancel();
    }
  }

  Future<void> _run(CancelableCompleter<Object?> completer) async {
    try {
      final response = await _resolveTemplateResponse(completer);
      if (response == null || completer.isCanceled) return;

      completer.complete(response.body);
    } on Object catch (error, stackTrace) {
      if (!completer.isCanceled) completer.completeError(error, stackTrace);
    }
  }

  Future<UrlResponse?> _resolveTemplateResponse(
    CancelableCompleter<Object?> completer,
  ) async {
    final workspaceId = _request.workspaceId;
    final session = await _usecase._workspaceSession(workspaceId);
    _usecase._ensureLocalSession(session);
    if (completer.isCanceled) return null;

    return await _resolveEnabledTemplateSkill(completer, workspaceId);
  }

  Future<UrlResponse?> _resolveEnabledTemplateSkill(
    CancelableCompleter<Object?> completer,
    String workspaceId,
  ) async {
    final skill = await _usecase._loadEnabledSkill(
      workspaceId,
      _request.skillSlug,
    );
    if (skill == null) return _completeMissingTemplatePart(completer);
    if (completer.isCanceled) return null;

    return await _resolveEnabledTemplateTool(completer, workspaceId, skill);
  }

  Future<UrlResponse?> _resolveEnabledTemplateTool(
    CancelableCompleter<Object?> completer,
    String workspaceId,
    SkillEntity skill,
  ) async {
    final tool = await _usecase._loadEnabledTool(skill.id, _request.toolSlug);
    if (tool == null) return _completeMissingTemplatePart(completer);
    if (completer.isCanceled) return null;

    final execution = await _usecase._templateExecutionRequest((
      workspaceId: workspaceId,
      skill: skill,
      tool: tool,
      arguments: _request.arguments,
    ));
    if (completer.isCanceled) return null;

    return await _executeTemplate(execution);
  }

  UrlResponse? _completeMissingTemplatePart(
    CancelableCompleter<Object?> completer,
  ) {
    completer.complete(null);

    return null;
  }

  Future<UrlResponse?> _executeTemplate(_TemplateExecutionRequest execution) {
    final operation = _usecase._templateExecutor.call(
      definition: execution.definition,
      inputs: execution.inputs,
      credentials: execution.credentials,
      schema: execution.definition.inputSchema,
      credentialDefinitions: execution.credentialDefinitions,
    );
    _httpOperation = operation;

    return operation.valueOrCancellation();
  }
}

extension on RunSkillTemplateToolUsecase {
  void _ensureLocalSession(WorkspaceSession session) {
    if (session.cloud != null) {
      throw StateError(
        'Cloud template tools execute in the server agent loop.',
      );
    }
  }

  Future<SkillEntity?> _loadEnabledSkill(
    String workspaceId,
    String skillSlug,
  ) async {
    final skill = await _skillsRepository.getSkillBySlug(
      workspaceId,
      skillSlug,
    );

    return skill == null || !skill.isEnabled ? null : skill;
  }

  Future<SkillTemplateToolEntity?> _loadEnabledTool(
    String skillId,
    String toolSlug,
  ) async {
    final tool = await _skillTemplateToolsRepository.getToolBySlug(
      skillId,
      toolSlug,
    );

    return tool == null || !tool.isEnabled ? null : tool;
  }

  Future<_TemplateExecutionRequest> _templateExecutionRequest(
    _TemplateToolRequest request,
  ) async {
    final credential = await _resolveCredential(_credentialRequest(request));
    final definition = _definition(request.tool);
    final storedCredentialDefinitions = await _storedCredentialDefinitions(
      request,
    );
    final credentialAttributes = await _credentialAttributes(credential);

    return _templateRequest((
      definition: definition,
      tool: request.tool,
      arguments: request.arguments,
      credentials: credentialAttributes,
      credentialDefinitions: {
        ...definition.credentialDefinitions,
        ...storedCredentialDefinitions,
      },
    ));
  }

  Future<Map<String, SkillCredentialAttributeDefinition>>
  _storedCredentialDefinitions(_TemplateToolRequest request) =>
      _credentialDefinitions(
        request.tool.credentialDefinitionId ??
            request.skill.credentialDefinitionId,
      );

  _CredentialResolutionRequest _credentialRequest(
    _TemplateToolRequest request,
  ) => (
    workspaceId: request.workspaceId,
    credentialDefinitionId:
        request.tool.credentialDefinitionId ??
        request.skill.credentialDefinitionId,
    credentialId: request.arguments['credentialId'] as String?,
    requiresCredential: request.tool.requiresCredential,
  );

  Future<Map<String, String>> _credentialAttributes(
    SkillCredentialEntity? credential,
  ) {
    if (credential == null) return Future.value(const {});

    return _skillCredentialsRepository.readCredentialAttributes(credential.id);
  }

  _TemplateExecutionRequest _templateRequest(_TemplateInputRequest request) {
    final definition = request.definition;
    final template = definition.request;
    final inputs = request.arguments;
    final credentials = request.credentials;
    final inputDefinitions = definition.inputs;
    final credentialDefinitions = request.credentialDefinitions;

    return (
      definition: definition,
      template: template,
      inputs: inputs,
      credentials: credentials,
      inputDefinitions: inputDefinitions,
      credentialDefinitions: credentialDefinitions,
    );
  }

  Future<SkillCredentialEntity?> _resolveCredential(
    _CredentialResolutionRequest request,
  ) async {
    final credentialDefinitionId = request.credentialDefinitionId;
    if (credentialDefinitionId == null) {
      if (request.requiresCredential) {
        throw StateError('Skill tool requires a credential definition.');
      }

      return null;
    }

    final normalizedCredentialId = await _credentialId(request);
    if (normalizedCredentialId == null) return null;

    final credential = await _findUsableCredential(
      request,
      credentialDefinitionId,
      normalizedCredentialId,
    );
    _ensureCredentialAvailable(
      credential,
      request.workspaceId,
      credentialDefinitionId,
    );

    return credential;
  }

  Future<SkillCredentialEntity?> _findUsableCredential(
    _CredentialResolutionRequest request,
    String credentialDefinitionId,
    String credentialId,
  ) async =>
      (await _skillCredentialsRepository.getUsableCredentialsForDefinition(
        workspaceId: request.workspaceId,
        credentialDefinitionId: credentialDefinitionId,
      )).where((item) => item.id == credentialId).firstOrNull;

  Future<String?> _credentialId(_CredentialResolutionRequest request) {
    final normalizedCredentialId = request.credentialId?.trim();
    if (normalizedCredentialId case final credentialId?
        when credentialId.isNotEmpty) {
      return Future.value(credentialId);
    }
    if (!request.requiresCredential) return Future<String?>.value();

    return _missingCredentialId();
  }

  Never _missingCredentialId() =>
      throw StateError('Skill tool requires a credentialId argument.');

  void _ensureCredentialAvailable(
    SkillCredentialEntity? credential,
    String workspaceId,
    String credentialDefinitionId,
  ) {
    if (_isCredentialAvailable(
      credential,
      workspaceId,
      credentialDefinitionId,
    )) {
      return;
    }

    throw StateError('Skill credential is not available for this tool.');
  }

  bool _isCredentialAvailable(
    SkillCredentialEntity? credential,
    String workspaceId,
    String credentialDefinitionId,
  ) =>
      credential != null &&
      credential.workspaceId == workspaceId &&
      credential.credentialDefinitionId == credentialDefinitionId &&
      credential.isEnabled;
}

extension on RunSkillTemplateToolUsecase {
  package_skills.SkillTemplateDefinition _definition(
    SkillTemplateToolEntity tool,
  ) {
    final source = tool.definitionJson.trim();
    if (source.isNotEmpty && source != '{}') {
      return package_skills.SkillTemplateDefinition.fromJsonString(source);
    }

    return package_skills.SkillTemplateDefinition.fromLegacyJson(
      templateJson: tool.templateJson,
      inputsJson: tool.inputsJson,
    );
  }
}

extension on RunSkillTemplateToolUsecase {
  Future<Map<String, SkillCredentialAttributeDefinition>>
  _credentialDefinitions(String? credentialDefinitionId) async {
    if (credentialDefinitionId == null) return const {};
    final definition = await _skillCredentialDefinitionsRepository
        .getDefinitionById(credentialDefinitionId);
    if (definition == null) {
      throw StateError('Skill credential definition not found.');
    }

    return SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );
  }
}

final runSkillTemplateToolUsecaseProvider =
    Provider<RunSkillTemplateToolUsecase>((ref) {
      return RunSkillTemplateToolUsecase(
        ref.watch(skillTemplateToolsRepositoryProvider),
        ref.watch(skillsRepositoryProvider),
        ref.watch(skillCredentialDefinitionsRepositoryProvider),
        ref.watch(skillCredentialsRepositoryProvider),
        ref.watch(runSkillUrlTemplateUsecaseProvider),
        (workspaceId) =>
            ref.read(workspaceSessionForRouteProvider(workspaceId).future),
      );
    });
