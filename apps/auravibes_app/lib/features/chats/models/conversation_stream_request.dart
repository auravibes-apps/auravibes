import 'package:auravibes_app/features/chats/models/conversation_list_scope.dart';

typedef ConversationStreamPagination = ({int? limit, int offset});

/// Inputs that identify a page in the conversation stream.
class const ConversationStreamRequest({
  required this.workspaceId,
  this.search = '',
  this.pagination = const (limit: null, offset: 0),
  this.scope = ConversationListScope.active,
}) {
  final String workspaceId;
  final String search;
  final ConversationStreamPagination pagination;
  final ConversationListScope scope;

  @override
  bool operator ==(Object other) =>
      other is ConversationStreamRequest &&
      other.workspaceId == workspaceId &&
      other.search == search &&
      other.pagination == pagination &&
      other.scope == scope;

  @override
  int get hashCode => Object.hash(workspaceId, search, pagination, scope);
}
