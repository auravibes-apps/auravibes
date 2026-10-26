/// A user selection event never grants data in a copied/forked Conversation.
class WorkspaceContextSelection {
  new({
    required this.workspaceId,
    required this.conversationId,
    required this.itemId,
    required this.kind,
    this.parentId,
    List<String> recordIds = const [],
  }) : recordIds = List.unmodifiable(recordIds);
  final String workspaceId;
  final String conversationId;
  final String itemId;
  final String kind;
  final String? parentId;
  final List<String> recordIds;

  Map<String, Object?> toJson() => {
    'workspaceId': workspaceId,
    'conversationId': conversationId,
    'itemId': itemId,
    'kind': kind,
    'parentId': parentId,
    'recordIds': recordIds,
  };
  static WorkspaceContextSelection? decode(
    Object? value,
    String workspaceId,
    String conversationId,
  ) {
    if (value is! Map<String, dynamic>) return null;

    return _SelectionDecoder(value, workspaceId, conversationId).decode();
  }
}

class const _SelectionDecoder(
  final Map<String, dynamic> value,
  final String workspaceId,
  final String conversationId,
) {
  WorkspaceContextSelection? decode() {
    if (!_matchesConversation()) return null;
    final address = _address();
    final records = _records();
    if (address == null || records == null) return null;
    if (!_validKind(address, records)) return null;

    return WorkspaceContextSelection(
      workspaceId: workspaceId,
      conversationId: conversationId,
      itemId: address.itemId,
      kind: address.kind,
      parentId: address.parentId,
      recordIds: records,
    );
  }

  bool _matchesConversation() =>
      value['workspaceId'] == workspaceId &&
      value['conversationId'] == conversationId;

  ({String itemId, String kind, String? parentId})? _address() {
    final itemId = value['itemId'];
    final kind = value['kind'];
    final parentId = value['parentId'];
    if (itemId is! String || kind is! String || parentId is! String?) {
      return null;
    }

    return (itemId: itemId, kind: kind, parentId: parentId);
  }

  List<String>? _records() {
    final records = value['recordIds'];
    if (records is! List<Object?> || records.length > 50) return null;
    if (!_validRecords(records)) return null;

    return records.cast<String>();
  }

  bool _validRecords(List<Object?> records) =>
      records.every((id) => id is String && id.isNotEmpty) &&
      records.toSet().length == records.length;

  bool _validKind(
    ({String itemId, String kind, String? parentId}) address,
    List<String> records,
  ) {
    final emptyItem = address.itemId.isEmpty;
    final emptyRecords = records.isEmpty;

    return switch (address.kind) {
      'directory' => emptyItem && emptyRecords,
      'folder' => !emptyItem && emptyRecords,
      'table' || 'view' => !emptyItem,
      _ => false,
    };
  }
}
