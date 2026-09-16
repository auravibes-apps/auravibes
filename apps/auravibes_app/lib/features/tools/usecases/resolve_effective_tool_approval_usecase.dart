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
    final manifest = await _loadedManifest(
      conversationId: conversationId,
      workspaceId: workspaceId,
      command: command,
    );
    if (manifest == null) return null;

    final manifestTool = manifest.tools
        .where((candidate) => candidate.name == command.tool)
        .firstOrNull;
    if (manifestTool == null) return null;

    try {
      validateToolArguments(manifestTool.inputJsonSchema, command.args);
    } on FormatException {
      return null;
    }

    final targets = await _matchingTargets(
      conversationId: conversationId,
      workspaceId: workspaceId,
      command: command,
    );
    if (targets.length != 1) return null;

    return targets.single;
  }

  bool _isCallSkillTool(ResolvedTool tool) =>
      tool.isSkillCommand && tool.toolIdentifier == callSkillToolName;

  SkillCommandTarget? _parseCommand(String argumentsRaw) {
    try {
      final decoded = jsonDecode(argumentsRaw);
      if (decoded is! Map) return null;

      final arguments = <String, Object?>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String) return null;
        arguments[entry.key as String] = entry.value;
      }

      return SkillCommandTarget.fromArguments(arguments);
    } on FormatException {
      return null;
    } on Object {
      return null;
    }
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
    if (manifest == null || manifest.revision != command.revision) return null;

    return manifest;
  }

  Future<List<AgentResolvedToolName>> _matchingTargets({
    required String conversationId,
    required String workspaceId,
    required SkillCommandTarget command,
  }) async {
    final specs = [
      ...await _buildSkillTemplateToolSpecs.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
      ...await _buildAppSkillNativeToolSpecs.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
    ];
    const resolver = AgentToolNameResolver();

    return [
      for (final spec in specs)
        if (resolver.resolve(spec.name) case final target?
            when target.skillSlug == command.skill &&
                target.toolIdentifier == command.tool)
          target,
    ];
  }
}

final resolveEffectiveToolApprovalUsecaseProvider =
    Provider<ResolveEffectiveToolApprovalUsecase>((ref) {
      return ResolveEffectiveToolApprovalUsecase(
        ref.watch(buildLoadedSkillManifestsUsecaseProvider),
        ref.watch(buildSkillTemplateToolSpecsUsecaseProvider),
        ref.watch(buildAppSkillNativeToolSpecsUsecaseProvider),
      );
    });
