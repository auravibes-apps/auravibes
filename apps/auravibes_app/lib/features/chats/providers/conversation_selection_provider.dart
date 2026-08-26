// Required: Existing helpers remain top-level for local feature use.
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_selection_provider.g.dart';

extension ConversationSelectionProvider on ConversationSelectedFamily {
  Override overrideWithValue(String value) => overrideWith((_, _) => value);
}

@riverpod
String conversationSelected(Ref _, String conversationId) => conversationId;
