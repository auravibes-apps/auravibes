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
  SkillUrlTemplate template,
  Map<String, dynamic> inputs,
  Map<String, String> credentials,
  Map<String, SkillTemplateInputDefinition> inputDefinitions,
  Map<String, SkillCredentialAttributeDefinition> credentialDefinitions,
});

class const RunSkillTemplateToolUsecase(
  final SkillTemplateToolsRepository _skillTemplateToolsRepository,
  final SkillsRepository _skillsRepository,
  final SkillCredentialDefinitionsRepository
  _skillCredentialDefinitionsRepository,
  final SkillCredentialsRepository _skillCredentialsRepository,
  final package_skills.RunSkillUrlTemplate _runSkillUrlTemplateUsecase,
  final Future<WorkspaceSession> Function(String workspaceId) _workspaceSession,
) {
  Future<Object?> call({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) async {
    final session = await _workspaceSession(workspaceId);
    _ensureLocalSession(session);
    final skill = await _loadEnabledSkill(workspaceId, skillSlug);
    if (skill == null) return null;

    final tool = await _loadEnabledTool(skill.id, toolSlug);
    if (tool == null) return null;

    return _runTool(workspaceId, skill, tool, arguments);
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

  Future<Object?> _runTool(
    String workspaceId,
    SkillEntity skill,
    SkillTemplateToolEntity tool,
    Map<String, dynamic> arguments,
  ) async {
    final credential = await _resolveCredential(
      workspaceId: workspaceId,
      credentialDefinitionId: skill.credentialDefinitionId,
      credentialId: arguments['credentialId'] as String?,
      requiresCredential: tool.requiresCredential,
    );
    final credentialDefinitions = await _credentialDefinitions(
      skill.credentialDefinitionId,
    );
    final credentialAttributes = await _credentialAttributes(credential);

    return _runTemplate(
      tool,
      arguments,
      credentialAttributes,
      credentialDefinitions,
    );
  }

  Future<Map<String, String>> _credentialAttributes(
    SkillCredentialEntity? credential,
  ) {
    if (credential == null) return Future.value(const {});

    return _skillCredentialsRepository.readCredentialAttributes(credential.id);
  }

  Future<Object?> _runTemplate(
    SkillTemplateToolEntity tool,
    Map<String, dynamic> arguments,
    Map<String, String> credentials,
    Map<String, SkillCredentialAttributeDefinition> credentialDefinitions,
  ) => _executeTemplate(
    _templateRequest(tool, arguments, credentials, credentialDefinitions),
  );

  _TemplateExecutionRequest _templateRequest(
    SkillTemplateToolEntity tool,
    Map<String, dynamic> arguments,
    Map<String, String> credentials,
    Map<String, SkillCredentialAttributeDefinition> credentialDefinitions,
  ) => (
    template: SkillUrlTemplate.fromJsonString(tool.templateJson),
    inputs: arguments,
    credentials: credentials,
    inputDefinitions: SkillTemplateInputDefinition.parseMap(tool.inputsJson),
    credentialDefinitions: credentialDefinitions,
  );

  Future<Object?> _executeTemplate(_TemplateExecutionRequest request) async {
    final response = await _runTemplateCall(request);

    return response.body;
  }

  Future<UrlResponse> _runTemplateCall(_TemplateExecutionRequest request) =>
      _runSkillUrlTemplateUsecase
          .call(
            template: request.template,
            inputs: request.inputs,
            credentials: request.credentials,
            inputDefinitions: request.inputDefinitions,
            credentialDefinitions: request.credentialDefinitions,
          )
          .value;

  Future<SkillCredentialEntity?> _resolveCredential({
    required String workspaceId,
    required String? credentialDefinitionId,
    required String? credentialId,
    required bool requiresCredential,
  }) async {
    if (credentialDefinitionId == null) {
      return _missingCredentialDefinition(requiresCredential);
    }
    final normalizedCredentialId = credentialId?.trim();
    if (normalizedCredentialId == null || normalizedCredentialId.isEmpty) {
      return _missingCredentialId(requiresCredential);
    }

    final credential = await _skillCredentialsRepository.getCredentialById(
      normalizedCredentialId,
    );
    _ensureCredentialAvailable(credential, workspaceId, credentialDefinitionId);

    return credential;
  }

  SkillCredentialEntity? _missingCredentialDefinition(bool isRequired) {
    if (isRequired) {
      throw StateError('Skill tool requires a credential definition.');
    }

    return null;
  }

  SkillCredentialEntity? _missingCredentialId(bool isRequired) {
    if (isRequired) {
      throw StateError('Skill tool requires a credentialId argument.');
    }

    return null;
  }

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
