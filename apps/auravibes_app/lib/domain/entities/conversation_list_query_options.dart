class const ConversationListQueryOptions({
  this.search = '',
  this.archivedOnly = false,
  this.limit,
  this.offset = 0,
}) {
  final String search;
  final bool archivedOnly;
  final int? limit;
  final int offset;

  static const defaults = ConversationListQueryOptions();

  @override
  bool operator ==(Object other) =>
      other is ConversationListQueryOptions &&
      other.search == search &&
      other.archivedOnly == archivedOnly &&
      other.limit == limit &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(search, archivedOnly, limit, offset);
}
