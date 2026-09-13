import 'dart:convert';

class const AgentCatalogCursor({
  required this.workspaceId,
  required this.search,
  required this.type,
  required this.status,
  required this.name,
  required this.id,
}) {
  final int workspaceId;
  final String search;
  final String? type;
  final String? status;
  final String name;
  final String id;
}

final class AgentCatalogCursorCodec {
  const AgentCatalogCursorCodec();

  AgentCatalogCursor decode(String value) {
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(value))),
    );
    if (decoded case {
      'v': 1,
      'workspace': final int workspaceId,
      'search': final String search,
      'type': final String? type,
      'status': final String? status,
      'name': final String name,
      'id': final String id,
    }) {
      return AgentCatalogCursor(
        workspaceId: workspaceId,
        search: search,
        type: type,
        status: status,
        name: name,
        id: id,
      );
    }
    throw const FormatException('Invalid agent catalog cursor');
  }

  String encode(AgentCatalogCursor cursor) => base64Url.encode(
    utf8.encode(
      jsonEncode({
        'v': 1,
        'workspace': cursor.workspaceId,
        'search': cursor.search,
        'type': cursor.type,
        'status': cursor.status,
        'name': cursor.name,
        'id': cursor.id,
      }),
    ),
  );
}
