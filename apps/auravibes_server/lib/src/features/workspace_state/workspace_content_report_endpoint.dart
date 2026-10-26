import 'package:serverpod/serverpod.dart';

import '../accounts/authenticated_account_resolver.dart';
import 'workspace_content_report_service.dart';

class WorkspaceContentReportEndpoint extends Endpoint {
  Future<String> submit(
    Session session,
    int workspaceId,
    String targetJson,
    String reportId,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);

    return await WorkspaceContentReportService(
      session,
      workspaceId,
      account.userId,
    ).submit(targetJson, reportId);
  }

  Future<List<String>> list(Session session, int workspaceId) async {
    final account = await const AuthenticatedAccountResolver()(session);

    return await WorkspaceContentReportService(
      session,
      workspaceId,
      account.userId,
    ).list();
  }

  Future<String> resolve(
    Session session,
    int workspaceId,
    String reportId,
    String action,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);

    return await WorkspaceContentReportService(
      session,
      workspaceId,
      account.userId,
    ).resolve(reportId, action);
  }
}
