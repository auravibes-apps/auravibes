import 'package:auravibes_app/features/chats/models/conversation_list_scope.dart';

typedef ConversationStreamPagination = ({int? limit, int offset});

/// Inputs that identify a page in the conversation stream.
typedef ConversationStreamRequest = ({
  String workspaceId,
  String search,
  ConversationListScope scope,
  ConversationStreamPagination pagination,
});
