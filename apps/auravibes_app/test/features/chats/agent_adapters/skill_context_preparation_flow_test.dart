import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_skills_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/chats/agent_adapters/build_skill_context_messages_service.dart';
import 'package:auravibes_app/features/chats/models/skill_context_preparation_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_skill_context_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/prepare_conversation_skill_context_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/skills/usecases/build_loaded_skill_manifests_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test(
    'compaction, resume, and fork require fresh skill context preparation',
    () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      final conversations = ConversationRepository(database);
      final conversationSkills = ConversationSkillsRepository(database);
      final messages = MessageRepository(database);
      final skills = SkillsRepository(database);
      final containers = <ProviderContainer>[];
      addTearDown(() async {
        for (final container in containers) {
          container.dispose();
        }
        await database.close();
      });

      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'Workspace', type: .local),
      );
      final _ = await database.conversationDao.insertConversation(
        .insert(
          id: const Value('source'),
          workspaceId: workspace.id,
          title: 'Source',
        ),
      );
      final skillEntity = await skills.createSkill(
        workspace.id,
        const SkillToCreate(
          kind: .template,
          title: 'Research',
          description: 'Find sources',
          content: 'Use primary sources',
        ),
      );
      final skill = AvailableSkill(
        id: skillEntity.id,
        slug: skillEntity.slug,
        title: skillEntity.title,
        description: skillEntity.description,
        content: skillEntity.content,
        source: skillEntity.source,
        kind: skillEntity.kind,
        credentialReadiness: .ready,
      );
      final _ = await conversationSkills.setWorkspaceSkillLoaded(
        'source',
        skill.id,
        isLoaded: true,
      );
      final sourceMessage = await messages.createMessage(
        const .new(
          conversationId: 'source',
          content: 'Find recent research',
          messageType: .text,
          isUser: true,
          status: .sent,
        ),
      );

      var revision = 'r1';
      var supportsTools = true;
      final listSkills = _PersistedListSkills(conversationSkills, skill);
      final manifests = _ManifestBuilder(() => revision);
      final agentSkills = _EmptyAgentSkills();
      final contextBuilder = BuildSkillContextMessagesService(
        listSkills.call,
        agentSkills,
        manifests,
      );
      final preparation = PrepareConversationSkillContextUsecase(
        listLoadedSkills: (workspaceId, conversationId, filter) =>
            listSkills.call(
              conversationId: conversationId,
              workspaceId: workspaceId,
              filter: filter,
            ),
        buildContextMessages: (workspaceId, conversationId) => contextBuilder
            .call(conversationId: conversationId, workspaceId: workspaceId),
        previewTools: (_, _) async => [_activateSkillTool],
        supportsTools: (_) async => supportsTools,
      );

      ProviderContainer newContainer() {
        final container = _container(workspace.id, listSkills, manifests);
        containers.add(container);

        return container;
      }

      final sourceContainer = newContainer();
      final sourceProvider = conversationSkillSelectorProvider(
        workspace.id,
        'source',
      );
      expect(
        (await sourceContainer.read(sourceProvider.future))
            .contextStatusBySlug[skill.slug],
        ConversationSkillContextStatus.added,
      );

      final firstPreparation = await _prepare(
        sourceContainer,
        preparation,
        workspace.id,
        'source',
      );
      expect(firstPreparation.selectedRevisions, {skill.slug: 'r1'});
      expect(firstPreparation.canActivate, isTrue);
      expect(
        (await sourceContainer.read(sourceProvider.future))
            .contextStatusBySlug[skill.slug],
        ConversationSkillContextStatus.ready,
      );

      revision = 'r2';
      sourceContainer
          .read(conversationSkillContextRuntimeProvider.notifier)
          .markNeedsContext('source');
      expect(
        (await sourceContainer.read(sourceProvider.future))
            .contextStatusBySlug[skill.slug],
        ConversationSkillContextStatus.needsContext,
      );
      final compactedPreparation = await _prepare(
        sourceContainer,
        preparation,
        workspace.id,
        'source',
      );
      expect(compactedPreparation.selectedRevisions, {skill.slug: 'r2'});
      expect(compactedPreparation.canActivate, isTrue);

      final resumedContainer = newContainer();
      expect(
        (await resumedContainer.read(
          conversationSkillSelectorProvider(workspace.id, 'source').future,
        )).contextStatusBySlug[skill.slug],
        ConversationSkillContextStatus.added,
      );
      final resumedPreparation = await _prepare(
        resumedContainer,
        preparation,
        workspace.id,
        'source',
      );
      expect(resumedPreparation.selectedRevisions, {skill.slug: 'r2'});

      final fork = await conversations.forkConversation(
        'source',
        throughMessageId: sourceMessage.id,
      );
      final forkRows = await conversationSkills.getConversationSkills(fork.id);
      expect(forkRows.single.workspaceSkillId, skill.id);
      expect(forkRows.single.isLoaded, isTrue);
      final forkTranscriptIds =
          (await messages.getTranscriptMessagesByConversation(fork.id))
              .map((message) => message.id)
              .toList();

      final forkContainer = newContainer();
      final forkProvider = conversationSkillSelectorProvider(
        workspace.id,
        fork.id,
      );
      expect(
        (await forkContainer.read(forkProvider.future))
            .contextStatusBySlug[skill.slug],
        ConversationSkillContextStatus.added,
      );
      final forkPreparation = await _prepare(
        forkContainer,
        preparation,
        workspace.id,
        fork.id,
      );
      expect(forkPreparation.selectedRevisions, {skill.slug: 'r2'});
      expect(
        (await forkContainer.read(forkProvider.future))
            .contextStatusBySlug[skill.slug],
        ConversationSkillContextStatus.ready,
      );

      supportsTools = false;
      final failedPreparation = await _prepare(
        forkContainer,
        preparation,
        workspace.id,
        fork.id,
      );
      expect(failedPreparation.canActivate, isFalse);
      expect(
        (await forkContainer.read(forkProvider.future))
            .contextStatusBySlug[skill.slug],
        ConversationSkillContextStatus.error,
      );

      expect(
        (await messages.getTranscriptMessagesByConversation('source'))
            .map((message) => message.id),
        [sourceMessage.id],
      );
      expect(
        (await messages.getTranscriptMessagesByConversation(fork.id))
            .map((message) => message.id),
        forkTranscriptIds,
      );
    },
  );
}

Future<SkillContextPreparationResult> _prepare(
  ProviderContainer container,
  PrepareConversationSkillContextUsecase preparation,
  String workspaceId,
  String conversationId,
) async {
  final runtime = container.read(
    conversationSkillContextRuntimeProvider.notifier,
  );
  final generation = runtime.begin(conversationId);
  final result = await preparation.call(
    workspaceId: workspaceId,
    conversationId: conversationId,
  );
  final failure = result.failure;
  if (failure != null) {
    runtime.errorWithCause(
      conversationId,
      generation,
      ConversationSkillContextFailure.values.byName(failure.name),
    );
  } else {
    runtime.ready(
      conversationId,
      generation,
      selectedRevisions: result.selectedRevisions,
      canActivate: result.canActivate,
    );
  }

  return result;
}

ProviderContainer _container(
  String workspaceId,
  ListAvailableSkillsUsecase listSkills,
  BuildLoadedSkillManifestsUsecase manifests,
) => ProviderContainer(
  overrides: [
    listAvailableSkillsUsecaseProvider(workspaceId)
        .overrideWith((_) => listSkills),
    buildLoadedSkillManifestsUsecaseProvider.overrideWith((_) => manifests),
  ],
);

class _PersistedListSkills(
  final ConversationSkillsRepository _conversationSkills,
  final AvailableSkill _skill,
) extends Mock implements ListAvailableSkillsUsecase {
  @override
  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
    required SkillLoadFilter filter,
  }) async {
    final rows = await _conversationSkills.getConversationSkills(
      conversationId,
    );
    final isLoaded = rows.any(
      (row) => row.workspaceSkillId == _skill.id && row.isLoaded,
    );

    return switch (filter) {
      .loaded => isLoaded ? [_skill] : const [],
      .loadable => isLoaded ? const [] : [_skill],
      .selector || .catalog => [_skill],
    };
  }
}

class _ManifestBuilder(final String Function() _revision)
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
      description: 'Find sources',
      revision: _revision(),
      tools: const [],
    ),
  ];
}

class _EmptyAgentSkills implements ListConversationAgentSkillsUsecase {
  @override
  Future<List<AvailableSkill>> call({
    required String conversationId,
    required String workspaceId,
  }) async => const [];

  @override
  Future<AgentEntity?> loadSelectedAgent({
    required String conversationId,
    required String workspaceId,
  }) async => null;
}

final _activateSkillTool = ToolSpec(
  name: activateSkillToolName,
  description: 'Activate skill',
  inputJsonSchema: const {'type': 'object'},
);
