import 'dart:convert';

import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';

class const ResolveEffectiveToolApprovalUsecase(
  final BuildLoadedSkillManifestsUsecase _buildLoadedSkillManifests,
  final BuildSkillTemplateToolSpecsUsecase _buildSkillTemplateToolSpecs,
  final BuildAppSkillNativeToolSpecsUsecase _buildAppSkillNativeToolSpecs,
) {
  Future<ResolvedTool?> call({
    required String conversationId,
    required String workspaceId,
    required ResolvedTool requestedTool,
    required String argumentsRaw,
  }) async {
    if (!_isCallSkillTool(requestedTool)) return requestedTool;

    final command = _parseCommand(argumentsRaw);
    if (command == null) return null;

    final target = await resolveTarget(
      conversationId: conversationId,
      workspaceId: workspaceId,
      command: command,
    );
    if (target == null) return null;

    return ResolvedTool.skillCommand(
      commandName: callSkillToolName,
      target: target,
    );
  }

  Future<AgentResolvedToolName?> resolveTarget({
    required String conversationId,
    required String workspaceId,
    required SkillCommandTarget command,
  }) async {
    final manifestTool = await _loadedManifestTool(
      conversationId: conversationId,
      workspaceId: workspaceId,
      command: command,
    );
    if (manifestTool == null) return null;

    if (!_hasValidArguments(manifestTool, command)) return null;

    final targets = await _matchingTargets(
      conversationId: conversationId,
      workspaceId: workspaceId,
      command: command,
    );
    if (targets.length != 1) return null;

    return targets.single;
  }

  SkillCommandTarget? _parseCommand(String argumentsRaw) {
    final arguments = _decodeCommandArguments(argumentsRaw);
    if (arguments == null) return null;

    return SkillCommandTarget.fromArguments(arguments);
  }

  Map<String, Object?>? _decodeCommandArguments(String argumentsRaw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(argumentsRaw);
    } on Object {
      return null;
    }

    if (decoded is! Map<Object?, Object?>) return null;

    return _stringKeyedArguments(decoded);
  }

  Map<String, Object?>? _stringKeyedArguments(Map<Object?, Object?> decoded) {
    final arguments = <String, Object?>{};
    for (final entry in decoded.entries) {
      final key = entry.key;
      if (key is! String) return null;
      arguments[key] = entry.value;
    }

    return arguments;
  }

  Future<SkillManifestTool?> _loadedManifestTool({
    required String conversationId,
    required String workspaceId,
    required SkillCommandTarget command,
  }) async {
    final manifest = await _loadedManifest(
      conversationId: conversationId,
      workspaceId: workspaceId,
      command: command,
    );
    if (manifest == null) return null;

    return manifest.tools
        .where((candidate) => candidate.name == command.tool)
        .firstOrNull;
  }

  Future<SkillManifest?> _loadedManifest({
    required String conversationId,
    required String workspaceId,
    required SkillCommandTarget command,
  }) async {
    final manifests = await _buildLoadedSkillManifests.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final manifest = manifests
        .where((candidate) => candidate.slug == command.skill)
        .firstOrNull;
    if (manifest == null || manifest.revision != command.revision) {
      return null;
    }

    return manifest;
  }

  bool _hasValidArguments(SkillManifestTool tool, SkillCommandTarget command) {
    try {
      validateToolArguments(tool.inputJsonSchema, command.args);

      return true;
    } on FormatException {
      return false;
    }
  }

  Future<List<AgentResolvedToolName>> _matchingTargets({
    required String conversationId,
    required String workspaceId,
    required SkillCommandTarget command,
  }) async {
    final specs = await _skillToolSpecs(conversationId, workspaceId);
    const resolver = AgentToolNameResolver();

    return [
      for (final spec in specs)
        if (resolver.resolve(spec.name) case final target?
            when target.skillSlug == command.skill &&
                target.toolIdentifier == command.tool)
          target,
    ];
  }

  Future<List<ToolSpec>> _skillToolSpecs(
    String conversationId,
    String workspaceId,
  ) async => [
    ...await _buildSkillTemplateToolSpecs.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    ),
    ...await _buildAppSkillNativeToolSpecs.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    ),
  ];
}

final resolveEffectiveToolApprovalUsecaseProvider =
    Provider<ResolveEffectiveToolApprovalUsecase>((ref) {
      return ResolveEffectiveToolApprovalUsecase(
        ref.watch(buildLoadedSkillManifestsUsecaseProvider),
        ref.watch(buildSkillTemplateToolSpecsUsecaseProvider),
        ref.watch(buildAppSkillNativeToolSpecsUsecaseProvider),
      );
    });

bool _isCallSkillTool(ResolvedTool tool) =>
    tool.isSkillCommand && tool.toolIdentifier == callSkillToolName;
