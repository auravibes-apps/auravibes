import 'package:auravibes_app/domain/entities/skill_entity.dart';
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

  test(
    'dispatches loaded github create_issue through call_skill_tool',
    () async {
      const issueSchema = <String, Object?>{
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
        },
        'required': ['title'],
        'additionalProperties': false,
      };
      final loadedSkills = _LoadedSkills();
      final templateSpecs = _SkillSpecs([
        ToolSpec(
          name: 'skill__user__github__create_issue',
          description: 'Create a GitHub issue.',
          inputJsonSchema: issueSchema,
        ),
      ]);
      const nativeSpecs = _SkillSpecs([]);
      final manifests = BuildLoadedSkillManifestsUsecase(
        (_) => loadedSkills,
        templateSpecs,
        nativeSpecs,
      );
      final loadedManifest = (await manifests.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      )).single;
      final templateRunner = _TemplateRunner(result: const {'issueNumber': 42});
      final nativeRunner = _NativeRunner();
      final usecase = RunSkillCommandUsecase(
        listAvailableSkillsUsecase: (_) => _UnusedListSkills(),
        loadConversationSkillUsecase: (_) => _UnusedLoad(),
        unloadConversationSkillUsecase: (_) => _UnusedUnload(),
        buildLoadedSkillManifestsUsecase: manifests,
        buildSkillTemplateToolSpecsUsecase: templateSpecs,
        buildAppSkillNativeToolSpecsUsecase: nativeSpecs,
        runSkillTemplateToolUsecase: templateRunner,
        runAppSkillToolUsecase: nativeRunner,
        listSkillCredentials:
            ({
              required conversationId,
              required workspaceId,
              required arguments,
            }) async => const {},
      );

      final result = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        commandName: callSkillToolName,
        arguments: {
          'skill': 'github',
          'tool': 'create_issue',
          'args': {'title': 'Collision regression'},
          'revision': loadedManifest.revision,
        },
      );

      expect(result, {
        'result': {'issueNumber': 42},
      });
      expect(loadedManifest.slug, 'github');
      expect(loadedManifest.tools.single.name, 'create_issue');
      expect(loadedSkills.calls, 2);
      expect(loadedSkills.lastConversationId, 'conversation-1');
      expect(loadedSkills.lastWorkspaceId, 'workspace-1');
      expect(loadedSkills.filters, everyElement(SkillLoadFilter.loaded));
      expect(templateRunner.calls, 1);
      expect(templateRunner.lastWorkspaceId, 'workspace-1');
      expect(templateRunner.lastSkillSlug, 'github');
      expect(templateRunner.lastToolSlug, 'create_issue');
      expect(templateRunner.lastArguments, {'title': 'Collision regression'});
      expect(nativeRunner.calls, 0);
    },
  );
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

class _LoadedSkills implements ListAvailableSkillsUsecase {
  int calls = 0;
  String? lastConversationId;
  String? lastWorkspaceId;
  final filters = <SkillLoadFilter>[];

  @override
  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    calls++;
    lastConversationId = conversationId;
    lastWorkspaceId = workspaceId;
    filters.add(filter);

    return const [
      AvailableSkill(
        source: SkillSource.user,
        id: 'github-skill-row',
        slug: 'github',
        title: 'GitHub',
        description: 'Manage GitHub issues.',
        content: 'Create issues when requested.',
        kind: SkillKind.template,
      ),
    ];
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _TemplateRunner implements RunSkillTemplateToolUsecase {
  _TemplateRunner({this.result});

  final Map<String, int>? result;
  int calls = 0;
  String? lastWorkspaceId;
  String? lastSkillSlug;
  String? lastToolSlug;
  Map<String, dynamic>? lastArguments;

  @override
  Future<Object?> call({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) async {
    calls++;
    lastWorkspaceId = workspaceId;
    lastSkillSlug = skillSlug;
    lastToolSlug = toolSlug;
    lastArguments = arguments;

    return result;
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

class _SkillSpecs
    implements
        BuildSkillTemplateToolSpecsUsecase,
        BuildAppSkillNativeToolSpecsUsecase {
  const _SkillSpecs(this.specs);

  final List<ToolSpec> specs;

  @override
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async => specs;
}

class _UnusedTemplateSpecs implements BuildSkillTemplateToolSpecsUsecase {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedNativeSpecs implements BuildAppSkillNativeToolSpecsUsecase {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
