import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../workspaces/domain/workspace_roles.dart';
import '../repositories/skill_resource_repository.dart';

class SkillResourceUseCases(final SkillResourceDataRepository _repository) {
  static const descriptionLimit = 240;
  static const contentLimit = 50000;
  static const resourceLimit = 100;

  Future<List<SkillResourceView>> list(
    Session session, {
    required String userId,
    required ListSkillResourcesRequest request,
  }) async {
    await _requireMember(session, request.workspaceId, userId);
    final resources = await _repository.list(
      session,
      workspaceId: request.workspaceId,
      skillId: request.skillId,
    );

    return resources.map(_view).toList();
  }

  Future<SkillResourceView?> get(
    Session session, {
    required String userId,
    required GetSkillResourceRequest request,
  }) async {
    await _requireMember(session, request.workspaceId, userId);
    final resource = await _repository.find(
      session,
      workspaceId: request.workspaceId,
      resourceId: request.resourceId,
    );

    return resource == null ? null : _view(resource);
  }

  Future<SkillResourceView> create(
    Session session, {
    required String userId,
    required CreateSkillResourceRequest request,
  }) => session.db.transaction((transaction) async {
    await _requireManager(session, request.workspaceId, userId);
    _validate(
      request.title,
      request.description,
      request.content,
      request.resourceId,
    );
    await _requireSkill(
      session,
      workspaceId: request.workspaceId,
      skillId: request.skillId,
      transaction: transaction,
    );
    final resources = await _repository.list(
      session,
      workspaceId: request.workspaceId,
      skillId: request.skillId,
      transaction: transaction,
    );
    if (resources.length >= resourceLimit) _invalid();
    if (await _repository.findBySlug(
          session,
          workspaceId: request.workspaceId,
          skillId: request.skillId,
          slug: generateSkillSlug(request.title),
          transaction: transaction,
          lock: true,
        ) !=
        null) {
      _conflict();
    }
    if (await _repository.find(
          session,
          workspaceId: request.workspaceId,
          resourceId: request.resourceId,
          transaction: transaction,
          lock: true,
        ) !=
        null) {
      _conflict();
    }
    final now = DateTime.now().toUtc();
    final resource = await _repository.insert(
      session,
      SkillResource(
        workspaceId: request.workspaceId,
        skillId: request.skillId,
        resourceId: request.resourceId,
        title: request.title.trim(),
        slug: generateSkillSlug(request.title),
        description: request.description.trim(),
        content: request.content,
        revision: 1,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await _recordInvalidation(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
      skillId: request.skillId,
      transaction: transaction,
    );
    return _view(resource);
  });

  Future<SkillResourceView> update(
    Session session, {
    required String userId,
    required UpdateSkillResourceRequest request,
  }) => session.db.transaction((transaction) async {
    await _requireManager(session, request.workspaceId, userId);
    _validate(request.title, request.description, request.content, 'id');
    final existing = await _repository.find(
      session,
      workspaceId: request.workspaceId,
      resourceId: request.resourceId,
      transaction: transaction,
      lock: true,
    );
    if (existing == null || existing.revision != request.expectedRevision) {
      _staleRevision();
    }
    final updated = await _repository.update(
      session,
      existing.copyWith(
        title: request.title.trim(),
        description: request.description.trim(),
        content: request.content,
        revision: existing.revision + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
    await _recordInvalidation(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
      skillId: updated.skillId,
      transaction: transaction,
    );
    return _view(updated);
  });

  Future<void> delete(
    Session session, {
    required String userId,
    required DeleteSkillResourceRequest request,
  }) => session.db.transaction((transaction) async {
    await _requireManager(session, request.workspaceId, userId);
    final existing = await _repository.find(
      session,
      workspaceId: request.workspaceId,
      resourceId: request.resourceId,
      transaction: transaction,
      lock: true,
    );
    if (existing == null || existing.revision != request.expectedRevision) {
      _staleRevision();
    }
    await _repository.update(
      session,
      existing.copyWith(
        deletedAt: DateTime.now().toUtc(),
        revision: existing.revision + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
      transaction: transaction,
    );
    await _recordInvalidation(
      session,
      workspaceId: request.workspaceId,
      userId: userId,
      skillId: existing.skillId,
      transaction: transaction,
    );
  });

  Future<WorkspaceMember> _requireMember(
    Session session,
    int workspaceId,
    String userId,
  ) async {
    final member = await WorkspaceMember.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.userId.equals(userId) &
          table.removedAt.equals(null),
    );
    if (member == null) _permissionDenied();
    return member;
  }

  Future<WorkspaceMember> _requireManager(
    Session session,
    int workspaceId,
    String userId,
  ) async {
    final member = await _requireMember(session, workspaceId, userId);
    if (member.role != WorkspaceRoles.owner &&
        member.role != WorkspaceRoles.admin) {
      _permissionDenied();
    }

    return member;
  }

  Future<void> _requireSkill(
    Session session, {
    required int workspaceId,
    required String skillId,
    required Transaction transaction,
  }) async {
    final skill = await WorkspaceResource.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.resourceKind.equals(WorkspaceResourceKind.skill) &
          table.resourceId.equals(skillId) &
          table.deletedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (skill == null) _invalid();
  }

  void _validate(
    String title,
    String description,
    String content,
    String resourceId,
  ) {
    if (resourceId.trim().isEmpty ||
        title.trim().isEmpty ||
        title.length > 500 ||
        description.length > descriptionLimit ||
        content.length > contentLimit ||
        generateSkillSlug(title).isEmpty) {
      _invalid();
    }
  }

  Future<void> _recordInvalidation(
    Session session, {
    required int workspaceId,
    required String userId,
    required String skillId,
    required Transaction transaction,
  }) async {
    final workspace = await CloudWorkspace.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(workspaceId) & table.deletedAt.equals(null),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (workspace == null) _permissionDenied();
    final now = DateTime.now().toUtc();
    await CloudWorkspace.db.updateRow(
      session,
      workspace.copyWith(sequence: workspace.sequence + 1, updatedAt: now),
      transaction: transaction,
    );
    await WorkspaceEvent.db.insertRow(
      session,
      WorkspaceEvent(
        eventId: const Uuid().v7(),
        workspaceId: workspaceId,
        sequence: workspace.sequence + 1,
        actorUserId: userId,
        kind: 'skill_resource_updated',
        resourceKind: WorkspaceResourceKind.skill.name,
        resourceId: skillId,
        createdAt: now,
      ),
      transaction: transaction,
    );
  }

  SkillResourceView _view(SkillResource resource) => SkillResourceView(
    id: resource.resourceId,
    skillId: resource.skillId,
    title: resource.title,
    slug: resource.slug,
    description: resource.description,
    content: resource.content,
    revision: resource.revision,
    createdAt: resource.createdAt,
    updatedAt: resource.updatedAt,
  );
}

Never _invalid() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.validationFailed,
);

Never _conflict() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.conflict,
);

Never _staleRevision() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.staleRevision,
);

Never _permissionDenied() => throw CloudWorkspaceException(
  code: CloudWorkspaceErrorCode.permissionDenied,
);
