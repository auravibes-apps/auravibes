import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'workspace_reference_reader.dart';

class WorkspaceReferenceEndpoint extends Endpoint {
  Future<List<WorkspaceResource>> targets(
    Session session,
    WorkspaceReferenceTargetRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);

    return await WorkspaceReferenceReader(
      session,
      request.workspaceId,
      account.userId,
    ).targets(request);
  }

  Future<List<WorkspaceResource>> tableTargets(
    Session session,
    WorkspaceReferenceTableRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return await WorkspaceReferenceReader(
      session,
      request.workspaceId,
      account.userId,
    ).tableTargets(request);
  }

  Future<WorkspaceResource> record(
    Session session,
    WorkspaceReferenceRecordRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);

    return await WorkspaceReferenceReader(
      session,
      request.workspaceId,
      account.userId,
    ).record(request);
  }

  Future<List<WorkspaceResource>> reverse(
    Session session,
    WorkspaceReferenceRecordRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);

    return await WorkspaceReferenceReader(
      session,
      request.workspaceId,
      account.userId,
    ).reverse(request);
  }
}
