import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_app_skill_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_template_tool_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef ListSkillCredentials = Future<Map<String, Object?>> Function({
  required String conversationId,
  required String workspaceId,
  required Map<String, dynamic> arguments,
});

typedef ListSkillResourceSummaries =
    Future<List<SkillResourceSummary>> Function({
      required String conversationId,
      required String workspaceId,
      required String skillSlug,
    });

typedef LoadSkillResourceContent =
    Future<({String title, String content})?> Function({
      required String conversationId,
      required String workspaceId,
      required String skillSlug,
      required String resourceSlug,
    });

typedef RunSkillNativeToolRequest = ({
  String conversationId,
  String workspaceId,
  AgentResolvedToolName target,
  Map<String, dynamic> arguments,
});

typedef RunSkillNativeTool = Future<Object?> Function(
  RunSkillNativeToolRequest request,
);

typedef RunSkillCommandRequest = ({
  String conversationId,
  String workspaceId,
  String commandName,
  Map<String, dynamic> arguments,
});

typedef _SkillToolExecutionRequest = ({
  String conversationId,
  String workspaceId,
  AgentResolvedToolName target,
  SkillCommandTarget command,
});

typedef _SkillActivation = ({
  AvailableSkill skill,
  _SkillManifestRequest manifestRequest,
  SkillManifest manifest,
  List<SkillCredentialOption> credentials,
});

class const _SkillManifestRequest({
  required final String conversationId,
  required final String workspaceId,
  required final String slug,
  required final String? revision,
});

class const RunSkillCommandUsecase({
  required final ListAvailableSkillsUsecase Function(String workspaceId)
  listAvailableSkillsUsecase,
  required final LoadConversationSkillUsecase Function(String workspaceId)
  loadConversationSkillUsecase,
  required final BuildLoadedSkillManifestsUsecase
  buildLoadedSkillManifestsUsecase,
  required final BuildSkillTemplateToolSpecsUsecase
  buildSkillTemplateToolSpecsUsecase,
  required final BuildAppSkillNativeToolSpecsUsecase
  buildAppSkillNativeToolSpecsUsecase,
  required final RunSkillTemplateToolUsecase runSkillTemplateToolUsecase,
  required final RunAppSkillToolUsecase runAppSkillToolUsecase,
  required final ListSkillCredentials listSkillCredentials,
  final ListSkillCredentials? listCatalogSkillCredentials,
  final ListSkillResourceSummaries? listSkillResourceSummaries,
  final LoadSkillResourceContent? loadSkillResourceContent,
  final RunSkillNativeTool? runSkillNativeTool,
}) {
  Future<Object?> call(RunSkillCommandRequest request) =>
      _runSkillCommand(this, request);
}

Future<Object?> _runSkillCommand(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
) => switch (request.commandName) {
  activateSkillToolName => _activateSkillCommand(usecase, request),
  listSkillCredentialsToolName => _listSkillCredentialsCommand(
    usecase,
    request,
  ),
  loadSkillResourceToolName => _loadSkillResourceCommand(usecase, request),
  callSkillToolName => _callSkillCommand(usecase, request),
  _ => throw FormatException('Unknown skill command: ${request.commandName}'),
};

Future<Map<String, Object?>> _listSkillCredentialsCommand(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
) => usecase.listSkillCredentials(
  conversationId: request.conversationId,
  workspaceId: request.workspaceId,
  arguments: request.arguments,
);

Future<Object?> _activateSkillCommand(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
) => _activate(usecase, request);

Future<Object?> _activate(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest commandRequest,
) async {
  final activation = await _prepareActivation(usecase, commandRequest);

  await _loadConversationSkill(usecase, activation.manifestRequest);
  final resources = await usecase.listSkillResourceSummaries?.call(
    conversationId: commandRequest.conversationId,
    workspaceId: commandRequest.workspaceId,
    skillSlug: activation.skill.slug,
  );

  return buildSkillActivationResult(
    manifest: activation.manifest,
    content: activation.skill.content,
    credentials: activation.credentials,
    resources: resources ?? const [],
  );
}

Future<Object?> _loadSkillResourceCommand(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
) async {
  final target = SkillResourceTarget.fromArguments(
    Map<String, Object?>.from(request.arguments),
  );
  final manifest = await _findSkillManifest(
    usecase,
    .new(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      slug: target.skill,
      revision: null,
    ),
  );
  if (manifest == null) {
    throw StateError('Skill is not loaded: ${target.skill}');
  }
  final resource = await usecase.loadSkillResourceContent?.call(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    skillSlug: target.skill,
    resourceSlug: target.resource,
  );
  if (resource == null) {
    throw StateError(
      'Skill resource is unavailable: ${target.skill}/${target.resource}',
    );
  }

  return buildSkillResourceResult(
    skillSlug: target.skill,
    resourceSlug: target.resource,
    title: resource.title,
    content: resource.content,
  );
}

Future<_SkillActivation> _prepareActivation(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
) async {
  final target = _activationTarget(request);
  final skill = await _availableSkill(usecase, request, target);
  final manifestRequest = _activationManifestRequest(request, target);
  final manifest = await _manifestForAvailableSkill(
    usecase,
    manifestRequest,
    skill,
  );
  _validateActivationRevision(manifest, target);

  return (
    skill: skill,
    manifestRequest: manifestRequest,
    manifest: manifest,
    credentials: await _activationCredentials(
      usecase,
      manifestRequest,
      manifest,
    ),
  );
}

SkillActivationTarget _activationTarget(RunSkillCommandRequest request) =>
    SkillActivationTarget.fromArguments(
      Map<String, Object?>.from(request.arguments),
    );

Future<AvailableSkill> _availableSkill(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
  SkillActivationTarget target,
) async {
  final available = await _availableSkills(usecase, request);
  final skill = available
      .where((candidate) => candidate.slug == target.slug)
      .firstOrNull;
  if (skill == null) throw StateError('Skill is unavailable: ${target.slug}');

  return skill;
}

Future<List<AvailableSkill>> _availableSkills(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
) {
  final listAvailableSkills = usecase.listAvailableSkillsUsecase(
    request.workspaceId,
  );

  return listAvailableSkills(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    filter: .catalog,
  );
}

_SkillManifestRequest _activationManifestRequest(
  RunSkillCommandRequest request,
  SkillActivationTarget target,
) => _SkillManifestRequest(
  conversationId: request.conversationId,
  workspaceId: request.workspaceId,
  slug: target.slug,
  revision: target.revision,
);

void _validateActivationRevision(
  SkillManifest manifest,
  SkillActivationTarget target,
) {
  if (manifest.revision == target.revision) return;

  throw FormatException(
    'Skill revision changed; use the current skill catalog to refresh: '
    '${target.slug}',
  );
}

Future<List<SkillCredentialOption>> _activationCredentials(
  RunSkillCommandUsecase usecase,
  _SkillManifestRequest request,
  SkillManifest manifest,
) {
  if (!manifest.tools.any((tool) => tool.credentialRequired)) {
    return Future.value(const <SkillCredentialOption>[]);
  }

  return _loadActivationCredentials(usecase, request);
}

Future<List<SkillCredentialOption>> _loadActivationCredentials(
  RunSkillCommandUsecase usecase,
  _SkillManifestRequest request,
) async {
  final listSkillCredentials =
      usecase.listCatalogSkillCredentials ?? usecase.listSkillCredentials;
  final result = await listSkillCredentials(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    arguments: {'slug': request.slug},
  );

  return _credentialOptions(result);
}

List<SkillCredentialOption> _credentialOptions(Map<String, Object?> result) {
  final values = result['credentials'];
  if (values is! Iterable) return const [];

  return [
    for (final value in values)
      if (value is Map && value['id'] is String && value['name'] is String)
        SkillCredentialOption(
          credentialId: value['id']! as String,
          displayName: value['name']! as String,
        ),
  ];
}

Future<void> _loadConversationSkill(
  RunSkillCommandUsecase usecase,
  _SkillManifestRequest request,
) => usecase
    .loadConversationSkillUsecase(request.workspaceId)
    .call(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      slug: request.slug,
    );

Future<Map<String, Object?>> _callSkillCommand(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
) => _callTool(usecase, request);

Future<Map<String, Object?>> _callTool(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
) async {
  final command = await _validatedCallTool(usecase, request);
  final result = await _executeCallTool(usecase, request, command);

  return {'result': result};
}

Future<SkillCommandTarget> _validatedCallTool(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
) => _RunSkillCommandValidation(usecase)._validatedCommand(
  request.conversationId,
  request.workspaceId,
  request.arguments,
);

Future<Object?> _executeCallTool(
  RunSkillCommandUsecase usecase,
  RunSkillCommandRequest request,
  SkillCommandTarget command,
) async {
  final validation = _RunSkillCommandValidation(usecase);
  final target = await validation._resolveSkillToolTarget(
    request.conversationId,
    request.workspaceId,
    command,
  );

  return await _RunSkillCommandExecution(usecase)._runSkillTool((
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    target: target,
    command: command,
  ));
}

class const _RunSkillCommandValidation(final RunSkillCommandUsecase _usecase) {
  Future<SkillCommandTarget> _validatedCommand(
    String conversationId,
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final command = SkillCommandTarget.fromArguments(arguments);
    await _validateCommandManifest(
      .new(
        conversationId: conversationId,
        workspaceId: workspaceId,
        slug: command.skill,
        revision: command.revision,
      ),
      command,
    );

    return command;
  }

  Future<void> _validateCommandManifest(
    _SkillManifestRequest request,
    SkillCommandTarget command,
  ) async {
    final manifest = await _requiredManifest(request);
    validateToolArguments(
      _requiredManifestTool(manifest, command).inputJsonSchema,
      command.args,
    );
  }

  SkillManifestTool _requiredManifestTool(
    SkillManifest manifest,
    SkillCommandTarget command,
  ) {
    final manifestTool = manifest.tools
        .where((candidate) => candidate.name == command.tool)
        .firstOrNull;
    if (manifestTool == null) {
      throw StateError(
        'Skill tool is not configured: ${command.skill}/${command.tool}',
      );
    }

    return manifestTool;
  }

  Future<SkillManifest> _requiredManifest(_SkillManifestRequest request) async {
    final manifest = await _findSkillManifest(_usecase, request);
    if (manifest == null) {
      throw StateError('Skill is not loaded: ${request.slug}');
    }
    if (request.revision != null && manifest.revision != request.revision) {
      throw FormatException(
        'Skill manifest changed; use the current skill catalog to refresh: '
        '${request.slug}',
      );
    }

    return manifest;
  }

  Future<AgentResolvedToolName> _resolveSkillToolTarget(
    String conversationId,
    String workspaceId,
    SkillCommandTarget command,
  ) async {
    final targets = _matchingSkillToolTargets(
      await _skillToolSpecs(conversationId, workspaceId),
      command,
    );
    if (targets.length != 1) {
      throw StateError(
        'Skill tool target is ambiguous or missing: '
        '${command.skill}/${command.tool}',
      );
    }

    return targets.single;
  }

  List<AgentResolvedToolName> _matchingSkillToolTargets(
    List<ToolSpec> specs,
    SkillCommandTarget command,
  ) =>
      _resolvedSkillTools(specs)
          .where((candidate) => _matchesSkillTool(candidate, command))
          .toList();

  Future<List<ToolSpec>> _skillToolSpecs(
    String conversationId,
    String workspaceId,
  ) async {
    return [
      ...await _usecase.buildSkillTemplateToolSpecsUsecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
      ...await _usecase.buildAppSkillNativeToolSpecsUsecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
    ];
  }
}

bool _matchesSkillTool(
  AgentResolvedToolName candidate,
  SkillCommandTarget command,
) =>
    candidate.skillSlug == command.skill &&
    candidate.toolIdentifier == command.tool;

List<AgentResolvedToolName> _resolvedSkillTools(List<ToolSpec> specs) {
  const resolver = AgentToolNameResolver();

  return specs
      .map((spec) => resolver.resolve(spec.name))
      .whereType<AgentResolvedToolName>()
      .toList();
}

Future<SkillManifest?> _findSkillManifest(
  RunSkillCommandUsecase usecase,
  _SkillManifestRequest request,
) async => (await usecase.buildLoadedSkillManifestsUsecase.call(
  conversationId: request.conversationId,
  workspaceId: request.workspaceId,
)).where((candidate) => candidate.slug == request.slug).firstOrNull;

Future<SkillManifest> _manifestForAvailableSkill(
  RunSkillCommandUsecase usecase,
  _SkillManifestRequest request,
  AvailableSkill skill,
) async {
  final manifests = await usecase.buildLoadedSkillManifestsUsecase.call(
    conversationId: request.conversationId,
    workspaceId: request.workspaceId,
    extraSkills: [skill],
  );

  return _requiredSkillManifest(manifests, skill.slug);
}

SkillManifest _requiredSkillManifest(
  List<SkillManifest> manifests,
  String slug,
) {
  final manifest = manifests
      .where((candidate) => candidate.slug == slug)
      .firstOrNull;
  if (manifest == null) {
    throw StateError('Skill manifest unavailable: $slug');
  }

  return manifest;
}

class const _RunSkillCommandExecution(final RunSkillCommandUsecase _usecase) {
  Future<Object?> _runSkillTool(_SkillToolExecutionRequest request) =>
      switch (request.target.kind) {
        .skillTemplate => _runSkillTemplateTool(
          request.workspaceId,
          request.command,
        ),
        .skillAppTemplate => _runAppSkillTool(request),
        .skillNative => _runSkillNativeTool(request),
        _ => throw StateError(
          'Unsupported skill tool target: ${request.target.fullName}',
        ),
      };

  Future<Object?> _runSkillTemplateTool(
    String workspaceId,
    SkillCommandTarget command,
  ) => _usecase.runSkillTemplateToolUsecase.call(
    workspaceId: workspaceId,
    skillSlug: command.skill,
    toolSlug: command.tool,
    arguments: Map<String, dynamic>.from(command.args),
  );

  Future<Object?> _runSkillNativeTool(_SkillToolExecutionRequest request) {
    final nativeRunner = _usecase.runSkillNativeTool;
    if (nativeRunner == null) return _runAppSkillTool(request);

    return nativeRunner((
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      target: request.target,
      arguments: Map<String, dynamic>.from(request.command.args),
    ));
  }

  Future<Object?> _runAppSkillTool(_SkillToolExecutionRequest request) =>
      _runAppSkillToolWithArguments(
        request,
        Map<String, dynamic>.from(request.command.args),
      );

  Future<Object?> _runAppSkillToolWithArguments(
    _SkillToolExecutionRequest request,
    Map<String, dynamic> arguments,
  ) => _usecase.runAppSkillToolUsecase.call(
    workspaceId: request.workspaceId,
    skillSlug: request.command.skill,
    toolSlug: request.command.tool,
    arguments: arguments,
  );
}
