import 'package:auravibes_app/features/chats/models/chat_skill_suggestion_action.dart';

class const ChatSkillSuggestionIntent({
  required final String workspaceId,
  required final String conversationId,
  required final String messageId,
  required final String surfaceId,
  required final String componentId,
  required final String slug,
  required final String catalogRevision,
  required final ChatSkillSuggestionAction action,
});
