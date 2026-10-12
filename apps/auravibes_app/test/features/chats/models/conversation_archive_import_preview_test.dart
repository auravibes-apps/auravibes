import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 11);

  test('previews a single archive with incomplete agent context', () {
    final archiveJson = ConversationArchiveCodec.encode(
      .new(
        title: 'Single imported conversation',
        createdAt: createdAt,
        updatedAt: createdAt,
        messages: const [],
        agentContext: .new(
          isComplete: false,
          entriesInput: const [],
          toolSelectionsInput: const [],
        ),
      ),
    );

    final preview = ConversationArchiveCodec.previewImport(archiveJson);

    expect(preview, hasLength(1));
    expect(preview.single.title, 'Single imported conversation');
    expect(preview.single.hasIncompleteAgentContext, isTrue);
  });

  test('previews every bundle item without returning context payloads', () {
    final bundleJson = ConversationArchiveCodec.encodeMany([
      .new(
        title: 'Complete context',
        createdAt: createdAt,
        updatedAt: createdAt,
        messages: const [],
        agentContext: .new(
          isComplete: true,
          entriesInput: const [],
          toolSelectionsInput: const [],
        ),
      ),
      .new(
        title: 'Incomplete context',
        createdAt: createdAt,
        updatedAt: createdAt,
        messages: const [],
        agentContext: .new(
          isComplete: false,
          entriesInput: const [],
          toolSelectionsInput: const [],
        ),
      ),
    ]);

    final preview = ConversationArchiveCodec.previewImport(bundleJson);

    expect(preview.map((item) => item.title), [
      'Complete context',
      'Incomplete context',
    ]);
    expect(preview.map((item) => item.hasIncompleteAgentContext), [
      false,
      true,
    ]);
  });
}
