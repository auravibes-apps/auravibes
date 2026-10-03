import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'mcp_catalog_repository.dart';
import 'mcp_catalog_use_cases.dart';

class McpCatalogEndpoint extends Endpoint {
  Future<List<McpCatalogListing>> list(Session session) async {
    await const AuthenticatedAccountResolver()(session);
    return McpCatalogUseCases(McpCatalogRepository()).list(session);
  }
}
