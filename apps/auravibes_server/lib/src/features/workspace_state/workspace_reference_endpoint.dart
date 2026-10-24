import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'workspace_reference_reader.dart';

class WorkspaceReferenceEndpoint extends Endpoint {
  Future<List<WorkspaceResource>> targets(
    Session session,
    int workspaceId,
    String sourceTableId,
    String columnId,
    String search,
    String? afterId,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return WorkspaceReferenceReader(
      session,
      workspaceId,
      account.userId,
    ).targets(sourceTableId, columnId, search, afterId);
  }

  Future<List<WorkspaceResource>> reverse(
    Session session,
    int workspaceId,
    String tableId,
    String recordId,
    String? afterId,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return WorkspaceReferenceReader(
      session,
      workspaceId,
      account.userId,
    ).reverse(tableId, recordId, afterId);
  }
}
