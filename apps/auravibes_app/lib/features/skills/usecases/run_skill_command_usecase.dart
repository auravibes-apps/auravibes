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
  Future<Map<String, Object?>> call({
    required String conversationId,
    required String workspaceId,
    required String commandName,
    required Map<String, dynamic> arguments,
  }) async {
    return await switch (commandName) {
      listSkillsToolName => _listSkills(conversationId, workspaceId),
      loadSkillToolName => _load(conversationId, workspaceId, arguments),
      unloadSkillToolName => _unload(conversationId, workspaceId, arguments),
      listSkillCredentialsToolName => listSkillCredentials(
        conversationId: conversationId,
        workspaceId: workspaceId,
        arguments: arguments,
      ),
      callSkillToolName => _callTool(conversationId, workspaceId, arguments),
      _ => throw FormatException('Unknown skill command: $commandName'),
    };
  }

  Future<Map<String, Object?>> _listSkills(
    String conversationId,
    String workspaceId,
  ) async {
    Future<List<Map<String, String>>> list(SkillLoadFilter filter) async {
      final skills = await listAvailableSkillsUsecase(workspaceId).call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        filter: filter,
      );

      return [for (final skill in skills) _summary(skill)]
        ..sort((left, right) => left['slug']!.compareTo(right['slug']!));
    }

    return {
      'loadable': await list(SkillLoadFilter.loadable),
      'loaded': await list(SkillLoadFilter.loaded),
    };
  }

  Future<Map<String, Object?>> _load(
    String conversationId,
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final slug = _slug(arguments);
    await loadConversationSkillUsecase(workspaceId).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      slug: slug,
    );
    final manifest = (await _manifests(
      conversationId,
      workspaceId,
    )).where((candidate) => candidate.slug == slug).firstOrNull;
    if (manifest == null) throw StateError('Loaded skill not found: $slug');

    return {'loaded': slug, 'manifest': manifest.toJson()};
  }

  Future<Map<String, Object?>> _unload(
    String conversationId,
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final slug = _slug(arguments);
    await unloadConversationSkillUsecase(workspaceId).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      slug: slug,
    );

    return {'unloaded': slug};
  }

  Future<Map<String, Object?>> _callTool(
    String conversationId,
    String workspaceId,
    Map<String, dynamic> arguments,
  ) async {
    final command = SkillCommandTarget.fromArguments(arguments);
    final manifest = (await _manifests(
      conversationId,
      workspaceId,
    )).where((candidate) => candidate.slug == command.skill).firstOrNull;
    if (manifest == null) {
      throw StateError('Skill is not loaded: ${command.skill}');
    }
    if (manifest.revision != command.revision) {
      throw FormatException(
        'Skill manifest changed; call load_skill or list_skills to refresh: '
        '${command.skill}',
      );
    }
    final manifestTool = manifest.tools
        .where((candidate) => candidate.name == command.tool)
        .firstOrNull;
    if (manifestTool == null) {
      throw StateError(
        'Skill tool is not configured: ${command.skill}/${command.tool}',
      );
    }
    validateToolArguments(manifestTool.inputJsonSchema, command.args);

    final specs = [
      ...await buildSkillTemplateToolSpecsUsecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
      ...await buildAppSkillNativeToolSpecsUsecase.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
    ];
    const resolver = AgentToolNameResolver();
    final targets = specs
        .map((spec) => resolver.resolve(spec.name))
        .whereType<AgentResolvedToolName>()
        .where(
          (candidate) =>
              candidate.skillSlug == command.skill &&
              candidate.toolIdentifier == command.tool,
        )
        .toList();
    if (targets.length != 1) {
      throw StateError(
        'Skill tool target is ambiguous or missing: '
        '${command.skill}/${command.tool}',
      );
    }
    final target = targets.single;
    final result = switch (target.kind) {
      AgentResolvedToolKind.skillTemplate => runSkillTemplateToolUsecase.call(
        workspaceId: workspaceId,
        skillSlug: command.skill,
        toolSlug: command.tool,
        arguments: Map<String, dynamic>.from(command.args),
      ),
      AgentResolvedToolKind.skillNative => runAppSkillToolUsecase.call(
        workspaceId: workspaceId,
        skillSlug: command.skill,
        toolSlug: command.tool,
        arguments: Map<String, dynamic>.from(command.args),
      ),
      _ => throw StateError(
        'Unsupported skill tool target: ${target.fullName}',
      ),
    };

    return {'result': await result};
  }

  Future<List<SkillManifest>> _manifests(
    String conversationId,
    String workspaceId,
  ) => buildLoadedSkillManifestsUsecase.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
  );

  String _slug(Map<String, dynamic> arguments) {
    final slug = arguments['slug'];
    if (slug is! String || slug.isEmpty) {
      throw const FormatException('Skill command requires a slug.');
    }

    return slug;
  }

  Map<String, String> _summary(AvailableSkill skill) => {
    'slug': skill.slug,
    'title': skill.title,
  };
}
