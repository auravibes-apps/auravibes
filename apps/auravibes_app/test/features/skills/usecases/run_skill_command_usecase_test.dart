import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/load_conversation_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/run_skill_command_usecase.dart';
import 'package:auravibes_app/features/skills/services/cloud_skill_store.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const skill = AvailableSkill(
    id: 'crm-skill',
    slug: 'crm',
    title: 'CRM',
    description: 'Use Notion for CRM.',
    content: 'Search before creating records.',
    source: .user,
    kind: .template,
    connectorToolIds: ['connector/notion/search', 'connector/notion/create'],
  );
  final manifest = SkillManifest(
    slug: 'crm',
    title: 'CRM',
    description: 'Use Notion for CRM.',
    revision: 'r1',
    connectorToolIds: ['connector/notion/create', 'connector/notion/search'],
  );

  test('activation adds guidance and Connector references only', () async {
    final loader = _SkillLoader();
    var resourceSummaryReads = 0;
    final usecase = _usecase(
      skill: skill,
      manifest: manifest,
      loader: loader,
      listSkillResourceSummaries: ({
        required conversationId,
        required workspaceId,
        required skillSlug,
      }) async {
        resourceSummaryReads++;
        return const [
          SkillResourceSummary(
            slug: 'crm-policy',
            title: 'CRM policy',
            description: 'Account rules.',
          ),
        ];
      },
    );

    final result = await usecase.call(_request(
      activateSkillToolName,
      const {'slug': 'crm', 'revision': 'r1'},
    ));

    expect(result, isA<SkillActivationResult>());
    if (result is! SkillActivationResult) fail('Expected activation result.');
    expect(result.value, contains('Search before creating records.'));
    expect(result.value, contains('connector/notion/search'));
    expect(result.value, contains('connector/notion/create'));
    expect(result.value, contains('crm-policy,CRM policy,Account rules.'));
    expect(result.value, isNot(contains('<skill_tools>')));
    expect(result.value, isNot(contains('<skill_credentials>')));
    expect(loader.calls, 1);
    expect(resourceSummaryReads, 1);
  });

  test('stale Skill revision fails before changing conversation selection', () async {
    final loader = _SkillLoader();
    final usecase = _usecase(
      skill: skill,
      manifest: manifest,
      loader: loader,
    );

    await expectLater(
      usecase.call(_request(
        activateSkillToolName,
        const {'slug': 'crm', 'revision': 'stale'},
      )),
      throwsFormatException,
    );
    expect(loader.calls, 0);
  });

  test('resource load requires an activated Skill', () async {
    var contentReads = 0;
    final usecase = _usecase(
      skill: skill,
      manifest: manifest,
      loadedManifests: const [],
      loadSkillResourceContent: ({
        required conversationId,
        required workspaceId,
        required skillSlug,
        required resourceSlug,
      }) async {
        contentReads++;
        return (title: 'CRM policy', content: 'Account rules.');
      },
    );

    await expectLater(
      usecase.call(_request(
        loadSkillResourceToolName,
        const {'skill': 'crm', 'resource': 'crm-policy'},
      )),
      throwsStateError,
    );
    expect(contentReads, 0);
  });

  test('loaded Skill resource returns bounded content', () async {
    final usecase = _usecase(
      skill: skill,
      manifest: manifest,
      loadSkillResourceContent: ({
        required conversationId,
        required workspaceId,
        required skillSlug,
        required resourceSlug,
      }) async => (title: 'CRM policy', content: 'Before ]]> after.'),
    );

    final result = await usecase.call(_request(
      loadSkillResourceToolName,
      const {'skill': 'crm', 'resource': 'crm-policy'},
    ));

    expect(result, isA<SkillResourceResult>());
    if (result is! SkillResourceResult) fail('Expected resource result.');
    expect(result.value, contains('CRM policy'));
    expect(result.value, contains('Before ]]]]><![CDATA[> after.'));
  });
}

RunSkillCommandRequest _request(String commandName, Map<String, dynamic> args) =>
    (
      conversationId: 'conversation-1',
      workspaceId: 'workspace-1',
      commandName: commandName,
      arguments: args,
    );

RunSkillCommandUsecase _usecase({
  required AvailableSkill skill,
  required SkillManifest manifest,
  _SkillLoader? loader,
  List<SkillManifest>? loadedManifests,
  ListSkillResourceSummaries? listSkillResourceSummaries,
  LoadSkillResourceContent? loadSkillResourceContent,
}) {
  final skillLoader = loader ?? _SkillLoader();
  return RunSkillCommandUsecase(
    listAvailableSkillsUsecase: (_) => _SkillCatalog([skill]),
    loadConversationSkillUsecase: (_) => skillLoader,
    buildLoadedSkillManifestsUsecase: _SkillManifests(
      loadedManifests ?? [manifest],
    ),
    listSkillResourceSummaries: listSkillResourceSummaries,
    loadSkillResourceContent: loadSkillResourceContent,
  );
}

class _SkillCatalog(final List<AvailableSkill> skills)
    implements ListAvailableSkillsUsecase {
  @override
  CloudSkillStore? get cloudStore => null;

  @override
  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async => skills;
}

class _SkillLoader implements LoadConversationSkillUsecase {
  int calls = 0;

  @override
  CloudSkillStore? get cloudStore => null;

  @override
  Future<void> call({
    required String conversationId,
    required String workspaceId,
    required String slug,
  }) async {
    calls++;
  }
}

class _SkillManifests(final List<SkillManifest> manifests)
    implements BuildLoadedSkillManifestsUsecase {
  @override
  Future<List<SkillManifest>> call({
    required String conversationId,
    required String workspaceId,
    List<AvailableSkill> extraSkills = const [],
  }) async => manifests;
}
