// Required: Tests repeat finders and fixture lookups for clarity.
import 'dart:ui' show Tristate;

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/widgets/chat_queued_messages_indicator.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const _EasyLocalizationTestWrapper({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      child: child,
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }
}

void main() {
  Widget buildSubject({
    required List<ConversationQueuedDraft> queuedDrafts,
    bool watchQueue = false,
    ValueChanged<ChatDraft>? onEditDraft,
    void Function(ProviderContainer)? onContainer,
  }) {
    final container = ProviderContainer(
      overrides: [conversationSelectedProvider.overrideWithValue('conv-1')],
    );
    addTearDown(container.dispose);
    onContainer?.call(container);

    return UncontrolledProviderScope(
      container: container,
      child: _EasyLocalizationTestWrapper(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: AuraThemeScope(
                theme: .light,
                child: Theme(
                  data: .new(),
                  child: Material(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final visibleDrafts = watchQueue
                            ? ref.watch(
                                conversationSendQueueProvider.select(
                                  (queues) =>
                                      queues['conv-1'] ??
                                      const <ConversationQueuedDraft>[],
                                ),
                              )
                            : queuedDrafts;

                        return ChatQueuedMessagesIndicator(
                          conversationId: 'conv-1',
                          queuedDrafts: visibleDrafts,
                          onEditDraft: onEditDraft,
                        );
                      },
                    ),
                  ),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      ),
    );
  }

  Future<void> pumpAndInit(WidgetTester tester, Widget widget) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
    });
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders nothing when queuedDrafts is empty', (tester) async {
    await pumpAndInit(tester, buildSubject(queuedDrafts: const []));

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byType(AuraBadge), findsNothing);
  });

  testWidgets('renders queued drafts, count, and close buttons', (
    tester,
  ) async {
    final drafts = [
      ConversationQueuedDraft(
        id: 'q-1',
        draft: const ChatDraft(text: 'Hello'),
      ),
      ConversationQueuedDraft(
        id: 'q-2',
        draft: const ChatDraft(text: 'World'),
      ),
    ];

    await pumpAndInit(tester, buildSubject(queuedDrafts: drafts));

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);
    expect(find.byType(AuraBadge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNWidgets(2));
    expect(find.byType(AuraPopupMenuButton), findsNWidgets(2));
  });

  testWidgets('moves a queued row through its accessible actions', (
    tester,
  ) async {
    late final ConversationQueuedDraft first;
    late final ConversationQueuedDraft middle;
    late final ConversationQueuedDraft last;
    late final ConversationQueuedDraft other;
    const attachment = MessageAttachmentToCreate(
      localPath: '/tmp/middle.pdf',
      fileName: 'middle.pdf',
      displayName: 'Middle PDF',
      mimeType: 'application/pdf',
      modality: .file,
      sizeBytes: 12,
    );
    const middleContent = ChatDraft(
      text: 'Middle',
      attachments: [attachment],
    );
    ChatDraft? loadedDraft;
    final queueSnapshots = <Map<String, List<ConversationQueuedDraft>>>[];

    await pumpAndInit(
      tester,
      buildSubject(
        queuedDrafts: const [],
        watchQueue: true,
        onContainer: (container) {
          final subscription = container.listen(
            conversationSendQueueProvider,
            (_, next) => queueSnapshots.add(next),
          );
          addTearDown(subscription.close);
          final notifier = container.read(
            conversationSendQueueProvider.notifier,
          );
          first = notifier.enqueue(
            conversationId: 'conv-1',
            draft: const ChatDraft(text: 'First'),
          );
          middle = notifier.enqueue(
            conversationId: 'conv-1',
            draft: middleContent,
          );
          last = notifier.enqueue(
            conversationId: 'conv-1',
            draft: const ChatDraft(text: 'Last'),
          );
          other = notifier.enqueue(
            conversationId: 'conv-2',
            draft: const ChatDraft(text: 'Other conversation'),
          );
        },
        onEditDraft: (draft) => loadedDraft = draft,
      ),
    );

    final queuedMiddle = middle;
    final rowActions = find.byKey(
      ValueKey('queued-prompt-${queuedMiddle.id}-actions'),
    );
    await tester.tap(rowActions);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Move up'), findsOneWidget);
    expect(find.text('Move down'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('queued-prompt-${queuedMiddle.id}-move-up')),
    );
    final _ = await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Middle')).dy,
      lessThan(tester.getTopLeft(find.text('First')).dy),
    );
    expect(
      queueSnapshots.last['conv-1'],
      [middle, first, last],
    );
    expect(middle.draft, same(middleContent));
    expect(middle.draft.attachments.single, same(attachment));
    expect(
      queueSnapshots.last['conv-2'],
      [other],
    );

    await tester.tap(rowActions);
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('queued-prompt-${queuedMiddle.id}-move-down')),
    );
    final _ = await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('First')).dy,
      lessThan(tester.getTopLeft(find.text('Middle')).dy),
    );
    expect(
      queueSnapshots.last['conv-1'],
      [first, middle, last],
    );

    await tester.tap(find.byIcon(Icons.edit_outlined).at(1));
    await tester.pump();

    expect(loadedDraft, same(middleContent));
    expect(loadedDraft?.attachments.single, same(attachment));
    expect(
      queueSnapshots.last['conv-1'],
      [first, last],
    );
  });

  testWidgets('disables move actions at the first and last boundaries', (
    tester,
  ) async {
    late final ConversationQueuedDraft first;
    late final ConversationQueuedDraft last;
    final queueSnapshots = <Map<String, List<ConversationQueuedDraft>>>[];

    await pumpAndInit(
      tester,
      buildSubject(
        queuedDrafts: const [],
        watchQueue: true,
        onContainer: (container) {
          final subscription = container.listen(
            conversationSendQueueProvider,
            (_, next) => queueSnapshots.add(next),
          );
          addTearDown(subscription.close);
          final notifier = container.read(
            conversationSendQueueProvider.notifier,
          );
          first = notifier.enqueue(
            conversationId: 'conv-1',
            draft: const ChatDraft(text: 'First'),
          );
          last = notifier.enqueue(
            conversationId: 'conv-1',
            draft: const ChatDraft(text: 'Last'),
          );
        },
      ),
    );

    final queuedFirst = first;
    await tester.tap(
      find.byKey(ValueKey('queued-prompt-${queuedFirst.id}-actions')),
    );
    final _ = await tester.pumpAndSettle();
    final moveUpAtTop = tester
        .getSemantics(
          find.byKey(ValueKey('queued-prompt-${queuedFirst.id}-move-up')),
        )
        .getSemanticsData();
    expect(moveUpAtTop.flagsCollection.isButton, isTrue);
    expect(moveUpAtTop.flagsCollection.isEnabled, Tristate.isFalse);
    await tester.tap(
      find.byKey(ValueKey('queued-prompt-${queuedFirst.id}-move-up')),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      queueSnapshots.last['conv-1'],
      [first, last],
    );

    final _ = await tester.sendKeyEvent(.escape);
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('queued-prompt-${last.id}-actions')),
    );
    final _ = await tester.pumpAndSettle();
    final moveDownAtBottom = tester
        .getSemantics(
          find.byKey(ValueKey('queued-prompt-${last.id}-move-down')),
        )
        .getSemanticsData();
    expect(moveDownAtBottom.flagsCollection.isButton, isTrue);
    expect(moveDownAtBottom.flagsCollection.isEnabled, Tristate.isFalse);
    await tester.tap(
      find.byKey(ValueKey('queued-prompt-${last.id}-move-down')),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      queueSnapshots.last['conv-1'],
      [first, last],
    );
  });

  testWidgets('loads edited draft before removing it from the queue', (
    tester,
  ) async {
    const draft = ChatDraft(text: 'Edited message');
    final queuedDraft = ConversationQueuedDraft(id: 'queued-0', draft: draft);
    ChatDraft? loadedDraft;
    var queueState = <String, List<ConversationQueuedDraft>>{};
    var queueWasPresentWhenLoaded = false;

    await pumpAndInit(
      tester,
      buildSubject(
        queuedDrafts: [queuedDraft],
        onContainer: (value) {
          final subscription = value.listen(
            conversationSendQueueProvider,
            (_, next) => queueState = next,
          );
          addTearDown(subscription.close);
          final enqueuedDraft = value
              .read(conversationSendQueueProvider.notifier)
              .enqueue(conversationId: 'conv-1', draft: draft);
          expect(enqueuedDraft.draft, same(draft));
        },
        onEditDraft: (value) {
          loadedDraft = value;
          queueWasPresentWhenLoaded = queueState.isNotEmpty;
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();

    expect(loadedDraft, same(draft));
    expect(queueWasPresentWhenLoaded, isTrue);
    expect(queueState, isEmpty);
  });
}
