import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_task_brief_button.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

const _workspaceId = 'brief-workspace';
final _conversation = ConversationEntity(
  id: 'brief-source',
  workspaceId: _workspaceId,
  title: 'Conversation',
  isPinned: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
final _button = find.byKey(const ValueKey('conversation-task-brief-button'));

class _BriefRepository extends Fake implements ConversationRepository {
  new(this.save);

  final Future<ConversationEntity> Function(String, ConversationPatch) save;

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch patch,
  ) => save(id, patch);
}

class const _Subject({required final String conversationId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(
      conversationChatProvider(_workspaceId, conversationId),
    );
    return Scaffold(
      body: switch (result.value) {
        ConversationFound(:final conversation) => ConversationTaskBriefButton(
          workspaceId: _workspaceId,
          conversation: conversation,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

Future<void> _pumpSubject(
  WidgetTester tester, {
  required ConversationEntity conversation,
  required Future<ConversationEntity> Function(String, ConversationPatch) save,
}) async {
  await tester.runAsync(
    () => tester.pumpWidget(
      TestableApp(
        workspaceId: _workspaceId,
        overrides: [
          conversationByIdStreamProvider(
            _workspaceId,
            conversationId: conversation.id,
          ).overrideWith((_) => Stream.value(conversation)),
          cloudConversationUsecaseProvider.overrideWithValue(null),
          conversationRepositoryProvider.overrideWithValue(
            _BriefRepository(save),
          ),
        ],
        child: _Subject(conversationId: conversation.id),
      ),
    ),
  );
  final _ = await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final id in ['brief-source', 'brief-fork']) {
    testWidgets('save targets only the selected conversation $id', (
      tester,
    ) async {
      final conversation = _conversation.copyWith(id: id);
      final writes = <({String id, ConversationPatch patch})>[];
      await _pumpSubject(
        tester,
        conversation: conversation,
        save: (target, patch) async {
          writes.add((id: target, patch: patch));
          return conversation.copyWith(taskBrief: patch.taskBrief);
        },
      );
      expect(
        tester.widget<AuraIconButton>(find.byType(AuraIconButton)).tooltip,
        'Add task brief',
      );
      await tester.tap(_button);
      final _ = await tester.pumpAndSettle();
      const brief = '  Objetivo 🎯\nKeep the deadline.  ';
      await tester.enterText(find.byType(TextField), brief);
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Save'));
      final _ = await tester.pumpAndSettle();

      expect(writes, hasLength(1));
      expect(writes.single.id, id);
      expect(writes.single.patch.taskBrief, brief);
      expect(writes.single.patch.clearTaskBrief, isFalse);
      expect(
        tester.widget<AuraIconButton>(find.byType(AuraIconButton)).tooltip,
        'Edit task brief',
      );
    });
  }

  testWidgets('explicit Clear removes the brief and updates the button', (
    tester,
  ) async {
    final conversation = _conversation.copyWith(taskBrief: 'Saved objective.');
    final writes = <ConversationPatch>[];
    await _pumpSubject(
      tester,
      conversation: conversation,
      save: (_, patch) async {
        writes.add(patch);
        return conversation.copyWith(taskBrief: null);
      },
    );
    await tester.tap(_button);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Clear brief'));
    final _ = await tester.pumpAndSettle();

    expect(writes, [const ConversationPatch(clearTaskBrief: true)]);
    expect(
      tester.widget<AuraIconButton>(find.byType(AuraIconButton)).tooltip,
      'Add task brief',
    );
  });

  testWidgets('cancel never persists a changed draft', (tester) async {
    final writes = <ConversationPatch>[];
    await _pumpSubject(
      tester,
      conversation: _conversation,
      save: (_, patch) async {
        writes.add(patch);
        return _conversation;
      },
    );
    await tester.tap(_button);
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Unsaved draft');
    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();

    expect(writes, isEmpty);
  });

  testWidgets(
    'failed save reports failure and keeps the persisted value on reopen',
    (tester) async {
      final conversation = _conversation.copyWith(
        taskBrief: 'Saved objective.',
      );
      await _pumpSubject(
        tester,
        conversation: conversation,
        save: (_, _) async {
          throw StateError('Test persistence failure');
        },
      );
      await tester.tap(_button);
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Unsaved replacement');
      await tester.tap(find.text('Save'));
      final _ = await tester.pumpAndSettle();

      expect(
        find.text('Could not save the task brief. Try again.'),
        findsOneWidget,
      );
      expect(
        tester.widget<AuraIconButton>(find.byType(AuraIconButton)).tooltip,
        'Edit task brief',
      );
      await tester.tap(_button);
      final _ = await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'Saved objective.',
      );
    },
  );
}
