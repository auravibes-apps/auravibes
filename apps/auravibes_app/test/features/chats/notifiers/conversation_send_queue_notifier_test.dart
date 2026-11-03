import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('ConversationSendQueueNotifier', () {
    var container = ProviderContainer();
    var attachmentService = _FakeLocalChatAttachmentService();

    setUp(() {
      attachmentService = _FakeLocalChatAttachmentService();
      container = ProviderContainer(
        overrides: [
          localChatAttachmentServiceProvider.overrideWithValue(
            attachmentService,
          ),
        ],
      );
    });

    test('text-only queue creation does not initialize the audio recorder', () {
      final textOnlyContainer = ProviderContainer();
      addTearDown(textOnlyContainer.dispose);

      final queuedDraft = textOnlyContainer
          .read(conversationSendQueueProvider.notifier)
          .enqueue(
            conversationId: 'conv-1',
            draft: const ChatDraft(text: 'Text only'),
          );

      expect(queuedDraft.draft.text, 'Text only');
    });

    tearDown(() {
      container.dispose();
    });

    test('enqueues and dequeues drafts in FIFO order', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final first = notifier.enqueue(
        conversationId: 'conversation-1',
        draft: const ChatDraft(text: 'First queued message'),
      );
      final second = notifier.enqueue(
        conversationId: 'conversation-1',
        draft: const ChatDraft(text: 'Second queued message'),
      );

      expect(notifier.peek('conversation-1')?.content, 'First queued message');
      expect(notifier.dequeue('conversation-1')?.id, first.id);
      expect(notifier.dequeue('conversation-1')?.id, second.id);
      expect(notifier.dequeue('conversation-1'), isNull);
    });

    test('moves drafts only within the requested conversation', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);
      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final middle = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Middle'),
      );
      final last = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Last'),
      );
      final other = notifier.enqueue(
        conversationId: 'conv-2',
        draft: const ChatDraft(text: 'Other conversation'),
      );

      notifier.move(conversationId: 'conv-1', draftId: middle.id, offset: -1);

      expect(container.read(conversationSendQueueProvider)['conv-1'], [
        middle,
        first,
        last,
      ]);
      expect(container.read(conversationSendQueueProvider)['conv-2'], [other]);

      notifier.move(conversationId: 'conv-1', draftId: middle.id, offset: 1);

      expect(container.read(conversationSendQueueProvider)['conv-1'], [
        first,
        middle,
        last,
      ]);
      expect(container.read(conversationSendQueueProvider)['conv-2'], [other]);

      notifier.move(conversationId: 'conv-1', draftId: first.id, offset: 1);
      expect(container.read(conversationSendQueueProvider)['conv-1'], [
        middle,
        first,
        last,
      ]);

      notifier.move(conversationId: 'conv-1', draftId: first.id, offset: -1);
      expect(container.read(conversationSendQueueProvider)['conv-1'], [
        first,
        middle,
        last,
      ]);

      notifier.move(conversationId: 'conv-1', draftId: last.id, offset: -1);
      expect(container.read(conversationSendQueueProvider)['conv-1'], [
        first,
        last,
        middle,
      ]);

      notifier.move(conversationId: 'conv-1', draftId: last.id, offset: 1);
      expect(container.read(conversationSendQueueProvider)['conv-1'], [
        first,
        middle,
        last,
      ]);
      expect(container.read(conversationSendQueueProvider)['conv-2'], [other]);
    });

    test('dequeues drafts in their reordered display order', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);
      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final middle = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Middle'),
      );
      final last = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Last'),
      );

      notifier.move(conversationId: 'conv-1', draftId: last.id, offset: -1);

      expect(notifier.peek('conv-1'), same(first));
      expect(notifier.dequeue('conv-1'), same(first));
      expect(notifier.dequeue('conv-1'), same(last));
      expect(notifier.dequeue('conv-1'), same(middle));
      expect(notifier.dequeue('conv-1'), isNull);
    });

    test('drains in reordered visible order for active run continuation', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);
      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final middle = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Middle'),
      );
      final last = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Last'),
      );

      notifier.move(conversationId: 'conv-1', draftId: last.id, offset: -1);

      expect(notifier.dequeueAll('conv-1'), [first, last, middle]);
      expect(container.read(conversationSendQueueProvider), isEmpty);
    });

    test('boundary and unknown-draft moves leave state unchanged', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);
      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final last = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Last'),
      );
      final state = container.read(conversationSendQueueProvider);

      notifier.move(conversationId: 'conv-1', draftId: first.id, offset: -1);
      expect(container.read(conversationSendQueueProvider), same(state));

      notifier.move(conversationId: 'conv-1', draftId: last.id, offset: 1);
      expect(container.read(conversationSendQueueProvider), same(state));

      notifier.move(conversationId: 'conv-1', draftId: 'unknown', offset: -1);
      expect(container.read(conversationSendQueueProvider), same(state));

      notifier.move(conversationId: 'missing', draftId: first.id, offset: 1);
      expect(container.read(conversationSendQueueProvider), same(state));
    });

    test('moves preserve the queued draft and its attachment ownership', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);
      const attachedDraft = ChatDraft(
        text: 'Attached draft',
        attachments: [_attachment],
      );
      final attached = notifier.enqueue(
        conversationId: 'conv-1',
        draft: attachedDraft,
      );
      final next = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Next'),
      );

      notifier.move(conversationId: 'conv-1', draftId: attached.id, offset: 1);

      final reordered = container.read(conversationSendQueueProvider)['conv-1'];
      expect(reordered, [next, attached]);
      expect(reordered?.last, same(attached));
      expect(attached.draft, same(attachedDraft));
      expect(attached.draft.attachments, same(attachedDraft.attachments));
      expect(attachmentService.deletedPaths, isEmpty);
    });

    test('moving a single queued draft is a no-op in both directions', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);
      final only = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Only'),
      );
      final state = container.read(conversationSendQueueProvider);

      notifier.move(conversationId: 'conv-1', draftId: only.id, offset: -1);
      expect(container.read(conversationSendQueueProvider), same(state));

      notifier.move(conversationId: 'conv-1', draftId: only.id, offset: 1);
      expect(container.read(conversationSendQueueProvider), same(state));
    });

    test('keeps conversation queues independent across peek and dequeue', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Conv1 First'),
      );
      final second = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Conv1 Second'),
      );
      final other = notifier.enqueue(
        conversationId: 'conv-2',
        draft: const ChatDraft(text: 'Conv2 First'),
      );

      expect(notifier.peek('conv-1')?.id, first.id);
      expect(notifier.peek('conv-2')?.id, other.id);
      expect(notifier.dequeue('conv-1')?.id, first.id);
      expect(notifier.peek('conv-1')?.id, second.id);
      expect(notifier.dequeue('conv-2')?.id, other.id);
    });

    test('dequeueAll preserves order and clears all conversation queues', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final second = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Second'),
      );
      final third = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Third'),
      );
      final _ = notifier.enqueue(
        conversationId: 'conv-2',
        draft: const ChatDraft(text: 'Other'),
      );

      final all = notifier.dequeueAll('conv-1');

      expect(all.map((draft) => draft.id), [first.id, second.id, third.id]);
      expect(notifier.peek('conv-1'), isNull);
      final _ = notifier.dequeueAll('conv-2');
      expect(container.read(conversationSendQueueProvider), isEmpty);
    });

    test('remove removes a specific draft by id', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final first = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final second = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Second'),
      );

      notifier.remove(conversationId: 'conv-1', draftId: first.id);

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
      expect(state['conv-1']?.first.id, second.id);
    });

    test('remove deletes discarded draft attachments', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);
      final draft = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Attachment', attachments: [_attachment]),
      );

      notifier.remove(conversationId: 'conv-1', draftId: draft.id);

      expect(attachmentService.deletedPaths, ['/tmp/draft.txt']);
    });

    test('take preserves attachments for editing', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);
      final draft = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Attachment', attachments: [_attachment]),
      );

      expect(
        notifier.take(conversationId: 'conv-1', draftId: draft.id)?.id,
        draft.id,
      );
      expect(attachmentService.deletedPaths, isEmpty);
    });

    test('remove with unknown draftId is no-op', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      notifier.remove(conversationId: 'conv-1', draftId: 'nonexistent');

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
    });

    test('remove with unknown conversationId is no-op', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final draft = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );

      notifier.remove(conversationId: 'unknown', draftId: draft.id);

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
    });

    test('remove last draft clears conversation entry', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final draft = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Only one'),
      );

      notifier.remove(conversationId: 'conv-1', draftId: draft.id);

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1'], isNull);
    });

    test('clear removes all drafts for a conversation', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Second'),
      );
      final _ = notifier.enqueue(
        conversationId: 'conv-2',
        draft: const ChatDraft(text: 'Other conv'),
      );
      notifier.clear('conv-1');

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1'], isNull);
      expect(state['conv-2']?.length, 1);
    });

    test('clear with unknown conversationId is no-op', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);

      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'First'),
      );
      notifier.clear('unknown');

      final state = container.read(conversationSendQueueProvider);
      expect(state['conv-1']?.length, 1);
    });

    test('clear deletes all discarded draft attachments', () {
      final notifier = container.read(conversationSendQueueProvider.notifier);
      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Attachment', attachments: [_attachment]),
      );

      notifier.clear('conv-1');

      expect(attachmentService.deletedPaths, ['/tmp/draft.txt']);
    });

    test('provider disposal deletes attachments still owned by queue', () {
      final disposalService = _FakeLocalChatAttachmentService();
      final disposalContainer = ProviderContainer(
        overrides: [
          localChatAttachmentServiceProvider.overrideWithValue(disposalService),
        ],
      );
      final notifier = disposalContainer.read(
        conversationSendQueueProvider.notifier,
      );
      final _ = notifier.enqueue(
        conversationId: 'conv-1',
        draft: const ChatDraft(text: 'Attachment', attachments: [_attachment]),
      );

      disposalContainer.dispose();

      expect(disposalService.deletedPaths, ['/tmp/draft.txt']);
    });
  });
}

const _attachment = MessageAttachmentToCreate(
  localPath: '/tmp/draft.txt',
  fileName: 'draft.txt',
  displayName: 'draft.txt',
  mimeType: 'text/plain',
  modality: .file,
  sizeBytes: 5,
);

class _FakeLocalChatAttachmentService implements LocalChatAttachmentService {
  final String storageNamespace = 'test';
  final deletedPaths = <String>[];

  @override
  Future<void> deleteAttachment(String localPath) {
    deletedPaths.add(localPath);

    return Future.value();
  }

  @override
  Future<MessageAttachmentToCreate> copyIntoAppStorage(
    String sourcePath, {
    String? displayName,
  }) => throw UnimplementedError();

  @override
  Future<MessageAttachmentToCreate> copyBytesIntoAppStorage(
    Uint8List bytes, {
    required String fileName,
    required String displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> startVoiceRecording() => throw UnimplementedError();

  @override
  Future<MessageAttachmentToCreate?> stopVoiceRecording() =>
      throw UnimplementedError();

  @override
  @override
  Future<MessageAttachmentToCreate> createArchiveAttachment(
    ConversationArchiveAttachment _,
  ) => throw UnimplementedError();

  @override
  Future<MessageAttachmentToCreate> createToolResultAttachment({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String toolCallId,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> readAttachmentBytes(String _) => throw UnimplementedError();

  @override
  Future<void> cancelVoiceRecording() => throw UnimplementedError();
}
