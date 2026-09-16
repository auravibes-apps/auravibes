import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_effective_tool_approval_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves a loaded nested tool to its exact target', () async {
    final usecase = _usecase(
      manifests: [_manifest(revision: 'rev-1')],
      specs: [_nativeSpec()],
    );

    final result = await usecase.call(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
      requestedTool: ResolvedTool.skillCommand(commandName: callSkillToolName),
      argumentsRaw: _arguments(revision: 'rev-1'),
    );

    expect(result?.fullName, 'skill__app__agents__list_agents');
    expect(result?.target?.fullName, 'skill__app__agents__list_agents');
  });

  test('rejects malformed, stale, and unloaded commands', () async {
    final usecase = _usecase(
      manifests: [_manifest(revision: 'rev-1')],
      specs: [_nativeSpec()],
    );

    Future<ResolvedTool?> resolve(String argumentsRaw) => usecase.call(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
      requestedTool: ResolvedTool.skillCommand(commandName: callSkillToolName),
      argumentsRaw: argumentsRaw,
    );

    expect(await resolve('{not-json'), isNull);
    expect(await resolve(_arguments(revision: 'stale')), isNull);

    final unloaded = _usecase(manifests: const [], specs: [_nativeSpec()]);
    expect(
      await unloaded.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        requestedTool: ResolvedTool.skillCommand(
          commandName: callSkillToolName,
        ),
        argumentsRaw: _arguments(revision: 'rev-1'),
      ),
      isNull,
    );
  });

  test('rejects ambiguous nested targets', () async {
    final usecase = _usecase(
      manifests: [_manifest(revision: 'rev-1')],
      specs: [_nativeSpec(), _nativeSpec()],
    );

    final result = await usecase.call(
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
      requestedTool: ResolvedTool.skillCommand(commandName: callSkillToolName),
      argumentsRaw: _arguments(revision: 'rev-1'),
    );

    expect(result, isNull);
  });

  test('passes direct tools through unchanged', () async {
    final direct = ResolvedTool.skillNative(
      tableId: runSubAgentToolName,
      skillSlug: agentsSkillSlug,
      toolIdentifier: runSubAgentToolName,
    );
    final usecase = _usecase(manifests: const [], specs: const []);

    expect(
      await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        requestedTool: direct,
        argumentsRaw: '{}',
      ),
      same(direct),
    );
  });
}

ResolveEffectiveToolApprovalUsecase _usecase({
  required List<SkillManifest> manifests,
  required List<ToolSpec> specs,
}) => ResolveEffectiveToolApprovalUsecase(
  _Manifests(manifests),
  _Specs(const []),
  _Specs(specs),
);

String _arguments({required String revision}) =>
    '{"skill":"agents","tool":"list_agents","args":{},'
    '"revision":"$revision"}';

SkillManifest _manifest({required String revision}) => SkillManifest(
  slug: agentsSkillSlug,
  title: agentsSkillTitle,
  instructions: agentsSkillContent,
  revision: revision,
  tools: [
    SkillManifestTool(
      name: listAgentsToolName,
      description: 'List agents.',
      inputJsonSchema: const {'type': 'object', 'additionalProperties': false},
    ),
  ],
);

ToolSpec _nativeSpec() => ToolSpec(
  name: 'skill__app__agents__list_agents',
  description: 'List agents.',
  inputJsonSchema: const {'type': 'object', 'additionalProperties': false},
);

class _Manifests(final List<SkillManifest> value)
    implements BuildLoadedSkillManifestsUsecase {
  @override
  Future<List<SkillManifest>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async => value;
}

class _Specs(final List<ToolSpec> value)
    implements
        BuildSkillTemplateToolSpecsUsecase,
        BuildAppSkillNativeToolSpecsUsecase {
  @override
  Future<WorkspaceSession> Function(String workspaceId)? get workspaceSession =>
      null;

  @override
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async => value;
}
