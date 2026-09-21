import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'repositories/skill_resource_repository.dart';
import 'usecases/skill_resource_usecases.dart';

class SkillResourceEndpoint extends Endpoint {
  SkillResourceUseCases get _useCases =>
      SkillResourceUseCases(SkillResourceDataRepository());

  Future<List<SkillResourceView>> list(
    Session session,
    ListSkillResourcesRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.list(session, userId: account.userId, request: request);
  }

  Future<SkillResourceView?> get(
    Session session,
    GetSkillResourceRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.get(session, userId: account.userId, request: request);
  }

  Future<SkillResourceView> create(
    Session session,
    CreateSkillResourceRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.create(session, userId: account.userId, request: request);
  }

  Future<SkillResourceView> update(
    Session session,
    UpdateSkillResourceRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.update(session, userId: account.userId, request: request);
  }

  Future<void> delete(
    Session session,
    DeleteSkillResourceRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.delete(session, userId: account.userId, request: request);
  }
}
