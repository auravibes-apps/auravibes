import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../../generated/protocol.dart';
import '../domain/workspace_roles.dart';
import '../repositories/cloud_workspace_repository.dart' as workspace_repo;

class CloudWorkspaceUseCases(
  final workspace_repo.CloudWorkspaceRepository _repository,
) {
  static const _inviteLifetime = Duration(days: 7);
  static const _maxWorkspaceNameLength = 20;
  static const _maxEmailLength = 254;
  static const _createWorkspaceScope = 'create-workspace';
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  Future<List<CloudWorkspaceSummary>> listAuthorizedWorkspaces(
    Session session, {
    required String userId,
  }) => _repository.listAuthorizedWorkspaces(session, userId: userId);

  Future<List<PendingWorkspaceInviteSummary>> listPendingInvites(
    Session session, {
    required String email,
  }) => _repository.listPendingInvites(
    session,
    email: _normalizeEmail(email),
    now: DateTime.now().toUtc(),
  );

  Future<CloudWorkspaceDetail> getWorkspaceDetail(
    Session session, {
    required String userId,
    required GetCloudWorkspaceDetailRequest request,
  }) async {
    final workspace = await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, workspace.id!, userId);
    return CloudWorkspaceDetail(
      workspace: _repository.toSummary(workspace, actor.role),
      ownerUserId: workspace.ownerUserId,
      ownerEmail: await _findEmail(session, workspace.ownerUserId),
      capabilities: capabilitiesForRole(actor.role),
    );
  }

  Future<List<CloudWorkspaceMemberSummary>> listMembers(
    Session session, {
    required String userId,
    required ListWorkspaceMembersRequest request,
  }) async {
    await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, request.workspaceId, userId);
    if (!WorkspaceRoles.canViewRoster(actor.role)) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    final members = await _repository.listActiveMembers(
      session,
      workspaceId: request.workspaceId,
    );
    return Future.wait(
      members.map(
        (member) async => CloudWorkspaceMemberSummary(
          userId: member.userId,
          email: await _findEmail(session, member.userId),
          role: member.role,
          revision: member.revision,
          createdAt: member.createdAt,
        ),
      ),
    );
  }

  Future<List<CloudWorkspaceInviteSummary>> listWorkspaceInvites(
    Session session, {
    required String userId,
    required ListCloudWorkspaceInvitesRequest request,
  }) async {
    await _requireWorkspace(session, request.workspaceId);
    final actor = await _requireMember(session, request.workspaceId, userId);
    if (!WorkspaceRoles.canViewRoster(actor.role)) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    final invites = await _repository.listActiveInvites(
      session,
      workspaceId: request.workspaceId,
      now: DateTime.now().toUtc(),
    );
    return invites.map(_inviteSummary).toList();
  }

  Future<CloudWorkspaceSummary> createWorkspace(
    Session session, {
    required String userId,
    required CreateCloudWorkspaceRequest request,
  }) async {
    final name = _requireName(request.name);
    final now = DateTime.now().toUtc();
    return session.db.transaction((transaction) async {
      const endpoint = 'cloudWorkspace.createWorkspace';
      final requestHash = jsonEncode({'name': name});
      final receipt = await _repository.findReceipt(
        session,
        actorUserId: userId,
        scopeKey: _createWorkspaceScope,
        endpoint: endpoint,
        requestId: request.requestId,
        transaction: transaction,
      );
      if (receipt != null) {
        if (receipt.requestHash != requestHash) {
          _fail(CloudWorkspaceErrorCode.idempotencyConflict);
        }
        return CloudWorkspaceSummary.fromJson(
          jsonDecode(receipt.responseJson) as Map<String, dynamic>,
        );
      }
      final workspace = await _repository.createWorkspace(
        session,
        name: name,
        ownerUserId: userId,
        now: now,
        transaction: transaction,
      );
      final response = _repository
          .toSummary(workspace, WorkspaceRoles.owner)
          .copyWith(sequence: workspace.sequence + 1);
      await _repository.recordMutation(
        session,
        workspace: workspace,
        actorUserId: userId,
        scopeKey: _createWorkspaceScope,
        endpoint: endpoint,
        requestId: request.requestId,
        requestHash: requestHash,
        operation: 'created',
        resourceKind: 'workspace',
        resourceId: workspace.id.toString(),
        responseJson: jsonEncode(response.toJson()),
        now: now,
        transaction: transaction,
      );
      return response;
    });
  }

  Future<PendingWorkspaceInviteSummary> inviteMember(
    Session session, {
    required String userId,
    required InviteWorkspaceMemberRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'cloudWorkspace.inviteMember',
    requestId: request.requestId,
    requestBody: {
      'workspaceId': request.workspaceId,
      'email': _normalizeEmail(request.email),
      'role': request.role,
      'expectedWorkspaceRevision': request.expectedWorkspaceRevision,
    },
    decode: (json) => PendingWorkspaceInviteSummary.fromJson(json),
    run: (transaction, workspace, now) async {
      final role = _requireRole(request.role);
      _requireRevision(workspace.revision, request.expectedWorkspaceRevision);
      final actor = await _requireMember(
        session,
        workspace.id!,
        userId,
        transaction: transaction,
      );
      if (!WorkspaceRoles.canInvite(actor.role, role)) {
        _fail(CloudWorkspaceErrorCode.permissionDenied);
      }
      final email = _normalizeEmail(request.email);
      if (email.length > _maxEmailLength || !_emailPattern.hasMatch(email)) {
        _fail(CloudWorkspaceErrorCode.validationFailed);
      }
      final now = DateTime.now().toUtc();
      if (await _repository.findActiveInviteByEmail(
            session,
            workspaceId: workspace.id!,
            email: email,
            now: now,
            transaction: transaction,
            lock: true,
          ) !=
          null) {
        _fail(CloudWorkspaceErrorCode.duplicateInvite);
      }
      final invite = await (() async {
        final staleInvite = await _repository.findInviteByPendingKey(
          session,
          pendingKey: '${workspace.id}:$email',
          transaction: transaction,
        );
        if (staleInvite != null) {
          await _repository.clearPendingKey(
            session,
            invite: staleInvite,
            transaction: transaction,
          );
        }
        return _repository.createInvite(
          session,
          invite: WorkspaceInvite(
            workspaceId: workspace.id!,
            email: email,
            normalizedEmail: email,
            role: role,
            invitedByUserId: userId,
            revision: 1,
            createdAt: now,
            updatedAt: now,
            expiresAt: now.add(_inviteLifetime),
            pendingKey: '${workspace.id}:$email',
          ),
          transaction: transaction,
        );
      })();
      final response = PendingWorkspaceInviteSummary(
        id: invite.id!,
        workspaceId: workspace.id!,
        workspaceName: workspace.name,
        email: invite.email,
        role: invite.role,
        revision: invite.revision,
        createdAt: invite.createdAt,
      );
      return _MutationResult(
        value: response,
        responseJson: jsonEncode(response.toJson()),
        operation: 'invited',
        resourceKind: 'invite',
        resourceId: invite.id.toString(),
      );
    },
  );

  Future<CloudWorkspaceInviteSummary> renewInvite(
    Session session, {
    required String userId,
    required RenewWorkspaceInviteRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'cloudWorkspace.renewInvite',
    requestId: request.requestId,
    requestBody: _requestBody(request.toJson()),
    decode: CloudWorkspaceInviteSummary.fromJson,
    run: (transaction, workspace, now) async {
      final actor = await _requireMember(
        session,
        request.workspaceId,
        userId,
        transaction: transaction,
      );
      final invite = await _requireInvite(
        session,
        request.inviteId,
        transaction: transaction,
      );
      _requireRevision(invite.revision, request.expectedInviteRevision);
      _requireInviteWorkspace(invite, request.workspaceId);
      if (!WorkspaceRoles.canInvite(actor.role, invite.role)) {
        _fail(CloudWorkspaceErrorCode.permissionDenied);
      }
      if (invite.revokedAt != null) {
        _fail(CloudWorkspaceErrorCode.inviteRevoked);
      }
      if (invite.acceptedAt != null || invite.declinedAt != null) {
        _fail(CloudWorkspaceErrorCode.inviteNotFound);
      }
      final activeInvite = await _repository.findActiveInviteByEmail(
        session,
        workspaceId: invite.workspaceId,
        email: invite.email,
        now: now,
        transaction: transaction,
        lock: true,
      );
      if (activeInvite != null && activeInvite.id != invite.id) {
        _fail(CloudWorkspaceErrorCode.duplicateInvite);
      }
      final renewed = await _repository.renewInvite(
        session,
        invite: invite,
        expiresAt: now.add(_inviteLifetime),
        now: now,
        transaction: transaction,
      );
      final response = _inviteSummary(renewed);
      return _MutationResult(
        value: response,
        responseJson: jsonEncode(response.toJson()),
        operation: 'inviteRenewed',
        resourceKind: 'invite',
        resourceId: invite.id.toString(),
      );
    },
  );

  Future<void> revokeInvite(
    Session session, {
    required String userId,
    required RevokeWorkspaceInviteRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'cloudWorkspace.revokeInvite',
    requestId: request.requestId,
    requestBody: _requestBody(request.toJson()),
    decode: (_) {},
    run: (transaction, workspace, now) async {
      final actor = await _requireMember(
        session,
        request.workspaceId,
        userId,
        transaction: transaction,
      );
      final invite = await _requireInvite(
        session,
        request.inviteId,
        transaction: transaction,
      );
      _requireRevision(invite.revision, request.expectedInviteRevision);
      _requireInviteWorkspace(invite, request.workspaceId);
      if (!WorkspaceRoles.canInvite(actor.role, invite.role)) {
        _fail(CloudWorkspaceErrorCode.permissionDenied);
      }
      _requireActiveInvite(invite, now);
      await _repository.revokeInvite(
        session,
        invite: invite,
        now: now,
        transaction: transaction,
      );
      return _MutationResult(
        value: null,
        responseJson: '{}',
        operation: 'inviteRevoked',
        resourceKind: 'invite',
        resourceId: invite.id.toString(),
      );
    },
  );

  Future<CloudWorkspaceSummary> acceptInvite(
    Session session, {
    required String userId,
    required String email,
    required AcceptWorkspaceInviteRequest request,
  }) async {
    final invite = await _requireInvite(
      session,
      request.inviteId,
    );
    return _mutate(
      session,
      userId: userId,
      workspaceId: invite.workspaceId,
      endpoint: 'cloudWorkspace.acceptInvite',
      requestId: request.requestId,
      requestBody: _requestBody(request.toJson()),
      decode: CloudWorkspaceSummary.fromJson,
      run: (transaction, workspace, now) async {
        final lockedInvite = await _requireInvite(
          session,
          request.inviteId,
          transaction: transaction,
        );
        _requireRevision(lockedInvite.revision, request.expectedInviteRevision);
        _requireActiveInvite(lockedInvite, now);
        if (lockedInvite.email != _normalizeEmail(email)) {
          _fail(CloudWorkspaceErrorCode.inviteEmailMismatch);
        }
        if (await _repository.findActiveMember(
              session,
              workspaceId: workspace.id!,
              userId: userId,
              transaction: transaction,
            ) !=
            null) {
          _fail(CloudWorkspaceErrorCode.duplicateMembership);
        }
        await _repository.upsertMember(
          session,
          workspaceId: workspace.id!,
          userId: userId,
          role: lockedInvite.role,
          now: now,
          transaction: transaction,
        );
        await _repository.acceptInvite(
          session,
          invite: lockedInvite,
          userId: userId,
          now: now,
          transaction: transaction,
        );
        final response = _repository
            .toSummary(workspace, lockedInvite.role)
            .copyWith(sequence: workspace.sequence + 1);
        return _MutationResult(
          value: response,
          responseJson: jsonEncode(response.toJson()),
          operation: 'inviteAccepted',
          resourceKind: 'member',
          resourceId: userId,
        );
      },
    );
  }

  Future<void> declineInvite(
    Session session, {
    required String userId,
    required String email,
    required DeclineWorkspaceInviteRequest request,
  }) async {
    final invite = await _requireInvite(session, request.inviteId);
    await _mutate(
      session,
      userId: userId,
      workspaceId: invite.workspaceId,
      endpoint: 'cloudWorkspace.declineInvite',
      requestId: request.requestId,
      requestBody: _requestBody(request.toJson()),
      decode: (_) {},
      run: (transaction, workspace, now) async {
        final lockedInvite = await _requireInvite(
          session,
          request.inviteId,
          transaction: transaction,
        );
        _requireRevision(lockedInvite.revision, request.expectedInviteRevision);
        _requireActiveInvite(lockedInvite, now);
        if (lockedInvite.email != _normalizeEmail(email)) {
          _fail(CloudWorkspaceErrorCode.inviteEmailMismatch);
        }
        await _repository.declineInvite(
          session,
          invite: lockedInvite,
          now: now,
          transaction: transaction,
        );
        return _MutationResult(
          value: null,
          responseJson: '{}',
          operation: 'inviteDeclined',
          resourceKind: 'invite',
          resourceId: lockedInvite.id.toString(),
        );
      },
    );
  }

  Future<CloudWorkspaceSummary> renameWorkspace(
    Session session, {
    required String userId,
    required RenameCloudWorkspaceRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'cloudWorkspace.renameWorkspace',
    requestId: request.requestId,
    requestBody: {
      'workspaceId': request.workspaceId,
      'name': request.name.trim(),
      'expectedWorkspaceRevision': request.expectedWorkspaceRevision,
    },
    decode: CloudWorkspaceSummary.fromJson,
    run: (transaction, workspace, now) async {
      _requireRevision(workspace.revision, request.expectedWorkspaceRevision);
      _requireOwner(workspace, userId);
      final renamed = await _repository.renameWorkspace(
        session,
        workspace: workspace,
        name: _requireName(request.name),
        now: now,
        transaction: transaction,
      );
      final response = _repository
          .toSummary(renamed, WorkspaceRoles.owner)
          .copyWith(sequence: workspace.sequence + 1);
      return _MutationResult(
        value: response,
        responseJson: jsonEncode(response.toJson()),
        operation: 'renamed',
        resourceKind: 'workspace',
        resourceId: workspace.id.toString(),
        workspace: renamed,
      );
    },
  );

  Future<void> leaveWorkspace(
    Session session, {
    required String userId,
    required LeaveCloudWorkspaceRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'cloudWorkspace.leaveWorkspace',
    requestId: request.requestId,
    requestBody: {
      'workspaceId': request.workspaceId,
      'expectedWorkspaceRevision': request.expectedWorkspaceRevision,
    },
    decode: (_) {},
    run: (transaction, workspace, now) async {
      _requireRevision(workspace.revision, request.expectedWorkspaceRevision);
      if (workspace.ownerUserId == userId) {
        _fail(CloudWorkspaceErrorCode.ownerCannotLeave);
      }
      final member = await _requireMember(
        session,
        request.workspaceId,
        userId,
        transaction: transaction,
      );
      await _repository.removeMember(
        session,
        member: member,
        now: now,
        transaction: transaction,
      );
      return _MutationResult(
        value: null,
        responseJson: '{}',
        operation: 'left',
        resourceKind: 'member',
        resourceId: userId,
      );
    },
  );

  Future<void> transferOwnership(
    Session session, {
    required String userId,
    required TransferCloudWorkspaceOwnershipRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'cloudWorkspace.transferOwnership',
    requestId: request.requestId,
    requestBody: {
      'workspaceId': request.workspaceId,
      'newOwnerUserId': request.newOwnerUserId,
      'expectedWorkspaceRevision': request.expectedWorkspaceRevision,
    },
    decode: (_) {},
    run: (transaction, workspace, now) async {
      _requireOwner(workspace, userId);
      _requireRevision(workspace.revision, request.expectedWorkspaceRevision);
      final owner = await _requireMember(
        session,
        request.workspaceId,
        userId,
        transaction: transaction,
      );
      final newOwner = await _requireMember(
        session,
        request.workspaceId,
        request.newOwnerUserId,
        transaction: transaction,
      );
      if (newOwner.role == WorkspaceRoles.owner) {
        _fail(CloudWorkspaceErrorCode.validationFailed);
      }
      await _repository.transferOwnership(
        session,
        workspace: workspace,
        owner: owner,
        newOwner: newOwner,
        now: now,
        transaction: transaction,
      );
      return _MutationResult(
        value: null,
        responseJson: '{}',
        operation: 'ownershipTransferred',
        resourceKind: 'member',
        resourceId: request.newOwnerUserId,
        workspace: workspace.copyWith(
          ownerUserId: request.newOwnerUserId,
          revision: workspace.revision + 1,
          updatedAt: now,
        ),
      );
    },
  );

  Future<void> updateMemberRole(
    Session session, {
    required String userId,
    required UpdateWorkspaceMemberRoleRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'cloudWorkspace.updateMemberRole',
    requestId: request.requestId,
    requestBody: _requestBody(request.toJson()),
    decode: (_) {},
    run: (transaction, workspace, now) async {
      final role = _requireRole(request.role);
      final actor = await _requireMember(
        session,
        request.workspaceId,
        userId,
        transaction: transaction,
      );
      final target = await _requireMember(
        session,
        request.workspaceId,
        request.userId,
        transaction: transaction,
      );
      _requireRevision(target.revision, request.expectedMemberRevision);
      if (!WorkspaceRoles.canAssignRole(actor.role, target.role, role)) {
        _fail(CloudWorkspaceErrorCode.permissionDenied);
      }
      await _repository.updateMemberRole(
        session,
        member: target,
        role: role,
        now: now,
        transaction: transaction,
      );
      return _MutationResult(
        value: null,
        responseJson: '{}',
        operation: 'memberRoleUpdated',
        resourceKind: 'member',
        resourceId: target.userId,
      );
    },
  );

  Future<void> removeMember(
    Session session, {
    required String userId,
    required RemoveWorkspaceMemberRequest request,
  }) {
    if (request.userId == userId) {
      _fail(CloudWorkspaceErrorCode.permissionDenied);
    }
    return _mutate(
      session,
      userId: userId,
      workspaceId: request.workspaceId,
      endpoint: 'cloudWorkspace.removeMember',
      requestId: request.requestId,
      requestBody: _requestBody(request.toJson()),
      decode: (_) {},
      run: (transaction, workspace, now) async {
        final actor = await _requireMember(
          session,
          request.workspaceId,
          userId,
          transaction: transaction,
        );
        final target = await _requireMember(
          session,
          request.workspaceId,
          request.userId,
          transaction: transaction,
        );
        _requireRevision(target.revision, request.expectedMemberRevision);
        if (target.role == WorkspaceRoles.owner) {
          _fail(CloudWorkspaceErrorCode.ownerCannotBeRemoved);
        }
        if (!WorkspaceRoles.canManageTarget(actor.role, target.role)) {
          _fail(CloudWorkspaceErrorCode.permissionDenied);
        }
        await _repository.removeMember(
          session,
          member: target,
          now: now,
          transaction: transaction,
        );
        return _MutationResult(
          value: null,
          responseJson: '{}',
          operation: 'memberRemoved',
          resourceKind: 'member',
          resourceId: target.userId,
        );
      },
    );
  }

  Future<void> deleteWorkspace(
    Session session, {
    required String userId,
    required DeleteCloudWorkspaceRequest request,
  }) => _mutate(
    session,
    userId: userId,
    workspaceId: request.workspaceId,
    endpoint: 'cloudWorkspace.deleteWorkspace',
    requestId: request.requestId,
    requestBody: {
      'workspaceId': request.workspaceId,
      'confirmationName': request.confirmationName,
      'expectedWorkspaceRevision': request.expectedWorkspaceRevision,
    },
    decode: (_) {},
    run: (transaction, workspace, now) async {
      _requireOwner(workspace, userId);
      _requireRevision(workspace.revision, request.expectedWorkspaceRevision);
      if (request.confirmationName != workspace.name) {
        _fail(CloudWorkspaceErrorCode.confirmationNameMismatch);
      }
      await _repository.softDeleteWorkspace(
        session,
        workspace: workspace,
        now: now,
        transaction: transaction,
      );
      return _MutationResult(
        value: null,
        responseJson: '{}',
        operation: 'deleted',
        resourceKind: 'workspace',
        resourceId: workspace.id.toString(),
        workspace: workspace.copyWith(
          revision: workspace.revision + 1,
          updatedAt: now,
          deletedAt: now,
        ),
      );
    },
  );

  Future<CloudWorkspace> _requireWorkspace(
    Session session,
    int id, {
    Transaction? transaction,
  }) async {
    final workspace = await _repository.findActiveWorkspace(
      session,
      id,
      transaction: transaction,
      lock: transaction != null,
    );
    if (workspace == null) _fail(CloudWorkspaceErrorCode.workspaceNotFound);
    return workspace;
  }

  Future<WorkspaceMember> _requireMember(
    Session session,
    int workspaceId,
    String userId, {
    Transaction? transaction,
  }) async {
    final member = await _repository.findActiveMember(
      session,
      workspaceId: workspaceId,
      userId: userId,
      transaction: transaction,
      lock: transaction != null,
    );
    if (member == null) _fail(CloudWorkspaceErrorCode.membershipRequired);
    return member;
  }

  Future<WorkspaceInvite> _requireInvite(
    Session session,
    int id, {
    Transaction? transaction,
  }) async {
    final invite = await _repository.findInviteById(
      session,
      id,
      transaction: transaction,
      lock: transaction != null,
    );
    if (invite == null) _fail(CloudWorkspaceErrorCode.inviteNotFound);
    return invite;
  }

  void _requireActiveInvite(WorkspaceInvite invite, DateTime now) {
    if (invite.revokedAt != null) _fail(CloudWorkspaceErrorCode.inviteRevoked);
    final expiresAt = invite.expiresAt ?? invite.createdAt.add(_inviteLifetime);
    if (!expiresAt.isAfter(now)) {
      _fail(CloudWorkspaceErrorCode.inviteExpired);
    }
    if (invite.acceptedAt != null || invite.declinedAt != null) {
      _fail(CloudWorkspaceErrorCode.inviteNotFound);
    }
  }

  void _requireInviteWorkspace(WorkspaceInvite invite, int workspaceId) {
    if (invite.workspaceId != workspaceId) {
      _fail(CloudWorkspaceErrorCode.inviteNotFound);
    }
  }

  void _requireOwner(CloudWorkspace workspace, String userId) {
    if (workspace.ownerUserId != userId) {
      _fail(CloudWorkspaceErrorCode.ownerRequired);
    }
  }

  String _requireName(String value) {
    final name = value.trim();
    if (name.isEmpty || name.length > _maxWorkspaceNameLength) {
      _fail(CloudWorkspaceErrorCode.validationFailed);
    }
    return name;
  }

  String _requireRole(String value) {
    final role = value.trim().toLowerCase();
    if (!WorkspaceRoles.isValid(role) || role == WorkspaceRoles.owner) {
      _fail(CloudWorkspaceErrorCode.invalidRole);
    }
    return role;
  }

  void _requireRevision(int actual, int expected) {
    if (actual != expected) _fail(CloudWorkspaceErrorCode.staleRevision);
  }

  Future<String?> _findEmail(Session session, String userId) async {
    try {
      final account = await EmailAccount.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(UuidValue.fromString(userId)),
      );
      return account?.email;
    } on FormatException {
      return null;
    }
  }

  Future<T> _mutate<T>(
    Session session, {
    required String userId,
    required int workspaceId,
    required String endpoint,
    required String requestId,
    required Map<String, Object?> requestBody,
    required T Function(Map<String, dynamic>) decode,
    required Future<_MutationResult<T>> Function(
      Transaction transaction,
      CloudWorkspace workspace,
      DateTime now,
    )
    run,
  }) => session.db.transaction((transaction) async {
    final requestHash = jsonEncode(requestBody);
    final receipt = await _repository.findReceipt(
      session,
      actorUserId: userId,
      scopeKey: 'workspace:$workspaceId',
      endpoint: endpoint,
      requestId: requestId,
      transaction: transaction,
    );
    if (receipt != null) {
      if (receipt.requestHash != requestHash) {
        _fail(CloudWorkspaceErrorCode.idempotencyConflict);
      }
      return decode(jsonDecode(receipt.responseJson) as Map<String, dynamic>);
    }
    final workspace = await _requireWorkspace(
      session,
      workspaceId,
      transaction: transaction,
    );
    final now = DateTime.now().toUtc();
    final result = await run(transaction, workspace, now);
    await _repository.recordMutation(
      session,
      workspace: result.workspace ?? workspace,
      actorUserId: userId,
      scopeKey: 'workspace:$workspaceId',
      endpoint: endpoint,
      requestId: requestId,
      requestHash: requestHash,
      operation: result.operation,
      resourceKind: result.resourceKind,
      resourceId: result.resourceId,
      responseJson: result.responseJson,
      now: now,
      transaction: transaction,
    );
    return result.value;
  });

  CloudWorkspaceInviteSummary _inviteSummary(WorkspaceInvite invite) =>
      CloudWorkspaceInviteSummary(
        id: invite.id!,
        email: invite.email,
        role: invite.role,
        invitedByUserId: invite.invitedByUserId,
        revision: invite.revision,
        createdAt: invite.createdAt,
        expiresAt: invite.expiresAt ?? invite.createdAt.add(_inviteLifetime),
      );

  static CloudWorkspaceCapabilities capabilitiesForRole(String role) =>
      CloudWorkspaceCapabilities(
        canViewMembers: WorkspaceRoles.canViewRoster(role),
        canInviteMembers: WorkspaceRoles.canInvite(role, WorkspaceRoles.member),
        canInviteAdmins: WorkspaceRoles.canInvite(role, WorkspaceRoles.admin),
        canManageMembers: WorkspaceRoles.canManageTarget(
          role,
          WorkspaceRoles.member,
        ),
        canManageAdmins: WorkspaceRoles.canManageTarget(
          role,
          WorkspaceRoles.admin,
        ),
        canRename: role == WorkspaceRoles.owner,
        canTransferOwnership: role == WorkspaceRoles.owner,
        canLeave: role != WorkspaceRoles.owner,
        canDelete: role == WorkspaceRoles.owner,
      );

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Map<String, Object?> _requestBody(Map<String, dynamic> json) =>
      Map<String, Object?>.from(json)..remove('requestId');

  Never _fail(CloudWorkspaceErrorCode code) =>
      throw CloudWorkspaceException(code: code);
}

class const _MutationResult<T>({
  required final T value,
  required final String responseJson,
  required final String operation,
  required final String resourceKind,
  final String? resourceId,
  final CloudWorkspace? workspace,
});
