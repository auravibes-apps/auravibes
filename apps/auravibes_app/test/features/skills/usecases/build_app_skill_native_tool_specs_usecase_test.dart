import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('BuildAppSkillNativeToolSpecsUsecase', () {
    test('builds loaded service app skill tool specs', () async {
      final listUsecase = _MockListAvailableSkillsUsecase();
      final usecase = BuildAppSkillNativeToolSpecsUsecase(
        (_) => listUsecase,
        _FakeAppSkillCandidates({
          'openai': [_candidate('model:openai-1')],
        }),
      );
      when(
        () => listUsecase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer((_) async => [_appSkill('openai')]);

      final specs = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(specs, hasLength(1));
      expect(specs.single.name, 'skill__app__openai__web_search');
      expect(specs.single.inputJsonSchema['required'], ['question']);
      final properties = specs.single.inputJsonSchema['properties']! as Map;
      final credentialSchema = properties['credentialId'] as Map;
      expect(credentialSchema['enum'], ['model:openai-1']);
    });

    test('requires credentialId only with multiple credentials', () async {
      final listUsecase = _MockListAvailableSkillsUsecase();
      final usecase = BuildAppSkillNativeToolSpecsUsecase(
        (_) => listUsecase,
        _FakeAppSkillCandidates({
          'openai': [
            _candidate('model:openai-1', name: 'OpenAI key ****1234'),
            _candidate('service:openai-2', name: 'OpenAI service ****5678'),
          ],
        }),
      );
      when(
        () => listUsecase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer((_) async => [_appSkill('openai')]);

      final specs = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(specs.single.inputJsonSchema['required'], [
        'question',
        'credentialId',
      ]);
      final properties = specs.single.inputJsonSchema['properties']! as Map;
      final credentialSchema = properties['credentialId'] as Map;
      expect(credentialSchema['enum'], ['model:openai-1', 'service:openai-2']);
      expect(credentialSchema.toString(), isNot(contains('OpenAI key')));
      expect(credentialSchema.toString(), isNot(contains('1234')));
    });

    test('keeps skills manager specs with loaded service app skills', () async {
      final listUsecase = _MockListAvailableSkillsUsecase();
      final usecase = BuildAppSkillNativeToolSpecsUsecase(
        (_) => listUsecase,
        _FakeAppSkillCandidates({
          'brave': [_candidate('service:brave-1')],
        }),
      );
      when(
        () => listUsecase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer(
        (_) async => [
          _appSkill(SkillToolSlugs.skillsManager),
          _appSkill('brave'),
        ],
      );

      final specs = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(
        specs.map((spec) => spec.name),
        containsAll([
          'skill__app__skills_manager__list_user_skills',
          'skill__app__brave__web_search',
          'skill__app__brave__llm_context',
        ]),
      );
    });

    test('builds agents skill with list_agents only', () async {
      final listUsecase = _MockListAvailableSkillsUsecase();
      final usecase = BuildAppSkillNativeToolSpecsUsecase(
        (_) => listUsecase,
        const _FakeAppSkillCandidates({}),
      );
      when(
        () => listUsecase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer((_) async => [_appSkill(agentsSkillSlug)]);

      final specs = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(specs.map((spec) => spec.name), [
        'skill__app__agents__list_agents',
      ]);
    });

    test(
      'records model provider credential reuse for overlapping providers',
      () {
        final openAi = serviceSkillDefinitions.singleWhere(
          (skill) => skill.slug == 'openai',
        );
        final codex = serviceSkillDefinitions.singleWhere(
          (skill) => skill.slug == 'codex',
        );
        final duckDuckGo = serviceSkillDefinitions.singleWhere(
          (skill) => skill.slug == 'duckduckgo',
        );

        expect(openAi.requiresCredential, isTrue);
        expect(openAi.compatibleModelProviderIds, ['openai']);
        expect(
          openAi.compatibleModelProviderIds,
          isNot(contains('openai-codex')),
        );
        expect(codex.requiresCredential, isTrue);
        expect(codex.compatibleModelProviderIds, ['openai-codex']);
        expect(duckDuckGo.requiresCredential, isFalse);
        expect(duckDuckGo.compatibleModelProviderIds, isEmpty);
      },
    );

    test('builds Codex tool spec with Codex credential candidate', () async {
      final listUsecase = _MockListAvailableSkillsUsecase();
      final usecase = BuildAppSkillNativeToolSpecsUsecase(
        (_) => listUsecase,
        _FakeAppSkillCandidates({
          'codex': [_candidate('model:codex-1')],
        }),
      );
      when(
        () => listUsecase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer((_) async => [_appSkill('codex')]);

      final specs = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(specs.single.name, 'skill__app__codex__web_search');
      expect(specs.single.inputJsonSchema['required'], ['question']);
      final properties = specs.single.inputJsonSchema['properties']! as Map;
      final credentialSchema = properties['credentialId'] as Map;
      expect(credentialSchema['enum'], ['model:codex-1']);
    });

    test(
      'keeps no-key tools and omits credential tools without candidates',
      () async {
        final listUsecase = _MockListAvailableSkillsUsecase();
        final usecase = BuildAppSkillNativeToolSpecsUsecase(
          (_) => listUsecase,
          const _FakeAppSkillCandidates({}),
        );
        when(
          () => listUsecase.call(
            conversationId: any(named: 'conversationId'),
            workspaceId: any(named: 'workspaceId'),
            filter: SkillLoadFilter.loaded,
          ),
        ).thenAnswer((_) async => [_appSkill('jina')]);

        final specs = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(
          specs.map((spec) => spec.name),
          contains('skill__app__jina__reader_fetch'),
        );
        expect(
          specs.map((spec) => spec.name),
          isNot(contains('skill__app__jina__search')),
        );
      },
    );

    test('omits SearXNG search without a configured instance', () async {
      final listUsecase = _MockListAvailableSkillsUsecase();
      final usecase = BuildAppSkillNativeToolSpecsUsecase(
        (_) => listUsecase,
        const _FakeAppSkillCandidates({}),
      );
      when(
        () => listUsecase.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
          filter: SkillLoadFilter.loaded,
        ),
      ).thenAnswer((_) async => [_appSkill('searxng')]);

      final specs = await usecase.call(
        conversationId: 'conversation-1',
        workspaceId: 'workspace-1',
      );

      expect(specs, isEmpty);
    });

    test(
      'builds SearXNG search with optional credentialId and no baseUrl input',
      () async {
        final listUsecase = _MockListAvailableSkillsUsecase();
        final usecase = BuildAppSkillNativeToolSpecsUsecase(
          (_) => listUsecase,
          _FakeAppSkillCandidates({
            'searxng': [_candidate('service:searxng-1')],
          }),
        );
        when(
          () => listUsecase.call(
            conversationId: any(named: 'conversationId'),
            workspaceId: any(named: 'workspaceId'),
            filter: SkillLoadFilter.loaded,
          ),
        ).thenAnswer((_) async => [_appSkill('searxng')]);

        final specs = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(specs.single.name, 'skill__app__searxng__search');
        expect(specs.single.inputJsonSchema['required'], ['query']);
        final properties = specs.single.inputJsonSchema['properties']! as Map;
        final credentialSchema = properties['credentialId'] as Map;
        expect(credentialSchema['enum'], ['service:searxng-1']);
        expect(properties, isNot(contains('baseUrl')));
      },
    );
  });
}

AvailableSkill _appSkill(String slug) {
  return AvailableSkill(
    source: SkillSource.app,
    id: slug,
    slug: slug,
    title: slug,
    description: '',
    content: '',
    kind: SkillKind.native,
  );
}

class _MockListAvailableSkillsUsecase extends Mock
    implements ListAvailableSkillsUsecase {}

class _FakeAppSkillCandidates
    implements ListAppSkillCredentialCandidatesUsecase {
  const _FakeAppSkillCandidates(this.candidatesBySlug);

  final Map<String, List<AppSkillCredentialCandidate>> candidatesBySlug;

  @override
  Future<List<AppSkillCredentialCandidate>> call({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    return candidatesBySlug[skill.slug] ?? const [];
  }

  @override
  bool isCredentialRequired(AppSkillDefinition skill) {
    return skill.requiresCredential ||
        skill.nativeTools.any((tool) => tool.requiresCredential);
  }

  @override
  Future<bool> hasUsableNativeTool({
    required String workspaceId,
    required AppSkillDefinition skill,
  }) async {
    if (skill.nativeTools.any((tool) => !tool.requiresCredential)) {
      return true;
    }

    return (candidatesBySlug[skill.slug] ?? const []).isNotEmpty;
  }
}

AppSkillCredentialCandidate _candidate(String id, {String? name}) {
  return AppSkillCredentialCandidate(id: id, name: name ?? id);
}
