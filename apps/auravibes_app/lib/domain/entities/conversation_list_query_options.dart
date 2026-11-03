typedef ConversationListQueryOptions = ({
  String search,
  bool archivedOnly,
  int? limit,
  int offset,
});

const ConversationListQueryOptions defaultConversationListQueryOptions = (
  search: '',
  archivedOnly: false,
  limit: null,
  offset: 0,
);
