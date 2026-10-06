import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _ListSkills extends Mock implements ListAvailableSkillsUsecase;

class _BuildManifests extends Mock implements BuildLoadedSkillManifestsUsecase;

void main() {
  const skill = AvailableSkill(
    id: 'skill-1',
    slug: 'research',
    title: 'Research',
    description: 'Find sources',
    content: 'Use primary sources',
    source: .user,
    kind: .template,
    credentialReadiness: .ready,
  );

  test('selection survives stale context and revision changes', () async {
    var revision = 'r1';
    final list = _ListSkills();
    final manifests = _BuildManifests();
    _stubSkills(list, skill);
    when(
      () => manifests.call(
        conversationId: 'conversation',
        workspaceId: 'workspace',
      ),
    ).thenAnswer(
      (_) async => [
        SkillManifest(
          slug: 'research',
          title: 'Research',
          description: 'Find sources',
          revision: revision,
          tools: const [],
        ),
      ],
    );
    final container = _container(list, manifests);
    addTearDown(container.dispose);
    final provider = conversationSkillSelectorProvider(
      'workspace',
      'conversation',
    );
    final observed = <AsyncValue<ConversationSkillSelectorState>>[];
    final subscription = container.listen(
      provider,
      (_, next) => observed.add(next),
    );
    addTearDown(subscription.close);
    final runtime = container.read(
      conversationSkillContextRuntimeProvider.notifier,
    );

    expect((await container.read(provider.future)).loaded, [skill]);
    expect(
      (await container.read(provider.future)).contextStatusBySlug['research'],
      ConversationSkillContextStatus.added,
    );
    final generation = runtime.begin('conversation');
    expect(
      (await container.read(provider.future)).contextStatusBySlug['research'],
      ConversationSkillContextStatus.preparing,
    );
    runtime.ready(
      'conversation',
      generation,
      selectedRevisions: {'research': 'r1'},
      canActivate: true,
    );
    expect(
      (await container.read(provider.future)).contextStatusBySlug['research'],
      ConversationSkillContextStatus.ready,
    );

    revision = 'r2';
    container.invalidate(provider);
    expect(
      (await container.read(provider.future)).contextStatusBySlug['research'],
      ConversationSkillContextStatus.needsContext,
    );
    runtime.markNeedsContext('conversation');
    expect(
      (await container.read(provider.future)).contextStatusBySlug['research'],
      ConversationSkillContextStatus.needsContext,
    );
    final retry = runtime.begin('conversation');
    runtime.error('conversation', retry);
    expect(
      (await container.read(provider.future)).contextStatusBySlug['research'],
      ConversationSkillContextStatus.error,
    );
    expect(observed, isNotEmpty);

    final resumed = _container(list, manifests);
    addTearDown(resumed.dispose);
    final resumedState = await resumed.read(provider.future);
    expect(resumedState.loaded, [skill]);
    expect(
      resumedState.contextStatusBySlug['research'],
      ConversationSkillContextStatus.added,
    );
  });

  test(
    'new selection stays added while existing context stays ready',
    () async {
      const added = AvailableSkill(
        id: 'skill-2',
        slug: 'writing',
        title: 'Writing',
        description: 'Write clearly',
        content: 'Use plain language',
        source: .user,
        kind: .template,
        credentialReadiness: .ready,
      );
      final list = _ListSkills();
      final manifests = _BuildManifests();
      var selected = <AvailableSkill>[skill];
      when(
        () => list.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
          filter: .loaded,
        ),
      ).thenAnswer((_) async => selected);
      when(
        () => list.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
          filter: .selector,
        ),
      ).thenAnswer((_) async => [skill, added]);
      when(
        () => manifests.call(
          conversationId: 'conversation',
          workspaceId: 'workspace',
        ),
      ).thenAnswer(
        (_) async => [
          for (final item in [skill, added])
            SkillManifest(
              slug: item.slug,
              title: item.title,
              description: item.description,
              revision: 'r1',
              tools: const [],
            ),
        ],
      );
      final container = _container(list, manifests);
      addTearDown(container.dispose);
      final provider = conversationSkillSelectorProvider(
        'workspace',
        'conversation',
      );
      final generation = container
          .read(conversationSkillContextRuntimeProvider.notifier)
          .begin('conversation');
      container
          .read(conversationSkillContextRuntimeProvider.notifier)
          .ready(
            'conversation',
            generation,
            selectedRevisions: {'research': 'r1'},
            canActivate: true,
          );

      selected = [skill, added];
      container.invalidate(provider);
      final state = await container.read(provider.future);

      expect(
        state.contextStatusBySlug['research'],
        ConversationSkillContextStatus.ready,
      );
      expect(
        state.contextStatusBySlug['writing'],
        ConversationSkillContextStatus.added,
      );
    },
  );

  test('missing credentials remain selected and show error', () async {
    const missing = AvailableSkill(
      id: 'skill-1',
      slug: 'research',
      title: 'Research',
      description: '',
      content: '',
      source: .user,
      kind: .template,
      credentialReadiness: .missing,
    );
    final list = _ListSkills();
    final manifests = _BuildManifests();
    _stubSkills(list, missing);
    when(
      () => manifests.call(
        conversationId: 'conversation',
        workspaceId: 'workspace',
      ),
    ).thenAnswer((_) async => const []);
    final container = _container(list, manifests);
    addTearDown(container.dispose);

    final state = await container.read(
      conversationSkillSelectorProvider('workspace', 'conversation').future,
    );
    expect(state.loaded, [missing]);
    expect(
      state.contextStatusBySlug['research'],
      ConversationSkillContextStatus.error,
    );
    expect(
      state.failureBySlug['research'],
      ConversationSkillContextFailure.missingCredentials,
    );
  });

  test('maps unknown credentials to preparation failure', () async {
    const unknown = AvailableSkill(
      id: 'skill-1',
      slug: 'research',
      title: 'Research',
      description: '',
      content: '',
      source: .user,
      kind: .template,
    );
    final list = _ListSkills();
    final manifests = _BuildManifests();
    _stubSkills(list, unknown);
    when(
      () => manifests.call(
        conversationId: 'conversation',
        workspaceId: 'workspace',
      ),
    ).thenAnswer((_) async => const []);
    final container = _container(list, manifests);
    addTearDown(container.dispose);

    final state = await container.read(
      conversationSkillSelectorProvider('workspace', 'conversation').future,
    );

    expect(
      state.failureBySlug['research'],
      ConversationSkillContextFailure.preparationFailed,
    );
    expect(state.loaded, [unknown]);
  });

  test('maps missing current metadata separately', () async {
    final list = _ListSkills();
    final manifests = _BuildManifests();
    _stubSkills(list, skill);
    when(
      () => manifests.call(
        conversationId: 'conversation',
        workspaceId: 'workspace',
      ),
    ).thenAnswer((_) async => const []);
    final container = _container(list, manifests);
    addTearDown(container.dispose);

    final state = await container.read(
      conversationSkillSelectorProvider('workspace', 'conversation').future,
    );

    expect(
      state.failureBySlug['research'],
      ConversationSkillContextFailure.unavailableMetadata,
    );
  });
}

ProviderContainer _container(_ListSkills list, _BuildManifests manifests) =>
    ProviderContainer(
      overrides: [
        listAvailableSkillsUsecaseProvider('workspace')
            .overrideWith((ref) => list),
        buildLoadedSkillManifestsUsecaseProvider.overrideWith(
          (ref) => manifests,
        ),
      ],
    );

void _stubSkills(_ListSkills list, AvailableSkill skill) {
  when(
    () => list.call(
      conversationId: 'conversation',
      workspaceId: 'workspace',
      filter: .loaded,
    ),
  ).thenAnswer((_) async => [skill]);
  when(
    () => list.call(
      conversationId: 'conversation',
      workspaceId: 'workspace',
      filter: .selector,
    ),
  ).thenAnswer((_) async => [skill]);
}
