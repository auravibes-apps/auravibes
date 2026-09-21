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
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activates a catalog skill and returns its body envelope', () async {
    final load = _LoadRecorder();
    final credentialCalls = <Map<String, dynamic>>[];
    final usecase = RunSkillCommandUsecase(
      listAvailableSkillsUsecase: (_) => _LoadedSkills(
        skills: const [
          AvailableSkill(
            source: SkillSource.user,
            id: 'research-skill-row',
            slug: 'research',
            title: 'Research',
            description: 'Search sources.',
            content: 'Use research instructions.',
            kind: .template,
          ),
        ],
      ),
      loadConversationSkillUsecase: (_) => load,
      buildLoadedSkillManifestsUsecase: _Manifests(credentialRequired: true),
      buildSkillTemplateToolSpecsUsecase: _UnusedTemplateSpecs(),
      buildAppSkillNativeToolSpecsUsecase: _UnusedNativeSpecs(),
      runSkillTemplateToolUsecase: _TemplateRunner(),
      runAppSkillToolUsecase: _NativeRunner(),
      listSkillCredentials: ({
        required conversationId,
        required workspaceId,
        required arguments,
      }) async => const {},
      listCatalogSkillCredentials:
          ({
            required conversationId,
            required workspaceId,
            required arguments,
          }) async {
            credentialCalls.add(arguments);

            return const {
              'credentials': [
                {'id': 'credential-1', 'name': 'Personal account'},
              ],
            };
          },
      listSkillResourceSummaries:
          ({
            required conversationId,
            required workspaceId,
            required skillSlug,
          }) async => const [
            SkillResourceSummary(
              slug: 'refund_policy',
              title: 'Refund policy',
              description: 'Refund rules.',
            ),
          ],
    );

    final result = await usecase.call((
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
      commandName: activateSkillToolName,
      arguments: const {'slug': 'research', 'revision': 'r1'},
    ));

    expect(result, isA<SkillActivationResult>());
    if (result is! SkillActivationResult) {
      fail('Expected a skill activation result.');
    }
    final activation = result;
    expect(
      activation.value,
      allOf(
        startsWith('<skill_content slug="research"'),
        contains('Use research instructions.'),
        contains('<skill_tools>'),
        contains('<skill_credentials>'),
        contains('credential-1,Personal account'),
        contains('<skill_resources>'),
        contains('refund_policy,Refund policy,Refund rules.'),
      ),
    );
    expect(load.calls, 1);
    expect(credentialCalls, [
      {'slug': 'research'},
    ]);
  });

  test('loads a resource as a bounded thread result', () async {
    final usecase = RunSkillCommandUsecase(
      listAvailableSkillsUsecase: (_) => _UnusedListSkills(),
      loadConversationSkillUsecase: (_) => _UnusedLoad(),
      buildLoadedSkillManifestsUsecase: _Manifests(),
      buildSkillTemplateToolSpecsUsecase: _UnusedTemplateSpecs(),
      buildAppSkillNativeToolSpecsUsecase: _UnusedNativeSpecs(),
      runSkillTemplateToolUsecase: _TemplateRunner(),
      runAppSkillToolUsecase: _NativeRunner(),
      listSkillCredentials: ({
        required conversationId,
        required workspaceId,
        required arguments,
      }) async => const {},
      loadSkillResourceContent:
          ({
            required conversationId,
            required workspaceId,
            required skillSlug,
            required resourceSlug,
          }) async => (
            title: 'Refund policy',
            content: 'Never refund outside the policy.',
          ),
    );

    final result = await usecase.call((
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
      commandName: loadSkillResourceToolName,
      arguments: const {'skill': 'research', 'resource': 'refund_policy'},
    ));

    expect(result, isA<SkillResourceResult>());
    final resourceResult = result;
    if (resourceResult is! SkillResourceResult) {
      fail('Expected a skill resource result');
    }

    expect(resourceResult.value, contains('<skill_resource'));
    expect(resourceResult.value, contains('CDATA'));
    expect(resourceResult.value, contains('Never refund'));
  });

  test('does not persist selection when catalog credentials fail', () async {
    final load = _LoadRecorder();
    final usecase = RunSkillCommandUsecase(
      listAvailableSkillsUsecase: (_) => _LoadedSkills(
        skills: const [
          AvailableSkill(
            source: SkillSource.user,
            id: 'research-skill-row',
            slug: 'research',
            title: 'Research',
            description: 'Search sources.',
            content: 'Use research instructions.',
            kind: .template,
          ),
        ],
      ),
      loadConversationSkillUsecase: (_) => load,
      buildLoadedSkillManifestsUsecase: _Manifests(credentialRequired: true),
      buildSkillTemplateToolSpecsUsecase: _UnusedTemplateSpecs(),
      buildAppSkillNativeToolSpecsUsecase: _UnusedNativeSpecs(),
      runSkillTemplateToolUsecase: _TemplateRunner(),
      runAppSkillToolUsecase: _NativeRunner(),
      listSkillCredentials: ({
        required conversationId,
        required workspaceId,
        required arguments,
      }) async => const {},
      listCatalogSkillCredentials:
          ({
            required conversationId,
            required workspaceId,
            required arguments,
          }) async {
            throw StateError('credential lookup failed');
          },
    );

    await expectLater(
      usecase.call((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        commandName: activateSkillToolName,
        arguments: const {'slug': 'research', 'revision': 'r1'},
      )),
      throwsStateError,
    );
    expect(load.calls, 0);
  });

  test(
    'rejects a stale activation revision before persisting selection',
    () async {
      final load = _LoadRecorder();
      final usecase = RunSkillCommandUsecase(
        listAvailableSkillsUsecase: (_) => _LoadedSkills(
          skills: const [
            AvailableSkill(
              source: SkillSource.user,
              id: 'research-skill-row',
              slug: 'research',
              title: 'Research',
              description: 'Search sources.',
              content: 'Use research instructions.',
              kind: .template,
            ),
          ],
        ),
        loadConversationSkillUsecase: (_) => load,
        buildLoadedSkillManifestsUsecase: _Manifests(),
        buildSkillTemplateToolSpecsUsecase: _UnusedTemplateSpecs(),
        buildAppSkillNativeToolSpecsUsecase: _UnusedNativeSpecs(),
        runSkillTemplateToolUsecase: _TemplateRunner(),
        runAppSkillToolUsecase: _NativeRunner(),
        listSkillCredentials: ({
          required conversationId,
          required workspaceId,
          required arguments,
        }) async => const {},
      );

      await expectLater(
        usecase.call((
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
          commandName: activateSkillToolName,
          arguments: const {'slug': 'research', 'revision': 'stale'},
        )),
        throwsFormatException,
      );
      expect(load.calls, 0);
    },
  );

  test('rejects invalid target arguments before either runner', () async {
    final templateRunner = _TemplateRunner();
    final nativeRunner = _NativeRunner();
    final usecase = RunSkillCommandUsecase(
      listAvailableSkillsUsecase: (_) => _UnusedListSkills(),
      loadConversationSkillUsecase: (_) => _UnusedLoad(),
      buildLoadedSkillManifestsUsecase: _Manifests(),
      buildSkillTemplateToolSpecsUsecase: _UnusedTemplateSpecs(),
      buildAppSkillNativeToolSpecsUsecase: _UnusedNativeSpecs(),
      runSkillTemplateToolUsecase: templateRunner,
      runAppSkillToolUsecase: nativeRunner,
      listSkillCredentials: ({
        required conversationId,
        required workspaceId,
        required arguments,
      }) async => const {},
    );

    await expectLater(
      usecase.call((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        commandName: callSkillToolName,
        arguments: const {
          'skill': 'research',
          'tool': 'search',
          'args': {'limit': 'wrong'},
          'revision': 'r1',
        },
      )),
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
        buildLoadedSkillManifestsUsecase: manifests,
        buildSkillTemplateToolSpecsUsecase: templateSpecs,
        buildAppSkillNativeToolSpecsUsecase: nativeSpecs,
        runSkillTemplateToolUsecase: templateRunner,
        runAppSkillToolUsecase: nativeRunner,
        listSkillCredentials: ({
          required conversationId,
          required workspaceId,
          required arguments,
        }) async => const {},
      );

      final result = await usecase.call((
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
        commandName: callSkillToolName,
        arguments: {
          'skill': 'github',
          'tool': 'create_issue',
          'args': {'title': 'Collision regression'},
          'revision': loadedManifest.revision,
        },
      ));

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

  test('dispatches agents native tools through the injected runner', () async {
    final nativeRunner = _NativeRunner();
    final nativeTarget = <AgentResolvedToolName>[];
    final nativeSpecs = _SkillSpecs([
      ToolSpec(
        name: 'skill__app_native__agents__list_agents',
        description: 'List agents.',
        inputJsonSchema: const {
          'type': 'object',
          'additionalProperties': false,
        },
      ),
    ]);
    final manifests = _AgentsManifests();
    final usecase = RunSkillCommandUsecase(
      listAvailableSkillsUsecase: (_) => _UnusedListSkills(),
      loadConversationSkillUsecase: (_) => _UnusedLoad(),
      buildLoadedSkillManifestsUsecase: manifests,
      buildSkillTemplateToolSpecsUsecase: const _SkillSpecs([]),
      buildAppSkillNativeToolSpecsUsecase: nativeSpecs,
      runSkillTemplateToolUsecase: _TemplateRunner(),
      runAppSkillToolUsecase: nativeRunner,
      listSkillCredentials: ({
        required conversationId,
        required workspaceId,
        required arguments,
      }) async => const {},
      runSkillNativeTool: (request) async {
        nativeTarget.add(request.target);

        return {'count': 1};
      },
    );

    final result = await usecase.call((
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
      commandName: callSkillToolName,
      arguments: const <String, Object?>{
        'skill': agentsSkillSlug,
        'tool': listAgentsToolName,
        'args': {},
        'revision': 'agents-r1',
      },
    ));

    expect(result, {
      'result': {'count': 1},
    });
    expect(
      nativeTarget.single.fullName,
      'skill__app_native__agents__list_agents',
    );
    expect(nativeRunner.calls, 0);
    expect(manifests.calls, 1);
  });
}

class _Manifests({final bool credentialRequired = false})
    implements BuildLoadedSkillManifestsUsecase {
  @override
  Future<List<SkillManifest>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async => [
    SkillManifest(
      slug: 'research',
      title: 'Research',
      description: 'Search.',
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
          credentialRequired: credentialRequired,
        ),
      ],
    ),
  ];
}

class _AgentsManifests implements BuildLoadedSkillManifestsUsecase {
  int calls = 0;

  @override
  Future<List<SkillManifest>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async {
    calls++;

    return [
      SkillManifest(
        slug: agentsSkillSlug,
        title: agentsSkillTitle,
        description: 'Run sub-agents.',
        revision: 'agents-r1',
        tools: [
          SkillManifestTool(
            name: listAgentsToolName,
            description: 'List agents.',
            inputJsonSchema: const {
              'type': 'object',
              'additionalProperties': false,
            },
          ),
        ],
      ),
    ];
  }
}

class _LoadedSkills({
  final List<AvailableSkill> skills = const [
    AvailableSkill(
      source: SkillSource.user,
      id: 'github-skill-row',
      slug: 'github',
      title: 'GitHub',
      description: 'Manage GitHub issues.',
      content: 'Create issues when requested.',
      kind: .template,
    ),
  ],
}) implements ListAvailableSkillsUsecase {
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

    return skills;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _LoadRecorder implements LoadConversationSkillUsecase {
  int calls = 0;

  @override
  Future<void> call({
    required String conversationId,
    required String workspaceId,
    required String slug,
  }) async {
    calls++;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _TemplateRunner({final Map<String, int>? result})
    implements RunSkillTemplateToolUsecase {
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

class const _SkillSpecs(final List<ToolSpec> specs)
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
  }) async => specs;
}

class _UnusedTemplateSpecs implements BuildSkillTemplateToolSpecsUsecase {
  @override
  Future<WorkspaceSession> Function(String workspaceId)? get workspaceSession =>
      null;

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedNativeSpecs implements BuildAppSkillNativeToolSpecsUsecase {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
