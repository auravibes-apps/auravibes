import 'package:auravibes_app/features/chats/models/conversation_list_scope.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class FilteredCloudConversationPageReader(
  final CloudWorkspaceStateGateway _gateway,
  final CloudWorkspaceRef _cloud,
  final ConversationListScope _scope,
  final ({int? limit, int offset}) _pagination,
  final String _search,
  final Set<String> _archivedIds,
) {
  final _conversations = <ConversationSummary>[];
  final _seenCursors = <String>{};
  int _skipped = 0;
  String? _cursor;

  static Future<List<ConversationSummary>> readAllPages(
    CloudWorkspaceStateGateway gateway,
    CloudWorkspaceRef cloud,
  ) async {
    final conversations = <ConversationSummary>[];
    final seenCursors = <String>{};
    String? cursor;

    while (true) {
      final page = await _readCloudConversationPageAtCursor(
        gateway,
        cloud,
        cursor,
      );
      conversations.addAll(page.conversations);

      cursor = _nextCloudConversationCursor(page.nextCursor, seenCursors);
      if (cursor == null) return conversations;
    }
  }

  Future<List<ConversationSummary>> read() async {
    if (_scope == .archived && _archivedIds.isEmpty) return [];
    if (_pagination.limit == 0) return [];

    while (true) {
      if (!await _readNextPage()) return _conversations;
    }
  }

  bool get _stopAfterFirstPage =>
      _scope == ConversationListScope.active &&
      _pagination.limit == null &&
      _pagination.offset == 0;

  Future<bool> _readNextPage() async {
    final page = await _readCloudConversationPageAtCursor(
      _gateway,
      _cloud,
      _cursor,
      search: _search,
    );
    final reachedLimit = _appendMatchingConversations(page.conversations);
    final nextCursor = _nextCloudConversationCursor(
      page.nextCursor,
      _seenCursors,
    );
    if (_shouldStopAfterPage(reachedLimit, nextCursor)) return false;
    _cursor = nextCursor;

    return true;
  }

  bool _shouldStopAfterPage(bool reachedLimit, String? nextCursor) =>
      reachedLimit || _stopAfterFirstPage || nextCursor == null;

  bool _appendMatchingConversations(List<ConversationSummary> page) {
    for (final conversation in page) {
      final isArchived = _archivedIds.contains(conversation.id);
      if (isArchived != (_scope == .archived)) continue;
      if (_skipped < _pagination.offset) {
        _skipped++;
        continue;
      }
      _conversations.add(conversation);
      final limit = _pagination.limit;
      if (limit != null && _conversations.length >= limit) return true;
    }

    return false;
  }

  static Future<ConversationPage> _readCloudConversationPageAtCursor(
    CloudWorkspaceStateGateway gateway,
    CloudWorkspaceRef cloud,
    String? cursor, {
    String search = '',
  }) => gateway.client.conversation.listPage(
    .new(
      workspaceId: cloud.cloudWorkspaceId,
      limit: 100,
      cursor: cursor,
      search: search.isEmpty ? null : search,
    ),
  );

  static String? _nextCloudConversationCursor(
    String? nextCursor,
    Set<String> seenCursors,
  ) {
    if (nextCursor == null) return null;
    if (nextCursor.isEmpty || !seenCursors.add(nextCursor)) {
      _throwInvalidCloudConversationCursor();
    }

    return nextCursor;
  }

  static Never _throwInvalidCloudConversationCursor() =>
      throw const CloudAppException(
        localizationKey: LocaleKeys.cloud_errors_malformed_resource,
        context: .conversation,
        code: 'invalidCursor',
      );
}
