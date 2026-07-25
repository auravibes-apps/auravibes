import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
import 'package:test/test.dart';

void main() {
  test('retains text in memory and publishes each chunk in order', () async {
    final publisher = _RecordingConversationProgressPublisher();
    final response = ConversationResponseAccumulator(publisher: publisher);

    response.addText('Hello');
    response.addText(' world');
    await response.close();

    expect(response.content, 'Hello world');
    expect(publisher.events, ['Hello', ' world']);
  });

  test('does not publish empty provider chunks', () async {
    final publisher = _RecordingConversationProgressPublisher();
    final response = ConversationResponseAccumulator(publisher: publisher);

    response.addText('');
    await response.close();

    expect(response.content, isEmpty);
    expect(publisher.events, isEmpty);
  });
}

class _RecordingConversationProgressPublisher
    implements ConversationProgressPublisher {
  final events = <String>[];

  @override
  Future<void> queued() async {}

  @override
  Future<void> running() async {}

  @override
  Future<void> text(String text) async {
    events.add(text);
  }

  @override
  Future<void> flush() async {}
}
