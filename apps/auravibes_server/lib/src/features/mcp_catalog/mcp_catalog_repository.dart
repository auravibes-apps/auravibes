import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

class McpCatalogRepository {
  Future<List<McpCatalogEntry>> listEnabled(Session session) =>
      McpCatalogEntry.db.find(
        session,
        where: (table) => table.isEnabled.equals(true),
        orderByList: (table) => [table.name.asc(), table.catalogId.asc()],
      );
}
