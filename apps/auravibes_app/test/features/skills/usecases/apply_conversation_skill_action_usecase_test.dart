import 'dart:async';

import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/usecases/message_persisted_exception.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/models/conversation_skill_action.dart';
import 'package:auravibes_app/features/skills/usecases/apply_conversation_skill_action_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApplyConversationSkillActionUsecase', () {
    test('Add persists selection without sending a message', () async {
      var loads = 0;
      var sends = 0;
      final usecase = _usecase(
        load: (_, _, _) async => loads++,
        send: (_, _, _) async => sends++,
      );

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
        slug: 'research',
        action: .add,
        userRequestForSkill: _requestForSkill,
      );

      expect(result, ConversationSkillActionResult.added);
      expect(loads, 1);
      expect(sends, 0);
    });

    test(
      'stale catalog revision prevents selection and continuation',
      () async {
        var loads = 0;
        var sends = 0;
        final usecase = _usecase(
          load: (_, _, _) async => loads++,
          send: (_, _, _) async => sends++,
        );

        final result = await usecase.call(
          workspaceId: 'workspace-1',
          conversationId: 'conversation-1',
          slug: 'research',
          action: .useNow,
          expectedCatalogRevision: 'stale-revision',
          userRequestForSkill: (title) => 'Use $title for my latest request.',
        );

        expect(result, ConversationSkillActionResult.stale);
        expect(loads, 0);
        expect(sends, 0);
      },
    );

    test('concurrent duplicate action returns in progress', () async {
      final loadStarted = Completer<void>();
      final finishLoad = Completer<void>();
      final usecase = _usecase(
        load: (_, _, _) async {
          loadStarted.complete();
          await finishLoad.future;
        },
      );

      final first = usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
        slug: 'research',
        action: .add,
        userRequestForSkill: _requestForSkill,
      );
      await loadStarted.future;
      final duplicate = await usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
        slug: 'research',
        action: .add,
        userRequestForSkill: _requestForSkill,
      );
      finishLoad.complete();

      expect(duplicate, ConversationSkillActionResult.inProgress);
      expect(await first, ConversationSkillActionResult.added);
    });

    test('Use now sends one visible request after loading skill', () async {
      final drafts = <ChatDraft>[];
      final usecase = _usecase(send: (_, _, draft) async => drafts.add(draft));

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
        slug: 'research',
        action: .useNow,
        userRequestForSkill: (title) => 'Use $title for my latest request.',
      );

      expect(result, ConversationSkillActionResult.used);
      expect(drafts.map((draft) => draft.text), [
        'Use Research for my latest request.',
      ]);
    });

    test(
      'rejects workspace mismatch before looking up or loading skill',
      () async {
        var lookups = 0;
        var loads = 0;
        final usecase = _usecase(
          workspaceForConversation: (_) async => 'other-workspace',
          list: (_, _, _) async {
            lookups++;

            return const [_skill];
          },
          load: (_, _, _) async => loads++,
        );

        final result = await usecase.call(
          workspaceId: 'workspace-1',
          conversationId: 'conversation-1',
          slug: 'research',
          action: .add,
          userRequestForSkill: _requestForSkill,
        );

        expect(result, ConversationSkillActionResult.unauthorized);
        expect(lookups, 0);
        expect(loads, 0);
      },
    );

    test('rejects unavailable skills without loading', () async {
      var loads = 0;
      final usecase = _usecase(
        list: (_, _, _) async => const [],
        load: (_, _, _) async => loads++,
      );

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
        slug: 'missing',
        action: .add,
        userRequestForSkill: _requestForSkill,
      );

      expect(result, ConversationSkillActionResult.unavailable);
      expect(loads, 0);
    });

    test('blocks missing and unknown credentials before load', () async {
      final credentialCases =
          <
            ({
              SkillCredentialReadiness readiness,
              ConversationSkillActionResult expected,
            })
          >[
            (readiness: .missing, expected: .credentialsMissing),
            (readiness: .unknown, expected: .credentialsUnknown),
          ];
      for (final (:readiness, :expected) in credentialCases) {
        var loads = 0;
        final skill = _skillWithReadiness(readiness);
        final usecase = _usecase(
          list: (_, _, filter) async => filter == .loaded ? const [] : [skill],
          load: (_, _, _) async => loads++,
        );

        final result = await usecase.call(
          workspaceId: 'workspace-1',
          conversationId: 'conversation-1',
          slug: 'research',
          action: .useNow,
          userRequestForSkill: (title) => 'Use $title.',
        );

        expect(result, expected);
        expect(loads, 0);
      }
    });

    test('Add is idempotent for an already selected skill', () async {
      var loads = 0;
      var sends = 0;
      final usecase = _usecase(
        list: (_, _, _) async => const [_skill],
        load: (_, _, _) async => loads++,
        send: (_, _, _) async => sends++,
      );

      final result = await usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
        slug: 'research',
        action: .add,
        userRequestForSkill: _requestForSkill,
      );

      expect(result, ConversationSkillActionResult.alreadyAdded);
      expect(loads, 0);
      expect(sends, 0);
    });

    test('one concurrent Use now call sends one request', () async {
      final loadStarted = Completer<void>();
      final finishLoad = Completer<void>();
      final drafts = <ChatDraft>[];
      final usecase = _usecase(
        load: (_, _, _) async {
          loadStarted.complete();
          await finishLoad.future;
        },
        send: (_, _, draft) async => drafts.add(draft),
      );

      final first = usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
        slug: 'research',
        action: .useNow,
        userRequestForSkill: (title) => 'Use $title for my latest request.',
      );
      await loadStarted.future;
      final duplicate = await usecase.call(
        workspaceId: 'workspace-1',
        conversationId: 'conversation-1',
        slug: 'research',
        action: .useNow,
        userRequestForSkill: (title) => 'Use $title for my latest request.',
      );
      finishLoad.complete();

      expect(duplicate, ConversationSkillActionResult.inProgress);
      expect(await first, ConversationSkillActionResult.used);
      expect(drafts, hasLength(1));
    });

    test(
      'persisted visible request counts as used if continuation fails',
      () async {
        var sends = 0;
        final usecase = _usecase(
          send: (_, _, _) async {
            sends++;
            throw MessagePersistedException(
              message: 'continuation failed',
              stackTrace: .current,
            );
          },
        );

        final result = await usecase.call(
          workspaceId: 'workspace-1',
          conversationId: 'conversation-1',
          slug: 'research',
          action: .useNow,
          userRequestForSkill: (title) => 'Use $title.',
        );

        expect(result, ConversationSkillActionResult.used);
        expect(sends, 1);
      },
    );
  });
}

String _requestForSkill(String title) => 'Use $title.';

ApplyConversationSkillActionUsecase _usecase({
  Future<String?> Function(String conversationId)? workspaceForConversation,
  Future<List<AvailableSkill>> Function(
    String workspaceId,
    String conversationId,
    SkillLoadFilter filter,
  )?
  list,
  Future<void> Function(String workspaceId, String conversationId, String slug)?
  load,
  Future<void> Function(
    String workspaceId,
    String conversationId,
    ChatDraft draft,
  )?
  send,
  String catalogRevision = 'current-revision',
}) => ApplyConversationSkillActionUsecase(
  workspaceIdForConversation:
      workspaceForConversation ?? (_) async => 'workspace-1',
  listSkills:
      list ??
      (_, _, filter) async => switch (filter) {
        .loaded => const [],
        _ => const [_skill],
      },
  buildContextMessages: (_, _) async => [
    ChatMessage(
      role: .system,
      metadata: {
        'kind': 'skill_catalog',
        skillCatalogRevisionMetadataKey: catalogRevision,
      },
    ),
  ],
  loadSkill: load ?? (_, _, _) => Future<void>.value(),
  sendMessage: send ?? (_, _, _) => Future<void>.value(),
);

const _skill = AvailableSkill(
  source: .user,
  id: 'skill-1',
  slug: 'research',
  title: 'Research',
  description: 'Research topics.',
  content: 'Research carefully.',
  kind: .template,
  credentialReadiness: .ready,
);

AvailableSkill _skillWithReadiness(SkillCredentialReadiness readiness) =>
    AvailableSkill(
      source: _skill.source,
      id: _skill.id,
      slug: _skill.slug,
      title: _skill.title,
      description: _skill.description,
      content: _skill.content,
      kind: _skill.kind,
      credentialReadiness: readiness,
    );
