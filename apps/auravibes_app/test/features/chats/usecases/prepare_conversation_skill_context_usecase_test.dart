import 'package:auravibes_app/features/chats/models/skill_context_preparation_failure.dart';
import 'package:auravibes_app/features/chats/usecases/prepare_conversation_skill_context_usecase.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrepareConversationSkillContextUsecase', () {
    test(
      'returns current selected revisions and activation capability',
      () async {
        final usecase = _usecase(tools: [_tool(activateSkillToolName)]);

        final result = await usecase.call(
          workspaceId: 'workspace-1',
          conversationId: 'conversation-1',
        );

        expect(result.failure, isNull);
        expect(result.selectedRevisions, {'research': 'skill-revision'});
        expect(result.canActivate, isTrue);
      },
    );

    test('reports missing credentials without losing selected state', () async {
      final usecase = _usecase(skills: [_skillWithReadiness(.missing)]);

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
      );

      expect(result.failure, SkillContextPreparationFailure.missingCredentials);
      expect(result.selectedRevisions, {'research': 'skill-revision'});
    });

    test('reports missing catalog metadata as unavailable', () async {
      final usecase = _usecase(includeMetadata: false);

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
      );

      expect(
        result.failure,
        SkillContextPreparationFailure.unavailableMetadata,
      );
    });

    test('contains transient preparation exceptions', () async {
      final usecase = _usecase(
        buildContextMessages: (_, _) async => throw StateError('private'),
      );

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
      );

      expect(result.failure, SkillContextPreparationFailure.preparationFailed);
      expect(result.toString(), isNot(contains('private')));
    });
  });
}

PrepareConversationSkillContextUsecase _usecase({
  List<AvailableSkill> skills = const [_skill],
  List<ToolSpec> tools = const [],
  bool supportsTools = true,
  bool includeMetadata = true,
  Future<List<ChatMessage>> Function(String workspaceId, String conversationId)?
  buildContextMessages,
}) => PrepareConversationSkillContextUsecase(
  listLoadedSkills: (_, _, _) async => skills,
  buildContextMessages:
      buildContextMessages ??
      (_, _) async => [
        ChatMessage(
          role: .system,
          metadata: {
            if (includeMetadata) ...{
              'kind': 'skill_catalog',
              skillCatalogSelectedRevisionsMetadataKey: {
                'research': 'skill-revision',
              },
            },
          },
        ),
      ],
  previewTools: (_, _) async => tools,
  supportsTools: (_) async => supportsTools,
);

ToolSpec _tool(String name) => ToolSpec(
  name: name,
  description: 'Activate skill.',
  inputJsonSchema: const {'type': 'object'},
);

const _skill = AvailableSkill(
  id: 'skill-1',
  slug: 'research',
  title: 'Research',
  description: 'Research topics.',
  content: 'Research carefully.',
  source: .user,
  kind: .template,
  credentialReadiness: .ready,
);

AvailableSkill _skillWithReadiness(SkillCredentialReadiness readiness) =>
    AvailableSkill(
      id: _skill.id,
      slug: _skill.slug,
      title: _skill.title,
      description: _skill.description,
      content: _skill.content,
      source: _skill.source,
      kind: _skill.kind,
      credentialReadiness: readiness,
    );
