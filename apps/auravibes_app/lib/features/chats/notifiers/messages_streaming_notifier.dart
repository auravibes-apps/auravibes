import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'messages_streaming_notifier.freezed.dart';
part 'messages_streaming_notifier.g.dart';

@freezed
abstract class MessagesStreamingState with _$MessagesStreamingState {
  const factory MessagesStreamingState({
    required CompositeSubscription streamSubscription,
    ChatResult<ChatMessage>? lastResult,
  }) = _MessagesStreamingState;
}

@riverpod
class MessagesStreamingNotifier extends _$MessagesStreamingNotifier {
  @override
  Map<String, MessagesStreamingState> build() {
    return {};
  }

  void startSubscription(
    CompositeSubscription subscription,
    String messageId,
  ) {
    state = {
      ...state,
      messageId: MessagesStreamingState(streamSubscription: subscription),
    };
  }

  void updateResult(ChatResult<ChatMessage> result, String messageId) {
    final currentState = state[messageId];
    if (currentState == null) {
      throw Exception(
        'No subscription found for message id: $messageId',
      );
    }
    state = {
      ...state,
      messageId: currentState.copyWith(lastResult: result),
    };
  }

  Future<void> remove(String messageId) async {
    final currentState = state[messageId];
    if (currentState != null) {
      await currentState.streamSubscription.cancel();
    }
    state = {
      for (final entry in state.entries)
        if (entry.key != messageId) entry.key: entry.value,
    };
  }
}
