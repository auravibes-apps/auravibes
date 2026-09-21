import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

class SkillResourceDataRepository {
  Future<List<SkillResource>> list(
    Session session, {
    required int workspaceId,
    required String skillId,
    Transaction? transaction,
  }) => SkillResource.db.find(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.skillId.equals(skillId) &
        table.deletedAt.equals(null),
    orderBy: (table) => table.title,
    transaction: transaction,
  );

  Future<SkillResource?> find(
    Session session, {
    required int workspaceId,
    required String resourceId,
    Transaction? transaction,
    bool lock = false,
  }) => SkillResource.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.resourceId.equals(resourceId) &
        table.deletedAt.equals(null),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
  );

  Future<SkillResource?> findBySlug(
    Session session, {
    required int workspaceId,
    required String skillId,
    required String slug,
    Transaction? transaction,
    bool lock = false,
  }) => SkillResource.db.findFirstRow(
    session,
    where: (table) =>
        table.workspaceId.equals(workspaceId) &
        table.skillId.equals(skillId) &
        table.slug.equals(slug) &
        table.deletedAt.equals(null),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
  );

  Future<SkillResource> insert(
    Session session,
    SkillResource resource, {
    required Transaction transaction,
  }) => SkillResource.db.insertRow(session, resource, transaction: transaction);

  Future<SkillResource> update(
    Session session,
    SkillResource resource, {
    required Transaction transaction,
  }) => SkillResource.db.updateRow(session, resource, transaction: transaction);
}
