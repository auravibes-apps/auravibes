import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persists revision intent and target in message metadata', () {
    const draft = ChatDraft(
      text: 'Make the checklist shorter.',
      intent: .revision,
      targetMessageId: 'request-1',
    );

    final metadata = MessageMetadataEntity.fromJsonString(
      draft.metadataJsonForPersistence,
    );

    expect(metadata?.isRevision, isTrue);
    expect(metadata?.revisionTargetMessageId, 'request-1');
  });

  test('preserves metadata exactly for ordinary messages', () {
    const metadata = ' {"modelMetadata":{"source":"composer"}} ';
    const draft = ChatDraft(text: 'Hello', metadataJson: metadata);

    expect(draft.metadataJsonForPersistence, metadata);
    final persistedMetadata = draft.metadataJsonForPersistence;
    expect(persistedMetadata, isNotNull);
    expect(jsonDecode(persistedMetadata ?? ''), {
      'modelMetadata': {'source': 'composer'},
    });
  });
}
