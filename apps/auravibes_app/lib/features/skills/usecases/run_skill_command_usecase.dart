import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_app_skill_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/unload_conversation_skill_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef ListSkillCredentials = Future<Map<String, Object?>> Function({
  required String conversationId,
  required String workspaceId,
  required Map<String, dynamic> arguments,
});

typedef _RunSkillCommandRequest = ({
  String conversationId,
  String workspaceId,
  String commandName,
  Map<String, dynamic> arguments,
});

typedef _SkillFilterRequest = ({
  RunSkillCommandUsecase usecase,
  String conversationId,
  String workspaceId,
  SkillLoadFilter filter,
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
  required final UnloadConversationSkillUsecase Function(String workspaceId)
  unloadConversationSkillUsecase,
  required final BuildLoadedSkillManifestsUsecase
  buildLoadedSkillManifestsUsecase,
  required final BuildSkillTemplateToolSpecsUsecase
  buildSkillTemplateToolSpecsUsecase,
  required final BuildAppSkillNativeToolSpecsUsecase
  buildAppSkillNativeToolSpecsUsecase,
  required final RunSkillTemplateToolUsecase runSkillTemplateToolUsecase,
  required final RunAppSkillToolUsecase runAppSkillToolUsecase,
  required final ListSkillCredentials listSkillCredentials,
}) {
  Future<Map<String, Object?>> call(_RunSkillCommandRequest request) =>
      _runSkillCommand(this, request);
}

Future<Map<String, Object?>> _runSkillCommand(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
) => switch (request.commandName) {
  listSkillsToolName => _listSkillsCommand(usecase, request),
  loadSkillToolName => _loadSkillCommand(usecase, request),
  unloadSkillToolName => _unloadSkillCommand(usecase, request),
  listSkillCredentialsToolName => _listSkillCredentialsCommand(
    usecase,
    request,
  ),
  callSkillToolName => _callSkillCommand(usecase, request),
  _ => throw FormatException('Unknown skill command: ${request.commandName}'),
};

Future<Map<String, Object?>> _listSkillsCommand(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
) => _listSkills(usecase, request.conversationId, request.workspaceId);

Future<Map<String, Object?>> _listSkills(
  RunSkillCommandUsecase usecase,
  String conversationId,
  String workspaceId,
) async => {
  'loadable': await _listSkillsForFilter((
    usecase: usecase,
    conversationId: conversationId,
    workspaceId: workspaceId,
    filter: .loadable,
  )),
  'loaded': await _listSkillsForFilter((
    usecase: usecase,
    conversationId: conversationId,
    workspaceId: workspaceId,
    filter: .loaded,
  )),
};

Future<List<Map<String, String>>> _listSkillsForFilter(
  _SkillFilterRequest request,
) async {
  final skills = await _availableSkills(request);

  return _sortedSkillSummaries(skills);
}

Future<List<AvailableSkill>> _availableSkills(_SkillFilterRequest request) =>
    request.usecase.listAvailableSkillsUsecase(request.workspaceId)(
      conversationId: request.conversationId,
      workspaceId: request.workspaceId,
      filter: request.filter,
    );

Future<Map<String, Object?>> _listSkillCredentialsCommand(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
) => usecase.listSkillCredentials(
  conversationId: request.conversationId,
  workspaceId: request.workspaceId,
  arguments: request.arguments,
);

Future<Map<String, Object?>> _loadSkillCommand(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
) => _load(usecase, request);

Future<Map<String, Object?>> _load(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest commandRequest,
) async {
  final slug = _slug(commandRequest.arguments);
  final manifestRequest = _SkillManifestRequest(
    conversationId: commandRequest.conversationId,
    workspaceId: commandRequest.workspaceId,
    slug: slug,
    revision: null,
  );
  await _loadConversationSkill(usecase, manifestRequest);
  final manifest = await _loadSkillManifest(usecase, manifestRequest);

  return _loadedSkillResult(slug, manifest);
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

Future<Map<String, Object?>> _unloadSkillCommand(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
) => _unload(usecase, request);

Future<Map<String, Object?>> _unload(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
) async {
  final slug = _slug(request.arguments);
  await usecase
      .unloadConversationSkillUsecase(request.workspaceId)
      .call(
        conversationId: request.conversationId,
        workspaceId: request.workspaceId,
        slug: slug,
      );

  return {'unloaded': slug};
}

Future<Map<String, Object?>> _callSkillCommand(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
) => _callTool(usecase, request);

Future<Map<String, Object?>> _callTool(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
) async {
  final command = await _validatedCallTool(usecase, request);
  final result = await _executeCallTool(usecase, request, command);

  return {'result': result};
}

Future<SkillCommandTarget> _validatedCallTool(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
) => _RunSkillCommandValidation(usecase)._validatedCommand(
  request.conversationId,
  request.workspaceId,
  request.arguments,
);

Future<Object?> _executeCallTool(
  RunSkillCommandUsecase usecase,
  _RunSkillCommandRequest request,
  SkillCommandTarget command,
) async {
  final validation = _RunSkillCommandValidation(usecase);
  final target = await validation._resolveSkillToolTarget(
    request.conversationId,
    request.workspaceId,
    command,
  );

  return await _RunSkillCommandExecution(usecase)
      ._runSkillTool(target, request.workspaceId, command);
}

String _slug(Map<String, dynamic> arguments) {
  final slug = arguments['slug'];
  if (slug is! String || slug.isEmpty) {
    throw const FormatException('Skill command requires a slug.');
  }

  return slug;
}

List<Map<String, String>> _sortedSkillSummaries(List<AvailableSkill> skills) =>
    [
      for (final skill in skills) {'slug': skill.slug, 'title': skill.title},
    ]..sort((left, right) => left['slug']!.compareTo(right['slug']!));

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
        'Skill manifest changed; call load_skill or list_skills to refresh: '
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

Future<SkillManifest> _loadSkillManifest(
  RunSkillCommandUsecase usecase,
  _SkillManifestRequest request,
) async {
  final manifest = await _findSkillManifest(usecase, request);
  if (manifest == null) {
    throw StateError('Loaded skill not found: ${request.slug}');
  }

  return manifest;
}

Future<SkillManifest?> _findSkillManifest(
  RunSkillCommandUsecase usecase,
  _SkillManifestRequest request,
) async => (await usecase.buildLoadedSkillManifestsUsecase.call(
  conversationId: request.conversationId,
  workspaceId: request.workspaceId,
)).where((candidate) => candidate.slug == request.slug).firstOrNull;

Map<String, Object?> _loadedSkillResult(String slug, SkillManifest manifest) =>
    {'loaded': slug, 'manifest': manifest.toJson()};

class const _RunSkillCommandExecution(final RunSkillCommandUsecase _usecase) {
  Future<Object?> _runSkillTool(
    AgentResolvedToolName target,
    String workspaceId,
    SkillCommandTarget command,
  ) => switch (target.kind) {
    .skillTemplate => _runSkillTemplateTool(workspaceId, command),
    .skillNative => _runSkillNativeTool(workspaceId, command),
    _ => throw StateError('Unsupported skill tool target: ${target.fullName}'),
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

  Future<Object?> _runSkillNativeTool(
    String workspaceId,
    SkillCommandTarget command,
  ) => _usecase.runAppSkillToolUsecase.call(
    workspaceId: workspaceId,
    skillSlug: command.skill,
    toolSlug: command.tool,
    arguments: Map<String, dynamic>.from(command.args),
  );
}
