import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'titles_streams_notifier.g.dart';

@riverpod
class TitlesStreamsNotifier extends _$TitlesStreamsNotifier {
  @override
  Map<String, String> build() {
    return {};
  }

  void updateTitle(String conversationId, String title) {
    state = {
      ...state,
      conversationId: title,
    };
  }

  void removeTitle(String conversationId) {
    state = {
      for (final entry in state.entries)
        if (entry.key != conversationId) entry.key: entry.value,
    };
  }
}
