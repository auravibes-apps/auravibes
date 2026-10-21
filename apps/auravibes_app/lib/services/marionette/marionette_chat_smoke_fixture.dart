import 'dart:async';

import 'package:auravibes_app/services/marionette/marionette_chat_smoke_scenario.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class MarionetteChatSmokeFixture {
  MarionetteChatSmokeScenario? _scenario;
  StreamController<ChatResult<ChatMessage>>? _activeResponse;
  var _retryAttempts = 0;

  void configure(MarionetteChatSmokeScenario scenario) {
    if (_activeResponse != null) {
      throw StateError('Stop the active Marionette response first.');
    }
    _scenario = scenario;
    _retryAttempts = 0;
  }

  Stream<ChatResult<ChatMessage>> sendMessage() => switch (_scenario) {
    .complete => _completedResponse(),
    .stop => _stoppableResponse(),
    .retry => _retryResponse(),
    null => _completedResponse(),
  };

  Stream<ChatResult<ChatMessage>> _completedResponse() {
    _scenario = null;

    return Stream.value(
      ChatResult<ChatMessage>(
        output: ChatMessage.model('Marionette demo response.'),
        finishReason: .stop,
      ),
    );
  }

  Stream<ChatResult<ChatMessage>> _stoppableResponse() {
    final controller = StreamController<ChatResult<ChatMessage>>(
      onCancel: () {
        _activeResponse = null;
        _scenario = null;
      },
    );
    _activeResponse = controller;
    controller.add(
      ChatResult<ChatMessage>(
        output: ChatMessage.model('Marionette response in progress.'),
      ),
    );

    return controller.stream;
  }

  Stream<ChatResult<ChatMessage>> _retryResponse() {
    if (_retryAttempts++ == 0) {
      return Stream.error(
        ProviderTransientFailureException(
          StateError('Marionette smoke fixture failed once.'),
        ),
      );
    }

    _scenario = null;

    return _completedResponse();
  }
}
