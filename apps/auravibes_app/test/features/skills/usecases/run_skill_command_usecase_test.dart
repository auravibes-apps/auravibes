import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_app_skill_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_command_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/unload_conversation_skill_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects invalid target arguments before either runner', () async {
    final templateRunner = _TemplateRunner();
    final nativeRunner = _NativeRunner();
    final usecase = RunSkillCommandUsecase(
      listAvailableSkillsUsecase: (_) => _UnusedListSkills(),
      loadConversationSkillUsecase: (_) => _UnusedLoad(),
      unloadConversationSkillUsecase: (_) => _UnusedUnload(),
      buildLoadedSkillManifestsUsecase: _Manifests(),
      buildSkillTemplateToolSpecsUsecase: _UnusedTemplateSpecs(),
      buildAppSkillNativeToolSpecsUsecase: _UnusedNativeSpecs(),
      runSkillTemplateToolUsecase: templateRunner,
      runAppSkillToolUsecase: nativeRunner,
      listSkillCredentials:
          ({
            required conversationId,
            required workspaceId,
            required arguments,
          }) async => const {},
    );

    await expectLater(
      usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        commandName: callSkillToolName,
        arguments: const {
          'skill': 'research',
          'tool': 'search',
          'args': {'limit': 'wrong'},
          'revision': 'r1',
        },
      ),
      throwsFormatException,
    );
    expect(templateRunner.calls, 0);
    expect(nativeRunner.calls, 0);
  });
}

class _Manifests implements BuildLoadedSkillManifestsUsecase {
  @override
  Future<List<SkillManifest>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async => [
    SkillManifest(
      slug: 'research',
      title: 'Research',
      instructions: 'Search.',
      revision: 'r1',
      tools: [
        SkillManifestTool(
          name: 'search',
          description: 'Search.',
          inputJsonSchema: const {
            'type': 'object',
            'properties': {
              'limit': {'type': 'integer'},
            },
            'required': ['limit'],
            'additionalProperties': false,
          },
        ),
      ],
    ),
  ];
}

class _TemplateRunner implements RunSkillTemplateToolUsecase {
  int calls = 0;

  @override
  Future<Object?> call({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) async {
    calls++;

    return null;
  }
}

class _NativeRunner implements RunAppSkillToolUsecase {
  int calls = 0;

  @override
  Future<Object?> call({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) async {
    calls++;

    return null;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedListSkills implements ListAvailableSkillsUsecase {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedLoad implements LoadConversationSkillUsecase {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedUnload implements UnloadConversationSkillUsecase {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedTemplateSpecs implements BuildSkillTemplateToolSpecsUsecase {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedNativeSpecs implements BuildAppSkillNativeToolSpecsUsecase {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
