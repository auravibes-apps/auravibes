import 'dart:async';

import 'package:auravibes_app/services/marionette/marionette_chat_smoke_fixture.dart';
import 'package:auravibes_app/services/marionette/marionette_chat_smoke_scenario.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns a final response for the complete scenario', () async {
    final fixture = _fixture(.complete);

    expect(await fixture.sendMessage().toList(), <ChatResult<ChatMessage>>[
      .new(
        output: ChatMessage.model('Marionette demo response.'),
        finishReason: .stop,
      ),
    ]);
  });

  test('keeps the response active until the smoke run cancels it', () async {
    final fixture = _fixture(.stop);
    final firstChunk = Completer<ChatResult<ChatMessage>>();

    final subscription = fixture.sendMessage().listen(firstChunk.complete);
    final chunk = await firstChunk.future;

    expect(chunk.output.text, 'Marionette response in progress.');
    final _ = await subscription.cancel();

    fixture.configure(.complete);
    expect(
      (await fixture.sendMessage().toList()).single.output.text,
      'Marionette demo response.',
    );
  });

  test(
    'fails once with a retryable error, then returns a final response',
    () async {
      final fixture = _fixture(.retry);

      await expectLater(
        fixture.sendMessage(),
        emitsError(
          isA<ProviderTransientFailureException>().having(
            (error) => error.cause,
            'cause',
            isA<StateError>(),
          ),
        ),
      );
      expect(
        ProviderFailureRecovery.fromError(
          ProviderTransientFailureException(StateError('fixture failure')),
        ).retryable,
        isTrue,
      );
      expect(
        (await fixture.sendMessage().toList()).single.output.text,
        'Marionette demo response.',
      );
    },
  );
}

MarionetteChatSmokeFixture _fixture(MarionetteChatSmokeScenario scenario) =>
    .new()..configure(scenario);
