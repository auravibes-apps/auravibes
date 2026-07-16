import 'package:auravibes_server/src/features/conversations/engine/conversation_engine_host.dart';
import 'package:auravibes_server/src/features/conversations/engine/conversation_host_effects.dart';
import 'package:test/test.dart';

void main() {
  test('configuration exception exposes only safe code', () {
    const error = ConversationEngineConfigurationException('provider_secret');

    expect(error.code, 'provider_secret');
    expect(error.toString(), isNot(contains('api')));
  });

  test('provider stream stops before yielding chunk after cancellation', () {
    var checks = 0;
    final stream = cancellationCheckedStream(
      Stream.fromIterable([1, 2, 3]),
      () async => ++checks == 2,
    );

    expect(
      stream,
      emitsInOrder([1, emitsError(isA<ConversationCancelledException>())]),
    );
  });

  test('fallback title is stable and bounded', () {
    expect(fallbackConversationTitle('  hello   world  '), 'hello world');
    expect(fallbackConversationTitle('a' * 40), '${'a' * 27}...');
  });

  test('Codex provider consumes OAuth access token JSON', () {
    expect(
      providerCredential('openai-codex', '{"access_token":"oauth-token"}'),
      'oauth-token',
    );
    expect(
      () => providerCredential('openai-codex', '{"refresh_token":"token"}'),
      throwsA(isA<ConversationEngineConfigurationException>()),
    );
  });

  test('provider request URI retains the configured API base path', () {
    expect(
      providerRequestUri('openai', Uri.parse('https://api.openai.com/v1')),
      Uri.parse('https://api.openai.com/v1/chat/completions'),
    );
    expect(
      providerRequestUri(
        'openai-codex',
        Uri.parse('https://chatgpt.com/backend-api/codex/'),
      ),
      Uri.parse('https://chatgpt.com/backend-api/codex/responses'),
    );
  });
}
